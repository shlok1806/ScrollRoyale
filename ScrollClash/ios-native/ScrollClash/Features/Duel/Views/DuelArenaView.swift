import SwiftUI
import AVKit

struct DuelArenaView: View {
    @EnvironmentObject private var appState: AppState
    let match: Match?
    let opponent: DuelOpponent
    let onDismiss: () -> Void

    private let matchDuration = 90
    private let videoDuration = 10

    @State private var timeLeft = 90
    @State private var videoTimeLeft = 10
    @State private var yourHP = 1000
    @State private var opponentHP = 1000
    // Baseline opponent HP so we can map Supabase scores to HP deltas
    private let opponentHPBase = 1000
    @State private var bankedDamage = 0
    @State private var comboMeter = 2
    @State private var multiplier = 1.0
    @State private var focusMeter = 6
    @State private var reactionActive = false
    @State private var damagePopups: [(id: UUID, damage: Int, isYou: Bool)] = []
    @State private var showResult = false
    @State private var isVictory = false

    // VideoFeedView bindings
    @State private var scrollOffset: Double = 0
    @State private var currentVideoIndex = 0
    @State private var playbackTime: Double = 0

    private let boostDeck = [
        (id: 1, name: "Shield", focusCost: 3, cooldown: 0, available: true),
        (id: 2, name: "Double", focusCost: 5, cooldown: 3, available: false),
        (id: 3, name: "Freeze", focusCost: 4, cooldown: 0, available: true),
        (id: 4, name: "Rage",   focusCost: 6, cooldown: 5, available: false),
    ]

    @StateObject private var gameVM: GameViewModel

    init(match: Match?, opponent: DuelOpponent, onDismiss: @escaping () -> Void) {
        self.match = match
        self.opponent = opponent
        self.onDismiss = onDismiss

        let userId = SupabaseSessionStore.shared.userId ?? "demo-user"
        let effectiveMatch = match ?? Match(
            id: "demo-\(UUID().uuidString)",
            matchCode: "DEMO",
            player1Id: userId,
            player2Id: nil,
            status: .inProgress,
            createdAt: Date(),
            startedAt: Date(),
            endedAt: nil,
            durationSec: 90,
            contentFeedIds: []
        )

        if match != nil {
            // Live match: use Supabase content + sync services
            _gameVM = StateObject(wrappedValue: GameViewModel(
                match: effectiveMatch,
                currentUserId: userId,
                contentService: AppServices.contentService(),
                syncService: AppServices.syncService()
            ))
        } else {
            // Demo mode: fetch reels table directly, no sync needed
            _gameVM = StateObject(wrappedValue: GameViewModel(
                match: effectiveMatch,
                currentUserId: userId,
                contentService: AppServices.demoContentService(),
                syncService: MockSyncService.shared
            ))
        }
    }

    private var timerProgress: Double { Double(timeLeft) / Double(matchDuration) }
    private var yourHPPercent:   Double { Double(yourHP) / 1000 }
    private var opponentHPPercent: Double { Double(opponentHP) / 1000 }
    private var totalVideos: Int { max(1, gameVM.contentItems.isEmpty ? 9 : gameVM.contentItems.count) }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Video feed background
                if gameVM.contentItems.isEmpty {
                    VideoPlaceholderView(
                        videoNumber: currentVideoIndex + 1,
                        totalVideos: totalVideos,
                        sourceHint: nil,
                        playbackURL: nil
                    )
                } else {
                    VideoFeedView(
                        items: gameVM.contentItems,
                        scrollOffset: $scrollOffset,
                        currentIndex: $currentVideoIndex,
                        playbackTime: $playbackTime,
                        onScroll: { offset, index, time in
                            gameVM.handleScroll(offset: offset, videoIndex: index, playbackTime: time)
                        }
                    )
                    .ignoresSafeArea()
                }

                // Gradient overlays
                VStack {
                    LinearGradient(colors: [Color.black.opacity(0.8), Color.black.opacity(0.4), .clear],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: 260)
                    Spacer()
                    LinearGradient(colors: [.clear, Color.black.opacity(0.4), Color.black.opacity(0.8)],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: 260)
                }
                .ignoresSafeArea()

