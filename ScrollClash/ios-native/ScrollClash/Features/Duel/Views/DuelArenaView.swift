import SwiftUI
import AVKit

struct DuelArenaView: View {
    @EnvironmentObject private var appState: AppState
    let opponent: DuelOpponent
    let matchId: String?
    let onDismiss: () -> Void

    private let matchDuration = 90
    private let videoDuration = 10

    @State private var timeLeft = 90
    @State private var videoTimeLeft = 10
    @State private var currentVideoIndex = 0
    @State private var yourHP = 1000
    @State private var opponentHP = 1000
    @State private var bankedDamage = 0
    @State private var comboMeter = 2
    @State private var multiplier = 1.0
    @State private var focusMeter = 6
    @State private var reactionActive = false
    @State private var damagePopups: [(id: UUID, damage: Int, isYou: Bool)] = []
    @State private var showResult = false
    @State private var feedItems: [MatchFeedItem] = []
    @State private var liveScore: Double = 0
    @State private var telemetryBuffer: [TelemetryEvent] = []
    private let boostDeck = [
        (id: 1, name: "Shield", focusCost: 3, cooldown: 0, available: true),
        (id: 2, name: "Double", focusCost: 5, cooldown: 3, available: false),
        (id: 3, name: "Freeze", focusCost: 4, cooldown: 0, available: true),
        (id: 4, name: "Rage",   focusCost: 6, cooldown: 5, available: false),
    ]

    private var timerProgress: Double { Double(timeLeft) / Double(matchDuration) }
    private var yourHPPercent:   Double { Double(yourHP) / 1000 }
    private var opponentHPPercent: Double { Double(opponentHP) / 1000 }
    private var totalVideos: Int { max(1, feedItems.isEmpty ? 9 : feedItems.count) }
    private var currentFeedItem: MatchFeedItem? {
        guard currentVideoIndex >= 0, currentVideoIndex < feedItems.count else { return nil }
        return feedItems[currentVideoIndex]
    }
    private var currentPlaybackURL: URL? {
        resolvedVideoURL(from: currentFeedItem?.signedVideoURL)
    }

    var body: some View {
        // Use a plain ZStack — DuelArena is already inside a fullScreenCover from PreDuelView.
        // Avoid nesting another fullScreenCover (causes orientation-transaction warnings).
        // Instead, slide DuelResultView in as a ZStack overlay.
        GeometryReader { geo in
            ZStack {
                // Video background
                VideoPlaceholderView(
                    videoNumber: currentVideoIndex + 1,
                    totalVideos: totalVideos,
                    sourceHint: currentFeedItem?.signedVideoURL,
                    playbackURL: currentPlaybackURL
                )
                    .gesture(swipeGesture)

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

                // HUD — top safe-area padding keeps content below status bar
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

                // Result overlay — replaces nested fullScreenCover to avoid orientation warnings
                if showResult {
                    DuelResultView(opponent: opponent, onDismiss: { showResult = false; onDismiss() })
                        .transition(.move(edge: .bottom))
                        .zIndex(10)
                }
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .task { await runMatchTimer() }
        .task { await runVideoTimer() }
        .task { await simulateOpponentDamage() }
        .task { await runFocusRecharge() }
        .task { await loadFeedIfAvailable() }
        .task { await runScorePolling() }
        .task { await flushTelemetryLoop() }
    }

    // MARK: Top HUD

    private var topHUD: some View {
        VStack(spacing: 10) {
            // Forfeit + players
            HStack(alignment: .top) {
                // You
                HStack(spacing: 8) {
                    playerAvatar(brain: appState.customization, rotLevel: 25, bg: NeonTheme.purpleDark)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("YOU").font(.system(size: 13, weight: .black)).foregroundColor(.white)
                            .shadow(color: .black.opacity(0.8), radius: 0, x: 2, y: 2)
                        Text("#42").font(.system(size: 11, weight: .bold)).foregroundColor(NeonTheme.green)
                    }
                }

                Spacer()

                // Forfeit
                Button(action: { withAnimation(.easeInOut(duration: 0.3)) { showResult = true } }) {
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

                // Opponent
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

            // Timer ring + HP bar
            VStack(spacing: 6) {
                timerRing

                if let matchId {
                    HStack {
                        Text("MATCH \(matchId.prefix(6).uppercased())")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text("SCORE \(Int(liveScore))")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(NeonTheme.yellow)
                    }
                }

                // HP bar
                VStack(spacing: 4) {
                    HStack {
                        Text("\(yourHP)")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(NeonTheme.purpleLight)
                        Spacer()
                        Text("\(opponentHP)")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(NeonTheme.green)
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

    // MARK: Reaction Button

    private var reactionButton: some View {
        Button {
            // Reaction tap action
        } label: {
            ZStack {
                Circle()
                    .fill(reactionActive ? NeonTheme.pink : Color.white.opacity(0.2))
                    .frame(width: 52, height: 52)
                    .overlay(Circle().stroke(Color.black, lineWidth: 4))
                    .shadow(color: reactionActive ? NeonTheme.pink.opacity(0.8) : .clear, radius: 12)
                    .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 4)
                Image(systemName: "hand.thumbsup.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .disabled(!reactionActive)
    }

    private var quizIndicator: some View {
        ZStack {
            Circle()
                .fill(NeonTheme.yellow.opacity(0.8))
                .frame(width: 52, height: 52)
                .overlay(Circle().stroke(Color.black, lineWidth: 4))
                .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 4)
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.black)
        }
    }

    private var discoveryProgress: some View {
        VStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(i < 2 ? NeonTheme.green : Color.white.opacity(0.2))
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(Color.black, lineWidth: 1))
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 3))
        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 3)
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
                        queueTelemetry(eventType: "boost", payload: [
                            "focus_spent": Double(boost.focusCost),
                            "video_index": Double(currentVideoIndex)
                        ])
                    }
                }
            }
        }
    }

