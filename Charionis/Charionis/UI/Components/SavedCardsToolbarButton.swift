//
//  SavedCardsToolbarButton.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 17/09/26.
//

import SwiftUI
import SwiftData

struct SavedCardsToolbarButton: View {
	@Binding var isSavedCardShown: Bool
	var onToggle: () -> Void
	
	@Query(filter: #Predicate<Card> { !$0.ownCard })
	private var savedCards: [Card]
	
	var body: some View {
		if !savedCards.isEmpty {
			Button(action: onToggle) {
				Image(systemName: isSavedCardShown ? "arrow.backward" : "rectangle.grid.1x2")
			}
			.transition(.opacity.combined(with: .scale))
		}
	}
}
