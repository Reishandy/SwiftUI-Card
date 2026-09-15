//
//  PeerHandshake.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 15/09/26.
//

import Foundation

struct PeerHandshake: Codable, Sendable {
	let peerID: String
	let discoveryToken: Data
}
