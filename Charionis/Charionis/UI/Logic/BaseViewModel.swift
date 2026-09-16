//
//  BaseViewModel.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 16/09/26.
//

import SwiftUI
import SwiftData

/// Just a wrapper at this point...
@MainActor
@Observable
class BaseViewModel {
	let manager: SpatialManager
	let ownModel: OwnViewModel
	let peerModel: PeerViewModel
	
	var backdropOpacity: Double {
		let alignedOpacity = 0.5 + ownModel.sendProgress * 0.35
		return alignedOpacity + (0.45 - alignedOpacity) * peerModel.receivedBackdropProgress
	}
	var gradientHeight: CGFloat {
		let baseHeight: CGFloat = 200.0
		let maxHeight: CGFloat = 400.0
		return baseHeight + CGFloat(ownModel.sendProgress) * (maxHeight - baseHeight)
	}
	var backdropFadeHeight: CGFloat {
		let fullyReceivedFade: CGFloat = 250.0
		return gradientHeight + CGFloat(peerModel.receivedBackdropProgress) * (fullyReceivedFade - gradientHeight)
	}
	
	// TODO: Ask permission all at once
	
	init(modelContext: ModelContext) {
		let manager = SpatialManager()
		self.manager = manager
		self.ownModel = OwnViewModel(manager: manager, modelContext: modelContext)
		self.peerModel = PeerViewModel(manager: manager, modelContext: modelContext)
		
		manager.start()
	}
	
	// TODO: Deinit / stop manager
}
