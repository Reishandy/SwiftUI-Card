//
//  DebugView.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 17/09/26.
//

import SwiftUI

struct DebugView: View {
	@Bindable var baseViewModel: BaseViewModel
	
	private var manager: SpatialManager { baseViewModel.manager }
	private var ownModel: OwnViewModel { baseViewModel.ownModel }
	
	var body: some View {
		NavigationStack {
			List {
				// MARK: - Alignment Status Overview
				Section("Overall Status") {
					HStack {
						Text("Alignment Status")
						Spacer()
						Text(manager.isAligned ? "ALIGNED" : "NOT ALIGNED")
							.font(.caption.bold())
							.padding(.horizontal, 8)
							.padding(.vertical, 4)
							.background(manager.isAligned ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
							.foregroundStyle(manager.isAligned ? .green : .red)
							.clipShape(Capsule())
					}
					
					LabeledContent("Send Progress", value: String(format: "%.0f%%", ownModel.sendProgress * 100))
					LabeledContent("Is Sending", value: ownModel.isSending ? "Yes" : "No")
					LabeledContent("Manager Running", value: manager.isRunning ? "Yes" : "No")
				}
				
				// MARK: - Local Device
				Section("Own Device") {
					LabeledContent("Peer ID", value: String(manager.networkService.localPeerID.prefix(8)) + "...")
					LabeledContent("Compass Heading", value: String(format: "%.1f°", manager.motionManager.currentHeading))
					LabeledContent("Card Offset Y", value: String(format: "%.1f pt", ownModel.cardScreenOffset.height))
				}
				
				// MARK: - Active Sessions & Alignment Diagnostics
				Section("Active Nearby Interaction Sessions (\(manager.activeSessions.count))") {
					if manager.activeSessions.isEmpty {
						Text("No active sessions ranging. Make sure Bluetooth/Wi-Fi is on and another peer is nearby.")
							.font(.footnote)
							.foregroundStyle(.secondary)
					} else {
						ForEach(Array(manager.activeSessions.values), id: \.peerID) { session in
							VStack(alignment: .leading, spacing: 8) {
								HStack {
									Text("Peer: \(session.peerID.prefix(8))...")
										.font(.subheadline.bold())
									Spacer()
									statusBadge(session: session)
								}
								
								Divider()
								
								// Distance Diagnostic
								HStack {
									Image(systemName: "ruler")
										.frame(width: 20)
									Text("Distance:")
									Spacer()
									if let distance = session.currentDistance {
										Text(String(format: "%.2f m", distance))
											.foregroundStyle(session.isDistanceWithinThreshold ? .green : .red)
											.bold()
										Text("/ \(String(format: "%.2f m", session.alignmentDistanceThreshold))")
											.foregroundStyle(.secondary)
									} else {
										Text("Ranging...")
											.foregroundStyle(.orange)
									}
								}
								
								// Heading Diagnostic
								HStack {
									Image(systemName: "location.north.circle")
										.frame(width: 20)
									Text("Remote Heading:")
									Spacer()
									if let remote = session.remoteHeading {
										Text(String(format: "%.1f°", remote))
									} else {
										Text("Waiting for heading...")
											.foregroundStyle(.orange)
									}
								}
								
								// Angle Error
								HStack {
									Image(systemName: "arrow.triangle.swap")
										.frame(width: 20)
									Text("Opposing Error:")
									Spacer()
									if let error = session.angleError {
										Text(String(format: "%.1f°", error))
											.foregroundStyle(error <= session.facingAngleTolerance ? .green : .red)
											.bold()
										Text("/ tol: \(String(format: "%.0f°", session.facingAngleTolerance))")
											.foregroundStyle(.secondary)
									} else {
										Text("N/A")
											.foregroundStyle(.secondary)
									}
								}
							}
							.padding(.vertical, 4)
						}
					}
				}
				
				// MARK: - Network Connections
				Section("Network Connections (\(manager.networkService.connections.count))") {
					if manager.networkService.connections.isEmpty {
						Text("No Bonjour TCP connections active.")
							.font(.footnote)
							.foregroundStyle(.secondary)
					} else {
						ForEach(Array(manager.networkService.connections.keys), id: \.self) { peerID in
							HStack {
								Circle()
									.fill(.green)
									.frame(width: 8, height: 8)
								Text(peerID.prefix(12) + "...")
									.font(.system(.footnote, design: .monospaced))
								Spacer()
								Text("Connected")
									.font(.caption2)
									.foregroundStyle(.secondary)
							}
						}
					}
				}
			}
			.navigationTitle("Spatial Debugger")
			.navigationBarTitleDisplayMode(.inline)
		}
	}
	
	@ViewBuilder
	private func statusBadge(session: PeerSession) -> some View {
		let isFacing = (session.angleError ?? 999) <= session.facingAngleTolerance
		let isClose = session.isDistanceWithinThreshold
		
		HStack(spacing: 4) {
			Text(isFacing ? "Facing" : "Not Facing")
				.font(.caption2.bold())
				.padding(.horizontal, 6)
				.padding(.vertical, 2)
				.background(isFacing ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
				.foregroundStyle(isFacing ? .green : .red)
				.cornerRadius(4)
			
			Text(isClose ? "Close" : "Far")
				.font(.caption2.bold())
				.padding(.horizontal, 6)
				.padding(.vertical, 2)
				.background(isClose ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
				.foregroundStyle(isClose ? .green : .red)
				.cornerRadius(4)
		}
	}
}
