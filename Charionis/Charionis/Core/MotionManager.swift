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
			
			let m = data.attitude.rotationMatrix
			
			// The top of the phone is the device +Y axis.
			// In .xMagneticNorthZVertical:
			// m.m12 = projection onto Reference X (Magnetic North)
			// m.m22 = projection onto Reference Y (Magnetic West) -> -m.m22 is East
			let north = m.m12
			let east = -m.m22
			
			// Azimuth in radians clockwise from North
			let radians = atan2(east, north)
			var degrees = radians * 180.0 / .pi
			if degrees < 0 {
				degrees += 360.0
			}
			
			self.currentHeading = degrees
		}
	}
	
	func stop() {
		motion.stopDeviceMotionUpdates()
	}
}
