import Foundation
import Combine

protocol LeaderboardServiceProtocol {
    func fetchTopPlayers(limit: Int) -> AnyPublisher<[LeaderboardEntry], Error>
}

final class SupabaseLeaderboardService: LeaderboardServiceProtocol {
    private let client: SupabaseClient
    private let authService: SupabaseAuthService

    init(client: SupabaseClient, authService: SupabaseAuthService) {
        self.client = client
        self.authService = authService
    }

    func fetchTopPlayers(limit: Int) -> AnyPublisher<[LeaderboardEntry], Error> {
        authService.ensureAuthenticated(client: client)
            .flatMap { [client] _ in
                client.rpc(
                    function: "get_global_leaderboard",
                    body: ["p_limit": limit],
                    decodeAs: [LeaderboardEntry].self
                )
            }
            .eraseToAnyPublisher()
    }
}

final class MockLeaderboardService: LeaderboardServiceProtocol {
    static let shared = MockLeaderboardService()

    func fetchTopPlayers(limit: Int) -> AnyPublisher<[LeaderboardEntry], Error> {
        let entries: [LeaderboardEntry] = [
            LeaderboardEntry(userId: "u1", displayName: "Player-ALPHA", wins: 11, averageScore: 824),
            LeaderboardEntry(userId: "u2", displayName: "Player-BETA", wins: 9, averageScore: 781),
            LeaderboardEntry(userId: "u3", displayName: "Player-GAMMA", wins: 7, averageScore: 733)
        ]
        return Just(Array(entries.prefix(limit)))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