    // MARK: Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded { value in
                if value.translation.height < -50 {
                    swipe(up: true)
                } else if value.translation.height > 50 {
                    swipe(up: false)
                }
            }
    }

    private func swipe(up: Bool) {
        if up && currentVideoIndex < totalVideos - 1 {
            currentVideoIndex += 1
            videoTimeLeft = videoDuration
            applyBankedDamage()
            queueTelemetry(eventType: "scroll", payload: [
                "velocity": 1.0,
                "video_index": Double(currentVideoIndex),
                "playback_time": Double(videoDuration - videoTimeLeft)
            ])
        } else if !up && currentVideoIndex > 0 {
            currentVideoIndex -= 1
            videoTimeLeft = videoDuration
            bankedDamage = 0
            queueTelemetry(eventType: "scroll_back", payload: [
                "velocity": -1.0,
                "video_index": Double(currentVideoIndex),
                "playback_time": Double(videoDuration - videoTimeLeft)
            ])
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

    // MARK: Timers

    private func runMatchTimer() async {
        while timeLeft > 0 {
            try? await Task.sleep(for: .seconds(1))
            timeLeft = max(0, timeLeft - 1)
        }
        try? await Task.sleep(for: .milliseconds(500))
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

    private func loadFeedIfAvailable() async {
        guard let matchId else { return }
        let items = await appState.fetchFeed(matchId: matchId)
        await MainActor.run {
            feedItems = items
            if currentVideoIndex >= feedItems.count {
                currentVideoIndex = max(0, feedItems.count - 1)
            }
        }
    }

    private func runScorePolling() async {
        guard let matchId else { return }
        while true {
            if let snapshot = await appState.fetchLatestScore(matchId: matchId) {
                await MainActor.run {
                    liveScore = snapshot.score
                }
            }
            try? await Task.sleep(for: .seconds(1))
        }
    }

    private func queueTelemetry(eventType: String, payload: [String: Double]) {
        guard let item = currentFeedItem else { return }
        telemetryBuffer.append(
            TelemetryEvent(
                reelID: item.reelID,
                eventType: eventType,
                clientEventID: UUID().uuidString,
                occurredAt: ISO8601DateFormatter().string(from: Date()),
                payload: payload
            )
        )
    }

    private func flushTelemetryLoop() async {
        guard let matchId else { return }
        while true {
            try? await Task.sleep(for: .milliseconds(400))
            if telemetryBuffer.isEmpty { continue }
            let batch = telemetryBuffer
            telemetryBuffer.removeAll()
            await appState.ingestTelemetry(matchId: matchId, events: batch)
        }
    }

    private func resolvedVideoURL(from raw: String?) -> URL? {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            return URL(string: trimmed)
        }

        guard let base = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              !base.isEmpty else {
            return nil
        }

        let path: String
        if trimmed.contains("/") {
            path = trimmed
        } else {
            path = "reels/\(trimmed)"
        }

        let encodedPath = path
            .split(separator: "/")
            .map { String($0).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String($0) }
            .joined(separator: "/")
        return URL(string: "\(base)/storage/v1/object/public/\(encodedPath)")
    }
}

// MARK: - Video Placeholder

struct VideoPlaceholderView: View {
    let videoNumber: Int
    let totalVideos: Int
    let sourceHint: String?
    let playbackURL: URL?

    @State private var player: AVPlayer?
    @State private var didEndObserver: NSObjectProtocol?
    @State private var didFailObserver: NSObjectProtocol?

    var body: some View {
        ZStack {
            StripedBackground()
            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        player.play()
                    }
            }
            LinearGradient(
                colors: [Color(hex: "1a0a2e").opacity(0.6), Color(hex: "0f0520").opacity(0.4), Color(hex: "050509").opacity(0.6)],
                startPoint: .top, endPoint: .bottom
            )

            VStack(spacing: 8) {
                Text(player == nil ? "MP4 PLACEHOLDER" : "LIVE VIDEO")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                Text("VIDEO \(videoNumber) / \(totalVideos)")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(.white)
                if let sourceHint, !sourceHint.isEmpty {
                    Text(sourceHint)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
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
        .onDisappear { cleanupPlayerObservers() }
    }

    private func configurePlayerIfNeeded() {
        cleanupPlayerObservers()
        guard let playbackURL else {
            player = nil
            return
        }

        let item = AVPlayerItem(url: playbackURL)
        let avPlayer = AVPlayer(playerItem: item)
        avPlayer.isMuted = true
        player = avPlayer

        didEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { _ in
            avPlayer.seek(to: .zero)
            avPlayer.play()
        }

        didFailObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { notification in
            print("Video playback failed for URL \(playbackURL.absoluteString): \(notification.userInfo ?? [:])")
        }

        avPlayer.play()
    }

    private func cleanupPlayerObservers() {
        if let didEndObserver {
            NotificationCenter.default.removeObserver(didEndObserver)
            self.didEndObserver = nil
        }
        if let didFailObserver {
            NotificationCenter.default.removeObserver(didFailObserver)
            self.didFailObserver = nil
        }
        player?.pause()
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
                    // Icon area
                    ZStack(alignment: .topTrailing) {
                        Color.white
                            .frame(height: 56)

                        BoostTypeIcon(iconType: iconType, size: 28, color: iconColor)

                        // Focus cost badge
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

                    // Name
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

                // Cooldown overlay
                if cooldown > 0 {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.7))
                    Text("\(cooldown)s")
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(.white)
                }

                // Active glow
                if usable {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(NeonTheme.green.opacity(0.2))
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
