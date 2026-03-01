import Foundation
import Combine
import os

/// Protocol for realtime game synchronization and telemetry ingestion.
protocol SyncServiceProtocol {
    var gameStatePublisher: AnyPublisher<GameState, Never> { get }
    var scorePublisher: AnyPublisher<ScoreSnapshot, Never> { get }
    var opponentScorePublisher: AnyPublisher<ScoreSnapshot, Never> { get }
    func sendGameState(_ state: GameState, reelId: String?)
    func sendTelemetry(events: [TelemetryEvent], matchId: String) -> AnyPublisher<Void, Error>
    /// opponentUserId: the other player's userId — nil if unknown (e.g. demo/mock mode)
    func connect(to matchId: String, userId: String, opponentUserId: String?)
    func disconnect()
}

/// Mock implementation used when Supabase config is unavailable.
final class MockSyncService: SyncServiceProtocol {
    static let shared = MockSyncService()

    private let gameStateSubject = PassthroughSubject<GameState, Never>()
    private let scoreSubject = PassthroughSubject<ScoreSnapshot, Never>()
    private let opponentScoreSubject = PassthroughSubject<ScoreSnapshot, Never>()

    var gameStatePublisher: AnyPublisher<GameState, Never> {
        gameStateSubject.eraseToAnyPublisher()
    }
    var scorePublisher: AnyPublisher<ScoreSnapshot, Never> {
        scoreSubject.eraseToAnyPublisher()
    }
    var opponentScorePublisher: AnyPublisher<ScoreSnapshot, Never> {
        opponentScoreSubject.eraseToAnyPublisher()
    }

    private var timer: AnyCancellable?
    private var currentMatchId: String?
    private var currentUserId: String?

    private init() {}

    func connect(to matchId: String, userId: String, opponentUserId: String?) {
        currentMatchId = matchId
        currentUserId = userId
        // Simulate receiving updates from opponent
        timer = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                let state = GameState(
                    scrollOffset: Double.random(in: 0...500),
                    scrollVelocity: Double.random(in: 0...4),
                    currentVideoIndex: Int.random(in: 0...5),
                    videoPlaybackTime: Double.random(in: 0...30),
                    lastUpdated: Date(),
                    player1Score: nil,
                    player2Score: nil
                )
                self.gameStateSubject.send(state)
                let ownScore = ScoreSnapshot(
                    matchId: matchId,
                    userId: userId,
                    score: Double.random(in: 0...150),
                    metrics: ["likes": Double.random(in: 0...12)],
                    snapshotAt: Date()
                )
                self.scoreSubject.send(ownScore)
                let oppId = opponentUserId ?? "mock-opponent"
                let oppScore = ScoreSnapshot(
                    matchId: matchId,
                    userId: oppId,
                    score: Double.random(in: 0...150),
                    metrics: ["likes": Double.random(in: 0...12)],
                    snapshotAt: Date()
                )
                self.opponentScoreSubject.send(oppScore)
            }
    }

    func sendGameState(_ state: GameState, reelId: String?) {
        gameStateSubject.send(state)
    }

    func sendTelemetry(events: [TelemetryEvent], matchId: String) -> AnyPublisher<Void, Error> {
        Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func disconnect() {
        timer?.cancel()
        timer = nil
        currentMatchId = nil
        currentUserId = nil
    }
}

final class SupabaseSyncService: SyncServiceProtocol {
    private static let logger = Logger(subsystem: "com.scrollroyale.app", category: "SyncService")

    private let client: SupabaseClient
    private let authService: SupabaseAuthService
    private let cacheStore: SupabaseCacheStore

    private let gameStateSubject = PassthroughSubject<GameState, Never>()
    private let scoreSubject = PassthroughSubject<ScoreSnapshot, Never>()
    private let opponentScoreSubject = PassthroughSubject<ScoreSnapshot, Never>()

    private var scorePoller: AnyCancellable?
    /// Stores long-lived subscriptions that must complete fully (e.g. auth warm-up).
    private var sendCancellables = Set<AnyCancellable>()
    /// Single slot for game-state telemetry sends — assigning a new value cancels the previous
    /// in-flight request, preventing unbounded growth (scroll events are best-effort).
    private var lastSendCancellable: AnyCancellable?

    private var currentMatchId: String?
    private var currentUserId: String?
    private var currentOpponentUserId: String?
    private var connectedAt: Date?
    private var lastScorePollAt: Date = .distantPast
    private var scoreRequestInFlight = false
    private var opponentRequestInFlight = false

