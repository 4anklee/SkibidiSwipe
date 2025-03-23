//
//  ContentView.swift
//  swift-swipe-game
//
//  Created by Frank Lee on 3/21/25.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false
    @State private var showWelcome = false

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                VStack {
                    GameView()
                }
                .navigationTitle("Skibidi Swipe")
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            RankboardView()
                .tabItem {
                    Label("Leaderboard", systemImage: "trophy.fill")
                }
                .tag(1)
        }
        .onAppear {
            if !hasSeenWelcome {
                showWelcome = true
            }

            // Ensure database has a GameScore entry
            checkAndInitializeGameScore()
        }
        .fullScreenCover(isPresented: $showWelcome) {
            WelcomeView(isPresented: $showWelcome)
        }
        .preferredColorScheme(.dark)
    }

    private func checkAndInitializeGameScore() {
        let fetchDescriptor = FetchDescriptor<GameScore>()
        do {
            let scores = try modelContext.fetch(fetchDescriptor)
            if scores.isEmpty {
                let newScore = GameScore()
                modelContext.insert(newScore)
            }
        } catch {
            debugPrint("Failed to fetch game scores: \(error)")
            let newScore = GameScore()
            modelContext.insert(newScore)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Item.self, GameScore.self], inMemory: true)
}
