//
//  CharionisApp.swift
//  Charionis
//
//  Created by Muhammad Akbar Reishandy on 14/09/26.
//

import SwiftUI
import SwiftData

@main
struct CharionisApp: App {
	let container: ModelContainer
	
	init() {
		do {
			container = try ModelContainer(for: Card.self)
		} catch {
			fatalError("> Failed to initialize ModelContainer: \(error.localizedDescription)")
		}
	}
	
	var body: some Scene {
		WindowGroup {
			BaseView(modelContext: container.mainContext)
		}
		.modelContainer(container)
	}
}
