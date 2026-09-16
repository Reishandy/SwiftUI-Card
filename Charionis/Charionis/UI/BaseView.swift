//
//  BaseView.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 14/09/26.
//

import SwiftUI

struct BaseView: View {
	@State private var viewModel = BaseViewModel()
	
	var body: some View {
		ZStack {
			BackgroundView(offset: CGSize(
				width: -viewModel.cameraOffset.width,
				height: -viewModel.cameraOffset.height
			))
			
			if viewModel.isAligned || viewModel.receivedCard != nil {
				Color.clear
					.overlay(alignment: .top) {
						VStack(spacing: 0) {
							Color.black.opacity(viewModel.backdropOpacity)
								.frame(height: viewModel.backdropSolidHeight)
							
							LinearGradient(
								colors: [
									.black.opacity(viewModel.backdropOpacity),
									.clear
								],
								startPoint: .top,
								endPoint: .bottom
							)
							.frame(height: viewModel.backdropFadeHeight)
						}
						.frame(maxWidth: .infinity)
					}
					.contentShape(Rectangle())
					.clipped()
					.ignoresSafeArea()
					.transition(.move(edge: .top).combined(with: .opacity))
					.zIndex(2.5)
					.allowsHitTesting(viewModel.receivedCard != nil)
					.onTapGesture {
						viewModel.dismissReceivedCard()
					}
			}
			
			if viewModel.isDetailPresented {
				Color.black.opacity(0.45)
					.ignoresSafeArea()
					.transition(.opacity)
					.zIndex(1)
					.onTapGesture {
						viewModel.dismissDetail()
					}
			}
			
			CardView(
				data: viewModel.card,
				isRised: viewModel.isRised,
				flipAngle: viewModel.flipAngle,
				tiltAngle: viewModel.tiltAngle
			)
			.offset(
				x: viewModel.isDetailPresented ? 0 : viewModel.cardScreenOffset.width,
				y: viewModel.isDetailPresented ? 0 : (viewModel.cardScreenOffset.height + viewModel.transferYOffset)
			)
			.scaleEffect(viewModel.isDetailPresented ? 1.15 : 1)
			.opacity(viewModel.cardOpacity)
			.zIndex(2)
			.gesture(
				DragGesture(minimumDistance: 0)
					.onChanged { value in
						if viewModel.isDetailPresented {
							viewModel.handleDetailDragChanged(value: value)
						} else {
							viewModel.handlePositionChange(translation: value.translation)
						}
					}
					.onEnded { value in
						if viewModel.isDetailPresented {
							viewModel.handleDetailDragEnded(value: value)
						} else {
							viewModel.handlePositionEnded(translation: value.translation)
						}
					}
			)
			.disabled(viewModel.isSending)
			
			if let receivedCard = viewModel.receivedCard {
				CardView(
					data: receivedCard,
					isRised: true,
					flipAngle: viewModel.receivedCardFlipAngle,
					tiltAngle: viewModel.receivedCardTiltAngle
				)
				.rotationEffect(.degrees(viewModel.receivedCardRotationAngle))
				.offset(y: viewModel.receivedCardYOffset)
				.scaleEffect(viewModel.receivedCardScale)
				.zIndex(3)
				.gesture(
					DragGesture(minimumDistance: 0)
						.onChanged { value in
							viewModel.handleReceivedCardDragChanged(value: value)
						}
						.onEnded { value in
							viewModel.handleReceivedCardDragEnded(value: value)
						}
				)
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.ignoresSafeArea()
		.animation(.easeInOut(duration: 1), value: viewModel.isAligned)
	}
}

#Preview {
	BaseView()
}
