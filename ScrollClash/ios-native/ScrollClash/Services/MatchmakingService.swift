import Foundation
import Combine
import os

enum MatchDuration: Int, CaseIterable, Identifiable {
    case ninety = 90
    case oneEighty = 180
    case threeHundred = 300

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .ninety: return "1.5m"
        case .oneEighty: return "3m"
        case .threeHundred: return "5m"
        }
    }
}

/// Protocol for matchmaking backed by Supabase RPCs.
protocol MatchmakingServiceProtocol {
    func createMatch(duration: MatchDuration) -> AnyPublisher<Match, Error>
    func joinMatch(withCode code: String) -> AnyPublisher<Match, Error>
    func getMatch(matchId: String) -> AnyPublisher<Match, Error>
    func leaveMatch(matchId: String) -> AnyPublisher<Void, Error>
}

/// Mock implementation for development.
final class MockMatchmakingService: MatchmakingServiceProtocol {
    static let shared = MockMatchmakingService()

    private init() {}

    func createMatch(duration: MatchDuration) -> AnyPublisher<Match, Error> {
        let code = MockMatchmakingService.generateCode()
        let match = Match(
            id: UUID().uuidString,
            matchCode: code,
            player1Id: "player1",
            player2Id: nil,
            status: .waiting,
            createdAt: Date(),
            startedAt: nil,
            endedAt: nil,
            durationSec: duration.rawValue,
            contentFeedIds: ["feed1"]
        )
        return Just(match)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(0.5), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }

    func joinMatch(withCode code: String) -> AnyPublisher<Match, Error> {
        let match = Match(
            id: UUID().uuidString,
            matchCode: code,
            player1Id: "player1",
            player2Id: "player2",
            status: .inProgress,
            createdAt: Date(),
            startedAt: Date(),
            endedAt: nil,
            durationSec: 90,
            contentFeedIds: ["feed1"]
        )
        return Just(match)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(0.5), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }

