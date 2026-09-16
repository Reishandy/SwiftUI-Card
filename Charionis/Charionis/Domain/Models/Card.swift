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
	var primaryAdress: String
	var secondaryAdress: String
	var phoneNumber: String
	var emailAdress: String
	var webUrl: String
	
	init(card: SendableCard, ownCard: Bool = false) {
		self.id = UUID()
		self.ownCard = ownCard
		
		self.primaryText = card.primaryText
		self.secondaryText = card.secondaryText
		self.primaryAdress = card.primaryAdress
		self.secondaryAdress = card.secondaryAdress
		self.phoneNumber = card.phoneNumber
		self.emailAdress = card.emailAdress
		self.webUrl = card.webUrl
	}
	
	var sendableCard: SendableCard {
		return SendableCard(
			primaryText: self.primaryText,
			secondaryText: self.secondaryText,
			primaryAdress: self.primaryAdress,
			secondaryAdress: self.secondaryAdress,
			phoneNumber: self.phoneNumber,
			emailAdress: self.emailAdress,
			webUrl: self.webUrl
		)
	}
}
