//
//  DeviceMetrics.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 16/09/26.
//

import SwiftUI

enum DeviceMetrics {
	/// Falls back to a standard device height when no key window is available.
	@MainActor
	static var screenHeight: CGFloat {
		UIApplication.shared.connectedScenes
			.compactMap { $0 as? UIWindowScene }
			.flatMap(\.windows)
			.first(where: \.isKeyWindow)?
			.bounds.height ?? 852.0
	}
}
