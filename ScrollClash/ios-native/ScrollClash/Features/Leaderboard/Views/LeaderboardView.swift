import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject private var appState: AppState
    @State private var activeTab: LeaderboardTab = .global
    @State private var data: [LeaderboardPlayer] = MockData.leaderboardData
    @State private var loading = false
    @State private var errorMessage: String?

    enum LeaderboardTab { case global, friends }

    var body: some View {
        ZStack {
            StripedBackground().ignoresSafeArea()
                .overlay(Color.black.opacity(0.2).ignoresSafeArea())

            VStack(spacing: 0) {
                Color.clear.frame(height: 12)

                // Header
                HStack(spacing: 10) {
                    TrophyIcon(size: 28, color: NeonTheme.yellow)
                    Text("LEADERBOARD")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 0, x: 4, y: 4)
                }
                .padding(.bottom, 16)

                // Tab toggle
                tabToggle
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                // Your rank card
                yourRankCard
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                // Top 3 podium
                podiumRow
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                if loading {
                    ProgressView()
                        .tint(.white)
                        .padding(.bottom, 8)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(NeonTheme.pink.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 2))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }

                // Scrollable rows 4-10
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(Array(visibleData.dropFirst(3).enumerated()), id: \.element.id) { idx, player in
                            LeaderboardRowView(player: player)
                                .padding(.horizontal, 20)
                                .transition(.move(edge: .leading).combined(with: .opacity))
                        }
                        Color.clear.frame(height: 100)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .task { await loadLeaderboard() }
    }

    private var visibleData: [LeaderboardPlayer] {
        switch activeTab {
        case .global:
            return data
        case .friends:
            return Array(data.prefix(min(5, data.count)))
        }
    }

    // MARK: Tab Toggle

    private var tabToggle: some View {
        HStack(spacing: 8) {
            tabBtn(.global, icon: "globe", label: "GLOBAL")
            tabBtn(.friends, icon: "person.3.fill", label: "FRIENDS")
        }
        .padding(4)
        .background(Color.black.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black, lineWidth: 3))
    }

    @ViewBuilder
    private func tabBtn(_ tab: LeaderboardTab, icon: String, label: String) -> some View {
        let selected = activeTab == tab
        Button { withAnimation(.easeInOut(duration: 0.2)) { activeTab = tab } } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                Text(label)
                    .font(.system(size: 13, weight: .black))
            }
            .foregroundColor(selected ? .black : .white)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(selected ? NeonTheme.yellow : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: selected ? 2 : 0))
            .shadow(color: selected ? .black.opacity(0.6) : .clear, radius: 0, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    // MARK: Your Rank Card

    private var yourRankCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(NeonTheme.yellow)
                    .frame(width: 56, height: 56)
                    .overlay(Circle().stroke(Color.black, lineWidth: 3))
                    .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: 3)

                BrainCharacterView(
                    customization: appState.customization,
                    rotLevel: 20,
                    size: 44,
                    showArms: false
                )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("YOU")
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(.black)
                Text("Rank #12")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.black.opacity(0.7))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 0) {
                Text("\(MockData.currentUser.trophies)")
                    .font(.system(size: 30, weight: .black))
                    .foregroundColor(.black)
                Text("trophies")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black.opacity(0.7))
            }
        }
        .padding(16)
        .background(NeonTheme.green)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.black, lineWidth: 4))
        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 6)
    }

    // MARK: Podium

    private var podiumRow: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if visibleData.count >= 3 {
                PodiumCardView(player: visibleData[1], isFirst: false) // 2nd
                PodiumCardView(player: visibleData[0], isFirst: true)  // 1st
                PodiumCardView(player: visibleData[2], isFirst: false) // 3rd
            }
        }
    }

    private func loadLeaderboard() async {
        loading = true
        let entries = await appState.fetchGlobalLeaderboard(limit: 50)
        if entries.isEmpty {
            loading = false
            if appState.matchmakingSourceLabel == "supabase" {
                errorMessage = "Using local leaderboard fallback."
            }
            return
        }
        let mapped = entries.enumerated().map { idx, item in
            LeaderboardPlayer(
                rank: idx + 1,
                name: item.displayName,
                score: Int(item.averageScore.rounded()),
                badge: "Online",
                rotLevel: max(10, min(90, 20 + idx * 3))
            )
        }
        data = mapped
        errorMessage = nil
        loading = false
    }
}

// MARK: - Podium Card

struct PodiumCardView: View {
    let player: LeaderboardPlayer
    let isFirst: Bool

    private var cardColor: Color {
        switch player.rank {
        case 1: return NeonTheme.yellow
        case 2: return NeonTheme.purpleDark
        default: return NeonTheme.purpleDark
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            if isFirst {
                CrownIcon(size: 28, color: NeonTheme.yellow)
                    .shadow(color: .black.opacity(0.3), radius: 2)
            }

            ZStack {
                Circle()
                    .fill(medalColor)
                    .frame(width: isFirst ? 72 : 52, height: isFirst ? 72 : 52)
                    .overlay(Circle().stroke(Color.black, lineWidth: 3))

                BrainCharacterView(rotLevel: player.rotLevel, size: isFirst ? 60 : 42, showArms: false)
            }

            Text(player.name)
                .font(.system(size: isFirst ? 13 : 11, weight: .black))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 0, x: 2, y: 2)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(player.score.formatted())
                .font(.system(size: isFirst ? 18 : 14, weight: .black))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 0, x: 2, y: 2)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.black, lineWidth: isFirst ? 4 : 3))
        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 6)
    }

    private var medalColor: Color {
        switch player.rank {
        case 1: return Color(hex: "FFD700")
        case 2: return Color(hex: "C0C0C0")
        default: return Color(hex: "CD7F32")
        }
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRowView: View {
    let player: LeaderboardPlayer

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(NeonTheme.cyan)
                    .frame(width: 36, height: 36)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
                    .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: 2)
                Text("\(player.rank)")
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(.black)
            }

            ZStack {
                Circle()
                    .fill(NeonTheme.yellow)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
                    .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: 2)
                BrainCharacterView(rotLevel: player.rotLevel, size: 32, showArms: false)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 0, x: 1, y: 1)
                Text(player.badge)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            Text(player.score.formatted())
                .font(.system(size: 17, weight: .black))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 0, x: 2, y: 2)
        }
        .padding(12)
        .background(NeonTheme.purpleMid)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black, lineWidth: 3))
        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 4)
    }
}

private extension Int {
    func formatted() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
