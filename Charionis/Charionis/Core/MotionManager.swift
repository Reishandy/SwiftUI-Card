//
//  MotionManager.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 15/09/26.
//

import CoreMotion
import Foundation

@MainActor
final class MotionManager {
	private let motion = CMMotionManager()
	
	var currentHeading: Double = 0.0
	
	func start() {
		guard motion.isDeviceMotionAvailable else { return }
		motion.deviceMotionUpdateInterval = 1.0 / 30.0
		motion.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { [weak self] data, _ in
			guard let data, let self else { return }
			
			// Sensor fusion yaw -> Compass heading degrees (0...360)
			let yawDeg = (-data.attitude.yaw * 180.0 / .pi)
			self.currentHeading = (yawDeg + 360.0).truncatingRemainder(dividingBy: 360.0)
		}
	}
	
	func stop() {
		motion.stopDeviceMotionUpdates()
	}
}
