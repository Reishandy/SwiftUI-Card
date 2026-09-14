//
//  CardView.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 14/09/26.
//

import SwiftUI

struct CardView: View {
	var isRised: Bool = false
	var isDetail: Bool = false
	
    var body: some View {
		ZStack {
			RoundedRectangle(cornerRadius: 5)
				.foregroundStyle(.white)
				.shadow(radius: isRised ? 30 : 8, y: isRised ? 20 : 4)
				
		}
		.frame(width: 320, height: 190)
		.scaleEffect(isDetail ? 1.15 : 1)
		.animation(.spring(response: 0.3, dampingFraction: 0.7), value: isRised)
    }
}

#Preview {
	VStack(spacing: 50) {
		CardView()
		CardView(isRised: true)
	}
}
