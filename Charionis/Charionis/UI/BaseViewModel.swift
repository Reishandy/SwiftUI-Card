//
//  BaseViewModel.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 15/09/26.
//

import SwiftUI

@Observable
@MainActor
class BaseViewModel {
	// TODO: CLEAN UP ALL THIS MESS HAHAHA
	
	// TODO: Ask permission all at once
	private var manager = SpatialManager()
	
	var cardPosition: CGSize = .zero
	var dragTranslation: CGSize = .zero
	var cameraOffset: CGSize = .zero
	
	var isRised: Bool = false
	var isDetailPresented: Bool = false
	
	var flipAngle: Double = 0.0
	var dragStartAngle: Double? = nil
	var tiltAngle: Double = 0.0
	
	var isSending: Bool = false
	var transferYOffset: CGFloat = 0.0
	var cardOpacity: Double = 1.0
	
	var receivedCard: SendableCard? = nil
	var receivedCardYOffset: CGFloat = 0.0
	var receivedCardRotationAngle: Double = 180.0
	var receivedCardFlipAngle: Double = 0.0
	var receivedCardTiltAngle: Double = 0.0
	var receivedCardScale: CGFloat = 1.0
	var isReceivedCardInteractive: Bool = false
	
	/// 0.0 = top alignment beam, 1.0 = fully covering the screen
	var receivedBackdropProgress: Double = 0.0
	
	var backdropOpacity: Double {
		let alignedOpacity = 0.5 + sendProgress * 0.35
		return alignedOpacity + (0.45 - alignedOpacity) * receivedBackdropProgress
	}
	
	private let fadeHeight: CGFloat = 250.0
	
	var backdropSolidHeight: CGFloat {
		CGFloat(receivedBackdropProgress) * screenHeight
	}
	
	var backdropFadeHeight: CGFloat {
		let baseFade = gradientHeight
		return baseFade + CGFloat(receivedBackdropProgress) * (fadeHeight - baseFade)
	}
	
	var cardScreenOffset: CGSize {
		CGSize(
			width: (cardPosition.width + dragTranslation.width) - cameraOffset.width,
			height: (cardPosition.height + dragTranslation.height) - cameraOffset.height
		)
	}
	
	var isAligned: Bool {
		manager.isAligned
	}
	
	/// Returns 0.0...1.0 based on upward displacement towards the top of the screen
	var sendProgress: Double {
		guard isAligned, !isDetailPresented, !isSending else { return 0.0 }
		
		let upwardDisplacement = -cardScreenOffset.height
		let startThreshold: CGFloat = 30.0
		let capThreshold: CGFloat = 150.0
		
		guard upwardDisplacement > startThreshold else { return 0.0 }
		let progress = (upwardDisplacement - startThreshold) / (capThreshold - startThreshold)
		return min(max(Double(progress), 0.0), 1.0)
	}
	
	var gradientHeight: CGFloat {
		let baseHeight: CGFloat = 200.0
		let maxHeight: CGFloat = 400.0
		return baseHeight + CGFloat(sendProgress) * (maxHeight - baseHeight)
	}
	
	// TODO: Move to actual storage
	var card = SendableCard(primaryText: "Acme", secondaryText: "John Doe", primaryAdress: "Business Street No 12", secondaryAdress: "Quepie, Queland, 1111", phoneNumber: "1234567890", emailAdress: "john.doe@acme.com", webUrl: "acme.com/john")
	
	private var recenterTask: Task<Void, Never>?
	private var sendTask: Task<Void, Never>?
	private var receiveTask: Task<Void, Never>?
	
	private let tapDistanceThreshold: CGFloat = 6.0
	private let flipDistanceThreshold: CGFloat = 200.0
	
	private var screenHeight: CGFloat {
		UIApplication.shared.connectedScenes
			.compactMap { $0 as? UIWindowScene }
			.flatMap { $0.windows }
			.first(where: \.isKeyWindow)?
			.bounds.height ?? 852.0 // Fallback to standard device height
	}
	
	private var hasTriggeredThresholdHaptic: Bool = false
	private var receivedCardDragStartAngle: Double? = nil
	
	init() {
		manager.onCardReceived = { [weak self] card in
			if self?.receivedCard == nil {
				self?.handleReceivedCard(card)
			}
		}
		
		manager.start()
	}
	
