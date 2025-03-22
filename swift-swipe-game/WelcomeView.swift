import Combine
import SwiftUI

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

    var body: some View {
        ZStack {
            Color.black.opacity(0.9).edgesIgnoringSafeArea(.all)

            if currentPage == 0 {
                // Welcome page
                VStack(spacing: 30) {
                    Text("Welcome to Swift Swipe!")
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
                            description: "Swipe in any direction to start playing"
                        )

                        HowToPlayItem(
                            icon: "arrow.left.arrow.right",
                            title: "Be Consistent",
                            description: "Keep swiping in the same direction to increase your score"
                        )

                        HowToPlayItem(
                            icon: "trophy.fill",
                            title: "Break Records",
                            description: "Try to beat your high score!"
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
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .shadow(radius: 5)
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
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

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
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 200)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.blue, Color.purple,
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                                .shadow(radius: 5)
                                .opacity(isLoading ? 0 : 1)

                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                            }
                        }
                    }
                    .disabled(isLoading)
                    .padding(.top, 20)

                    // Skip option for testing
                    Button("Skip Supabase and play offline") {
                        DispatchQueue.main.async {
                            hasSeenWelcome = true
                            isPresented = false
                        }
                    }
                    .foregroundColor(.gray)
                    .padding(.top, 10)
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
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.bottom, 20)
                            .onAppear {
                                // Hide after 3 seconds
                                DispatchQueue.main.async {
                                    // Sleep this thread for 3 seconds
                                    Thread.sleep(forTimeInterval: 0.01)

                                    // After 3 seconds on main thread, hide the snackbar
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        withAnimation {
                                            self.showSnackbar = false
                                        }
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
        .onAppear {
            print("Environment vars check:")
            print(
                "SUPABASE_URL exists: \(ProcessInfo.processInfo.environment["SUPABASE_URL"] != nil)"
            )
            print(
                "SUPABASE_KEY exists: \(ProcessInfo.processInfo.environment["SUPABASE_KEY"] != nil)"
            )
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
        print("Checking if username is available: \(tempUsername)")

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
        print("Saving username to Supabase: \(username)")

        SupabaseManager.shared.saveUsername(username: username) { result in
            DispatchQueue.main.async {
                isLoading = false

                switch result {
                case .success:
                    print("Username saved successfully")
                    hasSeenWelcome = true
                    isPresented = false

                case .failure(let error):
                    let errorString = "\(error)"
                    print("Failed to save username: \(errorString)")

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
