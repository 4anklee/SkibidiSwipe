import SwiftUI

struct WelcomeView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9).edgesIgnoringSafeArea(.all)
            
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
                        hasSeenWelcome = true
                        isPresented = false
                    }
                }) {
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
                }
                .padding(.top, 20)
            }
            .padding(30)
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