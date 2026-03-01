import SwiftUI
import Combine
import Foundation

// MARK: - Brain Customization

struct BrainCustomization {
    var hat: String = "crown"
    var glasses: String = "sunglasses"
    var expression: String = "happy"
    var skin: String = "classic"
    var effect: String = "purple-aura"
    var accessory: String = "spoon"
}

// MARK: - Matchmaking Service

struct MatchmakingResult {
    let opponent: DuelOpponent
    let matchDuration: Int
    let trophyDelta: Int
    let boostSlots: Int
    let matchId: String?
}

struct QuickMatchHostSession {
    let matchId: String
    let matchCode: String
    let matchDuration: Int
}

struct MatchFeedItem: Identifiable {
    let reelID: String
    let ordinal: Int
    let durationMs: Int
    let signedVideoURL: String

    var id: String { "\(reelID)-\(ordinal)" }
}

struct ScoreSnapshot {
    let score: Double
    let metrics: [String: Double]
    let snapshotAt: Date?
}

struct TelemetryEvent: Encodable {
    let reelID: String
    let eventType: String
    let clientEventID: String
    let occurredAt: String
    let payload: [String: Double]

    enum CodingKeys: String, CodingKey {
        case reelID = "reel_id"
        case eventType = "event_type"
        case clientEventID = "client_event_id"
        case occurredAt = "occurred_at"
        case payload
    }
}

struct LeaderboardSummaryEntry: Identifiable {
    let userID: String
    let displayName: String
    let wins: Int
    let averageScore: Double

    var id: String { userID }
}

struct ProfileSummary {
    let userID: String
    let displayName: String
    let matchesPlayed: Int
    let wins: Int
    let bestScore: Double
}

protocol MatchmakingServicing {
    func findMatch(playerName: String, timeout: TimeInterval) async throws -> MatchmakingResult
}

enum MatchmakingError: Error {
    case notConfigured
    case invalidResponse
    case noMatchId
    case timeout
    case serverResponse(String)
}

extension MatchmakingError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase is not configured in this build."
        case .invalidResponse:
            return "Supabase returned an unexpected response. If RPC signatures changed, reload the Supabase schema cache."
        case .noMatchId:
            return "Match was created but no match ID was returned."
        case .timeout:
            return "No opponent joined within the timeout."
        case .serverResponse(let rawMessage):
            let lower = rawMessage.lowercased()
            if lower.contains("pgrst202")
                || lower.contains("could not find the function public.create_match_with_code")
                || lower.contains("schema cache")
            {
                return "Supabase RPC schema looks stale. Apply latest SQL migrations, then run: NOTIFY pgrst, 'reload schema';"
            }
            if lower.contains("invalid or unavailable match code")
                || (lower.contains("match code") && lower.contains("invalid"))
                || (lower.contains("match code") && lower.contains("unavailable"))
            {
                return "Match code is invalid, expired, or unavailable."
            }
            return rawMessage
        }
    }
}

// MARK: - Supabase Config

private struct SupabaseConfig {
    let baseURL: URL
    let anonKey: String

