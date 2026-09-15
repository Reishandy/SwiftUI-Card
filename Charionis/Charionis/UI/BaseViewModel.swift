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
	private var manager = SpatialManager()
	
	var cardPosition: CGSize = .zero
	var dragTranslation: CGSize = .zero
	var cameraOffset: CGSize = .zero
	
	var isRised: Bool = false
	var isDetailPresented: Bool = false
	
	var flipAngle: Double = 0.0
	var dragStartAngle: Double? = nil
	var tiltAngle: Double = 0.0
	
	var cardScreenOffset: CGSize {
		CGSize(
			width: (cardPosition.width + dragTranslation.width) - cameraOffset.width,
			height: (cardPosition.height + dragTranslation.height) - cameraOffset.height
		)
	}
	
	var isAligned: Bool {
		manager.isAligned
	}
	
	private var recenterTask: Task<Void, Never>?
	
	private let tapDistanceThreshold: CGFloat = 6.0
	private let flipDistanceThreshold: CGFloat = 200.0
	
	init() {
		manager.start()
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
	
	func handlePositionChange(translation: CGSize) {
		recenterTask?.cancel()
		
		if !isRised {
			isRised = true
		}
		
		dragTranslation = translation
	}
	
	func handlePositionEnded(translation: CGSize) {
		isRised = false
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
}
