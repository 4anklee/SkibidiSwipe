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

    // Add method to be called when game ends to ensure high score is synced
    func gameOver() {
        // If current score is a high score, update and sync
        if currentScore > highScore {
            self.highScore = currentScore
            syncHighScoreWithSupabase()
        }

        // Reset current score
        resetCurrentScore()
    }

    private func syncHighScoreWithSupabase() {
        let username = UserDefaults.standard.string(forKey: "username") ?? "Player"

        SupabaseManager.shared.updateHighScore(username: username, highScore: self.highScore) {
            result in
            switch result {
            case .success:
                print("High score synced successfully")
            case .failure(let error):
                print("Failed to sync high score: \(error)")
            }
        }
    }
}
