//
//  BackgroundView.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 14/09/26.
//

import SwiftUI

struct BackgroundView: View, Animatable {
	var offset: CGSize = .zero
	var customTileSize: CGSize? = nil
	
	var animatableData: AnimatablePair<CGFloat, CGFloat> {
		get { AnimatablePair(offset.width, offset.height) }
		set { offset = CGSize(width: newValue.first, height: newValue.second) }
	}
	
	private var tileSize: CGSize {
		if let customTileSize {
			return customTileSize
		}
		
		if let uiImage = UIImage(named: "Background") {
			return uiImage.size
		}
		
		return CGSize(width: 100, height: 100)
	}
	
	var body: some View {
		GeometryReader { proxy in
			let size = tileSize
			let xOffset = offset.width.truncatingRemainder(dividingBy: size.width)
			let yOffset = offset.height.truncatingRemainder(dividingBy: size.height)
			
			Image("Background")
				.resizable(resizingMode: .tile)
				.frame(
					width: proxy.size.width + (size.width * 4),
					height: proxy.size.height + (size.height * 4)
				)
				.offset(x: xOffset, y: yOffset)
				.frame(
					width: proxy.size.width,
					height: proxy.size.height,
					alignment: .center
				)
				.clipped()
		}
		.ignoresSafeArea()
	}
}

#Preview {
	BackgroundView()
}
