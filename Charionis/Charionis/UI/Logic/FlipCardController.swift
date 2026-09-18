//
//  FlipCardController.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 16/09/26.
//
import SwiftUI

@MainActor
@Observable
final class FlipCardController {
	var flipAngle: Double = 0.0
	var tiltAngle: Double = 0.0
	
	var isBackVisible: Bool {
		let degrees = flipAngle.truncatingRemainder(dividingBy: 360)
		let normalized = degrees < 0 ? degrees + 360 : degrees
		return normalized > 90 && normalized < 270
	}
	
	private var dragStartAngle: Double? = nil
	private let tapDistanceThreshold: CGFloat = 6.0
	private let flipDistanceThreshold: CGFloat = 200.0
	
	func dragChanged(_ value: DragGesture.Value) {
		if dragStartAngle == nil {
			dragStartAngle = flipAngle
		}
		
		let start = dragStartAngle ?? flipAngle
		let dragDelta = Double(-value.translation.width / flipDistanceThreshold) * 180.0
		flipAngle = start + dragDelta
		
		let rawTilt = Double(-value.translation.height / 15.0)
		tiltAngle = min(max(rawTilt, -15), 15)
	}
	
	func dragEnded(_ value: DragGesture.Value) {
		let start = dragStartAngle ?? flipAngle
		dragStartAngle = nil
		
		let travelDistance = hypot(value.translation.width, value.translation.height)
		
		if travelDistance < tapDistanceThreshold {
			animateFlip(to: flipAngle == 180.0 ? start - 180.0 : start + 180.0)
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
			
			animateFlip(to: targetAngle)
		}
	}
	
	/// Resets angle and any in-flight drag state — call when the card is dismissed
	/// or repositioned outside of a user drag (e.g. after sending).
	func reset() {
		flipAngle = 0
		tiltAngle = 0
		dragStartAngle = nil
	}
	
	private func animateFlip(to targetAngle: Double) {
		withAnimation(.spring(response: 0.75, dampingFraction: 0.75)) {
			flipAngle = targetAngle
			tiltAngle = 0
		} completion: {
			// Normalize angle to [0, 360) to prevent angle accumulation
			// that can result in lots of backflips on dismiss
			var transaction = Transaction()
			transaction.disablesAnimations = true
			withTransaction(transaction) {
				let degrees = self.flipAngle.truncatingRemainder(dividingBy: 360)
				self.flipAngle = degrees < 0 ? degrees + 360 : degrees
			}
		}
	}
}
