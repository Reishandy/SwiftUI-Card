//
//  CardView.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 14/09/26.
//

import SwiftUI

struct CardView: View {
	var isRised: Bool = false
	var isFlipped: Bool = false
	
    var body: some View {
		ZStack {
			RoundedRectangle(cornerRadius: 5)
				.foregroundStyle(.white)
				.shadow(radius: isRised ? 30 : 8, y: isRised ? 20 : 4)
				
			if isFlipped {
				cardBack
			} else {
				cardFront
			}
		}
		.frame(width: 320, height: 190)
		.animation(.spring(response: 0.3, dampingFraction: 0.7), value: isRised)
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
			
			// TODO: Check proportion
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
		CardView(isRised: true, isFlipped: true)
	}
}