	// TODO: Deinit
	
	func handlePositionChange(translation: CGSize) {
		guard !isSending else { return }
		recenterTask?.cancel()
		
		if !isRised {
			isRised = true
		}
		dragTranslation = translation
		
		// TODO: Haptic rethink
		if sendProgress >= 1.0 && !hasTriggeredThresholdHaptic {
			UIImpactFeedbackGenerator(style: .medium).impactOccurred()
			hasTriggeredThresholdHaptic = true
		} else if sendProgress < 1.0 {
			hasTriggeredThresholdHaptic = false
		}
	}
	
	func handlePositionEnded(translation: CGSize) {
		guard !isSending else { return }
		isRised = false
		hasTriggeredThresholdHaptic = false
		
		if isAligned && sendProgress >= 0.70 {
			triggerSendCard()
			return
		}
		
		dragTranslation = .zero
		let travelDistance = hypot(translation.width, translation.height)
		
		if travelDistance < tapDistanceThreshold {
			handleCardTap()
		} else {
			cardPosition.width += translation.width
			cardPosition.height += translation.height
			scheduleRecenter()
		}
	}
	
	func triggerSendCard() {
		isSending = true
		dragTranslation = .zero
		recenterTask?.cancel()
		sendTask?.cancel()
		
		UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
		
		withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
			transferYOffset = -screenHeight
			cardOpacity = 0.0
		}
		
		sendTask = Task {
			manager.sendCardToAligned(card)
			
			try? await Task.sleep(for: .seconds(2.0))
			guard !Task.isCancelled else { return }
			
			// Silently reposition card
			var transaction = Transaction()
			transaction.disablesAnimations = true
			withTransaction(transaction) {
				self.cardPosition = .zero
				self.cameraOffset = .zero
				self.transferYOffset = screenHeight
				self.cardOpacity = 0.0
				self.flipAngle = 0.0
				self.tiltAngle = 0.0
			}
			
			// TODO: Haptic
			try? await Task.sleep(for: .milliseconds(40))
			guard !Task.isCancelled else { return }
			UIImpactFeedbackGenerator(style: .light).impactOccurred()
			
			// Bring back card
			withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) {
				self.transferYOffset = 0.0
				self.cardOpacity = 1.0
			}
			
