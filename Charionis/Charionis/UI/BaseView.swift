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
			
			if viewModel.isAligned {
				LinearGradient(
					stops: [
						.init(color: .black.opacity(0.5 + viewModel.sendProgress * 0.35), location: 0.0),
						.init(color: .clear, location: 1.0)
					],
					startPoint: .top,
					endPoint: .bottom
				)
				.frame(height: viewModel.gradientHeight)
				.frame(maxHeight: .infinity, alignment: .top)
				.ignoresSafeArea(edges: .top)
				.transition(.move(edge: .top).combined(with: .opacity))
				.zIndex(1.5)
				.allowsHitTesting(false)
				.animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: viewModel.gradientHeight)
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
		}
		.animation(.easeInOut(duration: 1), value: viewModel.isAligned)
	}
}

#Preview {
	BaseView()
}