    func getMatch(matchId: String) -> AnyPublisher<Match, Error> {
        // Always returns waiting — only a real opponent joining should trigger inProgress.
        // (Previously used Bool.random() which caused instant false transitions.)
        let match = Match(
            id: matchId,
            matchCode: "ABC123",
            player1Id: "player1",
            player2Id: nil,
            status: .waiting,
            createdAt: Date(),
            startedAt: nil,
            endedAt: nil,
            durationSec: 90,
            contentFeedIds: ["feed1"]
        )
        return Just(match)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func leaveMatch(matchId: String) -> AnyPublisher<Void, Error> {
        Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    private static func generateCode() -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}

/// Supabase implementation using RPC functions from supabase/sql/003_functions.sql.
final class SupabaseMatchmakingService: MatchmakingServiceProtocol {
    private static let logger = Logger(subsystem: "com.scrollroyale.app", category: "MatchmakingService")

    private let client: SupabaseClient
    private let authService: SupabaseAuthService

    init(client: SupabaseClient, authService: SupabaseAuthService) {
        self.client = client
        self.authService = authService
    }

    func createMatch(duration: MatchDuration) -> AnyPublisher<Match, Error> {
        Self.logger.info("createMatch RPC — duration: \(duration.rawValue, privacy: .public)s")
        return authService.ensureAuthenticated(client: client)
            .handleEvents(receiveOutput: { _ in
                Self.logger.debug("createMatch: auth OK, calling create_match_with_code")
            }, receiveCompletion: { completion in
                if case .failure(let e) = completion {
                    Self.logger.error("createMatch: auth FAILED: \(e.localizedDescription, privacy: .public)")
                }
            })
            .flatMap { [client] _ in
                client.rpc(
                    function: "create_match_with_code",
                    body: [
                        "p_duration_sec": duration.rawValue,
                        "p_reel_set_id": NSNull(),
                        "p_idempotency_key": UUID().uuidString
                    ],
                    decodeAs: SupabaseMatchDTO.self
                )
            }
            .tryMap { dto in
                Self.logger.info("create_match_with_code response — id: \(dto.id, privacy: .public) code: \(dto.matchCode ?? "nil", privacy: .public) status: \(dto.status, privacy: .public)")
                let match = dto.toAppModel
                guard
                    let code = match.matchCode?.trimmingCharacters(in: .whitespacesAndNewlines),
                    code.count == 6
                else {
                    Self.logger.error("createMatch: no valid 6-char code in response — matchCode: \(dto.matchCode ?? "nil", privacy: .public)")
                    throw SupabaseClientError.serverError(
                        "Create match succeeded but no valid match code was returned. Run latest SQL migrations (001/003) in Supabase."
                    )
                }
                return match
            }
            .eraseToAnyPublisher()
    }

    func joinMatch(withCode code: String) -> AnyPublisher<Match, Error> {
        Self.logger.info("joinMatch RPC — code: \(code, privacy: .public)")
        return authService.ensureAuthenticated(client: client)
            .handleEvents(receiveOutput: { _ in
                Self.logger.debug("joinMatch: auth OK, calling join_match_by_code")
            }, receiveCompletion: { completion in
                if case .failure(let e) = completion {
                    Self.logger.error("joinMatch: auth FAILED: \(e.localizedDescription, privacy: .public)")
                }
            })
            .flatMap { [client] _ in
                client.rpc(
                    function: "join_match_by_code",
                    body: ["p_match_code": code.uppercased()],
                    decodeAs: SupabaseMatchDTO.self
                )
            }
            .map { dto in
                Self.logger.info("join_match_by_code response — id: \(dto.id, privacy: .public) status: \(dto.status, privacy: .public) player2UserId: \(dto.player2UserId ?? "nil", privacy: .public) startedAt: \(String(describing: dto.startedAt), privacy: .public)")
                return dto.toAppModel
            }
            .eraseToAnyPublisher()
    }

    func getMatch(matchId: String) -> AnyPublisher<Match, Error> {
        return authService.ensureAuthenticated(client: client)
            .flatMap { [client] _ in
                client.rpc(
                    function: "get_match",
                    body: ["p_match_id": matchId],
                    decodeAs: SupabaseMatchDTO.self
                )
            }
            .map { dto in
                Self.logger.debug("get_match response — id: \(dto.id, privacy: .public) status: \(dto.status, privacy: .public) player2UserId: \(dto.player2UserId ?? "nil", privacy: .public)")
                return dto.toAppModel
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let e) = completion {
                    Self.logger.error("getMatch FAILED — matchId: \(matchId, privacy: .public) error: \(e.localizedDescription, privacy: .public)")
                }
            })
            .eraseToAnyPublisher()
    }

    func leaveMatch(matchId: String) -> AnyPublisher<Void, Error> {
        Self.logger.info("leaveMatch RPC — matchId: \(matchId, privacy: .public)")
        return authService.ensureAuthenticated(client: client)
            .flatMap { [client] _ in
                client.rpcVoid(
                    function: "leave_match",
                    body: ["p_match_id": matchId]
                )
            }
            .eraseToAnyPublisher()
    }
}

private struct SupabaseMatchDTO: Codable {
    let id: String
    let matchCode: String?
    let status: String
    let createdAt: Date
    let startedAt: Date?
    let endedAt: Date?
    let durationSec: Int
    let createdBy: String
    // player2_user_id is set by join_match_by_code; used to confirm opponent actually joined
    let player2UserId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case matchCode = "match_code"
        case status
        case createdAt = "created_at"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case durationSec = "duration_sec"
        case createdBy = "created_by"
        case player2UserId = "player2_user_id"
    }

    var toAppModel: Match {
        // Treat as inProgress if the status field says so, OR if player2 has joined
        // and the match has started. This handles any schema variation gracefully.
        let mappedStatus: Match.MatchStatus
        switch status {
        case "in_progress":
            mappedStatus = .inProgress
        case "ended":
            mappedStatus = .ended
        default:
            // If player2 joined and startedAt is set, treat as in_progress even if
            // status string hasn't propagated yet (schema cache edge case)
            if player2UserId != nil && startedAt != nil {
                mappedStatus = .inProgress
            } else {
                mappedStatus = .waiting
            }
        }

        return Match(
            id: id,
            matchCode: matchCode,
            player1Id: createdBy,
            player2Id: player2UserId,
            status: mappedStatus,
            createdAt: createdAt,
            startedAt: startedAt,
            endedAt: endedAt,
            durationSec: durationSec,
            contentFeedIds: []
        )
    }
}
