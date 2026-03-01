import SwiftUI

struct PreDuelView: View {
    @EnvironmentObject private var appState: AppState
    let onDismiss: () -> Void

    enum Phase { case searching, found, countdown }
    enum MatchMode { case quick, joinCode }

    @State private var phase: Phase = .searching
    @State private var countdown = 3
    @State private var dots = ""
    @State private var showArena = false
    @State private var mode: MatchMode = .quick
    @State private var joinCode = ""
    @State private var isSubmitting = false
    @State private var waitingForJoin = false
    @State private var hostedCode: String?
    @State private var opponent = MockData.defaultOpponent
    @State private var matchDuration = 60
    @State private var trophyDelta = 25
    @State private var boostSlots = 4
    @State private var matchId: String? = nil
    @State private var matchmakingError: String?

    var body: some View {
        ZStack {
            // Matchmaking UI
            if !showArena {
                StripedBackground().ignoresSafeArea()
                    .overlay(
                        LinearGradient(
                            colors: [Color.black.opacity(0.4), Color.clear, Color.black.opacity(0.6)],
                            startPoint: .top, endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    )

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: onDismiss) {
                            ZStack {
                                Circle()
                                    .fill(NeonTheme.pink)
                                    .frame(width: 40, height: 40)
                                    .overlay(Circle().stroke(Color.black, lineWidth: 3))
                                    .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 3)
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Text(headerTitle)
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 0, x: 3, y: 3)

                        Spacer()
                        Color.clear.frame(width: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                    Spacer()

                    // Phase content
                    Group {
                        if phase == .searching {
                            searchingView
                                .transition(.opacity.combined(with: .scale))
                        } else {
                            foundView
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: phase)

                    Spacer()

                    Color.clear.frame(height: 32)
                }
                .transition(.opacity)
            }

            // Arena replaces this view in-place — avoids nested fullScreenCover
            // which triggers iOS orientation-transaction re-entry warnings.
            if showArena {
                DuelArenaView(opponent: opponent, matchId: matchId, onDismiss: { showArena = false; onDismiss() })
                    .transition(.move(edge: .bottom))
                    .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showArena)
    }

    private var headerTitle: String {
        switch phase {
        case .searching: return "FINDING OPPONENT"
        case .found:     return "OPPONENT FOUND"
        case .countdown: return "GET READY!"
        }
    }

    // MARK: Searching View

    private var searchingView: some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                modeButton(.quick, label: "QUICK MATCH")
                modeButton(.joinCode, label: "JOIN CODE")
            }
            .padding(4)
            .background(Color.black.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 2))
            .padding(.horizontal, 20)

            Image(systemName: "bolt.fill")
                .font(.system(size: 80, weight: .black))
                .foregroundColor(NeonTheme.green)
                .shadow(color: NeonTheme.green.opacity(0.6), radius: 20)
                .rotationEffect(.degrees(showArena ? 0 : 0))

