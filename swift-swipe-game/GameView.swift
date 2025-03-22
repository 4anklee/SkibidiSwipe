import SwiftData
import SwiftUI
import UIKit

struct GameView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Query private var gameScores: [GameScore]
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true
    @AppStorage("vibrationEnabled") private var vibrationEnabled: Bool = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = true

    @State private var swipeCount = 0
    @State private var lastSwipeDirection: String? = nil
    @State private var isDragging = false
    @State private var dragStartPosition: CGPoint = .zero
    @State private var consecutiveSwipes = 0
    @State private var showAnimation = false
    @State private var animationScale: CGFloat = 1.0
    @State private var targetDirection: String = "Up"
    @State private var displayedDirection: String = "Up"  // Actual direction shown to user
    @State private var isFakingDirection = false  // Flag to track if we're showing a fake direction
    @State private var fakingTimer: Timer? = nil
    @State private var directionArrows: [String: String] = [
        "Up": "arrow.up",
        "Down": "arrow.down",
        "Left": "arrow.left",
        "Right": "arrow.right",
    ]
    @State private var directionColors: [String: Color] = [
        "Up": .green,
        "Down": .blue,
        "Left": .red,
        "Right": .purple,
    ]
    @State private var isCorrectSwipe: Bool = false
    @State private var difficultyLevel: Int = 1  // Increases with score to make faking more frequent

    // Celebration animation states
    @State private var showCelebration = false
    @State private var emojis: [EmojiParticle] = []
    @State private var celebrationLevel = 1

    // Failure animation states (renamed from betrayal)
    @State private var shouldShowFailure = false  // Renamed from shouldBetray
    @State private var showFailure = false  // Renamed from showBetrayal
    @State private var failureScale: CGFloat = 0.1  // Renamed from betrayalScale
    @State private var arrowRotation: Double = 0
    @State private var arrowOpacity: Double = 1.0
    @State private var sealOpacity: Double = 0.0
    @State private var showFailText = false
    @State private var failTextScale: CGFloat = 0.1
    @State private var showFailEmojis = false  // Renamed from showSealEmojis
    @State private var failEmojis: [EmojiParticle] = []  // Renamed from sealEmojis
    @State private var showRedOverlay = false
    @State private var redOverlayOpacity: Double = 0.0
    @State private var arrowColor: Color = .blue
    @State private var showQuestionMark: Bool = false
    @State private var actualDirection: String = "Up"  // The real direction user needs to swipe
    @State private var revealedDirection: String = ""  // Direction revealed after user's guess
    @State private var isWaitingForGuess: Bool = false  // Flag to track if we're waiting for user's guess

    var body: some View {
        ZStack {
            // Dark theme background
            Color(darkModeEnabled ? .black : .white)
                .ignoresSafeArea()

            // Red overlay for failure
            Color.red
                .ignoresSafeArea()
                .opacity(redOverlayOpacity)
                .animation(.easeInOut(duration: 0.5), value: redOverlayOpacity)
                .zIndex(1)

            VStack {
                Spacer()

                // Game area - detect swipes
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(
                                    colors: darkModeEnabled
                                        ? [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]
                                        : [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 300, height: 300)
                        .shadow(radius: darkModeEnabled ? 15 : 10)

                    // Display target direction arrow - now using displayedDirection
                    ZStack {
                        if !revealedDirection.isEmpty {
                            // Revealed direction after question mark (during failure)
                            Image(systemName: directionArrows[revealedDirection] ?? "arrow.up")
                                .font(.system(size: 70))
                                .foregroundColor(.red)
                                .opacity(arrowOpacity)
                                .scaleEffect(1.2)
                                .animation(
                                    .spring(response: 0.3, dampingFraction: 0.6),
                                    value: revealedDirection)
                        } else if showQuestionMark {
                            // Question mark for failure
                            Image(systemName: "questionmark")
                                .font(.system(size: 70))
                                .foregroundColor(.red)
                                .opacity(arrowOpacity)
                                .scaleEffect(showAnimation ? 1.5 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: showAnimation)
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

                    // Emoji celebration overlay
                    if showCelebration {
                        ForEach(emojis) { particle in
                            Text(particle.emoji)
                                .font(.system(size: particle.size))
                                .position(particle.position)
                                .opacity(particle.opacity)
                                .rotationEffect(Angle(degrees: particle.rotation))
                                .zIndex(3)
                        }
                    }

                    // Failure seal overlay
                    if showFailure {
                        // Seal stamp effect
                        Circle()
                            .stroke(Color.red, lineWidth: 15)
                            .frame(width: 250, height: 250)
                            .scaleEffect(failureScale)
                            .opacity(sealOpacity)
                            .animation(
                                .spring(response: 0.4, dampingFraction: 0.6), value: failureScale
                            )
                            .animation(.easeInOut(duration: 0.3), value: sealOpacity)
                            .zIndex(4)

                        // FAIL text
                        if showFailText {
                            Text("YOU LOSE!!")
                                .font(.system(size: 60, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 2, x: 1, y: 1)
                                .scaleEffect(failTextScale)
                                .animation(
                                    .spring(response: 0.4, dampingFraction: 0.6),
                                    value: failTextScale
                                )
                                .rotationEffect(Angle(degrees: -15))
                                .shadow(color: .black, radius: 5, x: 0, y: 0)
                                .zIndex(5)
                        }

                        // Failure emojis
                        if showFailEmojis {
                            ForEach(failEmojis) { particle in
                                Text(particle.emoji)
                                    .font(.system(size: particle.size))
                                    .position(particle.position)
                                    .opacity(particle.opacity)
                                    .rotationEffect(Angle(degrees: particle.rotation))
                                    .zIndex(6)
                            }
                        }
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 20, coordinateSpace: .local)
                        .onChanged { value in
                            if !isDragging {
                                isDragging = true
                                dragStartPosition = value.startLocation
                            }
                        }
                        .onEnded { value in
                            let horizontalDistance = value.location.x - dragStartPosition.x
                            let verticalDistance = value.location.y - dragStartPosition.y

                            let direction: String

                            if abs(horizontalDistance) > abs(verticalDistance) {
                                direction = horizontalDistance > 0 ? "Right" : "Left"
                            } else {
                                direction = verticalDistance > 0 ? "Down" : "Up"
                            }

                            handleSwipe(direction: direction)
                            isDragging = false
                        }
                )

                Spacer()

                // Score displays below the game area
                HStack(spacing: 10) {
                    // Current Score grid
                    VStack {
                        Text("CURRENT")
                            .font(.caption)
                            .foregroundColor(darkModeEnabled ? .gray : .gray)
                        Text("\(gameScores.first?.currentScore ?? 0)")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(darkModeEnabled ? .cyan : .blue)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(darkModeEnabled ? Color.gray.opacity(0.2) : Color.blue.opacity(0.1))
                    .cornerRadius(10)

                    // High Score grid
                    VStack {
                        Text("BEST")
                            .font(.caption)
                            .foregroundColor(darkModeEnabled ? .gray : .gray)
                        Text("\(gameScores.first?.highScore ?? 0)")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(darkModeEnabled ? .pink : .purple)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        darkModeEnabled ? Color.gray.opacity(0.2) : Color.purple.opacity(0.1)
                    )
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 10)

                // Instructions
                VStack(spacing: 10) {
                    Text("Follow the arrow direction to increase your score!")
                        .font(.caption)
                        .foregroundColor(darkModeEnabled ? .gray : .gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button(action: {
                        resetGame()
                    }) {
                        Text("Reset Game")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(Color.red.opacity(0.8))
                            )
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .foregroundColor(darkModeEnabled ? .white : .black)
        .onAppear {
            createGameScoreIfNeeded()
            generateNewTargetDirection()
        }
        .onDisappear {
            // Clean up timer when view disappears
            fakingTimer?.invalidate()
            fakingTimer = nil
        }
    }

    private func createGameScoreIfNeeded() {
        if gameScores.isEmpty {
            let newGameScore = GameScore()
            modelContext.insert(newGameScore)
        }
    }

    private func generateNewTargetDirection() {
        let directions = ["Up", "Down", "Left", "Right"]
        targetDirection = directions.randomElement() ?? "Up"
        displayedDirection = targetDirection

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

    private func schedulePossibleDirectionFaking() {
        // Cancel any existing timer
        fakingTimer?.invalidate()
        fakingTimer = nil

        // Only start faking directions after score of 5
        if consecutiveSwipes < 5 {
            return
        }

        // Calculate chance of faking based on score
        // Higher scores = higher chance of faking
        difficultyLevel = max(1, min(10, consecutiveSwipes / 5))
        let fakeProbability = min(0.7, Double(difficultyLevel) * 0.07)  // Max 70% chance

        if Double.random(in: 0...1) < fakeProbability {
            // Schedule a random time to show fake direction
            let delayTime = Double.random(in: 0.8...2.5)
            fakingTimer = Timer.scheduledTimer(withTimeInterval: delayTime, repeats: false) { _ in
                self.showFakeDirection()
            }
        }
    }

    private func showFakeDirection() {
        // Get an array of directions excluding the current target
        let directions = ["Up", "Down", "Left", "Right"].filter { $0 != targetDirection }

        // Select a random fake direction from the filtered list
        if let fakeDirection = directions.randomElement() {
            // Show the fake direction with animation
            withAnimation(.easeInOut(duration: 0.2)) {
                displayedDirection = fakeDirection
                isFakingDirection = true
            }

            // Duration of the fake direction - shorter at higher difficulty
            let fakeDuration = max(0.2, 0.7 - (Double(difficultyLevel) * 0.05))

            // Schedule return to real direction
            DispatchQueue.main.asyncAfter(deadline: .now() + fakeDuration) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    displayedDirection = targetDirection
                    isFakingDirection = false
                }
            }
        }
    }

    private func handleSwipe(direction: String) {
        swipeCount += 1

        // If in failure waiting state, handle the guess
        if isWaitingForGuess {
            // User made their guess, reveal the actual direction
            handleFailureGuess(userGuess: direction)
            return
        }

        // Correct if swipe matches the ACTUAL target direction (not the displayed one)
        isCorrectSwipe = (direction == targetDirection)

        // If should show failure and swipe was correct, delay the failure animation
        if shouldShowFailure && isCorrectSwipe {
            // Initial correct feedback
            animationScale = 1.2
            showAnimation = true

            // Haptic feedback if enabled - medium strength for correct
            if vibrationEnabled {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }

            // Show initial success animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Then trigger dramatic failure animation
                self.triggerFailure()
            }

            return  // Exit early to wait for failure animation
        }

        // Normal (non-failure) swipe handling
        // Trigger animation
        animationScale = 1.2
        showAnimation = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            animationScale = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showAnimation = false
        }

        // Haptic feedback if enabled
        if vibrationEnabled {
            let impactType: UIImpactFeedbackGenerator.FeedbackStyle =
                isCorrectSwipe ? .medium : .light
            let generator = UIImpactFeedbackGenerator(style: impactType)
            generator.impactOccurred()
        }

        if let gameScore = gameScores.first {
            if isCorrectSwipe {
                // If correct swipe, increase score and set new target
                consecutiveSwipes += 1
                gameScore.updateScore(newScore: consecutiveSwipes)

                // Check if we reached a milestone (every 10 points)
                if consecutiveSwipes % 10 == 0 {
                    celebrationLevel = consecutiveSwipes / 10
                    triggerCelebration()
                }

                generateNewTargetDirection()
            } else {
                // If wrong swipe, reset consecutive swipes
                consecutiveSwipes = 0
                gameScore.resetCurrentScore()
                generateNewTargetDirection()
            }
        }
    }

    private func handleFailureGuess(userGuess: String) {
        // Now reveal the actual direction that was hidden
        revealedDirection = actualDirection
        showQuestionMark = false
        isWaitingForGuess = false

        // Check if the user guessed correctly
        let guessedCorrectly = (userGuess == actualDirection)

        // Strong haptic feedback regardless of guess
        if vibrationEnabled {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        }

        if guessedCorrectly {
            // User guessed correctly - show success animation and continue the game
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                arrowOpacity = 1.0
                showAnimation = true
            }

            // Short celebration
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Reset the animation state
                self.showAnimation = false

                // Continue the game with increased score
                if let gameScore = self.gameScores.first {
                    self.consecutiveSwipes += 1
                    gameScore.updateScore(newScore: self.consecutiveSwipes)
                }

                // Reset failure state
                self.showFailure = false
                self.showQuestionMark = false
                self.revealedDirection = ""

                // Generate new direction for next round
                self.generateNewTargetDirection()
            }
        } else {
            // User guessed wrong - trigger failure animation

            // Continue with the failure animation sequence
            // Stage 2: Red overlay flashes in
            withAnimation(.easeIn(duration: 0.3)) {
                self.redOverlayOpacity = 0.3
            }

            // Stage 3: Seal circles in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                // Strong haptic feedback for shock effect
                if self.vibrationEnabled {
                    let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
                    heavyGenerator.impactOccurred()
                }

                // Show seal with stamp effect
                self.sealOpacity = 0.9
                self.failureScale = 1.0

                // Fade out arrow during seal animation
                withAnimation(.easeOut(duration: 0.4)) {
                    self.arrowOpacity = 0.3
                }
            }

            // Stage 4: YOU LOSE text appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.showFailText = true
                self.failTextScale = 1.0

                // Third haptic pulse
                if self.vibrationEnabled {
                    let finalGenerator = UIImpactFeedbackGenerator(style: .heavy)
                    finalGenerator.impactOccurred()
                }
            }

            // Stage 5: Emoji explosion
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.createFailureEmojis()
                self.showFailEmojis = true
            }

            // Reset game state after full animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                // Reset all failure animations
                withAnimation(.easeOut(duration: 0.5)) {
                    self.redOverlayOpacity = 0
                    self.sealOpacity = 0
                    self.failureScale = 0.1
                    self.arrowOpacity = 1.0
                    self.arrowRotation = 0
                    self.showAnimation = false
                }

                self.showFailText = false
                self.failTextScale = 0.1
                self.showFailEmojis = false
                self.showFailure = false
                self.showQuestionMark = false
                self.revealedDirection = ""

                // Reset game score
                if let gameScore = self.gameScores.first {
                    self.consecutiveSwipes = 0
                    gameScore.resetCurrentScore()
                }

                // Generate new direction for next round
                self.generateNewTargetDirection()
            }
        }
    }

    private func triggerFailure() {
        // Activate failure mode
        showFailure = true

        // Store the original arrow color
        arrowColor = directionColors[displayedDirection] ?? .blue

        // Store the actual direction that player should swipe
        // Choose a random direction different from the one displayed
        let directions = ["Up", "Down", "Left", "Right"].filter { $0 != displayedDirection }
        actualDirection = directions.randomElement() ?? directions[0]

        // Stage 1: Switch to question mark
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Show the question mark with animation
            withAnimation(.easeInOut(duration: 0.3)) {
                self.showQuestionMark = true
                self.arrowOpacity = 1.0
            }

            // Activate waiting state - game will wait for user's guess
            self.isWaitingForGuess = true
        }
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

        consecutiveSwipes = 0
        lastSwipeDirection = nil
        difficultyLevel = 1
        isFakingDirection = false
        generateNewTargetDirection()

        if let gameScore = gameScores.first {
            gameScore.resetCurrentScore()
        }
    }

    private func createFailureEmojis() {
        // Clear existing failure emojis
        failEmojis.removeAll()

        // Define failure emojis
        let failureEmojiOptions = ["😵", "💥", "👎", "🛑", "❌", "⛔️", "🙅‍♂️", "🤦‍♀️", "😭", "💔"]

        // Create a burst of emojis from center
        for _ in 0..<20 {
            let randomEmoji = failureEmojiOptions.randomElement() ?? "😵"
            let size = CGFloat.random(in: 20...40)

            // Start from center
            let startX = CGFloat(150)
            let startY = CGFloat(150)

            let particle = EmojiParticle(
                emoji: randomEmoji,
                position: CGPoint(x: startX, y: startY),
                size: size,
                opacity: 0,
                rotation: Double.random(in: -30...30)
            )

            failEmojis.append(particle)
        }

        // Animate emojis exploding outward
        for i in 0..<failEmojis.count {
            // Random angle for explosion direction
            let angle = Double.random(in: 0...2 * Double.pi)
            let distance = CGFloat.random(in: 50...150)

            // Calculate end position
            let endX = 150 + cos(angle) * distance
            let endY = 150 + sin(angle) * distance

            // Animate with slight delay
            let delay = Double.random(in: 0...0.3)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if i < self.failEmojis.count {
                    // Fade in quickly
                    withAnimation(.easeIn(duration: 0.2)) {
                        self.failEmojis[i].opacity = 1.0
                    }

                    // Explode outward
                    withAnimation(.easeOut(duration: 0.7)) {
                        self.failEmojis[i].position = CGPoint(x: endX, y: endY)
                        self.failEmojis[i].rotation += Double.random(in: -180...180)
                    }

                    // Fade out after explosion
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            if i < self.failEmojis.count {
                                self.failEmojis[i].opacity = 0
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Celebration Functions

    private func triggerCelebration() {
        // Create emoji particles
        createEmojiParticles()

        // Show celebration
        showCelebration = true

        // Strong haptic feedback for celebration
        if vibrationEnabled {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        }

        // Hide celebration after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            showCelebration = false
        }
    }

    private func createEmojiParticles() {
        // Clear existing particles
        emojis.removeAll()

        // Define celebration emojis - using more achievement/positive themed emojis
        let celebrationEmojis = ["🏆", "⭐️", "🥇", "👑", "💪", "👏", "🙌", "🎯", "✅", "🔥"]

        // Number of particles based on celebration level
        // Fewer emojis for lower levels, more for higher levels
        let baseCount = min(3 + (celebrationLevel * 2), 15)

        // Create particles that will shoot up from bottom
        for _ in 0..<baseCount {
            let randomEmoji = celebrationEmojis.randomElement() ?? "🏆"
            // Start with smaller size
            let size = CGFloat(15)
            // Start from bottom of game area with random horizontal position
            let startX = CGFloat.random(in: 80...220)
            let startY: CGFloat = 350  // Below the game area

            let particle = EmojiParticle(
                emoji: randomEmoji,
                position: CGPoint(x: startX, y: startY),
                size: size,
                opacity: 1.0,
                rotation: Double.random(in: -30...30)
            )

            emojis.append(particle)
        }

        // Animate each particle in a sequence
        for i in 0..<emojis.count {
            let delay = Double(i) * 0.1  // Stagger the launch

            // Launch phase - shoot up
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if i < self.emojis.count {
                    withAnimation(Animation.easeOut(duration: 0.7)) {
                        // Calculate a random arc trajectory
                        let endX = self.emojis[i].position.x + CGFloat.random(in: -50...50)
                        let peakY = CGFloat.random(in: 80...180)  // Peak height

                        // Move to peak position
                        self.emojis[i].position = CGPoint(x: endX, y: peakY)
                        // Grow larger at peak
                        self.emojis[i].size =
                            CGFloat.random(in: 30...50)
                            * min(CGFloat(self.celebrationLevel) * 0.7, 2.0)
                    }

                    // Fall phase - after reaching peak
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        withAnimation(Animation.easeIn(duration: 1.0)) {
                            if i < self.emojis.count {
                                // Fall down with gravity effect
                                let fallX = self.emojis[i].position.x + CGFloat.random(in: -30...30)
                                let fallY: CGFloat = 350  // Fall below the game area

                                self.emojis[i].position = CGPoint(x: fallX, y: fallY)
                                // Gradually fade out as it falls
                                self.emojis[i].opacity = 0.0
                                // Add some rotation as it falls
                                self.emojis[i].rotation += Double.random(in: -180...180)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Types

struct EmojiParticle: Identifiable {
    let id = UUID()
    let emoji: String
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
    var rotation: Double
}
