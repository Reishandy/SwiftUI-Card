//
//  SavedCardsView.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 17/09/26.
//

import SwiftUI
import SwiftData

struct SavedCardsView: View {
	var isVisible: Bool = true
	
	@Query(filter: #Predicate<Card> { !$0.ownCard }, sort: \.primaryText) private var savedCards: [Card]
	
	private let flyDistance: CGFloat = DeviceMetrics.screenHeight + 100
	
	var body: some View {
		ZStack {
			Color.black.opacity(isVisible ? 0.45 : 0.0)
				.ignoresSafeArea()
				.animation(.easeInOut(duration: 0.3), value: isVisible)
			
			ScrollView {
				LazyVStack {
					ForEach(Array(savedCards.enumerated()), id: \.element.id) { index, card in
						SavedCardRow(card: card)
							.offset(y: isVisible ? 0 : flyDistance)
							.animation(staggerAnimation(for: index), value: isVisible)
					}
				}
				.padding(.vertical, 150)
			}
			.scrollDisabled(!isVisible)
		}
	}
	
	private func staggerAnimation(for index: Int) -> Animation {
		let cappedIndex = min(index, 5)
		if isVisible {
			return .spring(response: 0.55, dampingFraction: 0.78)
				.delay(Double(cappedIndex) * 0.07)
		} else {
			return .spring(response: 0.42, dampingFraction: 0.85)
				.delay(Double(cappedIndex) * 0.04)
		}
	}
}

struct SavedCardRow: View {
	let card: Card
	@State private var flipAngle: Double = 0.0
	
	private var isFlipped: Bool {
		let normalized = Int(flipAngle).magnitude % 360
		return normalized > 90 && normalized < 270
	}
	
	var body: some View {
		CardView(
			data: .constant(card.sendableCard),
			isRised: isFlipped,
			isEditMode: false,
			flipAngle: flipAngle,
			tiltAngle: 0.0
		)
		.scaleEffect(1.15)
		.contentShape(Rectangle())
		.onTapGesture {
			withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
				if flipAngle == 180.0 {
					flipAngle -= 180.0
				} else {
					flipAngle += 180.0
				}
			}
		}
		.padding(.vertical, 24)
	}
}

#Preview {
	let config = ModelConfiguration(isStoredInMemoryOnly: true)
	let container = try! ModelContainer(for: Card.self, configurations: config)
	
	let sampleCards = [
		SendableCard(
			primaryText: "Apple Inc.",
			secondaryText: "Craig Federighi",
			primaryAddress: "One Apple Park Way",
			secondaryAddress: "Cupertino, CA 95014",
			phoneNumber: "+1 408 996 1010",
			emailAddress: "craig@apple.com",
			webUrl: "apple.com"
		),
		SendableCard(
			primaryText: "Acme Corp",
			secondaryText: "John Doe",
			primaryAddress: "Business Street No 12",
			secondaryAddress: "Quepie, Queland, 1111",
			phoneNumber: "1234567890",
			emailAddress: "john.doe@acme.com",
			webUrl: "acme.com/john"
		)
	]
	
	for cardData in sampleCards {
		let card = Card(card: cardData, ownCard: false)
		container.mainContext.insert(card)
	}
	
	return SavedCardsView()
		.modelContainer(container)
}