                // Loading overlay
                if gameVM.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(NeonTheme.green)
                            .scaleEffect(1.5)
                        Text("Loading reels...")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(20)
                    .background(Color.black.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                if let msg = gameVM.feedStatusMessage, !gameVM.isLoading {
                    Text(msg)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(10)
                        .background(Color.black.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // HUD
                VStack(spacing: 0) {
                    topHUD
                        .padding(.horizontal, 16)
                        .padding(.top, max(geo.safeAreaInsets.top, 12))

                    Spacer()

                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 12) {
                            comboWidget
                            Spacer()
                            focusWidget
                        }
                        Spacer()
                        VStack(spacing: 12) {
                            reactionButton
                            quizIndicator
                            discoveryProgress
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(maxHeight: 220)

                    bankedDamagePanel
                        .padding(.horizontal, 20)

                    boostDeckRow
                        .padding(.horizontal, 16)
                        .padding(.bottom, max(geo.safeAreaInsets.bottom + 4, 16))
                }

                // Damage popups
                ForEach(damagePopups, id: \.id) { popup in
                    Text("-\(popup.damage)")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(popup.isYou ? NeonTheme.pink : NeonTheme.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(popup.isYou ? NeonTheme.pink.opacity(0.2) : NeonTheme.green.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 2))
                        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 3)
                        .position(x: popup.isYou ? 80 : geo.size.width - 80, y: 200)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Result overlay
                if showResult {
                    DuelResultView(opponent: opponent, isVictory: isVictory, onDismiss: { showResult = false; onDismiss() })
                        .transition(.move(edge: .bottom))
                        .zIndex(10)
                }
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .onAppear { gameVM.startSync() }
        .onDisappear { gameVM.stopSync() }
        .onChange(of: gameVM.localScore) { score in
            // Map own score to HP: higher score = more HP for you (max 1000).
            // Score is unbounded; clamp so it reads naturally on the bar.
            yourHP = max(0, min(1000, 200 + Int(score)))
        }
        .onChange(of: gameVM.opponentScore) { score in
            // Opponent's lower HP = they are "losing" — a higher opponent score
            // means they watched more, so their HP drains faster for the local player.
            // Simple model: opponent HP = 1000 - their score delta above our score.
            let delta = max(0, score - gameVM.localScore)
            opponentHP = max(0, min(1000, 1000 - Int(delta * 2)))
        }
        .task { await runMatchTimer() }
        .task { await runVideoTimer() }
        .task { await simulateOpponentDamage() }
        .task { await runFocusRecharge() }
    }

    // MARK: Top HUD

    private var topHUD: some View {
        VStack(spacing: 10) {
            HStack(alignment: .top) {
                HStack(spacing: 8) {
                    playerAvatar(brain: appState.customization, rotLevel: 25, bg: NeonTheme.purpleDark)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("YOU").font(.system(size: 13, weight: .black)).foregroundColor(.white)
                            .shadow(color: .black.opacity(0.8), radius: 0, x: 2, y: 2)
                        Text("#42").font(.system(size: 11, weight: .bold)).foregroundColor(NeonTheme.green)
                    }
                }

                Spacer()

                Button(action: {
                    isVictory = gameVM.localScore >= gameVM.opponentScore
                    withAnimation(.easeInOut(duration: 0.3)) { showResult = true }
                }) {
                    Text("FORFEIT")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(NeonTheme.pink)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 3))
                        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 3)
                        .shadow(color: NeonTheme.pink.opacity(0.6), radius: 8)
                }
                .buttonStyle(.plain)
                .zIndex(20)

                Spacer()

                HStack(spacing: 8) {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(opponent.name).font(.system(size: 12, weight: .black)).foregroundColor(.white)
                            .shadow(color: .black.opacity(0.8), radius: 0, x: 2, y: 2)
                            .lineLimit(1).minimumScaleFactor(0.7)
                        Text("#\(opponent.rank)").font(.system(size: 11, weight: .bold)).foregroundColor(NeonTheme.pink)
                    }
                    playerAvatar(
                        brain: { var c = BrainCustomization(); c.skin = "toxic"; c.expression = "focused"; return c }(),
                        rotLevel: 65, bg: NeonTheme.pink
                    )
                }
            }

            VStack(spacing: 6) {
                timerRing

                if let matchId = match?.id {
                    HStack {
                        Text("MATCH \(matchId.prefix(6).uppercased())")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text("OPP V\(gameVM.opponentVideoIndex + 1)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(NeonTheme.green.opacity(0.85))
                        Text("SCORE \(Int(gameVM.localScore))")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(NeonTheme.yellow)
                    }
                }

                VStack(spacing: 4) {
                    HStack {
                        // P1/P2 badge for local player
                        Text(gameVM.playerTag)
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.black)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(NeonTheme.purpleLight)
                            .clipShape(Capsule())
                        Text("\(yourHP)")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(NeonTheme.purpleLight)
                        Spacer()
                        Text("\(opponentHP)")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(NeonTheme.green)
                        // P1/P2 badge for opponent
                        Text(gameVM.opponentTag)
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.black)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(NeonTheme.green)
                            .clipShape(Capsule())
                    }

                    GeometryReader { geo in
                        HStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(NeonTheme.purpleDark)
                                .frame(width: geo.size.width * yourHPPercent)
                                .animation(.easeInOut(duration: 0.3), value: yourHP)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(NeonTheme.green)
                                .frame(width: geo.size.width * opponentHPPercent)
                                .animation(.easeInOut(duration: 0.3), value: opponentHP)
                        }
                    }
                    .frame(height: 16)
                    .background(Color.black.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 3))
                    .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 3)
                }
            }
        }
    }

    private func playerAvatar(brain: BrainCustomization, rotLevel: Int, bg: Color) -> some View {
        ZStack {
            Circle()
                .fill(bg)
                .frame(width: 52, height: 52)
                .overlay(Circle().stroke(Color.black, lineWidth: 3))
                .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 4)
            BrainCharacterView(customization: brain, rotLevel: rotLevel, size: 40, showArms: false, animated: false)
        }
    }

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 6)
                .frame(width: 72, height: 72)

            Circle()
                .trim(from: 0, to: timerProgress)
                .stroke(NeonTheme.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: NeonTheme.green.opacity(0.8), radius: 6)
                .frame(width: 72, height: 72)
                .animation(.linear(duration: 1), value: timeLeft)

            Text("\(timeLeft)")
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.8), radius: 0, x: 2, y: 2)
        }
    }

    // MARK: Combo Widget

    private var comboWidget: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("COMBO")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(i < comboMeter ? NeonTheme.yellow : Color.white.opacity(0.2))
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
                        .shadow(color: i < comboMeter ? NeonTheme.yellow.opacity(0.8) : .clear, radius: 4)
                }
            }
            Text("x\(String(format: "%.1f", multiplier))")
                .font(.system(size: 20, weight: .black))
                .foregroundColor(NeonTheme.yellow)
        }
        .padding(8)
        .background(Color.black.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 3))
        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 3)
    }

    // MARK: Focus Widget

    private var focusWidget: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("FOCUS")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(10), spacing: 4), count: 5), spacing: 4) {
                ForEach(0..<10, id: \.self) { i in
                    Circle()
                        .fill(i < focusMeter ? NeonTheme.cyan : Color.white.opacity(0.2))
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
                        .shadow(color: i < focusMeter ? NeonTheme.cyan.opacity(0.8) : .clear, radius: 4)
                }
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 3))
        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 3)
    }

    // MARK: Right Sidebar Actions (TikTok style — icon circle + label)

    private var reactionButton: some View {
        sidebarAction(
            label: "REACT",
            color: reactionActive ? NeonTheme.pink : Color.white.opacity(0.18),
            glow: reactionActive ? NeonTheme.pink.opacity(0.7) : .clear
        ) {
            Image(systemName: "hand.thumbsup.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
        .disabled(!reactionActive)
        .onTapGesture { }
    }

    private var quizIndicator: some View {
        sidebarAction(
            label: "QUIZ",
            color: NeonTheme.yellow,
            glow: NeonTheme.yellow.opacity(0.5)
        ) {
            Image(systemName: "questionmark")
                .font(.system(size: 24, weight: .black))
                .foregroundColor(.black)
        }
    }

    private var discoveryProgress: some View {
        VStack(spacing: 4) {
            // Three pip dots — mini discovery progress
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(i < 2 ? NeonTheme.green : Color.white.opacity(0.25))
                    .frame(width: 9, height: 9)
                    .shadow(color: i < 2 ? NeonTheme.green.opacity(0.7) : .clear, radius: 4)
                    .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
            }
            Text("DISC")
                .font(.system(size: 9, weight: .black))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 3))
        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 3)
    }

    @ViewBuilder
    private func sidebarAction<Icon: View>(
        label: String,
        color: Color,
        glow: Color,
        @ViewBuilder icon: () -> Icon
    ) -> some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 56, height: 56)
                    .overlay(Circle().stroke(Color.black, lineWidth: 3))
                    .shadow(color: glow, radius: 10)
                    .shadow(color: .black.opacity(0.7), radius: 0, x: 0, y: 4)
                icon()
            }
            Text(label)
                .font(.system(size: 9, weight: .black))
                .foregroundColor(.white.opacity(0.85))
                .shadow(color: .black.opacity(0.6), radius: 0, x: 1, y: 1)
        }
    }

    // MARK: Banked Damage

    private var bankedDamagePanel: some View {
        VStack(spacing: 6) {
            HStack {
                Text("BANKED DAMAGE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Text("\(bankedDamage)")
                    .font(.system(size: 17, weight: .black))
                    .foregroundColor(NeonTheme.pink)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 8)
                    LinearGradient(
                        colors: [NeonTheme.green, NeonTheme.yellow, NeonTheme.pink],
                        startPoint: .leading, endPoint: .trailing
                    )
                    .frame(
                        width: geo.size.width * (CGFloat(videoDuration - videoTimeLeft) / CGFloat(videoDuration)),
                        height: 8
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .animation(.linear(duration: 1), value: videoTimeLeft)
                }
            }
            .frame(height: 8)
        }
        .padding(12)
        .background(Color.black.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black, lineWidth: 3))
        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 4)
    }

    // MARK: Boost Deck

    private var boostDeckRow: some View {
        HStack(spacing: 8) {
            ForEach(boostDeck, id: \.id) { boost in
                BoostCardMiniView(
                    name: boost.name,
                    focusCost: boost.focusCost,
                    cooldown: boost.cooldown,
                    available: boost.available,
                    canAfford: focusMeter >= boost.focusCost
                ) {
                    if boost.available && focusMeter >= boost.focusCost {
                        focusMeter = max(0, focusMeter - boost.focusCost)
                    }
                }
            }
        }
    }

    // MARK: Timers

    private func runMatchTimer() async {
        while timeLeft > 0 {
            try? await Task.sleep(for: .seconds(1))
            timeLeft = max(0, timeLeft - 1)
        }
        try? await Task.sleep(for: .milliseconds(500))
        isVictory = gameVM.localScore >= gameVM.opponentScore
        showResult = true
    }

    private func runVideoTimer() async {
        while true {
            try? await Task.sleep(for: .seconds(1))
            videoTimeLeft = max(0, videoTimeLeft - 1)

            let watchTime = videoDuration - videoTimeLeft
            reactionActive = watchTime >= 2
            if watchTime >= 7 { bankedDamage = 50 }
            else if watchTime >= 5 { bankedDamage = 30 }
            else if watchTime >= 2 { bankedDamage = 10 }
            else { bankedDamage = 0 }

            if videoTimeLeft <= 0 && currentVideoIndex < totalVideos - 1 {
                currentVideoIndex += 1
                applyBankedDamage()
                videoTimeLeft = videoDuration
            }
        }
    }

    private func simulateOpponentDamage() async {
        while true {
            try? await Task.sleep(for: .seconds(4))
            if Double.random(in: 0...1) > 0.6 {
                let dmg = Int.random(in: 20...60)
                withAnimation { yourHP = max(0, yourHP - dmg) }
                addPopup(dmg, isYou: true)
            }
        }
    }

    private func runFocusRecharge() async {
        while true {
            try? await Task.sleep(for: .seconds(5))
            focusMeter = min(10, focusMeter + 1)
        }
    }

    private func applyBankedDamage() {
        let final = Int(Double(bankedDamage) * multiplier)
        if final > 0 {
            withAnimation { opponentHP = max(0, opponentHP - final) }
            addPopup(final, isYou: false)
            comboMeter = min(5, comboMeter + 1)
            multiplier = min(3.0, multiplier + 0.2)
        }
        bankedDamage = 0
    }

    private func addPopup(_ damage: Int, isYou: Bool) {
        let entry = (id: UUID(), damage: damage, isYou: isYou)
        withAnimation { damagePopups.append(entry) }
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation { damagePopups.removeAll { $0.id == entry.id } }
        }
    }
}

