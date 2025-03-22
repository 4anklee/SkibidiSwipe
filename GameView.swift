// Display target direction arrow - now using displayedDirection
ZStack {
    if showQuestionMark && revealedDirection.isEmpty {
        // Question mark for failure
        Image(systemName: "questionmark")
            .font(.system(size: 70))
            .foregroundColor(.red)
            .opacity(arrowOpacity)
            .scaleEffect(showAnimation ? 1.5 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: showAnimation)
    } else if !revealedDirection.isEmpty {
        // Revealed direction after question mark (during failure)
        Image(systemName: directionArrows[revealedDirection] ?? "arrow.up")
            .font(.system(size: 70))
            .foregroundColor(.red)
            .opacity(arrowOpacity)
            .scaleEffect(1.2)
            .animation(
                .spring(response: 0.3, dampingFraction: 0.6),
                value: revealedDirection)
    } else {
        // Regular direction arrow
        Image(systemName: directionArrows[displayedDirection] ?? "arrow.up")
            .font(.system(size: 70))
            .foregroundColor(directionColors[displayedDirection] ?? .blue)
            .scaleEffect(showAnimation ? 1.5 : 1.0)
            .opacity(arrowOpacity)
            .animation(.easeInOut(duration: 0.3), value: showAnimation)
            .rotationEffect(Angle(degrees: arrowRotation))
            .animation(
                showFailure
                    ? .spring(
                        response: 0.3, dampingFraction: 0.4, blendDuration: 0.5)
                    : .easeInOut(duration: 0.2),
                value: showFailure
            )
    }
}
.zIndex(2)

// REMOVE THE BELOW SECTION COMPLETELY since we integrated it above
// // Revealed direction after question mark (during failure)
// if !revealedDirection.isEmpty {
//     Image(systemName: directionArrows[revealedDirection] ?? "arrow.up")
//         .font(.system(size: 70))
//         .foregroundColor(.red)
//         .opacity(arrowOpacity)
//         .scaleEffect(1.2)
//         .animation(
//             .spring(response: 0.3, dampingFraction: 0.6),
//             value: revealedDirection)
// }

private func generateNewTargetDirection() {
    let directions = ["Up", "Down", "Left", "Right"]
    targetDirection = directions.randomElement() ?? "Up"
    displayedDirection = targetDirection

    // Reset animation state
    showAnimation = false

    // Only schedule possible failure when score is high enough
    if consecutiveSwipes >= 3 {
        // 20% chance of failure after a correct swipe
        shouldShowFailure = Double.random(in: 0...1) < 0.2
    } else {
        shouldShowFailure = false
    }

    // Schedule possible direction faking based on difficulty level
    schedulePossibleDirectionFaking()
}

private func resetGame() {
    // Cancel any active faking timer
    fakingTimer?.invalidate()
    fakingTimer = nil

    // Reset failure animations if active
    showFailure = false
    redOverlayOpacity = 0
    sealOpacity = 0
    failureScale = 0.1
    arrowOpacity = 1.0
    arrowRotation = 0
    showFailText = false
    failTextScale = 0.1
    showFailEmojis = false
    showQuestionMark = false
    revealedDirection = ""
    isWaitingForGuess = false

    // Reset animation state
    showAnimation = false
    animationScale = 1.0

    consecutiveSwipes = 0
    lastSwipeDirection = nil
    difficultyLevel = 1
    isFakingDirection = false
    generateNewTargetDirection()

    if let gameScore = gameScores.first {
        gameScore.resetCurrentScore()
    }
}
