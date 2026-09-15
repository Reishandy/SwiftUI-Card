//
//  CardView.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 14/09/26.
//

import SwiftUI

struct CardView: View, Animatable {
	var isRised: Bool = false
	var flipAngle: Double = 0.0
	var tiltAngle: Double = 0.0
	
	var animatableData: Double {
		get { flipAngle }
		set { flipAngle = newValue }
	}
	
	private var isBackVisible: Bool {
		let degrees = flipAngle.truncatingRemainder(dividingBy: 360)
		let normalized = degrees < 0 ? degrees + 360 : degrees
		return normalized > 90 && normalized < 270
	}
	
	var body: some View {
		ZStack {
			Image("Card")
				.resizable()
				.clipShape(RoundedRectangle(cornerRadius: 5))
				.frame(width: 320, height: 190)
			
			cardFront
				.opacity(isBackVisible ? 0 : 1)
				.accessibilityHidden(isBackVisible)
			
			cardBack
				.rotation3DEffect(.degrees(180), axis: (x: 0, y: -1, z: 0))
				.opacity(isBackVisible ? 1 : 0)
				.accessibilityHidden(!isBackVisible)
		}
		.frame(width: 320, height: 190)
		.rotation3DEffect(
			.degrees(flipAngle),
			axis: (x: 0, y: -1, z: 0),
			perspective: 0.35
		)
		.rotation3DEffect(
			.degrees(tiltAngle),
			axis: (x: 1, y: 0, z: 0),
			perspective: 0.35
		)
		.shadow(radius: isRised ? 30 : 8, y: isRised ? 20 : 4)
		.animation(.spring(response: 0.3, dampingFraction: 0.7), value: isRised)
		.contentShape(Rectangle())
	}
	
	// TODO: Placeholder text replace
	@ViewBuilder
	private var cardFront: some View {
		VStack {
			Text("EXAMPLE TEXT")
				.font(.title.bold())
			
			Text("Another Example Text")
				.font(.body.weight(.light))
		}
	}
	
	// TODO: Placeholder text replace
	@ViewBuilder
	private var cardBack: some View {
		VStack {
			VStack(alignment: .leading) {
				Text("EXAMPLE TEXT")
					.font(.title3.bold())
				
				Text("Another Example Text")
					.font(.caption.weight(.light))
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			
			Spacer()
			
			HStack(alignment: .bottom) {
				VStack(alignment: .leading) {
					Text("Street adress, City")
						.font(.caption2)
					
					Text("State, ZIP, Country")
						.font(.caption2)
				}
				
				Spacer()
				
				VStack {
					ReversedTextIcon(
						text: "+621234567890",
						systemIcon: "phone.fill"
					)
					
					ReversedTextIcon(
						text: "john.doe@acme.com",
						systemIcon: "envelope.fill"
					)
					
					ReversedTextIcon(
						text: "acme.com",
						systemIcon: "globe.fill"
					)
				}
			}
		}
		.padding(20)
	}
}

struct ReversedTextIcon: View {
	let text: String
	let systemIcon: String
	
	var body: some View {
		HStack {
			Spacer()
			
			Text(text)
				.font(.caption2.weight(.semibold))
			
			Image(systemName: systemIcon)
				.font(.caption2.weight(.semibold))
		}
	}
}

#Preview {
	VStack(spacing: 50) {
		CardView()
		CardView(isRised: true, flipAngle: 180)
	}
}
