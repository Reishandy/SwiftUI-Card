//
//  PeerViewModel.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 16/09/26.
//

import SwiftUI
import SwiftData

@MainActor
@Observable
class PeerViewModel {
	private var manager: SpatialManager
	private let modelContext: ModelContext
	
	// Card receiving
	var receivedCard: SendableCard? = nil
	private var receiveTask: Task<Void, Never>?
	
	// Receiving animation & interactive states
	var receivedCardYOffset: CGFloat = 0.0
	var receivedCardRotationAngle: Double = 180.0
	var receivedCardScale: CGFloat = 1.0
	var isReceivedCardInteractive: Bool = false
	
	let flip = FlipCardController()
	
	// Backdrop progress
	var receivedBackdropProgress: Double = 0.0
	var backdropSolidHeight: CGFloat {
		CGFloat(receivedBackdropProgress) * DeviceMetrics.screenHeight
	}
	
	// Wallet orchestration & drag-to-dismiss
	var isWalletPresented: Bool = false
	var isDismissingToWallet: Bool = false
	var isDraggingToWallet: Bool = false
	var cardDragOffset: CGSize = .zero
	private var hasTriggeredDismissFeedback: Bool = false
	
	let walletHeight: CGFloat = 280.0
	let walletPeekAmount: CGFloat = 140.0
	let walletMaxExtraExposure: CGFloat = 85.0
	
	/// Returns 0.0...1.0 based on downward drag distance towards the wallet
	var dismissProgress: Double {
		guard isReceivedCardInteractive, isWalletPresented else { return 0.0 }
		let downwardDisplacement = cardDragOffset.height
		let startThreshold: CGFloat = 20.0
		let capThreshold: CGFloat = 220.0
		guard downwardDisplacement > startThreshold else { return 0.0 }
		let progress = (downwardDisplacement - startThreshold) / (capThreshold - startThreshold)
		return min(max(Double(progress), 0.0), 1.0)
	}
	
	/// Controls how much of the wallet is peeking / exposed from the bottom
	var walletYOffset: CGFloat {
		guard isWalletPresented else { return walletHeight + 60.0 }
		let restingOffset = walletHeight - walletPeekAmount
		let dynamicLift = CGFloat(dismissProgress) * walletMaxExtraExposure
		return restingOffset - dynamicLift
	}
	
	init(manager: SpatialManager, modelContext: ModelContext) {
		self.manager = manager
		self.modelContext = modelContext
		
		self.manager.onCardReceived = { [weak self] card in
			if self?.receivedCard == nil {
				self?.handleReceivedCard(card)
			}
		}
	}
	
	func handleReceivedCard(_ card: SendableCard) {
		receiveTask?.cancel()
		
		var transaction = Transaction()
		transaction.disablesAnimations = true
		withTransaction(transaction) {
			self.receivedCard = card
			self.receivedCardYOffset = -DeviceMetrics.screenHeight
			self.receivedCardRotationAngle = 180.0
			self.receivedCardScale = 1.0
			self.cardDragOffset = .zero
			self.isDraggingToWallet = false
			self.isDismissingToWallet = false
			self.isWalletPresented = false
			self.flip.reset()
			self.isReceivedCardInteractive = false
			self.receivedBackdropProgress = 0.0
			self.hasTriggeredDismissFeedback = false
		}
		
		receiveTask = Task {
			try? await Task.sleep(for: .milliseconds(50))
			guard !Task.isCancelled else { return }
			
			// Drop into center
			withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
				self.receivedCardYOffset = 0.0
				self.receivedBackdropProgress = 1.0
			}
			
			try? await Task.sleep(for: .milliseconds(400))
			guard !Task.isCancelled else { return }
			
			// Rotate to upright and scale up
			withAnimation(.spring(response: 0.75, dampingFraction: 0.75)) {
				self.receivedCardRotationAngle = 0.0
				self.receivedCardScale = 1.15
			}
			
			try? await Task.sleep(for: .milliseconds(750))
			guard !Task.isCancelled else { return }
			
			// Make interactive & slide wallet up into peeking position
			withAnimation(.spring(response: 0.55, dampingFraction: 0.75)) {
				self.isWalletPresented = true
				self.isReceivedCardInteractive = true
			}
			HapticManager.shared.impact(.light)
		}
	}
	
	func handleCardDragChanged(_ value: DragGesture.Value) {
		guard isReceivedCardInteractive, !isDismissingToWallet else { return }
		
		let horizontal = abs(value.translation.width)
		let vertical = value.translation.height
		
		// Determine if drag is downward towards the wallet
		if !isDraggingToWallet && vertical > 15.0 && vertical > horizontal {
			isDraggingToWallet = true
		}
		
		if isDraggingToWallet {
			let y = max(0, value.translation.height)
			let x = value.translation.width * 0.25
			cardDragOffset = CGSize(width: x, height: y)
			
			if dismissProgress >= 0.70 && !hasTriggeredDismissFeedback {
				HapticManager.shared.impact(.medium)
				hasTriggeredDismissFeedback = true
			} else if dismissProgress < 0.70 {
				hasTriggeredDismissFeedback = false
			}
		} else {
			flip.dragChanged(value)
		}
	}
	
	func handleCardDragEnded(_ value: DragGesture.Value) {
		guard isReceivedCardInteractive, !isDismissingToWallet else { return }
		
		if isDraggingToWallet {
			let shouldDismiss = dismissProgress >= 0.70 || value.predictedEndTranslation.height > 350.0
			
			if shouldDismiss {
				triggerDismissToWallet()
			} else {
				hasTriggeredDismissFeedback = false
				isDraggingToWallet = false
				withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
					cardDragOffset = .zero
				}
			}
		} else {
			flip.dragEnded(value)
		}
	}
	
	private func triggerDismissToWallet() {
		isDismissingToWallet = true
		
		if let card = receivedCard {
			saveReceivedCard(card)
			HapticManager.shared.notification(.success)
		}
		
		receiveTask?.cancel()
		receiveTask = Task {
			// Slide the card completely down off-screen behind the wallet
			withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
				self.cardDragOffset.height = DeviceMetrics.screenHeight
				self.receivedCardScale = 1.0
			}
			
			try? await Task.sleep(for: .milliseconds(300))
			guard !Task.isCancelled else { return }
			
			// Slide wallet down and fade backdrop
			withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
				self.isWalletPresented = false
				self.receivedBackdropProgress = 0.0
			}
			
			try? await Task.sleep(for: .milliseconds(400))
			guard !Task.isCancelled else { return }
			
			self.dismissReceivedCard()
		}
	}
	
	func dismissReceivedCard() {
		receiveTask?.cancel()
		isReceivedCardInteractive = false
		isWalletPresented = false
		isDismissingToWallet = false
		isDraggingToWallet = false
		hasTriggeredDismissFeedback = false
		
		withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
			receivedCard = nil
			receivedBackdropProgress = 0.0
			receivedCardYOffset = 0.0
			receivedCardRotationAngle = 0.0
			receivedCardScale = 1.0
			cardDragOffset = .zero
			flip.reset()
		}
	}
	
	private func saveReceivedCard(_ sendable: SendableCard) {
		let newCard = Card(card: sendable, ownCard: false)
		modelContext.insert(newCard)
		try? modelContext.save()
	}
}
