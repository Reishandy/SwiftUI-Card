//
//  PeerPacket.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 15/09/26.
//

import Foundation

enum PeerPacket: Codable, Sendable {
	case heading(Double)
	case message(Data)
}
