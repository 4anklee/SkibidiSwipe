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
    
    // Setup environment variables
    init() {
        setupEnvironmentVariables()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func setupEnvironmentVariables() {
        #if DEBUG
        let fileManager = FileManager.default
        
        // Check the app's main bundle first
        if let path = Bundle.main.path(forResource: ".env", ofType: nil),
           fileManager.fileExists(atPath: path),
           let data = try? String(contentsOfFile: path, encoding: .utf8) {
            loadEnvironmentVariables(from: data)
            return
        }
        
        // Then check the app's documents directory
        if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let envFilePath = documentsDirectory.appendingPathComponent(".env").path
            if fileManager.fileExists(atPath: envFilePath),
               let data = try? String(contentsOfFile: envFilePath, encoding: .utf8) {
                loadEnvironmentVariables(from: data)
                return
            }
        }
        
        // Check the current directory
        let currentDirectoryPath = fileManager.currentDirectoryPath
        let envFilePath = currentDirectoryPath + "/.env"
        if fileManager.fileExists(atPath: envFilePath),
           let data = try? String(contentsOfFile: envFilePath, encoding: .utf8) {
            loadEnvironmentVariables(from: data)
            return
        }
        
        // If we can't find an .env file, we'll use the default values in SupabaseConfig
        print("No .env file found. Using default values from SupabaseConfig.")
        #endif
    }
    
    private func loadEnvironmentVariables(from content: String) {
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.components(separatedBy: "=")
            if parts.count >= 2 {
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                let value = parts[1...].joined(separator: "=").trimmingCharacters(in: .whitespaces)
                setenv(key, value, 1)
            }
        }
    }
}
