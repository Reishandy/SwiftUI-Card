//
//  OwnViewModel.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 16/09/26.
//

import SwiftUI
import SwiftData

@MainActor
@Observable
class OwnViewModel {
	private var manager: SpatialManager
	private let modelContext: ModelContext
	
	var ownCard: SendableCard = SendableCard.empty
	
	// Canvas
	var cardPosition: CGSize = .zero
	var dragTranslation: CGSize = .zero
	var cameraOffset: CGSize = .zero
	var isRised: Bool = false
	var cardScreenOffset: CGSize {
		CGSize(
			width: (cardPosition.width + dragTranslation.width) - cameraOffset.width,
			height: (cardPosition.height + dragTranslation.height) - cameraOffset.height
		)
	}
	
	private var recenterTask: Task<Void, Never>?
	private let tapDistanceThreshold: CGFloat = 6.0
	
	// Card manipulation
	var isDetailPresented: Bool = false
	var isEditMode: Bool = false
	let flip = FlipCardController()
	
	var isCardValid: Bool {
		return !ownCard.primaryText.isEmpty
		&& !ownCard.secondaryText.isEmpty
		&& !ownCard.primaryAddress.isEmpty
		&& !ownCard.secondaryAddress.isEmpty
		&& !ownCard.phoneNumber.isEmpty
		&& !ownCard.emailAddress.isEmpty
		&& !ownCard.webUrl.isEmpty
	}
	var hasAppeared: Bool = false
	
	// Card sending
	var isSending: Bool = false
	var transferYOffset: CGFloat = 0.0
	var cardOpacity: Double = 1.0
	var isAligned: Bool {
		manager.isAligned
	}
	
	/// Returns 0.0...1.0 based on upward displacement towards the top of the screen
	/// Not actual progress for sending
	var sendProgress: Double {
		guard isAligned, !isDetailPresented, !isSending else { return 0.0 }
		
		let upwardDisplacement = -cardScreenOffset.height
		let startThreshold: CGFloat = 30.0
		let capThreshold: CGFloat = 150.0
		
		guard upwardDisplacement > startThreshold else { return 0.0 }
		let progress = (upwardDisplacement - startThreshold) / (capThreshold - startThreshold)
		return min(max(Double(progress), 0.0), 1.0)
	}
	
	private var sendTask: Task<Void, Never>?
	private var hasTriggeredFeedback: Bool = false
	
	init(manager: SpatialManager, modelContext: ModelContext) {
		self.manager = manager
		self.modelContext = modelContext
		
		fetchOwnCard()
		
		if ownCard == SendableCard.empty {
			toggleEditMode()
		}
	}
	
	func handlePositionChange(translation: CGSize) {
		guard !isSending else { return }
		recenterTask?.cancel()
		
		if !isRised {
			isRised = true
			HapticManager.shared.impact(.light)
		}
		
		if isAligned {
			if sendProgress >= 0.70 && !hasTriggeredFeedback {
				HapticManager.shared.impact(.medium)
				hasTriggeredFeedback = true
			} else if sendProgress < 0.70 {
				hasTriggeredFeedback = false
			}
		}
		 
		dragTranslation = translation
	}
	
	func handlePositionEnded(translation: CGSize) {
		guard !isSending else { return }
		isRised = false
		
		if isAligned && sendProgress >= 0.70 {
			triggerSendCard()
			return
		}
		
		dragTranslation = .zero
		let travelDistance = hypot(translation.width, translation.height)
		
		if travelDistance < tapDistanceThreshold {
			withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
				isDetailPresented = true
			}
		} else {
			cardPosition.width += translation.width
			cardPosition.height += translation.height
			
			HapticManager.shared.impact(.light)
			
			scheduleRecenter()
		}
	}
	
	func dismissDetail() {
		withAnimation(.spring(response: 0.75, dampingFraction: 0.75)) {
			isDetailPresented = false
			flip.reset()
		}
		
		HapticManager.shared.impact(.light)
		
		scheduleRecenter()
	}
	
	func toggleEditMode() {
		if isEditMode {
			guard isCardValid else { return }
			saveOwnCard(ownCard)
			
			withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
				isEditMode = false
			}
		} else {
			withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
				isDetailPresented = true
				isEditMode = true
				flip.flipAngle = 180.0
			}
		}
	}
	
	private func scheduleRecenter() {
		recenterTask?.cancel()
		recenterTask = Task {
			try? await Task.sleep(for: .seconds(1.5))
			guard !Task.isCancelled else { return }
			
			withAnimation(.spring(response: 0.75, dampingFraction: 0.75)) {
				cameraOffset = cardPosition
			}
		}
	}
	
	private func triggerSendCard() {
		isSending = true
		dragTranslation = .zero
		recenterTask?.cancel()
		sendTask?.cancel()
		
		withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
			transferYOffset = -DeviceMetrics.screenHeight
			cardOpacity = 0.0
		}
		
		sendTask = Task {
			manager.sendCardToAligned(ownCard)
			
			// Let card send animation
			try? await Task.sleep(for: .seconds(0.7))
			guard !Task.isCancelled else { return }
			
			// Silently reposition card
			var transaction = Transaction()
			transaction.disablesAnimations = true
			withTransaction(transaction) {
				self.cardPosition = .zero
				self.cameraOffset = .zero
				self.transferYOffset = DeviceMetrics.screenHeight
				self.cardOpacity = 0.0
				self.flip.reset()
			}
			
			try? await Task.sleep(for: .milliseconds(40))
			guard !Task.isCancelled else { return }
			
			// Bring back card
			withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) {
				self.transferYOffset = 0.0
				self.cardOpacity = 1.0
			}
			
			self.isSending = false
		}
	}
	
	private func fetchOwnCard() {
		let predicate = #Predicate<Card> { card in
			card.ownCard == true
		}
		
		var descriptor = FetchDescriptor<Card>(predicate: predicate)
		descriptor.fetchLimit = 1
		
		do {
			if let card = try modelContext.fetch(descriptor).first {
				self.ownCard = card.sendableCard
			} else {
				self.ownCard = SendableCard.empty
			}
		} catch {
			print("> Failed to fetch own card: \(error.localizedDescription)")
		}
	}
	
	func saveOwnCard(_ sendable: SendableCard) {
		let predicate = #Predicate<Card> { card in
			card.ownCard == true
		}
		var descriptor = FetchDescriptor<Card>(predicate: predicate)
		descriptor.fetchLimit = 1
		
		if let existingCard = try? modelContext.fetch(descriptor).first {
			existingCard.primaryText = sendable.primaryText
			existingCard.secondaryText = sendable.secondaryText
			existingCard.primaryAddress = sendable.primaryAddress
			existingCard.secondaryAddress = sendable.secondaryAddress
			existingCard.phoneNumber = sendable.phoneNumber
			existingCard.emailAddress = sendable.emailAddress
			existingCard.webUrl = sendable.webUrl
		} else {
			let newCard = Card(card: sendable, ownCard: true)
			modelContext.insert(newCard)
		}
		
		self.ownCard = sendable
	}
}
