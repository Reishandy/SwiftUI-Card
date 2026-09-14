//
//  BackgroundView.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 14/09/26.
//

import SwiftUI

struct BackgroundView: View {
	// TODO: Change to actual bg image
    var body: some View {
		ZStack {
			Color.white
			
			GridShape(spacing: 50)
				.stroke(Color.blue.opacity(0.25), lineWidth: 1)
				.ignoresSafeArea()
		}
		.ignoresSafeArea()
    }
}

// TODO: Temp, remove
struct GridShape: Shape {
	var spacing: CGFloat = 30
	
	func path(in rect: CGRect) -> Path {
		var path = Path()
		
		// Vertical lines
		for x in stride(from: 0, through: rect.width, by: spacing) {
			path.move(to: CGPoint(x: x, y: 0))
			path.addLine(to: CGPoint(x: x, y: rect.height))
		}
		
		// Horizontal lines
		for y in stride(from: 0, through: rect.height, by: spacing) {
			path.move(to: CGPoint(x: 0, y: y))
			path.addLine(to: CGPoint(x: rect.width, y: y))
		}
		
		return path
	}
}

#Preview {
    BackgroundView()
}
