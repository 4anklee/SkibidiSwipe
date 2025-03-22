import Foundation
import SwiftData
import SwiftUI

@Model
final class GameScore {
    var currentScore: Int
    var highScore: Int
    var lastUpdated: Date
    
    init(currentScore: Int = 0, highScore: Int = 0, lastUpdated: Date = Date()) {
        self.currentScore = currentScore
        self.highScore = highScore
        self.lastUpdated = lastUpdated
    }
    
    func updateScore(newScore: Int) {
        self.currentScore = newScore
        let wasNewHighScore = newScore > highScore
        
        if wasNewHighScore {
            self.highScore = newScore
            // Sync high score with Supabase
            syncHighScoreWithSupabase()
        }
        
        self.lastUpdated = Date()
    }
    
    func resetCurrentScore() {
        self.currentScore = 0
        self.lastUpdated = Date()
    }
    
    private func syncHighScoreWithSupabase() {
        let username = UserDefaults.standard.string(forKey: "username") ?? "Player"
        
        SupabaseManager.shared.updateHighScore(username: username, highScore: self.highScore) { result in
            switch result {
            case .success:
                print("High score synced successfully")
            case .failure(let error):
                print("Failed to sync high score: \(error)")
            }
        }
    }
} 