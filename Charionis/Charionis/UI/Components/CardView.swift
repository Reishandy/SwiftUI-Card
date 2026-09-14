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
			.frame(width: 300, height: 170)
			.foregroundStyle(.white)
			.shadow(radius: isRised ? 30 : 8, y: isRised ? 20 : 4)
    }
}

#Preview {
	VStack(spacing: 50) {
		CardView()
		CardView(isRised: true)
	}
}
