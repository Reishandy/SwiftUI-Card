//
//  PeerNetworkService.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 15/09/26.
//

import Foundation
import Network

@MainActor
final class PeerNetworkService {
	let serviceType = "_proximity-p2p._tcp"
	let localPeerID = UUID().uuidString
	
	private var listener: NWListener?
	private var browser: NWBrowser?
	
	private(set) var connections: [String: NWConnection] = [:]
	private var pendingOutbound: Set<String> = []
	
	var onPeerDiscovered: (@Sendable (NWConnection, _ remotePeerID: String?) -> Void)?
	var onPeerDisconnected: (@Sendable (String) -> Void)?
	
	func start() {
		startListener()
		startBrowser()
	}
	
	func stop() {
		browser?.cancel()
		listener?.cancel()
		for (_, connection) in connections {
			connection.cancel()
		}
		connections.removeAll()
		pendingOutbound.removeAll()
		browser = nil
		listener = nil
	}
	
	func registerConnection(_ connection: NWConnection, for peerID: String) {
		connections[peerID] = connection
		pendingOutbound.remove(peerID)
		
		connection.stateUpdateHandler = { [weak self] state in
			MainActor.assumeIsolated {
				switch state {
				case .failed, .cancelled:
					self?.connections.removeValue(forKey: peerID)
					self?.onPeerDisconnected?(peerID)
				default:
					break
				}
			}
		}
	}
	
	private func startListener() {
		let params = NWParameters.tcp
		params.includePeerToPeer = true
		
		guard let listener = try? NWListener(using: params) else { return }
		self.listener = listener
		
		listener.service = NWListener.Service(
			name: localPeerID,
			type: serviceType,
			txtRecord: NWTXTRecord(["peerID": localPeerID])
		)
		
		listener.newConnectionHandler = { [weak self] connection in
			MainActor.assumeIsolated {
				guard let self else {
					connection.cancel()
					return
				}
				
				connection.start(queue: .main)
				self.onPeerDiscovered?(connection, nil)
			}
		}
		listener.start(queue: .main)
	}
	
	private func startBrowser() {
		let params = NWParameters.tcp
		params.includePeerToPeer = true
		
		let browser = NWBrowser(for: .bonjourWithTXTRecord(type: serviceType, domain: nil), using: params)
		self.browser = browser
		
		browser.browseResultsChangedHandler = { [weak self] results, _ in
			MainActor.assumeIsolated {
				self?.evaluate(results)
			}
		}
		browser.start(queue: .main)
	}
	
	private func evaluate(_ results: Set<NWBrowser.Result>) {
		for result in results {
			guard case let .bonjour(record) = result.metadata,
				  let remotePeerID = record.dictionary["peerID"] else {
				continue
			}
			
			if localPeerID > remotePeerID,
			   connections[remotePeerID] == nil,
			   !pendingOutbound.contains(remotePeerID) {
				
				pendingOutbound.insert(remotePeerID)
				connect(to: result.endpoint, remotePeerID: remotePeerID)
			}
		}
	}
	
	private func connect(to endpoint: NWEndpoint, remotePeerID: String) {
		let params = NWParameters.tcp
		params.includePeerToPeer = true
		let connection = NWConnection(to: endpoint, using: params)
		
		connection.stateUpdateHandler = { [weak self] state in
			MainActor.assumeIsolated {
				switch state {
				case .ready:
					self?.onPeerDiscovered?(connection, remotePeerID)
				case .failed, .cancelled:
					self?.pendingOutbound.remove(remotePeerID)
					self?.connections.removeValue(forKey: remotePeerID)
					self?.onPeerDisconnected?(remotePeerID)
				default:
					break
				}
			}
		}
		connection.start(queue: .main)
	}
}