    static func fromInfoPlist() -> SupabaseConfig? {
        let rawURL = (Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let rawKey = (Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let urlTrimmed = rawURL
        let keyTrimmed = rawKey
        guard
            !urlTrimmed.isEmpty,
            !keyTrimmed.isEmpty,
            !urlTrimmed.contains("REPLACE_WITH_SUPABASE_URL"),
            !keyTrimmed.contains("REPLACE_WITH_SUPABASE_ANON_KEY"),
            let url = URL(string: urlTrimmed)
        else {
            return nil
        }
        return SupabaseConfig(baseURL: url, anonKey: keyTrimmed)
    }
}

// MARK: - Supabase Auth

private actor SupabaseAuthService {
    struct Session {
        let accessToken: String
        let refreshToken: String
        let userId: String
        let expiresAt: Date
    }

    private let config: SupabaseConfig
    private let session: URLSession
    private var currentSession: Session?
    private var inFlightAuthentication: Task<Session, Error>?

    init(config: SupabaseConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    func ensureAuthenticated(displayName: String) async throws -> Session {
        if let currentSession, !isExpiringSoon(currentSession) {
            return currentSession
        }
        if let inFlightAuthentication {
            return try await inFlightAuthentication.value
        }

        let task = Task<Session, Error> {
            if let existing = currentSession, let refreshed = try await refresh(session: existing) {
                currentSession = refreshed
                return refreshed
            }
            let signedIn = try await signInAnonymously(displayName: displayName)
            currentSession = signedIn
            return signedIn
        }
        inFlightAuthentication = task
        defer { inFlightAuthentication = nil }
        return try await task.value
    }

    func currentUserId(displayName: String) async throws -> String {
        let session = try await ensureAuthenticated(displayName: displayName)
        return session.userId
    }

    func accessToken(displayName: String) async throws -> String {
        let session = try await ensureAuthenticated(displayName: displayName)
        return session.accessToken
    }

    private func isExpiringSoon(_ session: Session) -> Bool {
        Date().addingTimeInterval(90) >= session.expiresAt
    }

    private func signInAnonymously(displayName: String) async throws -> Session {
        var request = URLRequest(url: config.baseURL.appending(path: "/auth/v1/signup"))
        request.httpMethod = "POST"
        request.setValue(config.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(AnonymousSignupBody(data: .init(displayName: displayName)))

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw MatchmakingError.invalidResponse
        }
        let decoded = try JSONDecoder().decode(AnonymousSignupResponse.self, from: data)
        return decoded.asSession()
    }

    private func refresh(session existing: Session) async throws -> Session? {
        var request = URLRequest(url: config.baseURL.appending(path: "/auth/v1/token?grant_type=refresh_token"))
        request.httpMethod = "POST"
        request.setValue(config.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(RefreshBody(refreshToken: existing.refreshToken))

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { return nil }
        guard (200...299).contains(http.statusCode) else { return nil }

        let decoded = try JSONDecoder().decode(AnonymousSignupResponse.self, from: data)
        return decoded.asSession()
    }
}

private struct AnonymousSignupBody: Encodable {
    struct SignupData: Encodable {
        let displayName: String
        enum CodingKeys: String, CodingKey {
            case displayName = "display_name"
        }
    }
    let data: SignupData
}

private struct RefreshBody: Encodable {
    let refreshToken: String
    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

private struct AnonymousSignupResponse: Decodable {
    struct User: Decodable { let id: String }
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int?
    let expiresAt: TimeInterval?
    let user: User

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case expiresAt = "expires_at"
        case user
    }

    func asSession() -> SupabaseAuthService.Session {
        let expiresDate: Date
        if let expiresAt {
            expiresDate = Date(timeIntervalSince1970: expiresAt)
        } else {
            expiresDate = Date().addingTimeInterval(TimeInterval(expiresIn ?? 3600))
        }
        return .init(
            accessToken: accessToken,
            refreshToken: refreshToken,
            userId: user.id,
            expiresAt: expiresDate
        )
    }
}

// MARK: - Supabase RPC Client

private enum SupabaseRetryPolicy {
    case none
    case reads
}

private final class SupabaseClient {
    private let config: SupabaseConfig
    private let session: URLSession

    init(config: SupabaseConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    func rpc<T: Decodable, B: Encodable>(
        _ function: String,
        body: B,
        accessToken: String,
        decodeAs: T.Type,
        retryPolicy: SupabaseRetryPolicy = .none,
        requestLabel: String? = nil
    ) async throws -> T {
        let maxAttempts = retryPolicy == .reads ? 3 : 1
        var attempt = 0
        var lastError: Error?

        while attempt < maxAttempts {
            attempt += 1
            let start = Date()
            do {
                var request = URLRequest(url: config.baseURL.appending(path: "/rest/v1/rpc/\(function)"))
                request.httpMethod = "POST"
                request.timeoutInterval = 15
                request.setValue(config.anonKey, forHTTPHeaderField: "apikey")
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder().encode(body)

                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else { throw MatchmakingError.invalidResponse }
                guard (200...299).contains(http.statusCode) else {
                    let body = String(data: data, encoding: .utf8) ?? ""
                    if !body.isEmpty {
                        print("[SupabaseRPC] \(requestLabel ?? function) status \(http.statusCode) body: \(body)")
                    }
                    if shouldRetry(statusCode: http.statusCode), attempt < maxAttempts {
                        try await Task.sleep(for: .milliseconds(UInt64(350 * attempt)))
                        continue
                    }
                    throw MatchmakingError.serverResponse(body.isEmpty ? "Supabase request failed with status \(http.statusCode)." : body)
                }

                let decoder = JSONDecoder()
                let elapsed = Date().timeIntervalSince(start) * 1000
                print("[SupabaseRPC] \(requestLabel ?? function) success in \(Int(elapsed))ms attempt \(attempt)")
                return try decoder.decode(T.self, from: data)
            } catch {
                lastError = error
                let elapsed = Date().timeIntervalSince(start) * 1000
                print("[SupabaseRPC] \(requestLabel ?? function) failed in \(Int(elapsed))ms attempt \(attempt): \(error)")
                if attempt < maxAttempts {
                    try? await Task.sleep(for: .milliseconds(UInt64(350 * attempt)))
                    continue
                }
            }
        }

        throw lastError ?? MatchmakingError.invalidResponse
    }

    func rpcVoid<B: Encodable>(
        _ function: String,
        body: B,
        accessToken: String,
        retryPolicy: SupabaseRetryPolicy = .none,
        requestLabel: String? = nil
    ) async throws {
        let maxAttempts = retryPolicy == .reads ? 3 : 1
        var attempt = 0
        while attempt < maxAttempts {
            attempt += 1
            do {
                var request = URLRequest(url: config.baseURL.appending(path: "/rest/v1/rpc/\(function)"))
                request.httpMethod = "POST"
                request.timeoutInterval = 15
                request.setValue(config.anonKey, forHTTPHeaderField: "apikey")
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder().encode(body)
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    let bodyText = String(data: data, encoding: .utf8) ?? ""
                    throw MatchmakingError.serverResponse(bodyText.isEmpty ? "Supabase request failed." : bodyText)
                }
                return
            } catch {
                if attempt < maxAttempts {
                    try? await Task.sleep(for: .milliseconds(UInt64(350 * attempt)))
                    continue
                }
                throw error
            }
        }
    }

    private func shouldRetry(statusCode: Int) -> Bool {
        [408, 429, 500, 502, 503, 504].contains(statusCode)
    }
}

// MARK: - Supabase Matchmaking

/// Supabase-backed matchmaking using project-specific RPC contracts.
private final class SupabaseMatchmakingService: MatchmakingServicing {
    private let auth: SupabaseAuthService
    private let client: SupabaseClient
    private let displayNamePrefix = "Player-"

    init(config: SupabaseConfig) {
        self.auth = SupabaseAuthService(config: config)
        self.client = SupabaseClient(config: config)
    }

    func findMatch(playerName: String, timeout: TimeInterval) async throws -> MatchmakingResult {
        let displayName = playerName.hasPrefix(displayNamePrefix) ? playerName : "\(displayNamePrefix)\(playerName)"
        let session = try await auth.ensureAuthenticated(displayName: displayName)

        // Ensure profile exists for this user in backend profile tables.
        _ = try? await client.rpc(
            "ensure_user_profile",
            body: EnsureUserProfileBody(pDisplayName: displayName),
            accessToken: session.accessToken,
            decodeAs: String.self,
            requestLabel: "ensure_user_profile"
        )

        let created: SupabaseMatchRow = try await client.rpc(
            "create_match_with_code",
            body: CreateMatchBody(pDurationSec: 90, pReelSetId: nil, pIdempotencyKey: UUID().uuidString),
            accessToken: session.accessToken,
            decodeAs: SupabaseMatchRow.self,
            requestLabel: "create_match_with_code"
        )

        // Contract for get_match shape may evolve. We try polling briefly,
        // but fall back to deterministic opponent data to keep UX responsive.
        if let matchId = created.id {
            let pollUntil = Date().addingTimeInterval(timeout)
            while Date() < pollUntil {
                let fetched: SupabaseMatchRow = try await client.rpc(
                    "get_match",
                    body: GetMatchBody(pMatchId: matchId),
                    accessToken: session.accessToken,
                    decodeAs: SupabaseMatchRow.self,
                    retryPolicy: .reads,
                    requestLabel: "get_match"
                )
                if fetched.hasOpponentJoined {
                    let matchedName = fetched.opponentDisplayName ?? MockData.defaultOpponent.name
                    return MatchmakingResult(
                        opponent: DuelOpponent(
                            name: matchedName,
                            rank: MockData.defaultOpponent.rank,
                            rotLevel: MockData.defaultOpponent.rotLevel,
                            wins: MockData.defaultOpponent.wins
                        ),
                        matchDuration: fetched.durationSec ?? 90,
                        trophyDelta: 25,
                        boostSlots: 4,
                        matchId: matchId
                    )
                }
                try await Task.sleep(for: .seconds(1))
            }

            // Timeout fallback while preserving the real match id.
            return MatchmakingResult(
                opponent: MockData.defaultOpponent,
                matchDuration: created.durationSec ?? 90,
                trophyDelta: 25,
                boostSlots: 4,
                matchId: matchId
            )
        }

        throw MatchmakingError.noMatchId
    }

    func createQuickMatchHost(playerName: String) async throws -> QuickMatchHostSession {
        let displayName = playerName.hasPrefix(displayNamePrefix) ? playerName : "\(displayNamePrefix)\(playerName)"
        let session = try await auth.ensureAuthenticated(displayName: displayName)
        _ = try? await client.rpc(
            "ensure_user_profile",
            body: EnsureUserProfileBody(pDisplayName: displayName),
            accessToken: session.accessToken,
            decodeAs: String.self,
            requestLabel: "ensure_user_profile"
        )

        let created: SupabaseMatchRow = try await client.rpc(
            "create_match_with_code",
            body: CreateMatchBody(pDurationSec: 90, pReelSetId: nil, pIdempotencyKey: UUID().uuidString),
            accessToken: session.accessToken,
            decodeAs: SupabaseMatchRow.self,
            retryPolicy: .reads,
            requestLabel: "create_match_with_code"
        )

        guard let matchId = created.id else { throw MatchmakingError.noMatchId }
        if let code = created.matchCode, !code.isEmpty {
            return QuickMatchHostSession(matchId: matchId, matchCode: code, matchDuration: created.durationSec ?? 90)
        }

        // Some deployments can return a row before generated fields are visible.
        // Poll get_match briefly to recover the code instead of failing immediately.
        let recoveredCode = try await recoverMatchCode(matchId: matchId, token: session.accessToken)
        guard !recoveredCode.isEmpty else { throw MatchmakingError.invalidResponse }
        return QuickMatchHostSession(matchId: matchId, matchCode: recoveredCode, matchDuration: created.durationSec ?? 90)
    }

    func waitForOpponentJoin(matchId: String, playerName: String, timeout: TimeInterval) async throws -> MatchmakingResult {
        let displayName = playerName.hasPrefix(displayNamePrefix) ? playerName : "\(displayNamePrefix)\(playerName)"
        let token = try await auth.accessToken(displayName: displayName)
        let pollUntil = Date().addingTimeInterval(timeout)
        while Date() < pollUntil {
            let fetched: SupabaseMatchRow = try await client.rpc(
                "get_match",
                body: GetMatchBody(pMatchId: matchId),
                accessToken: token,
                decodeAs: SupabaseMatchRow.self,
                retryPolicy: .reads,
                requestLabel: "get_match"
            )
            if fetched.hasOpponentJoined {
                return MatchmakingResult(
                    opponent: DuelOpponent(
                        name: fetched.opponentDisplayName ?? "Opponent",
                        rank: MockData.defaultOpponent.rank,
                        rotLevel: MockData.defaultOpponent.rotLevel,
                        wins: MockData.defaultOpponent.wins
                    ),
                    matchDuration: fetched.durationSec ?? 90,
                    trophyDelta: 25,
                    boostSlots: 4,
                    matchId: matchId
                )
            }
            try await Task.sleep(for: .seconds(1))
        }
        throw MatchmakingError.timeout
    }

    func joinMatch(matchCode: String, playerName: String) async throws -> MatchmakingResult {
        let displayName = playerName.hasPrefix(displayNamePrefix) ? playerName : "\(displayNamePrefix)\(playerName)"
        let session = try await auth.ensureAuthenticated(displayName: displayName)

        _ = try? await client.rpc(
            "ensure_user_profile",
            body: EnsureUserProfileBody(pDisplayName: displayName),
            accessToken: session.accessToken,
            decodeAs: String.self,
            requestLabel: "ensure_user_profile"
        )

        let joined: SupabaseMatchRow = try await client.rpc(
            "join_match_by_code",
            body: JoinMatchBody(pMatchCode: matchCode),
            accessToken: session.accessToken,
            decodeAs: SupabaseMatchRow.self,
            requestLabel: "join_match_by_code"
        )

        return MatchmakingResult(
            opponent: MockData.defaultOpponent,
            matchDuration: joined.durationSec ?? 90,
            trophyDelta: 25,
            boostSlots: 4,
            matchId: joined.id
        )
    }

    func leaveMatch(matchId: String, playerName: String) async throws {
        let displayName = playerName.hasPrefix(displayNamePrefix) ? playerName : "\(displayNamePrefix)\(playerName)"
        let token = try await auth.accessToken(displayName: displayName)
        try await client.rpcVoid(
            "leave_match",
            body: LeaveMatchBody(pMatchId: matchId),
            accessToken: token,
            requestLabel: "leave_match"
        )
    }

    func fetchFeed(matchId: String, playerName: String) async throws -> [MatchFeedItem] {
        let displayName = playerName.hasPrefix(displayNamePrefix) ? playerName : "\(displayNamePrefix)\(playerName)"
        let token = try await auth.accessToken(displayName: displayName)
        let rows: [FeedRow] = try await client.rpc(
            "fetch_match_feed",
            body: GetMatchBody(pMatchId: matchId),
            accessToken: token,
            decodeAs: [FeedRow].self,
            retryPolicy: .reads,
            requestLabel: "fetch_match_feed"
        )
        return rows.map {
            MatchFeedItem(
                reelID: $0.reelId,
                ordinal: $0.ordinal,
                durationMs: $0.durationMs,
                signedVideoURL: $0.signedVideoURL
            )
        }
        .sorted { $0.ordinal < $1.ordinal }
    }

    func ingestTelemetry(matchId: String, events: [TelemetryEvent], playerName: String) async throws -> Int {
        guard !events.isEmpty else { return 0 }
        let displayName = playerName.hasPrefix(displayNamePrefix) ? playerName : "\(displayNamePrefix)\(playerName)"
        let token = try await auth.accessToken(displayName: displayName)
        let normalizedEvents = events.compactMap(normalizeTelemetryEvent)
        guard !normalizedEvents.isEmpty else { return 0 }
        return try await client.rpc(
            "ingest_telemetry_batch",
            body: IngestTelemetryBody(pMatchId: matchId, pEvents: normalizedEvents),
            accessToken: token,
            decodeAs: Int.self,
            requestLabel: "ingest_telemetry_batch"
        )
    }

    func latestScoreSnapshot(matchId: String, playerName: String) async throws -> ScoreSnapshot {
        let displayName = playerName.hasPrefix(displayNamePrefix) ? playerName : "\(displayNamePrefix)\(playerName)"
        let userID = try await auth.currentUserId(displayName: displayName)
        let token = try await auth.accessToken(displayName: displayName)
        let rows: OneOrMany<ScoreSnapshotRow> = try await client.rpc(
            "latest_score_snapshot",
            body: LatestScoreBody(pMatchId: matchId, pUserId: userID),
            accessToken: token,
            decodeAs: OneOrMany<ScoreSnapshotRow>.self,
            retryPolicy: .reads,
            requestLabel: "latest_score_snapshot"
        )
        guard let row = rows.values.first else { throw MatchmakingError.invalidResponse }
        let parsedAt = ISO8601DateFormatter().date(from: row.snapshotAt)
        return ScoreSnapshot(score: row.score, metrics: row.metrics, snapshotAt: parsedAt)
    }

    func globalLeaderboard(limit: Int, playerName: String) async throws -> [LeaderboardSummaryEntry] {
        let displayName = playerName.hasPrefix(displayNamePrefix) ? playerName : "\(displayNamePrefix)\(playerName)"
        let token = try await auth.accessToken(displayName: displayName)
        let rows: [LeaderboardRow] = try await client.rpc(
            "get_global_leaderboard",
            body: LeaderboardBody(pLimit: limit),
            accessToken: token,
            decodeAs: [LeaderboardRow].self,
            retryPolicy: .reads,
            requestLabel: "get_global_leaderboard"
        )
        return rows.map {
            LeaderboardSummaryEntry(
                userID: $0.userId,
                displayName: $0.displayName,
                wins: $0.wins,
                averageScore: $0.averageScore
            )
        }
    }

    func profileSummary(playerName: String) async throws -> ProfileSummary {
        let displayName = playerName.hasPrefix(displayNamePrefix) ? playerName : "\(displayNamePrefix)\(playerName)"
        let token = try await auth.accessToken(displayName: displayName)
        let row: ProfileSummaryRow = try await client.rpc(
            "get_profile_summary",
            body: EmptyBody(),
            accessToken: token,
            decodeAs: ProfileSummaryRow.self,
            retryPolicy: .reads,
            requestLabel: "get_profile_summary"
        )
        return ProfileSummary(
            userID: row.userId,
            displayName: row.displayName,
            matchesPlayed: row.matchesPlayed,
            wins: row.wins,
            bestScore: row.bestScore
        )
    }

    private func recoverMatchCode(matchId: String, token: String) async throws -> String {
        for _ in 0..<4 {
            let fetched: SupabaseMatchRow = try await client.rpc(
                "get_match",
                body: GetMatchBody(pMatchId: matchId),
                accessToken: token,
                decodeAs: SupabaseMatchRow.self,
                retryPolicy: .reads,
                requestLabel: "get_match(code-recovery)"
            )
            if let code = fetched.matchCode, !code.isEmpty { return code }
            try await Task.sleep(for: .milliseconds(500))
        }
        return ""
    }

    private func normalizeTelemetryEvent(_ event: TelemetryEvent) -> TelemetryEvent? {
        let normalizedType: String
        switch event.eventType.lowercased() {
        case "scroll_back":
            normalizedType = "scroll"
        case "boost":
            normalizedType = "scroll"
        default:
            normalizedType = event.eventType.lowercased()
        }
        return TelemetryEvent(
            reelID: event.reelID,
            eventType: normalizedType,
            clientEventID: event.clientEventID,
            occurredAt: event.occurredAt,
            payload: event.payload
        )
    }
}

private struct CreateMatchBody: Encodable {
    let pDurationSec: Int
    let pReelSetId: String?
    let pIdempotencyKey: String

    enum CodingKeys: String, CodingKey {
        case pDurationSec = "p_duration_sec"
        case pReelSetId = "p_reel_set_id"
        case pIdempotencyKey = "p_idempotency_key"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pDurationSec, forKey: .pDurationSec)
        if let pReelSetId {
            try container.encode(pReelSetId, forKey: .pReelSetId)
        } else {
            // Keep null in payload to match deployed RPC signature expectations.
            try container.encodeNil(forKey: .pReelSetId)
        }
        try container.encode(pIdempotencyKey, forKey: .pIdempotencyKey)
    }
}

private struct GetMatchBody: Encodable {
    let pMatchId: String
    enum CodingKeys: String, CodingKey {
        case pMatchId = "p_match_id"
    }
}

private struct JoinMatchBody: Encodable {
    let pMatchCode: String
    enum CodingKeys: String, CodingKey {
        case pMatchCode = "p_match_code"
    }
}

private struct LeaveMatchBody: Encodable {
    let pMatchId: String
    enum CodingKeys: String, CodingKey {
        case pMatchId = "p_match_id"
    }
}

private struct EnsureUserProfileBody: Encodable {
    let pDisplayName: String
    enum CodingKeys: String, CodingKey {
        case pDisplayName = "p_display_name"
    }
}

private struct LeaderboardBody: Encodable {
    let pLimit: Int
    enum CodingKeys: String, CodingKey {
        case pLimit = "p_limit"
    }
}

private struct LatestScoreBody: Encodable {
    let pMatchId: String
    let pUserId: String
    enum CodingKeys: String, CodingKey {
        case pMatchId = "p_match_id"
        case pUserId = "p_user_id"
    }
}

private struct IngestTelemetryBody: Encodable {
    let pMatchId: String
    let pEvents: [TelemetryEvent]
    enum CodingKeys: String, CodingKey {
        case pMatchId = "p_match_id"
        case pEvents = "p_events"
    }
}

private struct EmptyBody: Encodable {}

private struct SupabaseMatchRow: Decodable {
    let id: String?
    let matchCode: String?
    let status: String?
    let durationSec: Int?
    let player1UserId: String?
    let player2UserId: String?
    let player2DisplayName: String?
    let startedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case matchCode = "match_code"
        case status
        case durationSec = "duration_sec"
        case player1UserId = "player1_user_id"
        case player2UserId = "player2_user_id"
        case player2DisplayName = "player2_display_name"
        case startedAt = "started_at"
    }

    var hasSecondPlayer: Bool {
        guard let player2UserId else { return false }
        return !player2UserId.isEmpty
    }

    var hasOpponentJoined: Bool {
        if hasSecondPlayer { return true }
        if let status, status.lowercased() == "in_progress" { return true }
        if let startedAt, !startedAt.isEmpty { return true }
        return false
    }

    var opponentDisplayName: String? {
        guard let player2DisplayName, !player2DisplayName.isEmpty else { return nil }
        return player2DisplayName
    }
}

private struct OneOrMany<T: Decodable>: Decodable {
    let values: [T]

    init(from decoder: Decoder) throws {
        if let array = try? [T](from: decoder) {
            values = array
            return
        }
        values = [try T(from: decoder)]
    }
}

/// Local fallback used when backend is not configured or temporarily unavailable.
private struct MockMatchmakingService: MatchmakingServicing {
    func findMatch(playerName: String, timeout: TimeInterval) async throws -> MatchmakingResult {
        try await Task.sleep(for: .seconds(2))
        return MatchmakingResult(
            opponent: MockData.defaultOpponent,
            matchDuration: 60,
            trophyDelta: 25,
            boostSlots: 4,
            matchId: nil
        )
    }
}

private struct FeedRow: Decodable {
    let reelId: String
    let ordinal: Int
    let durationMs: Int
    let signedVideoURL: String

    enum CodingKeys: String, CodingKey {
        case reelId = "reel_id"
        case ordinal
        case durationMs = "duration_ms"
        case signedVideoURL = "signed_video_url"
    }
}

private struct ScoreSnapshotRow: Decodable {
    let score: Double
    let metrics: [String: Double]
    let snapshotAt: String

    enum CodingKeys: String, CodingKey {
        case score
        case metrics
        case snapshotAt = "snapshot_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        score = try container.decode(Double.self, forKey: .score)
        snapshotAt = try container.decode(String.self, forKey: .snapshotAt)

        if let dictionary = try? container.decode([String: Double].self, forKey: .metrics) {
            metrics = dictionary
        } else if let numericArray = try? container.decode([Double].self, forKey: .metrics) {
            // Some backend revisions return metrics as array; preserve values with synthetic keys.
            metrics = Dictionary(uniqueKeysWithValues: numericArray.enumerated().map { ("metric_\($0.offset)", $0.element) })
        } else {
            metrics = [:]
        }
    }
}

private struct LeaderboardRow: Decodable {
    let userId: String
    let displayName: String
    let wins: Int
    let averageScore: Double

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case displayName = "display_name"
        case wins
        case averageScore = "average_score"
    }
}

private struct ProfileSummaryRow: Decodable {
    let userId: String
    let displayName: String
    let matchesPlayed: Int
    let wins: Int
    let bestScore: Double

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case displayName = "display_name"
        case matchesPlayed = "matches_played"
        case wins
        case bestScore = "best_score"
    }
}

