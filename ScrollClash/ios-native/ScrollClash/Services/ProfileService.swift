import Foundation
import Combine

protocol ProfileServiceProtocol {
    func fetchProfileSummary() -> AnyPublisher<ProfileSummary, Error>
}

final class SupabaseProfileService: ProfileServiceProtocol {
    private let client: SupabaseClient
    private let authService: SupabaseAuthService

    init(client: SupabaseClient, authService: SupabaseAuthService) {
        self.client = client
        self.authService = authService
    }

    func fetchProfileSummary() -> AnyPublisher<ProfileSummary, Error> {
        authService.ensureAuthenticated(client: client)
            .flatMap { [client] _ in
                client.rpc(
                    function: "get_profile_summary",
                    body: [:],
                    decodeAs: ProfileSummary.self
                )
            }
            .eraseToAnyPublisher()
    }
}

final class MockProfileService: ProfileServiceProtocol {
    static let shared = MockProfileService()

    func fetchProfileSummary() -> AnyPublisher<ProfileSummary, Error> {
        let displayName = SupabaseSessionStore.shared.displayName ?? "Player"
        let userId = SupabaseSessionStore.shared.userId ?? "local-user"
        let summary = ProfileSummary(
            userId: userId,
            displayName: displayName,
            matchesPlayed: 0,
            wins: 0,
            bestScore: 0
        )
        return Just(summary)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
