//
//  CardView.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 14/09/26.
//

import SwiftUI

struct CardView: View {
	var isRised: Bool = false
	
    var body: some View {
        RoundedRectangle(cornerRadius: 5)
			.frame(width: 320, height: 190)
			.foregroundStyle(.white)
			.shadow(radius: isRised ? 30 : 8, y: isRised ? 20 : 4)
			.animation(.spring(response: 0.3, dampingFraction: 0.7), value: isRised)
    }
}

#Preview {
	VStack(spacing: 50) {
		CardView()
		CardView(isRised: true)
	}
}