// MARK: - App State

final class AppState: ObservableObject {
    @Published var customization = BrainCustomization()
    @Published var isLoggedIn = false
    @Published var matchmakingSourceLabel: String
    @Published var activeMatchID: String?
    @Published var liveScore: Double = 0
    @Published var liveMetrics: [String: Double] = [:]
    @Published var latestFeedItems: [MatchFeedItem] = []
    @Published var activeMatchCode: String?

    let matchmakingService: any MatchmakingServicing
    private let supabaseService: SupabaseMatchmakingService?
    private let playerDisplayName: String = "Player-ScrollClash"

    private func normalizedMatchCode(_ raw: String) -> String {
        let filtered = raw.uppercased().filter { $0.isNumber || $0.isLetter }
        return String(filtered.prefix(6))
    }

    init(matchmakingService: (any MatchmakingServicing)? = nil) {
        if let matchmakingService {
            self.matchmakingService = matchmakingService
            self.supabaseService = nil
            self.matchmakingSourceLabel = "custom"
            return
        }

        if let config = SupabaseConfig.fromInfoPlist() {
            let service = SupabaseMatchmakingService(config: config)
            self.matchmakingService = service
            self.supabaseService = service
            self.matchmakingSourceLabel = "supabase"
        } else {
            self.matchmakingService = MockMatchmakingService()
            self.supabaseService = nil
            self.matchmakingSourceLabel = "mock"
        }
    }