			self.isSending = false
		}
	}
	
	func handleDetailDragChanged(value: DragGesture.Value) {
		if dragStartAngle == nil {
			dragStartAngle = flipAngle
		}
		
		let start = dragStartAngle ?? flipAngle
		let dragDelta = Double(-value.translation.width / flipDistanceThreshold) * 180.0
		flipAngle = start + dragDelta
		
		let rawTilt = Double(-value.translation.height / 15.0)
		tiltAngle = min(max(rawTilt, -15), 15)
	}
	
	func handleDetailDragEnded(value: DragGesture.Value) {
		let start = dragStartAngle ?? flipAngle
		dragStartAngle = nil
		
		let travelDistance = hypot(value.translation.width, value.translation.height)
		
		if travelDistance < tapDistanceThreshold {
			animateFlip(targetAngle: flipAngle == 180.0 ? start - 180.0 : start + 180.0)
		} else {
			let threshold: CGFloat = 50
			let dragWidth = value.translation.width
			let predictedWidth = value.predictedEndTranslation.width
			
			let targetAngle: Double
			if dragWidth < -threshold || predictedWidth < -threshold {
				targetAngle = start + 180.0
			} else if dragWidth > threshold || predictedWidth > threshold {
				targetAngle = start - 180.0
			} else {
				targetAngle = start
			}
			
			animateFlip(targetAngle: targetAngle)
		}
	}
	
	func handleCardTap() {
		withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
			isDetailPresented = true
		}
	}
	
	func dismissDetail() {
		withAnimation(.spring(response: 0.75, dampingFraction: 0.75)) {
			isDetailPresented = false
			flipAngle = 0
			tiltAngle = 0
			dragStartAngle = nil
		}
		
		scheduleRecenter()
	}
	
	private func animateFlip(targetAngle: Double) {
		withAnimation(.spring(response: 0.75, dampingFraction: 0.75)) {
			flipAngle = targetAngle
			tiltAngle = 0
		} completion: {
			// Normalize angle to [0 360] to prevent angle accumulation
			// that can result on lots of backflips on dismiss
			var transaction = Transaction()
			transaction.disablesAnimations = true
			withTransaction(transaction) {
				let degrees = self.flipAngle.truncatingRemainder(dividingBy: 360)
				self.flipAngle = degrees < 0 ? degrees + 360 : degrees
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
	
	func handleReceivedCard(_ card: SendableCard) {
		receiveTask?.cancel()
		
		var transaction = Transaction()
		transaction.disablesAnimations = true
		withTransaction(transaction) {
			self.receivedCard = card
			self.receivedCardYOffset = -self.screenHeight
			self.receivedCardRotationAngle = 180.0
			self.receivedCardScale = 1.0
			self.receivedCardFlipAngle = 0.0
			self.receivedCardTiltAngle = 0.0
			self.isReceivedCardInteractive = false
			self.receivedBackdropProgress = 0.0
		}
		
		receiveTask = Task {
			try? await Task.sleep(for: .milliseconds(50))
			guard !Task.isCancelled else { return }
			
			UIImpactFeedbackGenerator(style: .medium).impactOccurred()
			
			withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
				self.receivedCardYOffset = 0.0
				self.receivedBackdropProgress = 1.0
			}
			
			try? await Task.sleep(for: .milliseconds(400))
			guard !Task.isCancelled else { return }
			
			withAnimation(.spring(response: 0.75, dampingFraction: 0.75)) {
				self.receivedCardRotationAngle = 0.0
				self.receivedCardScale = 1.15
			}
			try? await Task.sleep(for: .milliseconds(750))
			guard !Task.isCancelled else { return }
			
			self.isReceivedCardInteractive = true
		}
	}
	
	func dismissReceivedCard() {
		receiveTask?.cancel()
		isReceivedCardInteractive = false
		
		withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
			receivedCard = nil
			receivedBackdropProgress = 0.0
			receivedCardYOffset = 0.0
			receivedCardRotationAngle = 0.0
			receivedCardFlipAngle = 0.0
			receivedCardTiltAngle = 0.0
			receivedCardScale = 1.0
		}
	}
	
	// MARK: - Received Card Flip Gestures
	
	func handleReceivedCardDragChanged(value: DragGesture.Value) {
		guard isReceivedCardInteractive else { return }
		
		if receivedCardDragStartAngle == nil {
			receivedCardDragStartAngle = receivedCardFlipAngle
		}
		
		let start = receivedCardDragStartAngle ?? receivedCardFlipAngle
		let dragDelta = Double(-value.translation.width / flipDistanceThreshold) * 180.0
		receivedCardFlipAngle = start + dragDelta
		
		let rawTilt = Double(-value.translation.height / 15.0)
		receivedCardTiltAngle = min(max(rawTilt, -15), 15)
	}
	
	func handleReceivedCardDragEnded(value: DragGesture.Value) {
		guard isReceivedCardInteractive else { return }
		
		let start = receivedCardDragStartAngle ?? receivedCardFlipAngle
		receivedCardDragStartAngle = nil
		
		let travelDistance = hypot(value.translation.width, value.translation.height)
		if travelDistance < tapDistanceThreshold {
			animateReceivedCardFlip(targetAngle: receivedCardFlipAngle == 180.0 ? start - 180.0 : start + 180.0)
		} else {
			let threshold: CGFloat = 50
			let dragWidth = value.translation.width
			let predictedWidth = value.predictedEndTranslation.width
			
			let targetAngle: Double
			if dragWidth < -threshold || predictedWidth < -threshold {
				targetAngle = start + 180.0
			} else if dragWidth > threshold || predictedWidth > threshold {
				targetAngle = start - 180.0
			} else {
				targetAngle = start
			}
			animateReceivedCardFlip(targetAngle: targetAngle)
		}
	}
	
	private func animateReceivedCardFlip(targetAngle: Double) {
		withAnimation(.spring(response: 0.75, dampingFraction: 0.75)) {
			receivedCardFlipAngle = targetAngle
			receivedCardTiltAngle = 0
		} completion: {
			var transaction = Transaction()
			transaction.disablesAnimations = true
			withTransaction(transaction) {
				let degrees = self.receivedCardFlipAngle.truncatingRemainder(dividingBy: 360)
				self.receivedCardFlipAngle = degrees < 0 ? degrees + 360 : degrees
			}
		}
	}
}
