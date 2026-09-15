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
				y: viewModel.isDetailPresented ? 0 : viewModel.cardScreenOffset.height
			)
			.zIndex(viewModel.isDetailPresented ? 2 : 0)
			.scaleEffect(viewModel.isDetailPresented ? 1.15 : 1)
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
		}
		.sensoryFeedback(.impact(weight: .medium, intensity: 0.85), trigger: viewModel.isRised) { _, isRaised in
			isRaised
		}
	}
}

#Preview {
	BaseView()
}