    var gameStatePublisher: AnyPublisher<GameState, Never> {
        gameStateSubject.eraseToAnyPublisher()
    }
    var scorePublisher: AnyPublisher<ScoreSnapshot, Never> {
        scoreSubject.eraseToAnyPublisher()
    }
    var opponentScorePublisher: AnyPublisher<ScoreSnapshot, Never> {
        opponentScoreSubject.eraseToAnyPublisher()
    }

    init(client: SupabaseClient, authService: SupabaseAuthService, cacheStore: SupabaseCacheStore = .shared) {
        self.client = client
        self.authService = authService
        self.cacheStore = cacheStore
    }

    func connect(to matchId: String, userId: String, opponentUserId: String?) {
        Self.logger.info("connect — matchId: \(matchId, privacy: .public) userId: \(userId, privacy: .public) opponentUserId: \(opponentUserId ?? "nil", privacy: .public)")
        currentMatchId = matchId
        currentUserId = userId
        currentOpponentUserId = opponentUserId
        connectedAt = Date()
        lastScorePollAt = .distantPast
        scoreRequestInFlight = false
        opponentRequestInFlight = false

        // Warm up auth — store cancellable so it isn't immediately cancelled.
        authService.ensureAuthenticated(client: client)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        Self.logger.debug("connect: auth warm-up finished OK")
                    case .failure(let e):
                        Self.logger.error("connect: auth warm-up FAILED: \(e.localizedDescription, privacy: .public)")
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &sendCancellables)

        if let cachedSnapshot = cacheStore.score(matchId: matchId, userId: userId) {
            Self.logger.debug("connect: serving cached own score \(cachedSnapshot.score, privacy: .public)")
            scoreSubject.send(cachedSnapshot)
        }

