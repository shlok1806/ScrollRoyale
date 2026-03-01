import SwiftUI

enum Tab: Int, CaseIterable {
    case home, leaderboard, duel, graveyard, profile
}

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    @State private var showDuel = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(Tab.home)

                LeaderboardView()
                    .tag(Tab.leaderboard)

                Color.clear
                    .tag(Tab.duel)

                GraveyardView()
                    .tag(Tab.graveyard)

                ProfileView()
                    .tag(Tab.profile)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            CustomTabBar(selectedTab: $selectedTab, onDuelTap: { showDuel = true })
        }
        .fullScreenCover(isPresented: $showDuel) {
            PreDuelView(onDismiss: { showDuel = false })
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    let onDuelTap: () -> Void

    private let items: [(tab: Tab, icon: String, label: String)] = [
        (.home, "house.fill", "Home"),
        (.leaderboard, "trophy.fill", "Ranks"),
        (.graveyard, "ghost.fill", "History"),
        (.profile, "person.fill", "Profile"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            // Home
            tabButton(for: .home, systemImage: "house.fill", label: "Home")

            // Leaderboard
            tabButton(for: .leaderboard, systemImage: "trophy.fill", label: "Ranks")

            // Center Duel CTA
            Button(action: onDuelTap) {
                ZStack {
                    Circle()
                        .fill(NeonTheme.green)
                        .frame(width: 60, height: 60)
                        .overlay(Circle().stroke(Color.black, lineWidth: 3))
                        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 4)
                        .shadow(color: NeonTheme.green.opacity(0.6), radius: 12)

                    Image(systemName: "bolt.fill")
                        .font(.system(size: 26, weight: .black))
                        .foregroundColor(.black)
                }
            }
            .frame(maxWidth: .infinity)
            .offset(y: -8)

            // Graveyard
            tabButton(for: .graveyard, systemImage: "moon.fill", label: "History")

            // Profile
            tabButton(for: .profile, systemImage: "person.fill", label: "Profile")
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, max(20, UIApplication.safeAreaInsets.bottom))
        .background(
            Color.black.opacity(0.9)
                .overlay(Rectangle().fill(Color.white.opacity(0.05)))
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 1)
                }
        )
    }

    @ViewBuilder
    private func tabButton(for tab: Tab, systemImage: String, label: String) -> some View {
        let isSelected = selectedTab == tab
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(isSelected ? NeonTheme.green : Color.white.opacity(0.5))
                Text(label)
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(isSelected ? NeonTheme.green : Color.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private extension UIApplication {
    static var safeAreaInsets: UIEdgeInsets {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.safeAreaInsets ?? .zero
    }
}
