import Foundation
import Combine

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
        let match = Match(
            id: matchId,
            matchCode: "ABC123",
            player1Id: "player1",
            player2Id: Bool.random() ? "player2" : nil,
            status: Bool.random() ? .inProgress : .waiting,
            createdAt: Date(),
            startedAt: Date(),
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
    private let client: SupabaseClient
    private let authService: SupabaseAuthService

    init(client: SupabaseClient, authService: SupabaseAuthService) {
        self.client = client
        self.authService = authService
    }

    func createMatch(duration: MatchDuration) -> AnyPublisher<Match, Error> {
        authService.ensureAuthenticated(client: client)
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
            .map { $0.toAppModel }
            .eraseToAnyPublisher()
    }

    func joinMatch(withCode code: String) -> AnyPublisher<Match, Error> {
        authService.ensureAuthenticated(client: client)
            .flatMap { [client] _ in
                client.rpc(
                    function: "join_match_by_code",
                    body: ["p_match_code": code.uppercased()],
                    decodeAs: SupabaseMatchDTO.self
                )
            }
            .map { $0.toAppModel }
            .eraseToAnyPublisher()
    }

    func getMatch(matchId: String) -> AnyPublisher<Match, Error> {
        authService.ensureAuthenticated(client: client)
            .flatMap { [client] _ in
                client.rpc(
                    function: "get_match",
                    body: ["p_match_id": matchId],
                    decodeAs: SupabaseMatchDTO.self
                )
            }
            .map { $0.toAppModel }
            .eraseToAnyPublisher()
    }

    func leaveMatch(matchId: String) -> AnyPublisher<Void, Error> {
        authService.ensureAuthenticated(client: client)
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

    enum CodingKeys: String, CodingKey {
        case id
        case matchCode = "match_code"
        case status
        case createdAt = "created_at"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case durationSec = "duration_sec"
        case createdBy = "created_by"
    }

    var toAppModel: Match {
        let mappedStatus: Match.MatchStatus
        switch status {
        case "in_progress":
            mappedStatus = .inProgress
        case "ended":
            mappedStatus = .ended
        default:
            mappedStatus = .waiting
        }

        return Match(
            id: id,
            matchCode: matchCode,
            player1Id: createdBy,
            player2Id: nil,
            status: mappedStatus,
            createdAt: createdAt,
            startedAt: startedAt,
            endedAt: endedAt,
            durationSec: durationSec,
            contentFeedIds: []
        )
    }
}
