//
//  SendableCard.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 16/09/26.
//

import Foundation

struct SendableCard: Codable, Sendable, Equatable {
	var primaryText: String
	var secondaryText: String
	var primaryAddress: String
	var secondaryAddress: String
	var phoneNumber: String
	var emailAddress: String
	var webUrl: String
	
	static let empty = SendableCard(
		primaryText: "",
		secondaryText: "",
		primaryAddress: "",
		secondaryAddress: "",
		phoneNumber: "",
		emailAddress: "",
		webUrl: ""
	)
}
