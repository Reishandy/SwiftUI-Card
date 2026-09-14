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
	
	@State private var recenterTask: Task<Void, Never>?
	
	private let tapDistanceThreshold: CGFloat = 6.0
	
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
				isFlipped: false // TODO:
			)
			.offset(
				x: isDetailPresented ? 0 : cardScreenOffset.width,
				y: isDetailPresented ? 0 : cardScreenOffset.height
			)
			.zIndex(isDetailPresented ? 2 : 0)
			.allowsHitTesting(!isDetailPresented)
			.scaleEffect(isDetailPresented ? 1.2 : 1)
			.gesture(
				DragGesture(minimumDistance: 0)
					.onChanged { value in
						handlePositionChange(translation: value.translation)
					}
					.onEnded { value in
						handlePositionSettle(translation: value.translation)
					}
			)
		}
		.sensoryFeedback(.impact(weight: .medium, intensity: 0.85), trigger: isRised) { _, isRaised in
			isRaised
		}
	}
	
	private func handlePositionChange(translation: CGSize) {
		recenterTask?.cancel()
		
		if !isRised {
			isRised = true
		}
		dragTranslation = translation
	}
	
	private func handlePositionSettle(translation: CGSize) {
		isRised = false
		dragTranslation = .zero
		
		let travelDistance = hypot(translation.width, translation.height)
		
		if travelDistance < tapDistanceThreshold {
			handleCardTap()
		} else {
			cardPosition.width += translation.width
			cardPosition.height += translation.height
		}
		
		scheduleRecenter()
	}
	
	private func handleCardTap() {
		recenterTask?.cancel()
		withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
			isDetailPresented = true
		}
	}
	
	private func dismissDetail() {
		withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
			isDetailPresented = false
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
