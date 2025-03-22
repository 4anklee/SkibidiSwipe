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
                        if !tempUsername.isEmpty {
                            isLoading = true
                            username = tempUsername
                            saveUsernameToSupabase()
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
                                                gradient: Gradient(colors: [Color.blue, Color.purple]),
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
                    .disabled(tempUsername.isEmpty || isLoading)
                    .padding(.top, 20)
                }
                .padding(30)
                .alert(isPresented: $showError) {
                    Alert(
                        title: Text("Connection Error"),
                        message: Text(errorMessage),
                        primaryButton: .default(Text("Retry")) {
                            saveUsernameToSupabase()
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
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func saveUsernameToSupabase() {
        SupabaseManager.shared.saveUsername(username: username) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success:
                    // Success - continue to the game
                    hasSeenWelcome = true
                    isPresented = false
                    
                case .failure(let error):
                    // Show error alert with retry option
                    errorMessage = "Could not save your username. \(error.localizedDescription)"
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