// MARK: - Video Placeholder (fallback only)

struct VideoPlaceholderView: View {
    let videoNumber: Int
    let totalVideos: Int
    let sourceHint: String?
    let playbackURL: URL?

    @State private var player: AVPlayer?
    @State private var didEndObserver: NSObjectProtocol?

    var body: some View {
        ZStack {
            StripedBackground()
            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear { player.play() }
            }
            LinearGradient(
                colors: [Color(hex: "1a0a2e").opacity(0.6), Color(hex: "0f0520").opacity(0.4), Color(hex: "050509").opacity(0.6)],
                startPoint: .top, endPoint: .bottom
            )
            VStack(spacing: 8) {
                Text("LOADING REELS...")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                Text("VIDEO \(videoNumber) / \(totalVideos)")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .background(Color.black.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.2), lineWidth: 4))
        }
        .ignoresSafeArea()
        .onAppear { configurePlayerIfNeeded() }
        .onChange(of: playbackURL?.absoluteString) { _ in configurePlayerIfNeeded() }
    }

    private func configurePlayerIfNeeded() {
        guard let playbackURL else { player = nil; return }
        let item = AVPlayerItem(url: playbackURL)
        let avPlayer = AVPlayer(playerItem: item)
        avPlayer.isMuted = true
        player = avPlayer
        didEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
        ) { _ in
            avPlayer.seek(to: .zero)
            avPlayer.play()
        }
        avPlayer.play()
    }
}

