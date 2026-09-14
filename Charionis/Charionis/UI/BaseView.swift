//
//  BaseView.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 14/09/26.
//

import SwiftUI

struct BaseView: View {
    var body: some View {
		ZStack {
			BackgroundView()
			
			CardView()
		}
    }
}

#Preview {
    BaseView()
}
