import Foundation
import SwiftData

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
        if newScore > highScore {
            self.highScore = newScore
        }
        self.lastUpdated = Date()
    }
    
    func resetCurrentScore() {
        self.currentScore = 0
        self.lastUpdated = Date()
    }
} 