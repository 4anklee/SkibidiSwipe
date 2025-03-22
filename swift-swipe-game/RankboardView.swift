import SwiftData
import SwiftUI

struct RankboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var gameScores: [GameScore]

    @AppStorage("username") private var username: String = "Player"
    @State private var users: [[String: Any]] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    // Colors for different ranks
    private let rankColors: [Color] = [.yellow, .gray.opacity(0.8), .brown.opacity(0.8)]

    // Trophy icons for top ranks
    private let rankIcons = ["trophy.fill", "medal.fill", "medal"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 15) {
                        // Your stats card
                        VStack(spacing: 5) {
                            Text("YOUR STATS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)

                            StatsCard(
                                username: username, highScore: gameScores.first?.highScore ?? 0,
                                users: users)
                        }
                        .padding(.top, 5)
                        .padding(.bottom, 10)

                        // Global rankings
                        VStack(spacing: 5) {
                            Text("GLOBAL RANKINGS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)

                            if isLoading {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .padding()
                                    .frame(height: 200)
                            } else if users.isEmpty {
                                EmptyRankingsView()
                            } else {
                                RankingsList(
                                    users: users, username: username, rankColors: rankColors,
                                    rankIcons: rankIcons)
                            }

                            Button(action: {
                                fetchAllUsers()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Refresh Rankings")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 20)
                                .background(
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.blue, Color.purple.opacity(0.8),
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(10)
                                )
                                .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                            .padding(.top, 20)
                            .padding(.bottom, 30)
                        }
                    }
                    .padding(.horizontal)
                }
                .navigationTitle("Leaderboard")
                .navigationBarTitleDisplayMode(.large)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color.black, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .alert(isPresented: $showError) {
                    Alert(
                        title: Text("Loading Error"),
                        message: Text(errorMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
                .task {
                    fetchAllUsers()
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func fetchAllUsers() {
        isLoading = true
        SupabaseManager.shared.getAllUsers { result in
            DispatchQueue.main.async {
                isLoading = false

                switch result {
                case .success(let fetchedUsers):
                    // Sort users by highest score in descending order
                    self.users = fetchedUsers.sorted {
                        let score1 = $0["highest_score"] as? Int ?? 0
                        let score2 = $1["highest_score"] as? Int ?? 0
                        return score1 > score2
                    }

                case .failure(let error):
                    errorMessage = "Could not load rankings. \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct StatsCard: View {
    let username: String
    let highScore: Int
    let users: [[String: Any]]

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.1, green: 0.12, blue: 0.22))
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)

            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.cyan)
                        .font(.system(size: 16, weight: .bold))
                        .padding(8)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())

                    Text(username)
                        .foregroundColor(.white)
                        .font(.system(size: 22, weight: .bold))

                    Spacer()

                    // Show user's rank if found
                    if let userIndex = users.firstIndex(where: {
                        $0["username"] as? String == username
                    }) {
                        Text("RANK #\(userIndex + 1)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(8)
                    }
                }

                Divider()
                    .background(Color.gray.opacity(0.3))

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MAX AURA")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text("\(highScore)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.cyan)
                    }

                    Spacer()

                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 28))
                        .foregroundColor(.cyan.opacity(0.7))
                }
            }
            .padding()
        }
    }
}

struct EmptyRankingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.7))

            Text("No rankings available")
                .foregroundColor(.gray)
                .italic()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
}

struct RankingsList: View {
    let users: [[String: Any]]
    let username: String
    let rankColors: [Color]
    let rankIcons: [String]

    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(users.indices, id: \.self) { index in
                let user = users[index]
                let isCurrentUser = user["username"] as? String == username

                HStack {
                    // Rank number with medal for top 3
                    if index < 3 {
                        ZStack {
                            Circle()
                                .fill(rankColors[index])
                                .frame(width: 45, height: 45)

                            Image(systemName: rankIcons[index])
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .bold))
                        }
                    } else {
                        Text("\(index + 1)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.gray.opacity(0.7))
                            .frame(width: 45, height: 45)
                    }

                    // User info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user["username"] as? String ?? "Unknown")
                            .font(.system(size: 18, weight: isCurrentUser ? .heavy : .semibold))
                            .foregroundColor(isCurrentUser ? .yellow : .white)

                        if index == 0 {
                            Text("RIZZ KING")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else if index == 1 {
                            Text("SKIBIDI RIZZER")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else if index == 2 {
                            Text("OHIO RIZZER")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }

                    Spacer()

                    // Score with accent color based on position
                    VStack(alignment: .trailing) {
                        Text("\(user["highest_score"] as? Int ?? 0)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(index < 3 ? rankColors[index] : .cyan)

                        Text("POINTS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            isCurrentUser
                                ? Color(red: 0.3, green: 0.3, blue: 0.1).opacity(0.3)
                                : Color(red: 0.12, green: 0.12, blue: 0.14)
                        )
                        .shadow(
                            color: isCurrentUser
                                ? Color.yellow.opacity(0.3) : Color.black.opacity(0.1), radius: 3,
                            x: 0, y: 2)
                )
            }
        }
    }
}
