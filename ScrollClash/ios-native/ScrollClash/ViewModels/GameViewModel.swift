import Foundation
import Combine
import os

@MainActor
final class GameViewModel: ObservableObject {
    private static let logger = Logger(subsystem: "com.scrollroyale.app", category: "GameViewModel")

    @Published var contentItems: [ContentItem] = []
    @Published var scrollOffset: Double = 0
    @Published var localScore: Double = 0
    @Published var currentVideoIndex: Int = 0
    @Published var videoPlaybackTime: Double = 0
    @Published var isLoading = true
    @Published var feedStatusMessage: String?

    private let match: Match
    private let currentUserId: String
    private let contentService: ContentServiceProtocol
    private let syncService: SyncServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var scrollThrottle: Date?
    private var previousScrollOffset: Double = 0
    private var previousScrollTime: Date = .distantPast
    private var telemetryBuffer: [TelemetryEvent] = []
    private var telemetryTimer: AnyCancellable?

    init(
        match: Match,
        currentUserId: String,
        contentService: ContentServiceProtocol = MockContentService.shared,
        syncService: SyncServiceProtocol = MockSyncService.shared
    ) {
        self.match = match
        self.currentUserId = currentUserId
        self.contentService = contentService
        self.syncService = syncService
    }

    var matchCode: String {
        match.matchCode ?? "------"
    }

    var matchStatusLabel: String {
        match.status.rawValue.replacingOccurrences(of: "_", with: " ").uppercased()
    }

    var matchDurationSeconds: Int {
        match.durationSec
    }

    var approximateElapsedSeconds: Double {
        let estimated = (Double(currentVideoIndex) * 10.0) + videoPlaybackTime
        return min(estimated, Double(match.durationSec))
    }

    var remainingSeconds: Int {
        max(0, match.durationSec - Int(approximateElapsedSeconds))
    }

    var timerProgress: Double {
        guard match.durationSec > 0 else { return 0 }
        return approximateElapsedSeconds / Double(match.durationSec)
    }

    func loadContent() {
        isLoading = true
        feedStatusMessage = nil
        contentService.fetchContentFeed(matchId: match.id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    Self.logger.error("Feed load failed for match \(self?.match.id ?? "unknown", privacy: .public): \(String(describing: error), privacy: .public)")
                    self?.feedStatusMessage = "No playable videos found for this match."
                }
            } receiveValue: { [weak self] items in
                self?.contentItems = items.sorted { $0.order < $1.order }
                if !(self?.contentItems.isEmpty ?? true) {
                    self?.isLoading = false
                }
                if items.isEmpty {
                    Self.logger.warning("Feed returned 0 playable items for match \(self?.match.id ?? "unknown", privacy: .public)")
                    self?.feedStatusMessage = "No playable videos found for this match."
                } else {
                    self?.feedStatusMessage = nil
                }
            }
            .store(in: &cancellables)
    }

    func handleScroll(offset: Double, videoIndex: Int, playbackTime: Double) {
        scrollOffset = offset
        currentVideoIndex = videoIndex
        videoPlaybackTime = playbackTime
        let now = Date()
        let velocity = calculateVelocity(newOffset: offset, at: now)
        let reelId = contentItems[safe: videoIndex]?.id

        // Throttle sync updates (~10 Hz)
        if let last = scrollThrottle, now.timeIntervalSince(last) < 0.1 {
            return
        }
        scrollThrottle = now

        let state = GameState(
            scrollOffset: offset,
            scrollVelocity: velocity,
            currentVideoIndex: videoIndex,
            videoPlaybackTime: playbackTime,
            lastUpdated: now,
            player1Score: nil,
            player2Score: nil
        )
        syncService.sendGameState(state, reelId: reelId)
        queueTelemetry(
            TelemetryEvent(
                reelId: reelId,
                eventType: .scroll,
                payload: [
                    "offset": offset,
                    "velocity": velocity,
                    "video_index": Double(videoIndex),
                    "playback_time": playbackTime
                ]
            )
        )
    }

    func startSync() {
        loadContent()
        syncService.connect(to: match.id, userId: currentUserId)
        startTelemetryFlushTimer()

        syncService.gameStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.applyRemoteState(state)
            }
            .store(in: &cancellables)

        syncService.scorePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                self?.localScore = snapshot.score
            }
            .store(in: &cancellables)
    }

    func stopSync() {
        syncService.disconnect()
        telemetryTimer?.cancel()
        telemetryTimer = nil
        cancellables.removeAll()
    }

    private func applyRemoteState(_ state: GameState) {
        // Optional: interpolate remote state for smooth opponent view
        // For now we could use this to show opponent position in UI
    }

    private func calculateVelocity(newOffset: Double, at currentTime: Date) -> Double {
        defer {
            previousScrollOffset = newOffset
            previousScrollTime = currentTime
        }
        guard previousScrollTime != .distantPast else {
            return 0
        }
        let deltaTime = currentTime.timeIntervalSince(previousScrollTime)
        guard deltaTime > 0 else { return 0 }
        return abs(newOffset - previousScrollOffset) / deltaTime
    }

    private func queueTelemetry(_ event: TelemetryEvent) {
        telemetryBuffer.append(event)
    }

    private func startTelemetryFlushTimer() {
        telemetryTimer = Timer.publish(every: 0.4, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.flushTelemetry()
            }
    }

    private func flushTelemetry() {
        guard !telemetryBuffer.isEmpty else { return }
        let events = telemetryBuffer
        telemetryBuffer.removeAll(keepingCapacity: true)
        syncService.sendTelemetry(events: events, matchId: match.id)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
