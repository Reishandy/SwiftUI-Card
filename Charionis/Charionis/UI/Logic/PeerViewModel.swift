//
//  PeerViewModel.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 16/09/26.
//

import SwiftUI

@MainActor
@Observable
class PeerViewModel {
	private var manager: SpatialManager
	
	// Card receiving
	var receivedCard: SendableCard? = nil
	private var receiveTask: Task<Void, Never>?
	
	// Receiving animation
	var receivedCardYOffset: CGFloat = 0.0
	var receivedCardRotationAngle: Double = 180.0
	let flip = FlipCardController()
	var receivedCardScale: CGFloat = 1.0
	var isReceivedCardInteractive: Bool = false
	
	/// 0.0 = top alignment beam, 1.0 = fully covering the screen
	var receivedBackdropProgress: Double = 0.0
	var backdropSolidHeight: CGFloat {
		CGFloat(receivedBackdropProgress) * DeviceMetrics.screenHeight
	}
	
	init(manager: SpatialManager) {
		self.manager = manager
		
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
			self.flip.reset()
			self.isReceivedCardInteractive = false
			self.receivedBackdropProgress = 0.0
		}
		
		receiveTask = Task {
			try? await Task.sleep(for: .milliseconds(50))
			guard !Task.isCancelled else { return }
			
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
			flip.reset()
			receivedCardScale = 1.0
		}
	}
}