    func updateCustomization(_ update: BrainCustomization) {
        customization = update
    }

    @MainActor
    func findMatch(timeout: TimeInterval = 12) async throws -> MatchmakingResult {
        let result = try await matchmakingService.findMatch(playerName: playerDisplayName, timeout: timeout)
        activeMatchID = result.matchId
        return result
    }

    @MainActor
    func joinMatch(matchCode: String) async throws -> MatchmakingResult {
        guard let supabaseService else { throw MatchmakingError.notConfigured }
        let code = normalizedMatchCode(matchCode)
        let result = try await supabaseService.joinMatch(matchCode: code, playerName: playerDisplayName)
        activeMatchID = result.matchId
        return result
    }

    @MainActor
    func createQuickMatchHost() async throws -> QuickMatchHostSession {
        guard let supabaseService else { throw MatchmakingError.notConfigured }
        let hosted = try await supabaseService.createQuickMatchHost(playerName: playerDisplayName)
        let normalizedCode = normalizedMatchCode(hosted.matchCode)
        activeMatchID = hosted.matchId
        activeMatchCode = normalizedCode
        return .init(matchId: hosted.matchId, matchCode: normalizedCode, matchDuration: hosted.matchDuration)
    }

    @MainActor
    func waitForOpponentJoin(timeout: TimeInterval = 180) async throws -> MatchmakingResult {
        guard let supabaseService, let activeMatchID else { throw MatchmakingError.notConfigured }
        let result = try await supabaseService.waitForOpponentJoin(matchId: activeMatchID, playerName: playerDisplayName, timeout: timeout)
        return result
    }

