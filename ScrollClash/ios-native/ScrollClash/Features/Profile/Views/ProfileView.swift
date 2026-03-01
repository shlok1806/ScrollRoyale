import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var profileVM = ProfileViewModel(
        service: AppServices.profileService()
    )
    @State private var showBrainLab = false
    @State private var user = MockData.currentUser

    private let badges = MockData.badges
    private let skins = MockData.brainSkins

    var body: some View {
        ZStack {
            StripedBackground().ignoresSafeArea()
                .overlay(Color.black.opacity(0.2).ignoresSafeArea())

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 12)

                    // Settings button
                    HStack {
                        Spacer()
                        Button {} label: {
                            ZStack {
                                Circle()
                                    .fill(NeonTheme.purpleDark)
                                    .frame(width: 40, height: 40)
                                    .overlay(Circle().stroke(Color.black, lineWidth: 3))
                                    .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 3)
                                SettingsIcon(size: 17)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                    // Profile header
                    profileHeader
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                    if profileVM.isLoading {
                        ProgressView()
                            .tint(.white)
                            .padding(.bottom, 8)
                    }

                    if let errorMessage = profileVM.errorMessage {
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

                    // Stats cards
                    statsCards
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                    // Performance panel
                    performancePanel
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                    // Badges
                    badgesSection
                        .padding(.bottom, 16)

                    // Brain skins
                    brainSkinsSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                }
            }
        }
        .fullScreenCover(isPresented: $showBrainLab) {
            BrainLabView(onDismiss: { showBrainLab = false })
        }
        .task { loadProfileSummary() }
        .onChange(of: profileVM.profile) { summary in
            guard let summary else { return }
            user = UserProfile(
                username: summary.displayName,
                level: user.level,
                rank: max(1, summary.matchesPlayed - summary.wins + 1),
                trophies: Int(summary.bestScore.rounded()),
                winRate: summary.matchesPlayed > 0 ? Int((Double(summary.wins) / Double(summary.matchesPlayed) * 100).rounded()) : 0,
                totalDuels: summary.matchesPlayed,
                bestStreak: user.bestStreak,
                bestStability: user.bestStability,
                avgRot: user.avgRot,
                rankTitle: user.rankTitle
            )
        }
    }

    // MARK: Profile Header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottom) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [NeonTheme.green, NeonTheme.cyan],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 112, height: 112)
                        .overlay(Circle().stroke(Color.black, lineWidth: 4))
                        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 6)

                    BrainCharacterView(
                        customization: appState.customization,
                        rotLevel: 15,
                        size: 90,
                        showArms: false
                    )
                }

                // Level badge
                Text("LVL \(user.level)")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(NeonTheme.yellow)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.black, lineWidth: 2))
                    .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: 2)
                    .offset(y: 8)
            }
            .padding(.bottom, 8)

            Text(user.username)
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 0, x: 3, y: 3)

            // Rank title badge
            HStack(spacing: 6) {
                CrownIcon(size: 14, color: .black)
                Text(user.rankTitle)
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(NeonTheme.green)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.black, lineWidth: 2))

            // Customize button
            Button { showBrainLab = true } label: {
                Text("CUSTOMIZE BRAIN")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(NeonTheme.pink)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 3))
                    .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Stats Cards

    private var statsCards: some View {
        HStack(spacing: 8) {
            statCard(icon: TrophyIcon(size: 18, color: .black), value: "1,204", label: "TROPHIES",
                     bg: NeonTheme.green, fg: .black)
            statCard(icon: TargetIcon(size: 18, color: .white), value: "68%", label: "WIN RATE",
                     bg: NeonTheme.pink, fg: .white)
            statCard(icon: ZapIcon(size: 18, color: .black), value: "127", label: "DUELS",
                     bg: NeonTheme.cyan, fg: .black)
        }
    }

    private func statCard<I: View>(icon: I, value: String, label: String, bg: Color, fg: Color) -> some View {
        VStack(spacing: 4) {
            icon
            Text(value)
                .font(.system(size: 19, weight: .black))
                .foregroundColor(fg)
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(fg)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black, lineWidth: 3))
        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 4)
    }

    // MARK: Performance Panel

    private var performancePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                StarIcon(size: 15, color: NeonTheme.yellow)
                Text("PERFORMANCE")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.white)
            }

            VStack(spacing: 8) {
                statLine("Current Rank", value: "#\(user.rank) Global")
                statLine("Best Streak",  value: "\(user.bestStreak) days")
                statLine("Best Stability", value: "\(user.bestStability)%")
                statLine("Avg Rot",      value: "\(user.avgRot)%")
            }
        }
        .padding(16)
        .background(NeonTheme.purpleDark)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.black, lineWidth: 4))
        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 6)
    }

    private func statLine(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .black))
                .foregroundColor(.white)
        }
    }

    // MARK: Badges

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                AwardBadgeIcon(size: 18, color: NeonTheme.yellow)
                Text("BADGES")
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(badges) { badge in
                        VStack(spacing: 6) {
                            TrophyIcon(size: 24, color: .black)
                            Text(badge.name)
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.black)
                        }
                        .frame(width: 72)
                        .padding(.vertical, 12)
                        .background(badge.color)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black, lineWidth: 3))
                        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 4)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: Brain Skins

    private var brainSkinsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                PaletteIcon(size: 18, color: NeonTheme.pink)
                Text("BRAIN SKINS")
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(.white)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(skins) { skin in
                    VStack(spacing: 6) {
                        if skin.owned {
                            BrainCharacterView(rotLevel: 20, size: 36, showArms: false)
                        } else {
                            LockIcon(size: 22, color: .black)
                        }

                        Text(skin.name)
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.black)

                        Text(skin.owned ? "OWNED" : "LOCKED")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(skin.owned ? .black : .white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(skin.owned ? NeonTheme.green : Color.black.opacity(0.3))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.black, lineWidth: 1))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(skin.owned ? skin.color : Color(hex: "5A5A7A"))
                    .opacity(skin.owned ? 1 : 0.7)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black, lineWidth: 3))
                    .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 4)
                }
            }
        }
    }

    private func loadProfileSummary() {
        profileVM.load()
    }
}
