//
//  WalletView.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 17/09/26.
//

import SwiftUI

struct WalletView: View {
	var body: some View {
		Image("Wallet")
			.resizable()
			.frame(width: 350)
			.shadow(color: .black.opacity(0.35), radius: 24, y: -6)
	}
}

#Preview {
	WalletView()
		.ignoresSafeArea()
}
