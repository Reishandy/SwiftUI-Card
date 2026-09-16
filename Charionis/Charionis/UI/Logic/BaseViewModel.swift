//
//  BaseViewModel.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 16/09/26.
//

import SwiftUI

/// Just a wrapper at this point...
@MainActor
@Observable
class BaseViewModel {
	let manager: SpatialManager
	let ownModel: OwnViewModel
	let peerModel: PeerViewModel
	
	// TODO: Ask permission all at once
	
	init() {
		let manager = SpatialManager()
		self.manager = manager
		self.ownModel = OwnViewModel(manager: manager)
		self.peerModel = PeerViewModel(manager: manager)
		
		manager.start()
	}
	
	// TODO: Deinit / stop manager
}
