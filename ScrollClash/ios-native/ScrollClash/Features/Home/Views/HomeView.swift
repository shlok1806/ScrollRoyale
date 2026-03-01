import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showBoosts = false
    @State private var appeared = false

    private let rotLevel = 37
    private let weeklyData = MockData.weeklyRotData
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        ZStack {
            StripedBackground().ignoresSafeArea()
                .overlay(Color.black.opacity(0.2).ignoresSafeArea())

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 12)

                    // Header
                    headerRow
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                    // Today's Brain title
                    Text("TODAY'S BRAIN")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 0, x: 4, y: 4)
                        .padding(.bottom, 12)

                    // Brain + ring
                    brainSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                    // Stats pills
                    statsPills
                        .padding(.bottom, 12)

                    // Battle panel
                    battlePanel
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                    // Boost deck button
                    boostDeckButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                    // Daily challenge
                    dailyChallengePanel
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                    // 7-day chart
                    weeklyChart
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                }
            }
        }
        .fullScreenCover(isPresented: $showBoosts) {
            BoostInventoryView(onDismiss: { showBoosts = false })
                .environmentObject(appState)
        }
    }

    // MARK: Header

    private var headerRow: some View {
        HStack {
            // Trophy pill
            HStack(spacing: 6) {
                TrophyIcon(size: 14, color: .black)
                Text("+12")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(NeonTheme.green)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.black, lineWidth: 3))
            .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 3)

            Spacer()

            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 48, height: 48)
                    .overlay(Circle().stroke(Color.black, lineWidth: 3))
                    .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 3)

                BrainCharacterView(
                    customization: appState.customization,
                    rotLevel: 10,
                    size: 38,
                    showArms: false
                )
            }
        }
    }

    // MARK: Brain Section

    private var brainSection: some View {
        VStack(spacing: 8) {
            ZStack {
                ProgressRingView(progress: Double(rotLevel), size: 180, strokeWidth: 14)

                BrainCharacterView(
                    customization: appState.customization,
                    rotLevel: rotLevel,
                    size: 120
                )
            }

            // Rot badge
            Text("\(rotLevel)% ROT")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 0, x: 2, y: 2)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(NeonTheme.pink)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 4))
                .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 4)
        }
    }

    // MARK: Stats Pills

    private var statsPills: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                FlameIcon(size: 13, color: .white)
                Text("4 DAYS")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(NeonTheme.orange)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.black, lineWidth: 2))

            HStack(spacing: 6) {
                TrophyIcon(size: 13, color: .black)
                Text("1,204")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(NeonTheme.yellow)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.black, lineWidth: 2))
        }
    }

    // MARK: Battle Panel

    private var battlePanel: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "cube.transparent.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(NeonTheme.yellow)
                Text("READY FOR BATTLE?")
                    .font(.system(size: 17, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 0, x: 2, y: 2)
            }

            // Battle Now button (handled by center tab CTA)
            Text("TAP ⚡ TO BATTLE!")
                .font(.system(size: 17, weight: .black))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(NeonTheme.green)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 4))
                .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 6)
                .shadow(color: NeonTheme.green.opacity(0.4), radius: 10)

            HStack(spacing: 8) {
                smallActionButton("INVITE", icon: "person.badge.plus.fill", color: NeonTheme.blue)
                smallActionButton("PRACTICE", icon: "target", color: Color(hex: "F72585"))
            }
        }
        .padding(16)
        .background(NeonTheme.purpleDark)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.black, lineWidth: 4))
        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 6)
    }

    private func smallActionButton(_ label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
            Text(label)
                .font(.system(size: 12, weight: .black))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 40)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 2))
        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 3)
    }

    // MARK: Boost Deck

    private var boostDeckButton: some View {
        Button { showBoosts = true } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(NeonTheme.yellow)
                        .frame(width: 48, height: 48)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 2))
                        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 3)
                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("BOOST DECK")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.white)
                    Text("4/4 equipped • Manage cards")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(12)
            .background(NeonTheme.pink)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.black, lineWidth: 4))
            .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: Daily Challenge

    private var dailyChallengePanel: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(NeonTheme.yellow)
                    .frame(width: 48, height: 48)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 2))
                    .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 3)
                TargetIcon(size: 22, color: .black)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("DAILY CHALLENGE")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.black)
                Text("No Rage Flicks x60s")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black.opacity(0.8))
            }

            Spacer()

            Text("+50")
                .font(.system(size: 12, weight: .black))
                .foregroundColor(.black)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(NeonTheme.yellow)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.black, lineWidth: 2))
        }
        .padding(12)
        .background(NeonTheme.cyan)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.black, lineWidth: 4))
        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 6)
    }

    // MARK: Weekly Chart

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZapIcon(size: 15, color: NeonTheme.yellow)
                Text("7-DAY TREND")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.white)
            }

            HStack(spacing: 6) {
                ForEach(weeklyData.indices, id: \.self) { idx in
                    let value = weeklyData[idx]
                    let maxH: CGFloat = 40
                    let h: CGFloat = CGFloat(value) / 100 * maxH
                    let barColor: Color = value < 35 ? NeonTheme.green : value < 50 ? NeonTheme.cyan : NeonTheme.pink

                    VStack(spacing: 4) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.black.opacity(0.3))
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black, lineWidth: 2))
                                .frame(height: maxH)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(barColor)
                                .frame(height: h)
                                .animation(.easeOut(duration: 0.4).delay(Double(idx) * 0.08), value: appeared)
                        }
                        .frame(maxWidth: .infinity)

                        Text(dayLabels[idx])
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(12)
        .background(NeonTheme.purpleMid)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.black, lineWidth: 4))
        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 6)
    }
}
