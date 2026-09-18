//
//  IndicatorDots.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 18/09/26.
//

import SwiftUI

struct IndicatorDots: View {
	var isBackVisible: Bool = false
	
	var body: some View {
		HStack(spacing: 8) {
			ForEach(0..<2) { index in
				let isCurrent = (index == (isBackVisible ? 1 : 0))
				Circle()
					.fill(isCurrent ? Color.white : Color.white.opacity(0.35))
					.frame(width: 7, height: 7)
					.scaleEffect(isCurrent ? 1.15 : 1.0)
					.contentShape(Rectangle().inset(by: -6))
			}
		}
		.padding(.vertical, 6)
		.padding(.horizontal, 10)
		.background(
			Capsule()
				.fill(Color.black.opacity(0.25))
		)
		.animation(.spring(response: 0.35, dampingFraction: 0.75), value: isBackVisible)
		.transition(.opacity.combined(with: .scale(scale: 0.85)))
	}
}

#Preview {
    IndicatorDots()
}
