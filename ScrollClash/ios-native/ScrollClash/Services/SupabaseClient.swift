import Foundation
import Combine
import os

enum SupabaseClientError: Error {
    case invalidURL
    case missingConfiguration
    case invalidResponse
    case serverError(String)
    case decodingError
}

extension SupabaseClientError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Supabase URL is invalid. Check SUPABASE_URL in Info.plist."
        case .missingConfiguration:
            return "Supabase configuration is missing. Add SUPABASE_URL and SUPABASE_ANON_KEY."
        case .invalidResponse:
            return "Received an invalid response from Supabase."
        case .serverError(let message):
            return message
        case .decodingError:
            return "Failed to decode Supabase response."
        }
    }
}

struct SupabaseConfiguration {
    let url: URL
    let anonKey: String
    let accessTokenProvider: () -> String?

    static var fromBundle: SupabaseConfiguration? {
        guard
            let rawURLString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let rawAnonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String
        else {
            return nil
        }

        let urlString = rawURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        let anonKey = rawAnonKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            let url = URL(string: urlString),
            !anonKey.isEmpty
        else {
            return nil
        }

        return SupabaseConfiguration(url: url, anonKey: anonKey) {
            SupabaseSessionStore.shared.accessToken
        }
    }
}

struct SupabaseRetryPolicy {
    let maxRetries: Int
    let initialBackoff: TimeInterval
    let multiplier: Double

    static let none = SupabaseRetryPolicy(maxRetries: 0, initialBackoff: 0, multiplier: 1)
    static let reads = SupabaseRetryPolicy(maxRetries: 2, initialBackoff: 0.2, multiplier: 2)
}

final class SupabaseClient {
    private static let logger = Logger(subsystem: "com.scrollroyale.app", category: "SupabaseClient")

