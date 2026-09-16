//
//  Card.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 16/09/26.
//

import Foundation
import SwiftData

@Model
class Card {
	var id: UUID
	var ownCard: Bool
	
	var primaryText: String
	var secondaryText: String
	var primaryAddress: String
	var secondaryAddress: String
	var phoneNumber: String
	var emailAddress: String
	var webUrl: String
	
	init(card: SendableCard, ownCard: Bool = false) {
		self.id = UUID()
		self.ownCard = ownCard
		
		self.primaryText = card.primaryText
		self.secondaryText = card.secondaryText
		self.primaryAddress = card.primaryAddress
		self.secondaryAddress = card.secondaryAddress
		self.phoneNumber = card.phoneNumber
		self.emailAddress = card.emailAddress
		self.webUrl = card.webUrl
	}
	
	var sendableCard: SendableCard {
		return SendableCard(
			primaryText: self.primaryText,
			secondaryText: self.secondaryText,
			primaryAddress: self.primaryAddress,
			secondaryAddress: self.secondaryAddress,
			phoneNumber: self.phoneNumber,
			emailAddress: self.emailAddress,
			webUrl: self.webUrl
		)
	}
}
