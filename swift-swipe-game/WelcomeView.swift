import Combine
import SwiftUI

struct PixelParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var color: Color
    var speed: Double
    var angle: Double
}

struct WelcomeView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false
    @AppStorage("username") private var username: String = "Player"
    @Binding var isPresented: Bool
    @State private var tempUsername: String = ""
    @State private var currentPage = 0
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var detailedErrorInfo = ""
    @State private var showSnackbar = false
    @State private var snackbarMessage = ""
    @State private var gradientStart = UnitPoint(x: 0, y: 0)
    @State private var gradientEnd = UnitPoint(x: 1, y: 1)
    @State private var pixels: [PixelParticle] = []
    @State private var timer: Timer?

    let pixelCount = 150

    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]),
                startPoint: gradientStart,
                endPoint: gradientEnd
            )
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                    self.gradientStart = UnitPoint(x: 1, y: 0)
                    self.gradientEnd = UnitPoint(x: 0, y: 1)
                }
            }

            // Pixel animation layer
            GeometryReader { geometry in
                ZStack {
                    // Render all the pixels
                    ForEach(pixels) { pixel in
                        Circle()
                            .fill(pixel.color)
                            .frame(width: pixel.size, height: pixel.size)
                            .position(pixel.position)
                            .blendMode(.screen)
                    }
                }
                .onAppear {
                    // Initialize pixels
                    generatePixels(in: geometry.size)

                    // Setup animation timer
                    timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                        updatePixels(in: geometry.size)
                    }
                }
                .onDisappear {
                    timer?.invalidate()
                    timer = nil
                }
            }
            .background(Material.ultraThinMaterial)

            // Rest of your view content
            if currentPage == 0 {
                // Welcome page
                VStack(spacing: 30) {
                    Text("Welcome to Skibidi Swipe!")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Image(systemName: "hand.draw.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .padding()
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 160, height: 160)
                        )

                    VStack(spacing: 16) {
                        HowToPlayItem(
                            icon: "hand.tap.fill",
                            title: "Swipe",
                            description: "Swipe in any direction to start aura farming"
                        )

                        HowToPlayItem(
                            icon: "arrow.left.arrow.right",
                            title: "Be Consistent",
                            description: "Keep swiping in the same direction to increase your aura"
                        )

                        HowToPlayItem(
                            icon: "trophy.fill",
                            title: "Break Records",
                            description: "Try to beat the RIZZ GOD!"
                        )
                    }
                    .padding(.top)

                    Button(action: {
                        withAnimation {
                            currentPage = 1
                        }
                    }) {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 200)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        Material.ultraThin
                                    )
                            )
                            .shadow(radius: 10)
                    }
                    .padding(.top, 20)
                }
                .padding(30)
            } else {
                // Username entry page
                VStack(spacing: 30) {
                    Text("What should we call you?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Image(systemName: "person.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .padding()
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 120, height: 120)
                        )

                    TextField("Enter your username", text: $tempUsername)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .textInputAutocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding([.top], 10)

                    Button(action: {
                        if tempUsername.isEmpty {
                            showSnackbarMessage("Please enter a username")
                        } else {
                            isLoading = true
                            username = tempUsername
                            checkUsernameAndSave()
                        }
                    }) {
                        ZStack {
                            Text("Let's Play!")
                                .padding()
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            Material.thin
                                        )
                                )
                                .opacity(isLoading ? 0 : 1)

                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                            }
                        }
                    }
                    .disabled(isLoading)

                    // Skip option for testing
                    Button("Skip and play offline") {
                        DispatchQueue.main.async {
                            hasSeenWelcome = true
                            isPresented = false
                        }
                    }
                    .foregroundColor(.gray)
                }
                .padding(30)
                .alert(isPresented: $showError) {
                    Alert(
                        title: Text("Connection Error"),
                        message: Text("\(errorMessage)\n\nDetails: \(detailedErrorInfo)"),
                        primaryButton: .default(Text("Retry")) {
                            checkUsernameAndSave()
                        },
                        secondaryButton: .cancel(Text("Skip")) {
                            // Skip Supabase and continue with local storage only
                            DispatchQueue.main.async {
                                isLoading = false
                                hasSeenWelcome = true
                                isPresented = false
                            }
                        }
                    )
                }

                // Display snackbar if needed
                if showSnackbar {
                    VStack {
                        Spacer()
                        Text(snackbarMessage)
                            .font(.system(size: 20))
                            .padding(.vertical, 20)
                            .padding(.horizontal, 30)
                            .background(
                                Rectangle()
                                    .fill(Material.ultraThinMaterial.opacity(0.5))
                                    .cornerRadius(10)
                            )
                            .foregroundColor(.primary)
                            .padding(.bottom, 16)
                            .onAppear {
                                // Hide after 3 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    withAnimation {
                                        self.showSnackbar = false
                                    }
                                }
                            }
                    }
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: showSnackbar)
                    .zIndex(1)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // Generate initial pixels
    private func generatePixels(in size: CGSize) {
        pixels = []
        for _ in 0..<pixelCount {
            let position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            let pixelSize = CGFloat.random(in: 2...5)
            let pixelColor = [Color.blue, Color.purple, Color.cyan].randomElement()!.opacity(
                CGFloat.random(in: 0.3...0.7))
            let speed = Double.random(in: 0.5...2.0)
            let angle = Double.random(in: 0..<(2 * .pi))

            pixels.append(
                PixelParticle(
                    position: position,
                    size: pixelSize,
                    color: pixelColor,
                    speed: speed,
                    angle: angle
                ))
        }
    }

    // Update pixel positions
    private func updatePixels(in size: CGSize) {
        for i in 0..<pixels.count {
            var pixel = pixels[i]

            // Calculate new position based on angle and speed
            let dx = CGFloat(cos(pixel.angle) * pixel.speed)
            let dy = CGFloat(sin(pixel.angle) * pixel.speed)

            var newPosition = CGPoint(
                x: pixel.position.x + dx,
                y: pixel.position.y + dy
            )

            // Boundary check - wrap around if out of bounds
            if newPosition.x < 0 {
                newPosition.x = size.width
            } else if newPosition.x > size.width {
                newPosition.x = 0
            }

            if newPosition.y < 0 {
                newPosition.y = size.height
            } else if newPosition.y > size.height {
                newPosition.y = 0
            }

            // Small random changes to angle occasionally
            if Int.random(in: 0...100) < 5 {
                pixel.angle += Double.random(in: -0.2...0.2)
            }

            pixel.position = newPosition
            pixels[i] = pixel
        }
    }

    private func showSnackbarMessage(_ message: String) {
        // Show the snackbar with the new message
        snackbarMessage = message
        withAnimation {
            showSnackbar = true
        }
    }

    private func checkUsernameAndSave() {
        debugPrint("Checking if username is available: \(tempUsername)")

        // Check if username exists in Supabase
        SupabaseManager.shared.checkUsernameExists(username: tempUsername) { exists, error in
            if let error = error {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = "Connection error"
                    detailedErrorInfo = error.localizedDescription
                    showError = true
                }
                return
            }

            if exists {
                DispatchQueue.main.async {
                    isLoading = false
                    showSnackbarMessage("Username has been taken")
                }
                return
            }

            // Username is available, save it
            saveUsernameToSupabase()
        }
    }

    private func saveUsernameToSupabase() {
        debugPrint("Saving username to Supabase: \(username)")

        SupabaseManager.shared.saveUsername(username: username) { result in
            DispatchQueue.main.async {
                isLoading = false

                switch result {
                case .success:
                    debugPrint("Username saved successfully")
                    hasSeenWelcome = true
                    isPresented = false

                case .failure(let error):
                    let errorString = "\(error)"
                    debugPrint("Failed to save username: \(errorString)")

                    // Create a user-friendly error message
                    switch error {
                    case .invalidURL:
                        errorMessage = "Invalid Supabase URL. Please try again later."
                        detailedErrorInfo = "URL could not be created"
                    case .networkError(let innerError):
                        errorMessage = "Network error: \(innerError.localizedDescription)"
                        detailedErrorInfo = "Check your internet connection"
                    case .invalidResponse:
                        errorMessage = "The Supabase server returned an error."
                        detailedErrorInfo =
                            "This could be due to missing 'User' table. Make sure you have created this table in your Supabase database."
                    case .decodingError(let innerError):
                        errorMessage = "Data encoding error: \(innerError.localizedDescription)"
                        detailedErrorInfo = "Internal app error"
                    case .configurationError:
                        errorMessage = "Supabase configuration error. Please check your setup."
                        detailedErrorInfo = "Check API key and URL"
                    }

                    showError = true
                }
            }
        }
    }
}

struct HowToPlayItem: View {
    var icon: String
    var title: String
    var description: String

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

#Preview {
    WelcomeView(isPresented: .constant(true))
}
