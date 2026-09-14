//
//  BackgroundView.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 14/09/26.
//

import SwiftUI

struct BackgroundView: View {
	// TODO: Change to actual bg image
	var offset: CGSize = .zero
	
	var body: some View {
		ZStack {
			Color.white
			
			GridShape(spacing: 50, offset: offset)
				.stroke(Color.blue.opacity(0.25), lineWidth: 1)
				.ignoresSafeArea()
		}
		.ignoresSafeArea()
	}
}

// TODO: Temp, remove
struct GridShape: Shape {
	var spacing: CGFloat = 50
	var offset: CGSize = .zero
	
	// Animate grid translation alongside camera movements
	var animatableData: AnimatablePair<CGFloat, CGFloat> {
		get { AnimatablePair(offset.width, offset.height) }
		set { offset = CGSize(width: newValue.first, height: newValue.second) }
	}
	
	func path(in rect: CGRect) -> Path {
		var path = Path()
		
		let xOffset = offset.width.truncatingRemainder(dividingBy: spacing)
		let yOffset = offset.height.truncatingRemainder(dividingBy: spacing)
		
		for x in stride(from: xOffset - spacing, through: rect.width + spacing, by: spacing) {
			path.move(to: CGPoint(x: x, y: 0))
			path.addLine(to: CGPoint(x: x, y: rect.height))
		}
		
		for y in stride(from: yOffset - spacing, through: rect.height + spacing, by: spacing) {
			path.move(to: CGPoint(x: 0, y: y))
			path.addLine(to: CGPoint(x: rect.width, y: y))
		}
		
		return path
	}
}

#Preview {
    BackgroundView()
}
