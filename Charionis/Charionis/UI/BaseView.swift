//
//  BaseView.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 14/09/26.
//

import SwiftUI

struct BaseView: View {
	@State private var cardPosition: CGSize = .zero
	@State private var dragTranslation: CGSize = .zero
	@State private var cameraOffset: CGSize = .zero
	
	@State private var isRised: Bool = false
	@State private var isDetailPresented: Bool = false
	
	@State private var flipAngle: Double = 0.0
	@State private var dragStartAngle: Double? = nil
	@State private var tiltAngle: Double = 0.0
	
	@State private var recenterTask: Task<Void, Never>?
	
	private let tapDistanceThreshold: CGFloat = 6.0
	private let flipDistanceThreshold: CGFloat = 200.0
	
	private var cardScreenOffset: CGSize {
		CGSize(
			width: (cardPosition.width + dragTranslation.width) - cameraOffset.width,
			height: (cardPosition.height + dragTranslation.height) - cameraOffset.height
		)
	}
	
	var body: some View {
		ZStack {
			BackgroundView(offset: CGSize(
				width: -cameraOffset.width,
				height: -cameraOffset.height
			))
			
			if isDetailPresented {
				Color.black.opacity(0.45)
					.ignoresSafeArea()
					.transition(.opacity)
					.zIndex(1)
					.onTapGesture {
						dismissDetail()
					}
			}
			
			CardView(
				isRised: isRised,
				flipAngle: flipAngle,
				tiltAngle: tiltAngle
			)
			.offset(
				x: isDetailPresented ? 0 : cardScreenOffset.width,
				y: isDetailPresented ? 0 : cardScreenOffset.height
			)
			.zIndex(isDetailPresented ? 2 : 0)
			.scaleEffect(isDetailPresented ? 1.2 : 1)
			.gesture(
				DragGesture(minimumDistance: 0)
					.onChanged { value in
						if isDetailPresented {
							handleDetailDragChanged(value: value)
						} else {
							handlePositionChange(translation: value.translation)
						}
					}
					.onEnded { value in
						if isDetailPresented {
							handleDetailDragEnded(value: value)
						} else {
							handlePositionEnded(translation: value.translation)
						}
					}
			)
		}
		.sensoryFeedback(.impact(weight: .medium, intensity: 0.85), trigger: isRised) { _, isRaised in
			isRaised
		}
	}
	
	private func handleDetailDragChanged(value: DragGesture.Value) {
		if dragStartAngle == nil {
			dragStartAngle = flipAngle
		}
		
		let start = dragStartAngle ?? flipAngle
		let dragDelta = Double(-value.translation.width / flipDistanceThreshold) * 180.0
		flipAngle = start + dragDelta
		
		let rawTilt = Double(-value.translation.height / 15.0)
		tiltAngle = min(max(rawTilt, -15), 15)
	}
	
	private func handleDetailDragEnded(value: DragGesture.Value) {
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
			// Drag form left
			if dragWidth < -threshold || predictedWidth < -threshold {
				targetAngle = start + 180.0
			// Drag from right
			} else if dragWidth > threshold || predictedWidth > threshold {
				targetAngle = start - 180.0
			} else {
				targetAngle = start
			}
			
			animateFlip(targetAngle: targetAngle)
		}
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
				let degrees = flipAngle.truncatingRemainder(dividingBy: 360)
				flipAngle = degrees < 0 ? degrees + 360 : degrees
			}
		}
	}
	
	private func handlePositionChange(translation: CGSize) {
		recenterTask?.cancel()
		
		if !isRised {
			isRised = true
		}
		
		dragTranslation = translation
	}
	
	private func handlePositionEnded(translation: CGSize) {
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
	
	private func handleCardTap() {
		withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
			isDetailPresented = true
		}
	}
	
	private func dismissDetail() {
		withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
			isDetailPresented = false
			flipAngle = 0
			tiltAngle = 0
			dragStartAngle = nil
		}
		
		scheduleRecenter()
	}
	
	private func scheduleRecenter() {
		recenterTask?.cancel()
		recenterTask = Task {
			try? await Task.sleep(for: .seconds(1.5))
			guard !Task.isCancelled else { return }
			
			withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
				cameraOffset = cardPosition
			}
		}
	}
}

#Preview {
	BaseView()
}
