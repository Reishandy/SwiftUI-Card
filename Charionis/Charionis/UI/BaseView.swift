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
	
	@State private var recenterTask: Task<Void, Never>?
	
    var body: some View {
		ZStack {
			BackgroundView(offset: CGSize(width: -cameraOffset.width, height: -cameraOffset.height))
			
			CardView(isRised: isRised)
				.offset(
					x: (cardPosition.width + dragTranslation.width) - cameraOffset.width,
					y: (cardPosition.height + dragTranslation.height) - cameraOffset.height
				)
				.gesture(
					DragGesture(minimumDistance: 0)
						.onChanged { value in
							recenterTask?.cancel()
							
							if !isRised {
								isRised = true
							}
							dragTranslation = value.translation
						}
						.onEnded { value in
							cardPosition.width += value.translation.width
							cardPosition.height += value.translation.height
							dragTranslation = .zero
							isRised = false
							
							recenterTask = Task {
								try? await Task.sleep(for: .seconds(2))
								guard !Task.isCancelled else { return }
								
								withAnimation(.spring(response: 1, dampingFraction: 0.85)) {
									cameraOffset = cardPosition
								}
							}
						}
				)
		}
		.sensoryFeedback(.impact(weight: .medium, intensity: 0.85), trigger: isRised) { _, isRaised in
			isRaised
		}
    }
}

#Preview {
    BaseView()
}