            VStack(spacing: 8) {
                Text("SEARCHING\(animatedDots)")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 0, x: 2, y: 2)
                Text(mode == .quick ? "Generate code and wait for someone to join" : "Join a friend with code")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }

            if mode == .quick {
                VStack(spacing: 10) {
                    if let hostedCode {
                        VStack(spacing: 6) {
                            Text("SHARE THIS CODE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                            Text(hostedCode)
                                .font(.system(size: 34, weight: .black, design: .monospaced))
                                .foregroundColor(NeonTheme.yellow)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 3))
                        }
                    }

                    Button {
                        Task { await createCodeAndWait() }
                    } label: {
                        Text(quickButtonTitle)
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(NeonTheme.green)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black, lineWidth: 4))
                            .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSubmitting)
                    .opacity(isSubmitting ? 0.6 : 1)
                    .padding(.horizontal, 20)
                }
            } else {
                VStack(spacing: 10) {
                    TextField("Enter match code", text: $joinCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled(true)
                        .font(.system(size: 15, weight: .black))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .frame(height: 48)
                        .background(NeonTheme.yellow)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 3))
                        .padding(.horizontal, 20)
                        .onChange(of: joinCode) { value in
                            let filtered = value.uppercased().filter { $0.isNumber || $0.isLetter }
                            joinCode = String(filtered.prefix(6))
                        }

                    Button {
                        Task { await joinMatchByCode() }
                    } label: {
                        Text(isSubmitting ? "JOINING..." : "JOIN MATCH")
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(NeonTheme.green)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black, lineWidth: 4))
                            .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSubmitting || joinCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity((isSubmitting || joinCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.6 : 1)
                    .padding(.horizontal, 20)
                }
            }

            if let matchmakingError {
                Text(matchmakingError)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(NeonTheme.pink.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 2))
                    .padding(.horizontal, 20)
            }
        }
        .task {
            while true {
                try? await Task.sleep(for: .milliseconds(500))
                dots = dots.count >= 3 ? "" : dots + "."
            }
        }
    }

    private var animatedDots: String { dots }
    private var quickButtonTitle: String {
        if waitingForJoin && isSubmitting { return "WAITING FOR JOIN..." }
        if hostedCode != nil { return "REGENERATE CODE" }
        return "GENERATE MATCH CODE"
    }

    @ViewBuilder
    private func modeButton(_ target: MatchMode, label: String) -> some View {
        let selected = mode == target
        Button {
            mode = target
            matchmakingError = nil
            hostedCode = nil
            waitingForJoin = false
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .black))
                .foregroundColor(selected ? .black : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(selected ? NeonTheme.green : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: selected ? 2 : 0))
        }
        .buttonStyle(.plain)
    }

    // MARK: Found View

    private var foundView: some View {
        VStack(spacing: 20) {
            // VS panel
            HStack(alignment: .center, spacing: 12) {
                // You
                playerCard(
                    brain: appState.customization,
                    rotLevel: 25,
                    name: "YOU",
                    rank: "#42",
                    rot: "25%",
                    wins: "37",
                    bg: NeonTheme.purpleDark
                )

                // VS badge
                ZStack {
                    Circle()
                        .fill(NeonTheme.pink)
                        .frame(width: 52, height: 52)
                        .overlay(Circle().stroke(Color.black, lineWidth: 4))
                        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 4)
                    Text("VS")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.white)
                }

                // Opponent
                playerCard(
                    brain: { var c = BrainCustomization(); c.skin = "toxic"; c.expression = "focused"; return c }(),
                    rotLevel: opponent.rotLevel,
                    name: opponent.name,
                    rank: "#\(opponent.rank)",
                    rot: "\(opponent.rotLevel)%",
                    wins: "\(opponent.wins)",
                    bg: NeonTheme.pink
                )
            }
            .padding(.horizontal, 20)

            // Battle info
            HStack(spacing: 0) {
                battleInfoCell("\(matchDuration)s", label: "DURATION", color: NeonTheme.green)
                Divider().background(Color.white.opacity(0.2))
                battleInfoCell("+\(trophyDelta)", label: "TROPHY",   color: NeonTheme.yellow)
                Divider().background(Color.white.opacity(0.2))
                battleInfoCell("\(boostSlots)",   label: "BOOSTS",   color: NeonTheme.pink)
            }
            .padding(16)
            .background(Color.black.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.2), lineWidth: 3))
            .padding(.horizontal, 20)

            if let matchmakingError {
                Text(matchmakingError)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(NeonTheme.pink.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 2))
                    .padding(.horizontal, 20)
            }

            // Countdown or Ready
            if phase == .countdown {
                ZStack {
                    Circle()
                        .fill(NeonTheme.green)
                        .frame(width: 120, height: 120)
                        .overlay(Circle().stroke(Color.black, lineWidth: 6))
                        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 8)
                    Text("\(countdown)")
                        .font(.system(size: 64, weight: .black))
                        .foregroundColor(.black)
                }
                .scaleEffect(1.0)
                .transition(.scale)
            } else {
                Button {
                    withAnimation { phase = .countdown }
                    startCountdown()
                } label: {
                    Text("READY!")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(NeonTheme.green)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.black, lineWidth: 4))
                        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 6)
                        .shadow(color: NeonTheme.green.opacity(0.4), radius: 12)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    private func playerCard(brain: BrainCustomization, rotLevel: Int, name: String, rank: String, rot: String, wins: String, bg: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 2))
                    BrainCharacterView(customization: brain, rotLevel: rotLevel, size: 46)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("Rank \(rank)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            VStack(spacing: 4) {
                miniStatRow("ROT", value: rot)
                miniStatRow("WINS", value: wins)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black, lineWidth: 4))
        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 6)
    }

    private func miniStatRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.white)
        }
    }

    private func battleInfoCell(_ value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .black))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }

    @MainActor
    private func startCountdown() {
        Task {
            for i in stride(from: 3, through: 1, by: -1) {
                countdown = i
                try? await Task.sleep(for: .seconds(1))
            }
            try? await Task.sleep(for: .milliseconds(300))
            showArena = true
        }
    }

    @MainActor
    private func createCodeAndWait() async {
        isSubmitting = true
        matchmakingError = nil
        waitingForJoin = false
        hostedCode = nil
        do {
            let host = try await appState.createQuickMatchHost()
            hostedCode = host.matchCode
            matchId = host.matchId
            matchDuration = max(30, host.matchDuration)
            waitingForJoin = true

            let result = try await appState.waitForOpponentJoin(timeout: 240)
            guard !Task.isCancelled else { return }
            opponent = result.opponent
            matchDuration = max(30, result.matchDuration)
            trophyDelta = max(0, result.trophyDelta)
            boostSlots = max(1, result.boostSlots)
            matchId = result.matchId
            isSubmitting = false
            waitingForJoin = false
            withAnimation { phase = .found }
        } catch {
            guard !Task.isCancelled else { return }
            isSubmitting = false
            waitingForJoin = false
            if case MatchmakingError.timeout = error {
                matchmakingError = "No one joined yet. Generate a new code."
            } else {
                matchmakingError = (error as? LocalizedError)?.errorDescription ?? "Unable to generate code. Check Supabase/backend."
            }
        }
    }

    @MainActor
    private func joinMatchByCode() async {
        guard mode == .joinCode else { return }
        let code = joinCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }
        isSubmitting = true
        matchmakingError = nil
        do {
            let result = try await appState.joinMatch(matchCode: code)
            guard !Task.isCancelled else { return }
            opponent = result.opponent
            matchDuration = max(30, result.matchDuration)
            trophyDelta = max(0, result.trophyDelta)
            boostSlots = max(1, result.boostSlots)
            matchId = result.matchId
            isSubmitting = false
            withAnimation { phase = .found }
        } catch {
            guard !Task.isCancelled else { return }
            isSubmitting = false
            matchmakingError = (error as? LocalizedError)?.errorDescription ?? "Unable to join match code. Try again."
        }
    }
}
