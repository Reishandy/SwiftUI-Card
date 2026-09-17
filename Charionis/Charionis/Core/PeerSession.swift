//
//  PeerSession.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 15/09/26.
//

import Foundation
import Network
import NearbyInteraction
import UIKit

@MainActor
final class PeerSession: NSObject, NISessionDelegate {
	var peerID: String
	let connection: NWConnection
	private var session: NISession?
	
	var currentDistance: Float?
	var remoteHeading: Double?
	private(set) var lastLocalHeading: Double = 0.0
	
	var alignmentDistanceThreshold: Float = 0.3	// Meters
	var facingAngleTolerance: Double = 20.0			// Degrees
	
	var onSpatialUpdate: (@Sendable (String, Float?, Bool, Bool) -> Void)?
	var onSessionEnded: (@Sendable (String) -> Void)?
	var onCardReceived: (@Sendable (SendableCard) -> Void)?
	
	private var isListening = false
	
	var angleError: Double? {
		guard let remoteHeading else { return nil }
		let diff = abs(lastLocalHeading - remoteHeading).truncatingRemainder(dividingBy: 360.0)
		let angularDistance = diff > 180.0 ? 360.0 - diff : diff
		return abs(180.0 - angularDistance)
	}
	
	var isDistanceWithinThreshold: Bool {
		guard let currentDistance else { return false }
		return currentDistance <= alignmentDistanceThreshold
	}
	
	init(peerID: String, connection: NWConnection) {
		self.peerID = peerID
		self.connection = connection
		super.init()
		
		if NISession.deviceCapabilities.supportsPreciseDistanceMeasurement {
			let session = NISession()
			session.delegate = self
			session.delegateQueue = .main
			self.session = session
		}
	}
	
	var localTokenData: Data? {
		guard let token = session?.discoveryToken else { return nil }
		return try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
	}
	
	func startRanging(with remoteTokenData: Data) {
		guard let session else { return }
		do {
			guard let token = try NSKeyedUnarchiver.unarchivedObject(
				ofClass: NIDiscoveryToken.self,
				from: remoteTokenData
			) else { return }
			
			let config = NINearbyPeerConfiguration(peerToken: token)
			session.run(config)
			startReceivingHeadings()
		} catch {
			stop()
		}
	}
	
	func sendLocalHeading(_ heading: Double) {
		var value = heading
		let data = Data(bytes: &value, count: MemoryLayout<Double>.size)
		Framing.send(data: data, over: connection)
	}
	
	func sendCard(_ card: SendableCard) {
		guard let data = try? JSONEncoder().encode(card) else { return }
		Framing.send(data: data, over: connection)
	}
	
	func evaluateAlignment(localHeading: Double) {
		self.lastLocalHeading = localHeading
		
		guard let remoteHeading, let currentDistance else {
			notifySpatialUpdate(isFacing: false, isAligned: false)
			return
		}
		
		// Check opposing heading: diff should be ~180°
		let diff = abs(localHeading - remoteHeading).truncatingRemainder(dividingBy: 360.0)
		let angularDistance = diff > 180.0 ? 360.0 - diff : diff
		let angleError = abs(180.0 - angularDistance)
		let isFacing = angleError <= facingAngleTolerance
		
		let isAligned = isFacing && (currentDistance <= alignmentDistanceThreshold)
		
		notifySpatialUpdate(isFacing: isFacing, isAligned: isAligned)
		
		// TODO: Remove
		print("> \(localHeading) \(remoteHeading) - \(angleError) \(isFacing) | \(currentDistance) | \(isAligned)")
	}
	
	private func notifySpatialUpdate(isFacing: Bool, isAligned: Bool) {
		onSpatialUpdate?(peerID, currentDistance, isFacing, isAligned)
	}
	
	private func startReceivingHeadings() {
		guard !isListening else { return }
		isListening = true
		
		Task { [weak self] in
			while !Task.isCancelled {
				guard let self else { break }
				do {
					let data = try await Framing.receive(from: self.connection)
					
					if data.count == MemoryLayout<Double>.size {
						let heading = data.withUnsafeBytes { $0.load(as: Double.self) }
						self.remoteHeading = heading
						self.evaluateAlignment(localHeading: self.lastLocalHeading)
					} else if let card = try? JSONDecoder().decode(SendableCard.self, from: data) {
						self.onCardReceived?(card)
					}
				} catch {
					break
				}
			}
		}
	}
	
	func stop() {
		isListening = false
		session?.invalidate()
		session = nil
		connection.cancel()
	}
	
	nonisolated func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
		MainActor.assumeIsolated {
			guard let object = nearbyObjects.first else { return }
			self.currentDistance = object.distance
			self.evaluateAlignment(localHeading: self.lastLocalHeading)
		}
	}
	
	nonisolated func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
		MainActor.assumeIsolated { self.onSessionEnded?(self.peerID) }
	}
	
	nonisolated func session(_ session: NISession, didInvalidateWith error: any Error) {
		MainActor.assumeIsolated { self.onSessionEnded?(self.peerID) }
	}
	
	nonisolated func sessionWasSuspended(_ session: NISession) {
		MainActor.assumeIsolated { self.onSessionEnded?(self.peerID) }
	}
}
