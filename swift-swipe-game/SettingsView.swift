import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var gameScores: [GameScore]

    @AppStorage("username") private var username: String = "Player"
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true
    @AppStorage("vibrationEnabled") private var vibrationEnabled: Bool = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile").foregroundColor(darkModeEnabled ? .gray : nil)) {
                    TextField("Username", text: $username)
                        .foregroundColor(darkModeEnabled ? .white : nil)
                }

                Section(
                    header: Text("Game Settings").foregroundColor(darkModeEnabled ? .gray : nil)
                ) {
                    Toggle("Sound Effects", isOn: $soundEnabled)
                        .foregroundColor(darkModeEnabled ? .white : nil)
                    Toggle("Vibration", isOn: $vibrationEnabled)
                        .foregroundColor(darkModeEnabled ? .white : nil)
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                        .foregroundColor(darkModeEnabled ? .white : nil)
                }

                Section(header: Text("Game Stats").foregroundColor(darkModeEnabled ? .gray : nil)) {
                    HStack {
                        Text("High Score")
                            .foregroundColor(darkModeEnabled ? .white : nil)
                        Spacer()
                        Text("\(gameScores.first?.highScore ?? 0)")
                            .foregroundColor(darkModeEnabled ? .cyan : .blue)
                            .bold()
                    }

                    Button("Reset High Score") {
                        resetHighScore()
                    }
                    .foregroundColor(.red)
                }

                Section(header: Text("About").foregroundColor(darkModeEnabled ? .gray : nil)) {
                    HStack {
                        Text("Version")
                            .foregroundColor(darkModeEnabled ? .white : nil)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(darkModeEnabled ? .gray : .gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .background(darkModeEnabled ? Color.black : Color.white)
            .scrollContentBackground(darkModeEnabled ? .hidden : .visible)
            .preferredColorScheme(darkModeEnabled ? .dark : .light)
        }
    }

    private func resetHighScore() {
        if let gameScore = gameScores.first {
            gameScore.highScore = 0
            gameScore.lastUpdated = Date()
        }
    }
}