    func leaveActiveMatch() async {
        guard let supabaseService, let activeMatchID else { return }
        do { try await supabaseService.leaveMatch(matchId: activeMatchID, playerName: playerDisplayName) }
        catch { print("leave_match failed: \(error)") }
        await MainActor.run { self.activeMatchID = nil }
    }

    @MainActor
    func fetchFeed(matchId: String) async -> [MatchFeedItem] {
        guard let supabaseService else { return [] }
        do {
            let items = try await supabaseService.fetchFeed(matchId: matchId, playerName: playerDisplayName)
            latestFeedItems = items
            return items
        } catch {
            print("fetch_match_feed failed: \(error)")
            latestFeedItems = []
            return []
        }
    }

    @MainActor
    func fetchLatestScore(matchId: String) async -> ScoreSnapshot? {
        guard let supabaseService else { return nil }
        do {
            let snapshot = try await supabaseService.latestScoreSnapshot(matchId: matchId, playerName: playerDisplayName)
            liveScore = snapshot.score
            liveMetrics = snapshot.metrics
            return snapshot
        } catch {
            print("latest_score_snapshot failed: \(error)")
            return nil
        }
    }

    func ingestTelemetry(matchId: String, events: [TelemetryEvent]) async {
        guard let supabaseService else { return }
        do {
            _ = try await supabaseService.ingestTelemetry(matchId: matchId, events: events, playerName: playerDisplayName)
        } catch {
            print("ingest_telemetry_batch failed: \(error)")
        }
    }

    func fetchGlobalLeaderboard(limit: Int = 50) async -> [LeaderboardSummaryEntry] {
        guard let supabaseService else { return [] }
        do {
            return try await supabaseService.globalLeaderboard(limit: limit, playerName: playerDisplayName)
        } catch {
            print("get_global_leaderboard failed: \(error)")
            return []
        }
    }

    func fetchProfileSummary() async -> ProfileSummary? {
        guard let supabaseService else { return nil }
        do {
            return try await supabaseService.profileSummary(playerName: playerDisplayName)
        } catch {
            print("get_profile_summary failed: \(error)")
            return nil
        }
    }
}
