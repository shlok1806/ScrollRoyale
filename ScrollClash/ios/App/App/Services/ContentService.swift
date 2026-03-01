import Foundation
import Combine

/// Fetches deterministic ordered match feed content.
protocol ContentServiceProtocol {
    func fetchContentFeed(matchId: String) -> AnyPublisher<[ContentItem], Error>
}

/// Mock implementation for local development.
final class MockContentService: ContentServiceProtocol {
    static let shared = MockContentService()

    private init() {}

    func fetchContentFeed(matchId: String) -> AnyPublisher<[ContentItem], Error> {
        // Sample videos - use real URLs for production (e.g. from Bundle or remote)
        let sampleItems: [ContentItem] = (1...6).map { index in
            ContentItem(
                id: "video-\(index)",
                videoURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!,
                duration: 60,
                order: index,
                thumbnailURL: nil
            )
        }
        return Just(sampleItems)
            .setFailureType(to: Error.self)
            .delay(for: .milliseconds(300), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
}

final class SupabaseContentService: ContentServiceProtocol {
    private let client: SupabaseClient
    private let authService: SupabaseAuthService

    init(client: SupabaseClient, authService: SupabaseAuthService) {
        self.client = client
        self.authService = authService
    }

    func fetchContentFeed(matchId: String) -> AnyPublisher<[ContentItem], Error> {
        authService.ensureAuthenticated(client: client)
            .flatMap { [client] _ in
                client.rpc(
                    function: "fetch_match_feed",
                    body: ["p_match_id": matchId],
                    decodeAs: [SupabaseFeedItemDTO].self
                )
            }
            .map { rows in
                rows.map {
                    ContentItem(
                        id: $0.reelId,
                        videoURL: $0.signedVideoURL,
                        duration: TimeInterval($0.durationMs) / 1000.0,
                        order: $0.ordinal,
                        thumbnailURL: nil
                    )
                }
                .sorted { $0.order < $1.order }
            }
            .eraseToAnyPublisher()
    }
}

private struct SupabaseFeedItemDTO: Codable {
    let reelId: String
    let ordinal: Int
    let durationMs: Int
    let signedVideoURL: URL

    enum CodingKeys: String, CodingKey {
        case reelId = "reel_id"
        case ordinal
        case durationMs = "duration_ms"
        case signedVideoURL = "signed_video_url"
    }
}
