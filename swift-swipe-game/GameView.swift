import SwiftData
import SwiftUI

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
    @State private var displayedDirection: String = "Up"
    @State private var isFakingDirection = false
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
    @State private var difficultyLevel: Int = 1
    @State private var showCelebration = false
    @State private var emojis: [EmojiParticle] = []
    @State private var celebrationLevel = 1
    @State private var shouldShowFailure = false
    @State private var showFailure = false
    @State private var failureScale: CGFloat = 0.1
    @State private var arrowRotation: Double = 0
    @State private var arrowOpacity: Double = 1.0
    @State private var sealOpacity: Double = 0.0
    @State private var showFailText = false
    @State private var failTextScale: CGFloat = 0.1
    @State private var showFailEmojis = false
    @State private var failEmojis: [EmojiParticle] = []
    @State private var showRedOverlay = false
    @State private var redOverlayOpacity: Double = 0.0
    @State private var arrowColor: Color = .blue
    @State private var showQuestionMark: Bool = false
    @State private var actualDirection: String = "Up"
    @State private var revealedDirection: String = ""
    @State private var isWaitingForGuess: Bool = false

    var body: some View {
        ZStack {
            Color(darkModeEnabled ? .black : .white)
                .ignoresSafeArea()

            Color.red
                .ignoresSafeArea()
                .opacity(redOverlayOpacity)
                .animation(.easeInOut(duration: 0.5), value: redOverlayOpacity)
                .zIndex(1)

            VStack {
                Spacer()

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
                        .frame(alignment: .center)
                        .shadow(radius: darkModeEnabled ? 15 : 10)
                        .padding()

                    ZStack {
                        if !revealedDirection.isEmpty {
                            Image(systemName: directionArrows[revealedDirection] ?? "arrow.up")
                                .font(.system(size: 70))
                                .foregroundColor(.red)
                                .opacity(arrowOpacity)
                                .scaleEffect(1.2)
                                .animation(
                                    .spring(response: 0.3, dampingFraction: 0.6),
                                    value: revealedDirection)
                        } else if showQuestionMark {
                            Image(systemName: "questionmark")
                                .font(.system(size: 70))
                                .foregroundColor(.red)
                                .opacity(arrowOpacity)
                                .scaleEffect(showAnimation ? 1.5 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: showAnimation)
                        } else {
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

                    if showFailure {
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

                        if showFailText {
                            let failText = [
                                "OH MY GYATT!!", "YOU LOSE!!", "YOU A NPC", "EHH, WHAT THE SIGMA?",
                            ]
                            let randomText = failText.randomElement() ?? "OH MY GYATT!!"
                            Text(randomText)
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

                HStack(spacing: 10) {
                    VStack {
                        Text("CURRENT AURA")
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

                    VStack {
                        Text("MAX AURA")
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

                VStack(spacing: 10) {
                    Text("Follow the arrow direction to increase your aura!")
                        .font(.caption)
                        .foregroundColor(darkModeEnabled ? .gray : .gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button(action: {
                        resetGame()
                    }) {
                        Text("BREAK MEWING STREAK")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(
                                Rectangle()
                                    .fill(Color.red.opacity(0.8))
                                    .cornerRadius(10)  // Added corner radius
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

        if consecutiveSwipes >= 3 {
            shouldShowFailure = Double.random(in: 0...1) < 0.2
        } else {
            shouldShowFailure = false
        }

        schedulePossibleDirectionFaking()
    }

    private func schedulePossibleDirectionFaking() {
        fakingTimer?.invalidate()
        fakingTimer = nil

        if consecutiveSwipes < 5 {
            return
        }

        difficultyLevel = max(1, min(10, consecutiveSwipes / 5))
        let fakeProbability = min(0.7, Double(difficultyLevel) * 0.07)  // Max 70% chance

        if Double.random(in: 0...1) < fakeProbability {
            let delayTime = Double.random(in: 0.8...2.5)
            fakingTimer = Timer.scheduledTimer(withTimeInterval: delayTime, repeats: false) { _ in
                self.showFakeDirection()
            }
        }
    }

    private func showFakeDirection() {
        let directions = ["Up", "Down", "Left", "Right"].filter { $0 != targetDirection }

        if let fakeDirection = directions.randomElement() {
            withAnimation(.easeInOut(duration: 0.2)) {
                displayedDirection = fakeDirection
                isFakingDirection = true
            }

            let fakeDuration = max(0.2, 0.7 - (Double(difficultyLevel) * 0.05))

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

        if isWaitingForGuess {
            handleFailureGuess(userGuess: direction)
            return
        }

        isCorrectSwipe = (direction == targetDirection)

        if shouldShowFailure && isCorrectSwipe {
            animationScale = 1.2
            showAnimation = true

            if vibrationEnabled {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.triggerFailure()
            }

            return
        }

        animationScale = 1.2
        showAnimation = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            animationScale = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showAnimation = false
        }

        if vibrationEnabled {
            let impactType: UIImpactFeedbackGenerator.FeedbackStyle =
                isCorrectSwipe ? .medium : .light
            let generator = UIImpactFeedbackGenerator(style: impactType)
            generator.impactOccurred()
        }

        if let gameScore = gameScores.first {
            if isCorrectSwipe {
                consecutiveSwipes += 1
                gameScore.updateScore(newScore: consecutiveSwipes)

                if consecutiveSwipes % 10 == 0 {
                    celebrationLevel = consecutiveSwipes / 10
                    triggerCelebration()
                }

                generateNewTargetDirection()
            } else {
                consecutiveSwipes = 0
                gameScore.gameOver()
                generateNewTargetDirection()
            }
        }
    }

    private func handleFailureGuess(userGuess: String) {
        revealedDirection = actualDirection
        showQuestionMark = false
        isWaitingForGuess = false

        let guessedCorrectly = (userGuess == actualDirection)

        if vibrationEnabled {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        }

        if guessedCorrectly {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                arrowOpacity = 1.0
                showAnimation = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let gameScore = self.gameScores.first {
                    self.consecutiveSwipes += 1
                    gameScore.updateScore(newScore: self.consecutiveSwipes)
                }

                self.showFailure = false
                self.showQuestionMark = false
                self.revealedDirection = ""

                self.generateNewTargetDirection()
            }
        } else {
            withAnimation(.easeIn(duration: 0.3)) {
                self.redOverlayOpacity = 0.3
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                if self.vibrationEnabled {
                    let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
                    heavyGenerator.impactOccurred()
                }

                self.sealOpacity = 0.9
                self.failureScale = 1.0

                withAnimation(.easeOut(duration: 0.4)) {
                    self.arrowOpacity = 0.3
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.showFailText = true
                self.failTextScale = 1.0

                if self.vibrationEnabled {
                    let finalGenerator = UIImpactFeedbackGenerator(style: .heavy)
                    finalGenerator.impactOccurred()
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.createFailureEmojis()
                self.showFailEmojis = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    self.redOverlayOpacity = 0
                    self.sealOpacity = 0
                    self.failureScale = 0.1
                    self.arrowOpacity = 1.0
                    self.arrowRotation = 0
                }

                self.showFailText = false
                self.failTextScale = 0.1
                self.showFailEmojis = false
                self.showFailure = false
                self.showQuestionMark = false
                self.revealedDirection = ""

                if let gameScore = self.gameScores.first {
                    gameScore.gameOver()
                    self.consecutiveSwipes = 0
                }

                self.generateNewTargetDirection()
            }
        }
    }

    private func triggerFailure() {
        showFailure = true

        arrowColor = directionColors[displayedDirection] ?? .blue

        let directions = ["Up", "Down", "Left", "Right"].filter { $0 != displayedDirection }
        actualDirection = directions.randomElement() ?? directions[0]

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.showQuestionMark = true
                self.arrowOpacity = 1.0
            }

            self.isWaitingForGuess = true
        }
    }

    private func resetGame() {
        fakingTimer?.invalidate()
        fakingTimer = nil

        if let gameScore = gameScores.first {
            gameScore.gameOver()
        }

        consecutiveSwipes = 0
        swipeCount = 0
        showQuestionMark = false
        showFailure = false
        showFailEmojis = false
        failEmojis = []
        showCelebration = false
        emojis = []
        showFailText = false
        redOverlayOpacity = 0
        generateNewTargetDirection()
    }

    private func createFailureEmojis() {
        failEmojis.removeAll()

        let failureEmojiOptions = ["🤡"]

        for _ in 0..<20 {
            let randomEmoji = failureEmojiOptions.randomElement() ?? "😵"
            let size = CGFloat.random(in: 20...40)

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

        for i in 0..<failEmojis.count {
            let angle = Double.random(in: 0...2 * Double.pi)
            let distance = CGFloat.random(in: 50...150)

            let endX = 150 + cos(angle) * distance
            let endY = 150 + sin(angle) * distance

            let delay = Double.random(in: 0...0.3)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if i < self.failEmojis.count {
                    withAnimation(.easeIn(duration: 0.2)) {
                        self.failEmojis[i].opacity = 1.0
                    }

                    withAnimation(.easeOut(duration: 0.7)) {
                        self.failEmojis[i].position = CGPoint(x: endX, y: endY)
                        self.failEmojis[i].rotation += Double.random(in: -180...180)
                    }

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

    private func triggerCelebration() {
        createEmojiParticles()
        showCelebration = true

        if vibrationEnabled {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            showCelebration = false
        }
    }

    private func createEmojiParticles() {
        emojis.removeAll()

        let celebrationEmojis = ["🐺", "🍑", "😻"]

        let baseCount = min(3 + (celebrationLevel * 2), 15)

        for _ in 0..<baseCount {
            let randomEmoji = celebrationEmojis.randomElement() ?? "🏆"
            let size = CGFloat(15)
            let startX = CGFloat.random(in: 80...220)
            let startY: CGFloat = 350

            let particle = EmojiParticle(
                emoji: randomEmoji,
                position: CGPoint(x: startX, y: startY),
                size: size,
                opacity: 1.0,
                rotation: Double.random(in: -30...30)
            )

            emojis.append(particle)
        }

        for i in 0..<emojis.count {
            let delay = Double(i) * 0.1

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if i < self.emojis.count {
                    withAnimation(Animation.easeOut(duration: 0.7)) {
                        let endX = self.emojis[i].position.x + CGFloat.random(in: -50...50)
                        let peakY = CGFloat.random(in: 80...180)

                        self.emojis[i].position = CGPoint(x: endX, y: peakY)
                        self.emojis[i].size =
                            CGFloat.random(in: 30...50)
                            * min(CGFloat(self.celebrationLevel) * 0.7, 2.0)
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        withAnimation(Animation.easeIn(duration: 1.0)) {
                            if i < self.emojis.count {
                                let fallX = self.emojis[i].position.x + CGFloat.random(in: -30...30)
                                let fallY: CGFloat = 350

                                self.emojis[i].position = CGPoint(x: fallX, y: fallY)
                                self.emojis[i].opacity = 0.0
                                self.emojis[i].rotation += Double.random(in: -180...180)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct EmojiParticle: Identifiable {
    let id = UUID()
    let emoji: String
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
    var rotation: Double
}
