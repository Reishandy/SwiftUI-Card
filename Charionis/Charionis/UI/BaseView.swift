//
//  BaseView.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 14/09/26.
//

import SwiftUI

struct BaseView: View {
	@State private var baseViewModel = BaseViewModel()
	
	private var ownModel: OwnViewModel { baseViewModel.ownModel }
	private var peerModel: PeerViewModel { baseViewModel.peerModel }
	
	private var backdropOpacity: Double {
		let alignedOpacity = 0.5 + ownModel.sendProgress * 0.35
		return alignedOpacity + (0.45 - alignedOpacity) * peerModel.receivedBackdropProgress
	}
	private var gradientHeight: CGFloat {
		let baseHeight: CGFloat = 200.0
		let maxHeight: CGFloat = 400.0
		return baseHeight + CGFloat(ownModel.sendProgress) * (maxHeight - baseHeight)
	}
	private var backdropFadeHeight: CGFloat {
		let fullyReceivedFade: CGFloat = 250.0
		return gradientHeight + CGFloat(peerModel.receivedBackdropProgress) * (fullyReceivedFade - gradientHeight)
	}
	
	var body: some View {
		ZStack {
			BackgroundView(offset: CGSize(
				width: -ownModel.cameraOffset.width,
				height: -ownModel.cameraOffset.height
			))
			
			if ownModel.isAligned || peerModel.receivedCard != nil {
				Color.clear
					.overlay(alignment: .top) {
						VStack(spacing: 0) {
							Color.black.opacity(backdropOpacity)
								.frame(height: peerModel.backdropSolidHeight)
							
							LinearGradient(
								colors: [
									.black.opacity(backdropOpacity),
									.clear
								],
								startPoint: .top,
								endPoint: .bottom
							)
							.frame(height: backdropFadeHeight)
						}
						.frame(maxWidth: .infinity)
					}
					.contentShape(Rectangle())
					.clipped()
					.ignoresSafeArea()
					.transition(.move(edge: .top).combined(with: .opacity))
					.zIndex(peerModel.receivedCard != nil ? 2 : 1)
					.allowsHitTesting(peerModel.receivedCard != nil)
					.onTapGesture {
						peerModel.dismissReceivedCard()
					}
			}
			
			if ownModel.isDetailPresented {
				Color.black.opacity(0.45)
					.ignoresSafeArea()
					.transition(.opacity)
					.zIndex(1)
					.onTapGesture {
						ownModel.dismissDetail()
					}
			}
			
			CardView(
				data: ownModel.card,
				isRised: ownModel.isRised,
				flipAngle: ownModel.flip.flipAngle,
				tiltAngle: ownModel.flip.tiltAngle
			)
			.offset(
				x: ownModel.isDetailPresented ? 0 : ownModel.cardScreenOffset.width,
				y: ownModel.isDetailPresented ? 0 : (ownModel.cardScreenOffset.height + ownModel.transferYOffset)
			)
			.scaleEffect(ownModel.isDetailPresented ? 1.15 : 1)
			.opacity(ownModel.cardOpacity)
			.zIndex(2)
			.gesture(
				DragGesture(minimumDistance: 0)
					.onChanged { value in
						if ownModel.isDetailPresented {
							ownModel.flip.dragChanged(value)
						} else {
							ownModel.handlePositionChange(translation: value.translation)
						}
					}
					.onEnded { value in
						if ownModel.isDetailPresented {
							ownModel.flip.dragEnded(value)
						} else {
							ownModel.handlePositionEnded(translation: value.translation)
						}
					}
			)
			.disabled(ownModel.isSending)
			
			if let receivedCard = peerModel.receivedCard {
				CardView(
					data: receivedCard,
					isRised: true,
					flipAngle: peerModel.flip.flipAngle,
					tiltAngle: peerModel.flip.tiltAngle
				)
				.rotationEffect(.degrees(peerModel.receivedCardRotationAngle))
				.offset(y: peerModel.receivedCardYOffset)
				.scaleEffect(peerModel.receivedCardScale)
				.zIndex(4)
				.gesture(
					DragGesture(minimumDistance: 0)
						.onChanged { value in
							guard peerModel.isReceivedCardInteractive else { return }
							peerModel.flip.dragChanged(value)
						}
						.onEnded { value in
							guard peerModel.isReceivedCardInteractive else { return }
							peerModel.flip.dragEnded(value)
						}
				)
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.ignoresSafeArea()
		.animation(.easeInOut(duration: 1), value: ownModel.isAligned)
	}
}

#Preview {
	BaseView()
}
