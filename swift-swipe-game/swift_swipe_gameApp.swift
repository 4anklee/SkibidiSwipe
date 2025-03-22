//
//  swift_swipe_gameApp.swift
//  swift-swipe-game
//
//  Created by Frank Lee on 3/21/25.
//

import SwiftUI
import SwiftData

@main
struct swift_swipe_gameApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            GameScore.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
