//
//  WalletChevronIndicator.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 18/09/26.
//

import SwiftUI

struct WalletChevronIndicator: View {
	let isPresented: Bool
	let walletYOffset: CGFloat
	let walletHeight: CGFloat
	let walletPeekAmount: CGFloat
	
	@State private var bounceOffset: CGFloat = 0.0
	@State private var bounceTask: Task<Void, Never>? = nil
	
	var body: some View {
		VStack(spacing: 0) {
			Spacer()
			
			Image(systemName: "chevron.down")
				.font(.largeTitle.bold())
				.foregroundStyle(.white)
				.opacity(isPresented ? 0.7 : 0.0)
				.offset(y: bounceOffset)
				.padding(.bottom, walletPeekAmount - 32)
		}
		.offset(y: walletYOffset - (walletHeight - walletPeekAmount))
		.ignoresSafeArea(edges: .bottom)
		.allowsHitTesting(false)
		.onChange(of: isPresented) {
			triggerBounce(presented: isPresented)
		}
		.onAppear {
			if isPresented {
				triggerBounce(presented: true)
			}
		}
		.onDisappear {
			bounceTask?.cancel()
		}
	}
	
	@MainActor
	private func triggerBounce(presented: Bool) {
		bounceTask?.cancel()
		if presented {
			bounceTask = Task { @MainActor in
				try? await Task.sleep(for: .milliseconds(1000))
				guard !Task.isCancelled else { return }
				
				withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
					bounceOffset = 10
				}
				
				try? await Task.sleep(for: .milliseconds(500))
				guard !Task.isCancelled else { return }
				
				withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) {
					bounceOffset = 0
				}
			}
		} else {
			bounceOffset = 0
		}
	}
}

#Preview {
	// WalletChevronIndicator()
}