// MARK: - Boost Card Mini

struct BoostCardMiniView: View {
    let name: String
    let focusCost: Int
    let cooldown: Int
    let available: Bool
    let canAfford: Bool
    let onTap: () -> Void

    private var usable: Bool { available && canAfford }

    var body: some View {
        Button(action: { if usable { onTap() } }) {
            ZStack {
                VStack(spacing: 0) {
                    ZStack(alignment: .topTrailing) {
                        Color.white.frame(height: 56)
                        BoostTypeIcon(iconType: iconType, size: 28, color: iconColor)
                        HStack(spacing: 2) {
                            Circle().fill(NeonTheme.cyan).frame(width: 6, height: 6)
                            Text("\(focusCost)")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(NeonTheme.cyan)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black, lineWidth: 1.5))
                        .padding(4)
                    }
                    Text(name.uppercased())
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(Color.white)
                }
                .background(Color(hex: "F5F5DC"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 4))
                .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 4)
                .opacity(usable ? 1 : 0.5)

                if cooldown > 0 {
                    RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.7))
                    Text("\(cooldown)s").font(.system(size: 20, weight: .black)).foregroundColor(.white)
                }
                if usable {
                    RoundedRectangle(cornerRadius: 10).fill(NeonTheme.green.opacity(0.2))
                }
            }
            .frame(width: 76, height: 100)
        }
        .buttonStyle(.plain)
    }

    private var iconType: String {
        switch name {
        case "Shield": return "shield"
        case "Double": return "blast"
        case "Freeze": return "freeze"
        case "Rage":   return "fire"
        default:       return "energy"
        }
    }

    private var iconColor: Color {
        switch name {
        case "Shield": return NeonTheme.cyan
        case "Double": return NeonTheme.yellow
        case "Freeze": return NeonTheme.cyan
        case "Rage":   return NeonTheme.pink
        default:       return NeonTheme.green
        }
    }
}
