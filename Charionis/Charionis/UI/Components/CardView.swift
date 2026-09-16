//
//  CardView.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 14/09/26.
//

import SwiftUI

struct CardView: View, Animatable {
	@Binding var data: SendableCard
	var isRised: Bool = false
	var isEditMode: Bool = false
	var flipAngle: Double = 0.0
	var tiltAngle: Double = 0.0
	
	init(
		data: Binding<SendableCard>,
		isRised: Bool = false,
		isEditMode: Bool = false,
		flipAngle: Double = 0.0,
		tiltAngle: Double = 0.0
	) {
		self._data = data
		self.isRised = isRised
		self.isEditMode = isEditMode
		self.flipAngle = flipAngle
		self.tiltAngle = tiltAngle
	}
	
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
			Text(data.primaryText.uppercased())
				.font(.title.bold())
			
			Text(data.secondaryText)
				.font(.body.weight(.light))
		}
	}
	
	@ViewBuilder
	private var cardBack: some View {
		VStack {
			VStack(alignment: .leading) {
				CardField(
					placeholder: "Company",
					text: $data.primaryText,
					isEditMode: isEditMode,
					editFont: .title3.bold(),
					displayFont: .title3.bold(),
					fixedHeight: 20,
					verticalPadding: 8,
					uppercased: true
				)
				
				CardField(
					placeholder: "Name",
					text: $data.secondaryText,
					isEditMode: isEditMode,
					editFont: .caption.weight(.light),
					displayFont: .caption.weight(.light),
					fixedHeight: 14,
					verticalPadding: 4
				)
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			
			Spacer()
			
			HStack(alignment: .bottom) {
				VStack(alignment: .leading) {
					CardField(
						placeholder: "Address 1",
						text: $data.primaryAddress,
						isEditMode: isEditMode,
						editFont: .caption2,
						displayFont: .caption2,
						stretchToFill: true
					)
					
					CardField(
						placeholder: "Address 2",
						text: $data.secondaryAddress,
						isEditMode: isEditMode,
						editFont: .caption2,
						displayFont: .caption2,
						stretchToFill: true
					)
				}
				.frame(maxWidth: 140)
				
				Spacer()
				
				HStack {
					VStack(alignment: .trailing, spacing: 4) {
						CardField(
							placeholder: "Phone",
							text: $data.phoneNumber,
							isEditMode: isEditMode,
							editFont: .caption2,
							displayFont: .caption.weight(.semibold)
						)
						
						CardField(
							placeholder: "Email",
							text: $data.emailAddress,
							isEditMode: isEditMode,
							editFont: .caption2,
							displayFont: .caption.weight(.semibold)
						)
						
						CardField(
							placeholder: "Website",
							text: $data.webUrl,
							isEditMode: isEditMode,
							editFont: .caption2,
							displayFont: .caption.weight(.semibold)
						)
					}
					
					VStack(spacing: isEditMode ? 10 : 4) {
						Image(systemName: "phone.fill")
							.font(.caption2.weight(.semibold))
						
						Image(systemName: "envelope.fill")
							.font(.caption2.weight(.semibold))
						
						Image(systemName: "globe.fill")
							.font(.caption2.weight(.semibold))
					}
				}
			}
		}
		.padding(20)
	}
}

struct CardField: View {
	let placeholder: String
	@Binding var text: String
	var isEditMode: Bool
	var editFont: Font
	var displayFont: Font
	var fixedHeight: CGFloat = 14
	var verticalPadding: CGFloat = 2
	var horizontalPadding: CGFloat = 8
	var uppercased: Bool = false
	var alignment: Alignment = .leading
	var stretchToFill: Bool = false
	
	private var textAlignment: TextAlignment {
		switch alignment {
		case .trailing: return .trailing
		case .center: return .center
		default: return .leading
		}
	}
	
	var body: some View {
		if isEditMode {
			TextField(placeholder, text: $text)
				.font(editFont)
				.frame(height: fixedHeight)
				.padding(.vertical, verticalPadding)
				.padding(.horizontal, horizontalPadding)
				.border(Color.black, width: 1)
		} else {
			Text(uppercased ? text.uppercased() : text)
				.font(displayFont)
				.multilineTextAlignment(textAlignment)
				.frame(maxWidth: stretchToFill ? .infinity : nil, alignment: alignment)
				.lineLimit(1)
				.truncationMode(.middle)
		}
	}
}

#Preview {
	let card = SendableCard(
		primaryText: "Acme",
		secondaryText: "John Doe",
		primaryAddress: "Business Street No 12",
		secondaryAddress: "Quepie, Queland, 1111",
		phoneNumber: "1234567890",
		emailAddress: "john.doe@acme.com",
		webUrl: "acme.com/john"
	)
	
	VStack(spacing: 50) {
		CardView(data: .constant(SendableCard.empty), isEditMode: true, flipAngle: 180)
		CardView(data: .constant(card))
		CardView(data: .constant(card), isRised: true, flipAngle: 180)
	}
}
