//
//  SpatialManager.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 15/09/26.
//

import SwiftUI
import Network
import NearbyInteraction

@Observable
@MainActor
final class SpatialManager {
	var trackedPeers: [String: TrackedPeer] = [:]
	var isRunning = false
	
	var peerList: [TrackedPeer] {
		Array(trackedPeers.values)
	}
	
	/// True when at least one peer is currently aligned
	var isAligned: Bool {
		alignedPeer != nil
	}
	
	/// Returns the currently aligned peer, or nil
	var alignedPeer: TrackedPeer? {
		trackedPeers.values.first(where: { $0.isAligned })
	}
	
	private let networkService = PeerNetworkService()
	private let motionManager = MotionManager()
	private var activeSessions: [String: PeerSession] = [:]
	private var headingTimer: Timer?
	
	init() {
		setupBindings()
	}
	
	func start() {
		isRunning = true
		motionManager.start()
		networkService.start()
		
		headingTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
			MainActor.assumeIsolated {
				self?.broadcastHeading()
			}
		}
	}
	
	func stop() {
		isRunning = false
		headingTimer?.invalidate()
		headingTimer = nil
		motionManager.stop()
		networkService.stop()
		for session in activeSessions.values {
			session.stop()
		}
		activeSessions.removeAll()
		trackedPeers.removeAll()
	}
	
	/// Send data to the currently aligned peer
	func sendToAligned(data: Data) {
		guard let peer = alignedPeer else { return }
		// TODO: Send data over connection to peer.id
		_ = peer
	}
	
	private func broadcastHeading() {
		let heading = motionManager.currentHeading
		for session in activeSessions.values {
			session.sendLocalHeading(heading)
			session.evaluateAlignment(localHeading: heading)
		}
	}
	
	private func setupBindings() {
		networkService.onPeerDiscovered = { [weak self] connection, knownPeerID in
			MainActor.assumeIsolated {
				self?.handleDiscoveredConnection(connection, knownPeerID: knownPeerID)
			}
		}
		
		networkService.onPeerDisconnected = { [weak self] peerID in
			MainActor.assumeIsolated {
				self?.removePeer(peerID)
			}
		}
	}
	
	private func handleDiscoveredConnection(_ connection: NWConnection, knownPeerID: String?) {
		Task {
			do {
				let sessionID = knownPeerID ?? "pending-\(UUID().uuidString)"
				let peerSession = PeerSession(peerID: sessionID, connection: connection)
				
				guard let localTokenData = peerSession.localTokenData else {
					connection.cancel()
					return
				}
				
				let localHandshake = PeerHandshake(peerID: self.networkService.localPeerID, discoveryToken: localTokenData)
				let payload = try JSONEncoder().encode(localHandshake)
				Framing.send(data: payload, over: connection)
				
				let responseData = try await Framing.receive(from: connection)
				let remoteHandshake = try JSONDecoder().decode(PeerHandshake.self, from: responseData)
				let peerID = remoteHandshake.peerID
				
				peerSession.peerID = peerID
				self.activeSessions[peerID]?.stop()
				self.networkService.registerConnection(connection, for: peerID)
				self.activeSessions[peerID] = peerSession
				self.trackedPeers[peerID] = TrackedPeer(id: peerID)
				
				peerSession.onSpatialUpdate = { [weak self] id, distance, isFacing, isAligned in
					MainActor.assumeIsolated {
						guard let self, var peer = self.trackedPeers[id] else { return }
						peer.distance = distance
						peer.isFacing = isFacing
						peer.isAligned = isAligned
						self.trackedPeers[id] = peer
					}
				}
				
				peerSession.onSessionEnded = { [weak self] id in
					MainActor.assumeIsolated {
						self?.removePeer(id)
					}
				}
				
				peerSession.startRanging(with: remoteHandshake.discoveryToken)
				
			} catch {
				connection.cancel()
			}
		}
	}
	
	private func removePeer(_ peerID: String) {
		activeSessions[peerID]?.stop()
		activeSessions.removeValue(forKey: peerID)
		trackedPeers.removeValue(forKey: peerID)
	}
}
