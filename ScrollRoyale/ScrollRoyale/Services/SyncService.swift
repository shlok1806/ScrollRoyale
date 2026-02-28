import Foundation
import Combine

/// Protocol for realtime game synchronization and telemetry ingestion.
protocol SyncServiceProtocol {
    var gameStatePublisher: AnyPublisher<GameState, Never> { get }
    var scorePublisher: AnyPublisher<ScoreSnapshot, Never> { get }
    func sendGameState(_ state: GameState, reelId: String?)
    func sendTelemetry(events: [TelemetryEvent], matchId: String) -> AnyPublisher<Void, Error>
    func connect(to matchId: String, userId: String)
    func disconnect()
}

/// Mock implementation used when Supabase config is unavailable.
final class MockSyncService: SyncServiceProtocol {
    static let shared = MockSyncService()

    private let gameStateSubject = PassthroughSubject<GameState, Never>()
    private let scoreSubject = PassthroughSubject<ScoreSnapshot, Never>()
    var gameStatePublisher: AnyPublisher<GameState, Never> {
        gameStateSubject.eraseToAnyPublisher()
    }
    var scorePublisher: AnyPublisher<ScoreSnapshot, Never> {
        scoreSubject.eraseToAnyPublisher()
    }

    private var timer: AnyCancellable?
    private var currentMatchId: String?
    private var currentUserId: String?

    private init() {}

    func connect(to matchId: String, userId: String) {
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
                    player1Score: 0,
                    player2Score: 0
                )
                self.gameStateSubject.send(state)
                self.scoreSubject.send(
                    ScoreSnapshot(
                        matchId: matchId,
                        userId: userId,
                        score: Double.random(in: 0...150),
                        metrics: ["likes": Double.random(in: 0...12)],
                        snapshotAt: Date()
                    )
                )
            }
    }

    func sendGameState(_ state: GameState, reelId: String?) {
        // In real impl: send to backend/WebSocket
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
    private let client: SupabaseClient
    private let authService: SupabaseAuthService
    private let gameStateSubject = PassthroughSubject<GameState, Never>()
    private let scoreSubject = PassthroughSubject<ScoreSnapshot, Never>()
    private var scorePoller: AnyCancellable?
    private var currentMatchId: String?
    private var currentUserId: String?

    var gameStatePublisher: AnyPublisher<GameState, Never> {
        gameStateSubject.eraseToAnyPublisher()
    }

    var scorePublisher: AnyPublisher<ScoreSnapshot, Never> {
        scoreSubject.eraseToAnyPublisher()
    }

    init(client: SupabaseClient, authService: SupabaseAuthService) {
        self.client = client
        self.authService = authService
    }

    func connect(to matchId: String, userId: String) {
        currentMatchId = matchId
        currentUserId = userId
        _ = authService.ensureAuthenticated(client: client)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })

        // Until websocket protocol is wired, use a lightweight polling fallback.
        scorePoller = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .flatMap { [weak self] _ -> AnyPublisher<ScoreSnapshot, Never> in
                guard
                    let self,
                    let matchId = self.currentMatchId,
                    let userId = self.currentUserId
                else {
                    return Empty().eraseToAnyPublisher()
                }
                return self.fetchLatestScore(matchId: matchId, userId: userId)
                    .replaceError(with: ScoreSnapshot(matchId: matchId, userId: userId, score: 0, metrics: [:], snapshotAt: Date()))
                    .eraseToAnyPublisher()
            }
            .sink { [weak self] snapshot in
                self?.scoreSubject.send(snapshot)
            }
    }

    func sendGameState(_ state: GameState, reelId: String?) {
        guard let matchId = currentMatchId else { return }
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
        _ = sendTelemetry(events: [event], matchId: matchId).sink(receiveCompletion: { _ in }, receiveValue: { _ in })
    }

    func sendTelemetry(events: [TelemetryEvent], matchId: String) -> AnyPublisher<Void, Error> {
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
            .eraseToAnyPublisher()
    }

    func disconnect() {
        scorePoller?.cancel()
        scorePoller = nil
        currentMatchId = nil
        currentUserId = nil
    }

    private func fetchLatestScore(matchId: String, userId: String) -> AnyPublisher<ScoreSnapshot, Error> {
        authService.ensureAuthenticated(client: client)
            .flatMap { [client] _ in
                client.rpc(
                    function: "latest_score_snapshot",
                    body: ["p_match_id": matchId, "p_user_id": userId],
                    decodeAs: SupabaseScoreSnapshotDTO.self
                )
            }
            .map { $0.toModel(matchId: matchId, userId: userId) }
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
