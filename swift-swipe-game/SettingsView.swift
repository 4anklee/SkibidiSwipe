import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var gameScores: [GameScore]

    @AppStorage("username") private var username: String = "Player"
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true
    @AppStorage("vibrationEnabled") private var vibrationEnabled: Bool = true
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile").foregroundColor(.gray)) {
                    TextField("Username", text: $username)
                        .foregroundColor(.white)
                        .onChange(of: username) { oldValue, newValue in
                            if oldValue != newValue {
                                updateUsernameInSupabase()
                            }
                        }
                }

                Section(
                    header: Text("Game Settings").foregroundColor(.gray)
                ) {
                    Toggle("Sound Effects", isOn: $soundEnabled)
                        .foregroundColor(.white)
                    Toggle("Vibration", isOn: $vibrationEnabled)
                        .foregroundColor(.white)
                }

                Section(header: Text("Game Stats").foregroundColor(.gray)) {
                    HStack {
                        Text("High Score")
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(gameScores.first?.highScore ?? 0)")
                            .foregroundColor(.cyan)
                            .bold()
                    }

                    Button("Reset High Score") {
                        resetHighScore()
                    }
                    .foregroundColor(.red)
                }

                Section(header: Text("About").foregroundColor(.gray)) {
                    HStack {
                        Text("Version")
                            .foregroundColor(.white)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .background(Color.black)
            .scrollContentBackground(.hidden)
            .preferredColorScheme(.dark)
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Sync Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private func resetHighScore() {
        if let gameScore = gameScores.first {
            gameScore.highScore = 0
            gameScore.lastUpdated = Date()
            
            // Sync with Supabase
            let username = UserDefaults.standard.string(forKey: "username") ?? "Player"
            SupabaseManager.shared.updateHighScore(username: username, highScore: 0) { result in
                if case .failure(let error) = result {
                    DispatchQueue.main.async {
                        errorMessage = "Could not sync high score. \(error.localizedDescription)"
                        showError = true
                    }
                }
            }
        }
    }
    
    private func updateUsernameInSupabase() {
        SupabaseManager.shared.saveUsername(username: username) { result in
            if case .failure(let error) = result {
                DispatchQueue.main.async {
                    errorMessage = "Could not update username. \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}