        // Adaptive polling — burst on connect (0.4 s), settle to 0.5 s after 5 s.
        scorePoller = Timer.publish(every: 0.35, on: .main, in: .common)
            .autoconnect()
            .flatMap { [weak self] _ -> AnyPublisher<Void, Never> in
                guard
                    let self,
                    let matchId = self.currentMatchId,
                    let userId = self.currentUserId
                else {
                    return Empty().eraseToAnyPublisher()
                }
                let now = Date()
                let elapsed = now.timeIntervalSince(self.connectedAt ?? now)
                let requiredInterval: TimeInterval = elapsed < 5 ? 0.4 : 0.5
                guard now.timeIntervalSince(self.lastScorePollAt) >= requiredInterval else {
                    return Empty().eraseToAnyPublisher()
                }
                self.lastScorePollAt = now

                return self.pollScores(matchId: matchId, userId: userId)
            }
            .sink { _ in }
    }

    /// Fires parallel requests for own score and (if available) opponent score.
    private func pollScores(matchId: String, userId: String) -> AnyPublisher<Void, Never> {
        guard !scoreRequestInFlight else {
            return Empty().eraseToAnyPublisher()
        }
        scoreRequestInFlight = true

        var publishers: [AnyPublisher<Void, Never>] = []

        // Own score — receive on main before handleEvents so flag resets happen on main.
        let ownPublisher = fetchLatestScore(matchId: matchId, userId: userId)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] snapshot in
                self?.cacheStore.setScore(snapshot)
                Self.logger.info("[score poll] OWN score=\(snapshot.score, privacy: .public) snapshotAt=\(snapshot.snapshotAt, privacy: .public)")
            }, receiveCompletion: { [weak self] completion in
                self?.scoreRequestInFlight = false
                if case .failure(let e) = completion {
                    Self.logger.error("[score poll] FAILED (own) — \(e.localizedDescription, privacy: .public)")
                }
            })
            .replaceError(with: cacheStore.score(matchId: matchId, userId: userId)
                ?? ScoreSnapshot(matchId: matchId, userId: userId, score: 0, metrics: [:], snapshotAt: Date()))
            .map { [weak self] snapshot -> Void in
                self?.scoreSubject.send(snapshot)
            }
            .eraseToAnyPublisher()

        publishers.append(ownPublisher)

        // Opponent score — only if we know their userId and not already in flight
        if let opponentId = currentOpponentUserId, !opponentId.isEmpty, !opponentRequestInFlight {
            opponentRequestInFlight = true
            // Receive on main before handleEvents so flag reset is thread-safe.
            let oppPublisher = fetchLatestScore(matchId: matchId, userId: opponentId)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { snapshot in
                    Self.logger.info("[score poll] OPPONENT score=\(snapshot.score, privacy: .public) snapshotAt=\(snapshot.snapshotAt, privacy: .public)")
                }, receiveCompletion: { [weak self] completion in
                    self?.opponentRequestInFlight = false
                    if case .failure(let e) = completion {
                        Self.logger.error("[score poll] FAILED (opponent) — \(e.localizedDescription, privacy: .public)")
                    }
                })
                .replaceError(with: ScoreSnapshot(matchId: matchId, userId: opponentId, score: 0, metrics: [:], snapshotAt: Date()))
                .map { [weak self] snapshot -> Void in
                    self?.opponentScoreSubject.send(snapshot)
                    // Also publish both scores via gameStatePublisher so consumers that
                    // only watch gameStatePublisher see opponent state updates.
                    if let ownCached = self?.cacheStore.score(matchId: matchId, userId: userId) {
                        let state = GameState(
                            scrollOffset: 0,
                            scrollVelocity: 0,
                            currentVideoIndex: 0,
                            videoPlaybackTime: 0,
                            lastUpdated: Date(),
                            player1Score: ownCached.score,
                            player2Score: snapshot.score
                        )
                        self?.gameStateSubject.send(state)
                    }
                }
                .eraseToAnyPublisher()
            publishers.append(oppPublisher)
        }

        return Publishers.MergeMany(publishers)
            .collect()
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func sendGameState(_ state: GameState, reelId: String?) {
        guard let matchId = currentMatchId else {
            Self.logger.warning("sendGameState: no currentMatchId, dropping event")
            return
        }
        let event = TelemetryEvent(
            reelId: reelId,
            eventType: .scroll,
            payload: [
                "offset": state.scrollOffset,
                "video_index": Double(state.currentVideoIndex),
                "playback_time": state.videoPlaybackTime,
                "velocity": state.scrollVelocity
            ]
        )
        // Replace the previous slot — scroll telemetry is best-effort, so superseding
        // an in-flight request with the latest state is acceptable and prevents unbounded
        // Set growth (up to 900+ entries over a 90-second match at 10 Hz send rate).
        lastSendCancellable = sendTelemetry(events: [event], matchId: matchId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let e) = completion {
                        Self.logger.error("sendGameState telemetry FAILED: \(e.localizedDescription, privacy: .public)")
                    }
                },
                receiveValue: { _ in }
            )
    }

    func sendTelemetry(events: [TelemetryEvent], matchId: String) -> AnyPublisher<Void, Error> {
        Self.logger.debug("sendTelemetry — \(events.count, privacy: .public) event(s) for matchId: \(matchId, privacy: .public)")
        let payload = events.map { $0.requestBody }
        return authService.ensureAuthenticated(client: client)
            .flatMap { [client] _ in
                client.rpc(
                    function: "ingest_telemetry_batch",
                    body: ["p_match_id": matchId, "p_events": payload],
                    decodeAs: Int.self
                )
            }
            .map { (_: Int) in () }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let e) = completion {
                    Self.logger.error("ingest_telemetry_batch FAILED: \(e.localizedDescription, privacy: .public)")
                }
            })
            .eraseToAnyPublisher()
    }

    func disconnect() {
        Self.logger.info("disconnect — matchId: \(self.currentMatchId ?? "nil", privacy: .public)")
        scorePoller?.cancel()
        scorePoller = nil
        lastSendCancellable = nil
        sendCancellables.removeAll()
        currentMatchId = nil
        currentUserId = nil
        currentOpponentUserId = nil
        connectedAt = nil
        scoreRequestInFlight = false
        opponentRequestInFlight = false
    }

    private func fetchLatestScore(matchId: String, userId: String) -> AnyPublisher<ScoreSnapshot, Error> {
        authService.ensureAuthenticated(client: client)
            .flatMap { [client] _ in
                // latest_score_snapshot returns SETOF (an array) from PostgREST;
                // use rpcFirstRow to unwrap the first element automatically.
                client.rpcFirstRow(
                    function: "latest_score_snapshot",
                    body: ["p_match_id": matchId, "p_user_id": userId],
                    decodeAs: SupabaseScoreSnapshotDTO.self,
                    retryPolicy: .reads,
                    requestLabel: "latest_score_snapshot"
                )
            }
            .map { dto -> ScoreSnapshot in
                let snap = dto.toModel(matchId: matchId, userId: userId)
                Self.logger.info("[score] decoded score=\(snap.score, privacy: .public) for userId=\(userId, privacy: .public) matchId=\(matchId, privacy: .public)")
                return snap
            }
            .eraseToAnyPublisher()
    }
}

private struct SupabaseScoreSnapshotDTO: Codable {
    let score: Double
    let metrics: [String: Double]
    let snapshotAt: Date

    enum CodingKeys: String, CodingKey {
        case score
        case metrics
        case snapshotAt = "snapshot_at"
    }

    func toModel(matchId: String, userId: String) -> ScoreSnapshot {
        ScoreSnapshot(
            matchId: matchId,
            userId: userId,
            score: score,
            metrics: metrics,
            snapshotAt: snapshotAt
        )
    }
}