    private let configuration: SupabaseConfiguration
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
        // Supabase timestamps use fractional seconds (e.g. 2026-02-28T15:30:00.123456+00:00).
        // Swift's built-in .iso8601 strategy rejects fractional seconds, silently failing
        // every Date field decode and making all RPC calls appear to fail. Use a custom
        // strategy that tries fractional-seconds first, then falls back to whole seconds.
        decoder.dateDecodingStrategy = .custom(Self.supabaseDateDecoder)
    }

    private static let fractionalSecondsFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let wholeSecondsFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static func supabaseDateDecoder(_ decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        if let date = fractionalSecondsFormatter.date(from: string) { return date }
        if let date = wholeSecondsFormatter.date(from: string) { return date }
        // Last-resort: try legacy DateFormatter for non-standard formats
        let legacy = DateFormatter()
        legacy.locale = Locale(identifier: "en_US_POSIX")
        for fmt in ["yyyy-MM-dd'T'HH:mm:ssZZZZZ", "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ", "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"] {
            legacy.dateFormat = fmt
            if let date = legacy.date(from: string) { return date }
        }
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Cannot decode date string: \(string)"
        )
    }

    func rpc<T: Decodable>(
        function: String,
        body: [String: Any],
        decodeAs: T.Type,
        retryPolicy: SupabaseRetryPolicy = .none,
        requestLabel: String? = nil
    ) -> AnyPublisher<T, Error> {
        guard let endpoint = URL(string: "/rest/v1/rpc/\(function)", relativeTo: configuration.url) else {
            return Fail(error: SupabaseClientError.invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(configuration.anonKey, forHTTPHeaderField: "apikey")
        if let token = configuration.accessTokenProvider() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        return executeRequest(
            request,
            decodeAs: T.self,
            retryPolicy: retryPolicy,
            requestLabel: requestLabel ?? "rpc.\(function)"
        )
    }

    func rpcVoid(function: String, body: [String: Any]) -> AnyPublisher<Void, Error> {
        rpc(function: function, body: body, decodeAs: EmptyResponse.self)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    /// Generic REST table SELECT. Pass `accessToken: nil` for unauthenticated (anon-key-only) reads.
    func select<T: Decodable>(
        table: String,
        queryItems: [URLQueryItem],
        accessToken: String? = nil,
        decodeAs: T.Type,
        requestLabel: String? = nil
    ) -> AnyPublisher<T, Error> {
        var components = URLComponents(
            url: configuration.url.appendingPathComponent("rest/v1/\(table)"),
            resolvingAgainstBaseURL: true
        )
        components?.queryItems = queryItems
        guard let endpoint = components?.url else {
            return Fail(error: SupabaseClientError.invalidURL).eraseToAnyPublisher()
        }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(configuration.anonKey, forHTTPHeaderField: "apikey")
        let token = accessToken ?? configuration.accessTokenProvider()
        if let token, !token.isEmpty {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return executeRequest(
            request,
            decodeAs: T.self,
            retryPolicy: .reads,
            requestLabel: requestLabel ?? "select.\(table)"
        )
    }

    func createSignedStorageURL(bucket: String, path: String, expiresIn: Int = 3600) -> AnyPublisher<URL, Error> {
        let trimmedBucket = bucket.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/").union(.whitespacesAndNewlines))
        guard !trimmedBucket.isEmpty, !trimmedPath.isEmpty else {
            return Fail(error: SupabaseClientError.invalidURL).eraseToAnyPublisher()
        }

        let encodedBucket = trimmedBucket.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? trimmedBucket
        let encodedPath = trimmedPath
            .split(separator: "/")
            .map { segment in
                String(segment).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String(segment)
            }
            .joined(separator: "/")

        guard let endpoint = URL(string: "/storage/v1/object/sign/\(encodedBucket)/\(encodedPath)", relativeTo: configuration.url) else {
            return Fail(error: SupabaseClientError.invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(configuration.anonKey, forHTTPHeaderField: "apikey")
        if let token = configuration.accessTokenProvider() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["expiresIn": expiresIn])

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let http = response as? HTTPURLResponse else {
                    throw SupabaseClientError.invalidResponse
                }
                guard (200...299).contains(http.statusCode) else {
                    let message = String(data: data, encoding: .utf8) ?? "unknown"
                    throw SupabaseClientError.serverError(message)
                }
                return data
            }
            .decode(type: SignedStorageURLResponse.self, decoder: decoder)
            .tryMap { [configuration] payload in
                if let absolute = URL(string: payload.signedURL), absolute.scheme != nil {
                    return absolute
                }
                guard let relative = URL(string: payload.signedURL, relativeTo: configuration.url)?.absoluteURL else {
                    throw SupabaseClientError.decodingError
                }
                return relative
            }
            .eraseToAnyPublisher()
    }

    func createPublicStorageURL(bucket: String, path: String) -> URL? {
        let trimmedBucket = bucket.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/").union(.whitespacesAndNewlines))
        guard !trimmedBucket.isEmpty, !trimmedPath.isEmpty else {
            return nil
        }

        let encodedBucket = trimmedBucket.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? trimmedBucket
        let encodedPath = trimmedPath
            .split(separator: "/")
            .map { segment in
                String(segment).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String(segment)
            }
            .joined(separator: "/")

        return URL(string: "/storage/v1/object/public/\(encodedBucket)/\(encodedPath)", relativeTo: configuration.url)?.absoluteURL
    }

    private func executeRequest<T: Decodable>(
        _ request: URLRequest,
        decodeAs: T.Type,
        retryPolicy: SupabaseRetryPolicy,
        requestLabel: String
    ) -> AnyPublisher<T, Error> {
        var attemptRequest: ((Int, TimeInterval) -> AnyPublisher<T, Error>)!
        attemptRequest = { [weak self] remainingRetries, currentBackoff in
            guard let self else {
                return Fail(error: SupabaseClientError.invalidResponse).eraseToAnyPublisher()
            }
            let startedAt = Date()
            return self.session.dataTaskPublisher(for: request)
                .tryMap { data, response in
                    guard let http = response as? HTTPURLResponse else {
                        throw SupabaseClientError.invalidResponse
                    }
                    guard (200...299).contains(http.statusCode) else {
                        let message = String(data: data, encoding: .utf8) ?? "unknown"
                        throw SupabaseClientError.serverError(message)
                    }
                    return data
                }
                .decode(type: T.self, decoder: self.decoder)
                .handleEvents(receiveCompletion: { completion in
                    let elapsedMs = Int(Date().timeIntervalSince(startedAt) * 1000)
                    switch completion {
                    case .finished:
                        Self.logger.debug("[\(requestLabel, privacy: .public)] success in \(elapsedMs)ms")
                    case .failure(let error):
                        Self.logger.error("[\(requestLabel, privacy: .public)] failure in \(elapsedMs)ms: \(String(describing: error), privacy: .public)")
                    }
                })
                .catch { error -> AnyPublisher<T, Error> in
                    guard remainingRetries > 0, self.shouldRetry(error) else {
                        return Fail(error: error).eraseToAnyPublisher()
                    }
                    let nextBackoff = max(0, currentBackoff)
                    Self.logger.warning("[\(requestLabel, privacy: .public)] retrying in \(nextBackoff, privacy: .public)s (\(remainingRetries, privacy: .public) retries left)")
                    return Just(())
                        .setFailureType(to: Error.self)
                        .delay(for: .seconds(nextBackoff), scheduler: DispatchQueue.global(qos: .utility))
                        .flatMap { attemptRequest(remainingRetries - 1, currentBackoff * retryPolicy.multiplier) }
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }

        return attemptRequest(retryPolicy.maxRetries, retryPolicy.initialBackoff)
    }

    private func shouldRetry(_ error: Error) -> Bool {
        if error is URLError {
            return true
        }
        if let clientError = error as? SupabaseClientError {
            switch clientError {
            case .serverError(let message):
                let lowered = message.lowercased()
                return lowered.contains("timeout")
                    || lowered.contains("temporar")
                    || lowered.contains("429")
                    || lowered.contains("500")
                    || lowered.contains("502")
                    || lowered.contains("503")
                    || lowered.contains("504")
            default:
                return false
            }
        }
        return false
    }
}

private struct EmptyResponse: Decodable {}

private struct SignedStorageURLResponse: Decodable {
    let signedURL: String

    enum CodingKeys: String, CodingKey {
        case signedURL = "signedURL"
    }
}
