//
//  TrackedPeer.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 15/09/26.
//

import Foundation

struct TrackedPeer: Identifiable, Sendable {
	let id: String
	var distance: Float?
	var remoteHeading: Double?
	var isFacing: Bool = false
	var isAligned: Bool = false
}
