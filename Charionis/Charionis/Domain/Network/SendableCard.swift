//
//  SendableCard.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 16/09/26.
//

import Foundation

struct SendableCard: Codable, Sendable {
	let primaryText: String
	let secondaryText: String
	let primaryAdress: String
	let secondaryAdress: String
	let phoneNumber: String
	let emailAdress: String
	let webUrl: String
}
