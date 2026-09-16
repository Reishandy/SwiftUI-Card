//
//  CardView.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 14/09/26.
//

import SwiftUI

struct CardView: View, Animatable {
	var data: SendableCard? = nil
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
				
			
			cardFront
				.opacity(isBackVisible ? 0 : 1)
				.accessibilityHidden(isBackVisible)
			
			cardBack
				.rotation3DEffect(.degrees(180), axis: (x: 0, y: -1, z: 0))
				.opacity(isBackVisible ? 1 : 0)
				.accessibilityHidden(!isBackVisible)
		}
		.containerRelativeFrame(.horizontal) { length, axis in
			length * 0.8
		}
		.containerRelativeFrame(.vertical) { height, axis in
			height * 0.25
		}
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
	
	@ViewBuilder
	private var cardFront: some View {
		VStack {
			Text(data?.primaryText.uppercased() ?? "")
				.font(.title.bold())
			
			Text(data?.secondaryText ?? "")
				.font(.body.weight(.light))
		}
	}
	
	// TODO: Placeholder text replace
	@ViewBuilder
	private var cardBack: some View {
		VStack {
			VStack(alignment: .leading) {
				Text(data?.primaryText.uppercased() ?? "")
					.font(.title3.bold())
				
				Text(data?.secondaryText ?? "")
					.font(.caption.weight(.light))
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			
			Spacer()
			
			HStack(alignment: .bottom) {
				VStack(alignment: .leading) {
					Text(data?.primaryAdress ?? "")
						.font(.caption2)
					
					Text(data?.secondaryAdress ?? "")
						.font(.caption2)
				}
				
				Spacer()
				
				VStack {
					ReversedTextIcon(
						text: data?.phoneNumber ?? "",
						systemIcon: "phone.fill"
					)
					
					ReversedTextIcon(
						text: data?.emailAdress ?? "",
						systemIcon: "envelope.fill"
					)
					
					ReversedTextIcon(
						text: data?.webUrl ?? "",
						systemIcon: "globe.fill"
					)
				}
			}
		}
		.padding(20)
	}
}

// TODO: Revamp the icon haha...
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
	let card = SendableCard(
		primaryText: "Acme",
		secondaryText: "John Doe",
		primaryAdress: "Business Street No 12",
		secondaryAdress: "Quepie, Queland, 1111",
		phoneNumber: "1234567890",
		emailAdress: "john.doe@acme.com",
		webUrl: "acme.com/john"
	)
	
	VStack(spacing: 50) {
		CardView()
		CardView(data: card)
		CardView(data: card, isRised: true, flipAngle: 180)
	}
}
