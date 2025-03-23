import SwiftData
import SwiftUI

#if canImport(UIKit)
    import UIKit
#else
    import AppKit
#endif

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

                        VStack(spacing: 5) {
                            Text("GLOBAL RANKINGS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)

                            ZStack {
                                // Rankings content
                                if users.isEmpty {
                                    EmptyRankingsView()
                                        .opacity(isLoading ? 0.3 : 1.0)
                                        .animation(.easeInOut(duration: 0.5), value: isLoading)
                                } else {
                                    RankingsList(
                                        users: users, username: username, rankColors: rankColors,
                                        rankIcons: rankIcons
                                    )
                                    .opacity(isLoading ? 0.3 : 1.0)
                                    .animation(.easeInOut(duration: 0.5), value: isLoading)
                                }

                                // Loading overlay
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .padding()
                                        .frame(maxWidth: .infinity, minHeight: 200)
                                        .transition(.opacity)
                                        .animation(.easeInOut(duration: 0.3), value: isLoading)
                                }
                            }

                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    isLoading = true
                                }
                                fetchAllUsers()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                        .rotationEffect(.degrees(isLoading ? 360 : 0))
                                        .animation(
                                            isLoading
                                                ? .linear(duration: 1.0).repeatForever(
                                                    autoreverses: false) : .default,
                                            value: isLoading
                                        )
                                    Text("Refresh Rankings")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 20)
                                .background(
                                    Rectangle()
                                        .fill(
                                            Material.ultraThin
                                        )
                                        .cornerRadius(10)
                                )
                            }
                            .opacity(isLoading ? 0.6 : 1.0)
                            .scaleEffect(isLoading ? 0.95 : 1.0)
                            .disabled(isLoading)
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
        let loadingDelay = DispatchTime.now() + 1.5

        SupabaseManager.shared.getAllUsers { result in
            DispatchQueue.main.asyncAfter(deadline: loadingDelay) {
                isLoading = false

                switch result {
                case .success(let fetchedUsers):
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

                    // Custom share button
                    Button(action: {
                        // Create a comprehensive share message
                        let shareText =
                            "I just got \(highScore) points in Skibidi Swipe! Can you beat me? 🎮 #SkibidiSwipe"

                        // Initialize shareItems array
                        var shareItems: [Any] = []

                        // Add text first for better display on most platforms
                        shareItems.append(shareText)

                        // Get app share URL from Info.plist (set in Secrets.xcconfig)
                        // Add https:// prefix since we can't include it in xcconfig (would be treated as comment)
                        if let appURLString = Bundle.main.object(
                            forInfoDictionaryKey: "AppShareURL") as? String
                        {
                            let fullURLString = "https://" + appURLString
                            let appURL = URL(string: fullURLString)

                            // Add URL to share items
                            if let appURL = appURL {
                                shareItems.append(appURL)
                            }
                        }

                        // Add app icon as a preview image
                        #if canImport(UIKit)
                            if let appIcon = UIImage(named: "AppIcon")
                                ?? UIImage(systemName: "gamecontroller.fill")
                            {
                                shareItems.append(appIcon)
                            }
                        #endif

                        // Create and configure activity view controller
                        #if canImport(UIKit)
                            let activityVC = UIActivityViewController(
                                activityItems: shareItems,
                                applicationActivities: nil
                            )

                            // Optional: Customize title and subject for email/messages
                            activityVC.setValue(
                                "Skibidi Swipe - High Score Challenge", forKey: "subject")

                            // Set up share sheet for iPad
                            if let windowScene = UIApplication.shared.connectedScenes.first
                                as? UIWindowScene,
                                let rootViewController = windowScene.windows.first?
                                    .rootViewController
                            {
                                // For iPad: Set the source point to avoid crashes
                                if let popover = activityVC.popoverPresentationController {
                                    popover.sourceView = rootViewController.view
                                    popover.sourceRect = CGRect(
                                        x: UIScreen.main.bounds.width / 2,
                                        y: UIScreen.main.bounds.height / 2,
                                        width: 0,
                                        height: 0)
                                    popover.permittedArrowDirections = []
                                }

                                rootViewController.present(activityVC, animated: true)
                            }
                        #endif
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20))
                            Text("Share")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.cyan.opacity(0.2))
                        .cornerRadius(8)
                        .foregroundColor(.cyan)
                    }
                    .buttonStyle(.plain)
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
