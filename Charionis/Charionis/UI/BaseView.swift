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
	@State private var isRised: Bool = false
	
	// TODO: Haptic when card is picked up and released
	
    var body: some View {
		ZStack {
			BackgroundView()
			
			CardView(isRised: isRised)
				.offset(
					x: cardPosition.width + dragTranslation.width,
					y: cardPosition.height + dragTranslation.height
				)
				.gesture(
					DragGesture(minimumDistance: 0)
						.onChanged { value in
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
							
							// Ready for later: trigger a timer or Task here
							// to animate canvas/camera offset toward `cardPosition`
						}
				)
		}
    }
}

#Preview {
    BaseView()
}
