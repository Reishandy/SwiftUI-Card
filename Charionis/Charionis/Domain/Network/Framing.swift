//
//  Framing.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 15/09/26.
//

import Foundation
import Network

enum Framing: Sendable {
	static func send(data: Data, over connection: NWConnection) {
		var length = UInt32(data.count).bigEndian
		var packet = Data(bytes: &length, count: 4)
		packet.append(data)
		
		connection.send(content: packet, completion: .contentProcessed { _ in })
	}
	
	static func receive(from connection: NWConnection, completion: @escaping @Sendable (Result<Data, any Error>) -> Void) {
		connection.receive(minimumIncompleteLength: 4, maximumLength: 4) { lengthData, _, _, error in
			if let error {
				completion(.failure(error))
				return
			}
			
			guard let lengthData, lengthData.count == 4 else {
				completion(.failure(POSIXError(.ECONNRESET)))
				return
			}
			let length = Int(lengthData.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian })
			
			connection.receive(minimumIncompleteLength: length, maximumLength: length) { payload, _, _, error in
				if let error {
					completion(.failure(error))
					return
				}
				
				guard let payload else {
					completion(.failure(POSIXError(.ECONNRESET)))
					return
				}
				completion(.success(payload))
			}
		}
	}
	
	static func receive(from connection: NWConnection) async throws -> Data {
		try await withCheckedThrowingContinuation { continuation in
			receive(from: connection) { result in
				continuation.resume(with: result)
			}
		}
	}
}
