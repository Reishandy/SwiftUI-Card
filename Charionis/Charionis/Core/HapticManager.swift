//
//  HapticManager.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 17/09/26.
//

import UIKit

@MainActor
final class HapticManager {
	static let shared = HapticManager()
	private init() {}
	
	func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
		let generator = UIImpactFeedbackGenerator(style: style)
		generator.prepare()
		generator.impactOccurred()
	}
	
	func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
		let generator = UINotificationFeedbackGenerator()
		generator.prepare()
		generator.notificationOccurred(type)
	}
	
	func selection() {
		let generator = UISelectionFeedbackGenerator()
		generator.prepare()
		generator.selectionChanged()
	}
}
