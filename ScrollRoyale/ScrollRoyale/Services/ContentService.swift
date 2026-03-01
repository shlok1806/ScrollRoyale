import Foundation
import Combine
import os

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
    private static let logger = Logger(subsystem: "com.scrollroyale.app", category: "ContentService")

    private let client: SupabaseClient
    private let authService: SupabaseAuthService
    private let defaultStorageBucket: String
    private let cacheStore: SupabaseCacheStore
    private let requestStateQueue = DispatchQueue(label: "supabase.content.request-state")
    private var inFlightFeedRequests: [String: AnyPublisher<[ContentItem], Error>] = [:]

    init(
        client: SupabaseClient,
        authService: SupabaseAuthService,
        defaultStorageBucket: String = "reels",
        cacheStore: SupabaseCacheStore = .shared
    ) {
        self.client = client
        self.authService = authService
        self.defaultStorageBucket = defaultStorageBucket
        self.cacheStore = cacheStore
    }

    func fetchContentFeed(matchId: String) -> AnyPublisher<[ContentItem], Error> {
        let networkPublisher = coalescedFreshFeed(matchId: matchId)
        if let cachedItems = cacheStore.feed(matchId: matchId), !cachedItems.isEmpty {
            Self.logger.debug("Feed cache hit for match \(matchId, privacy: .public)")
            return Just(cachedItems)
                .setFailureType(to: Error.self)
                .append(
                    networkPublisher
                        .catch { error -> AnyPublisher<[ContentItem], Error> in
                            Self.logger.warning("Using stale feed cache for \(matchId, privacy: .public) due to refresh failure: \(String(describing: error), privacy: .public)")
                            return Empty<[ContentItem], Error>().eraseToAnyPublisher()
                        }
                )
                .eraseToAnyPublisher()
        }
        return networkPublisher
    }

    private func fetchFreshFeed(matchId: String) -> AnyPublisher<[ContentItem], Error> {
        authService.ensureAuthenticated(client: client)
            .flatMap { [client] _ in
                client.rpc(
                    function: "fetch_match_feed",
                    body: ["p_match_id": matchId],
                    decodeAs: [SupabaseFeedItemDTO].self,
                    retryPolicy: .reads,
                    requestLabel: "fetch_match_feed"
                )
            }
            .flatMap { [weak self] rows -> AnyPublisher<[ContentItem], Error> in
                guard let self else {
                    return Fail(error: SupabaseClientError.invalidResponse).eraseToAnyPublisher()
                }
                Self.logger.info("Fetched \(rows.count) feed rows for match \(matchId, privacy: .public)")
                return self.resolveVideoURLs(rows: rows)
            }
            .handleEvents(receiveOutput: { [weak self] items in
                self?.cacheStore.setFeed(items, matchId: matchId)
            })
            .eraseToAnyPublisher()
    }

    private func coalescedFreshFeed(matchId: String) -> AnyPublisher<[ContentItem], Error> {
        requestStateQueue.sync {
            if let existing = inFlightFeedRequests[matchId] {
                return existing
            }
            let publisher = fetchFreshFeed(matchId: matchId)
                .handleEvents(receiveCompletion: { [weak self] _ in
                    self?.requestStateQueue.async {
                        self?.inFlightFeedRequests.removeValue(forKey: matchId)
                    }
                }, receiveCancel: { [weak self] in
                    self?.requestStateQueue.async {
                        self?.inFlightFeedRequests.removeValue(forKey: matchId)
                    }
                })
                .share()
                .eraseToAnyPublisher()
            inFlightFeedRequests[matchId] = publisher
            return publisher
        }
    }

    private func resolveVideoURLs(rows: [SupabaseFeedItemDTO]) -> AnyPublisher<[ContentItem], Error> {
        let publishers: [AnyPublisher<ContentItem, Error>] = rows.map { row in
            resolveVideoURL(rawValue: row.signedVideoURL)
                .map { resolvedURL in
                    ContentItem(
                        id: row.reelId,
                        videoURL: resolvedURL,
                        duration: TimeInterval(row.durationMs) / 1000.0,
                        order: row.ordinal,
                        thumbnailURL: nil
                    )
                }
                .eraseToAnyPublisher()
        }

        return Publishers.MergeMany(publishers)
            .collect()
            .map { $0.sorted { $0.order < $1.order } }
            .eraseToAnyPublisher()
    }

    private func resolveVideoURL(rawValue: String) -> AnyPublisher<URL, Error> {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return Fail(error: SupabaseClientError.invalidURL).eraseToAnyPublisher()
        }

        if let absolute = URL(string: trimmed), let scheme = absolute.scheme, scheme == "http" || scheme == "https" {
            return Just(absolute)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        let cleaned = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let components = cleaned.split(separator: "/", maxSplits: 1).map(String.init)
        if components.count == 2 {
            return resolveStorageURL(bucket: components[0], path: components[1], rawValue: rawValue)
                .eraseToAnyPublisher()
        }

        return resolveStorageURL(bucket: defaultStorageBucket, path: cleaned, rawValue: rawValue)
            .eraseToAnyPublisher()
    }

    private func resolveStorageURL(bucket: String, path: String, rawValue: String) -> AnyPublisher<URL, Error> {
        let cacheKey = "\(bucket)/\(path)"
        if let cachedURL = cacheStore.resolvedURL(for: cacheKey) {
            return Just(cachedURL)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        let publicURL = client.createPublicStorageURL(bucket: bucket, path: path)

        return client.createSignedStorageURL(bucket: bucket, path: path)
            .catch { [publicURL] signingError -> AnyPublisher<URL, Error> in
                if let publicURL {
                    Self.logger.warning("Signing failed for \(bucket, privacy: .public)/\(path, privacy: .public); falling back to public URL. Error: \(String(describing: signingError), privacy: .public)")
                    return Just(publicURL)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                return Fail(error: signingError).eraseToAnyPublisher()
            }
            .handleEvents(receiveOutput: { resolvedURL in
                self.cacheStore.setResolvedURL(resolvedURL, key: cacheKey)
                Self.logger.debug("Resolved reel path \(rawValue, privacy: .public) -> \(resolvedURL.absoluteString, privacy: .public)")
            }, receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Self.logger.error("Failed to resolve reel path \(rawValue, privacy: .public): \(String(describing: error), privacy: .public)")
                }
            })
            .eraseToAnyPublisher()
    }
}

private struct SupabaseFeedItemDTO: Codable {
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
