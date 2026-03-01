import Foundation
import Combine
import UIKit
import os

final class SupabaseSessionStore {
    static let shared = SupabaseSessionStore()

    private let defaults = UserDefaults.standard
    private let tokenKey = "supabase.access_token"
    private let refreshTokenKey = "supabase.refresh_token"
    private let expiresAtKey = "supabase.expires_at"
    private let userIdKey = "supabase.user_id"
    private let displayNameKey = "supabase.display_name"

    private init() {}

    var accessToken: String? {
        get { defaults.string(forKey: tokenKey) }
        set { defaults.set(newValue, forKey: tokenKey) }
    }

    var refreshToken: String? {
        get { defaults.string(forKey: refreshTokenKey) }
        set { defaults.set(newValue, forKey: refreshTokenKey) }
    }

    var expiresAt: Date? {
        get {
            let timestamp = defaults.double(forKey: expiresAtKey)
            guard timestamp > 0 else { return nil }
            return Date(timeIntervalSince1970: timestamp)
        }
        set {
            if let newValue {
                defaults.set(newValue.timeIntervalSince1970, forKey: expiresAtKey)
            } else {
                defaults.removeObject(forKey: expiresAtKey)
            }
        }
    }

    var userId: String? {
        get { defaults.string(forKey: userIdKey) }
        set { defaults.set(newValue, forKey: userIdKey) }
    }

    var displayName: String? {
        get { defaults.string(forKey: displayNameKey) }
        set { defaults.set(newValue, forKey: displayNameKey) }
    }

    var shouldRefreshSoon: Bool {
        guard let token = accessToken, !token.isEmpty else { return false }
        guard let expiresAt else { return true } // legacy token without metadata
        return Date().addingTimeInterval(30) >= expiresAt
    }

    func clearSession() {
        defaults.removeObject(forKey: tokenKey)
        defaults.removeObject(forKey: refreshTokenKey)
        defaults.removeObject(forKey: expiresAtKey)
        defaults.removeObject(forKey: userIdKey)
        defaults.removeObject(forKey: displayNameKey)
    }
}

/// Bootstraps an authenticated Supabase session for RPC calls that depend on auth.uid().
final class SupabaseAuthService {
    private static let logger = Logger(subsystem: "com.scrollroyale.app", category: "SupabaseAuth")

    private let configuration: SupabaseConfiguration
    private let sessionStore: SupabaseSessionStore
    private let session: URLSession
    private let authStateQueue = DispatchQueue(label: "supabase.auth.state")
    private var inFlightAuthentication: AnyPublisher<Void, Error>?
    private var mostRecentClient: SupabaseClient?
    private var lifecycleCancellable: AnyCancellable?
    private var backgroundCancellables = Set<AnyCancellable>()

    init(
        configuration: SupabaseConfiguration,
        sessionStore: SupabaseSessionStore = .shared,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.sessionStore = sessionStore
        self.session = session
        observeAppLifecycleForRefresh()
    }

    func ensureAuthenticated(client: SupabaseClient) -> AnyPublisher<Void, Error> {
        return authStateQueue.sync {
            mostRecentClient = client
            if let inFlightAuthentication {
                return inFlightAuthentication
            }

            let publisher = makeAuthenticationPipeline(client: client)
                .share()
                .eraseToAnyPublisher()

            inFlightAuthentication = publisher
            return publisher
        }
    }

    private func makeAuthenticationPipeline(client: SupabaseClient) -> AnyPublisher<Void, Error> {
        let pipeline: AnyPublisher<Void, Error>

        if let token = sessionStore.accessToken, !token.isEmpty {
            if sessionStore.shouldRefreshSoon {
                pipeline = refreshOrReauthenticate(client: client)
            } else if let userId = sessionStore.userId, !userId.isEmpty {
                pipeline = Just(())
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            } else {
                pipeline = ensureProfile(client: client)
            }
        } else {
            pipeline = reauthenticate(client: client)
        }

        return pipeline.handleEvents(
            receiveCompletion: { [weak self] _ in
                self?.authStateQueue.async {
                    self?.inFlightAuthentication = nil
                }
            },
            receiveCancel: { [weak self] in
                self?.authStateQueue.async {
                    self?.inFlightAuthentication = nil
                }
            }
        )
        .eraseToAnyPublisher()
    }

    private func refreshOrReauthenticate(client: SupabaseClient) -> AnyPublisher<Void, Error> {
        refreshSession()
            .catch { [weak self] refreshError -> AnyPublisher<Void, Error> in
                guard let self else {
                    return Fail(error: SupabaseClientError.invalidResponse).eraseToAnyPublisher()
                }
                if self.isTransientError(refreshError) {
                    Self.logger.warning("Transient refresh failure, retrying once: \(String(describing: refreshError), privacy: .public)")
                    return self.refreshSession()
                        .catch { [weak self] secondError -> AnyPublisher<Void, Error> in
                            guard let self else {
                                return Fail(error: SupabaseClientError.invalidResponse).eraseToAnyPublisher()
                            }
                            Self.logger.error("Second refresh attempt failed, reauthenticating: \(String(describing: secondError), privacy: .public)")
                            self.sessionStore.clearSession()
                            return self.reauthenticate(client: client)
                        }
                        .eraseToAnyPublisher()
                }
                Self.logger.warning("Refresh token is not recoverable, reauthenticating: \(String(describing: refreshError), privacy: .public)")
                self.sessionStore.clearSession()
                return self.reauthenticate(client: client)
            }
            .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
                guard let self else {
                    return Fail(error: SupabaseClientError.invalidResponse).eraseToAnyPublisher()
                }
                if let userId = self.sessionStore.userId, !userId.isEmpty {
                    return Just(())
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                return self.ensureProfile(client: client)
            }
            .eraseToAnyPublisher()
    }

    private func reauthenticate(client: SupabaseClient) -> AnyPublisher<Void, Error> {
        signUpAnonymous()
            .handleEvents(receiveOutput: { [weak self] payload in
                self?.persistSession(payload)
            })
            .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
                guard let self else {
                    return Fail(error: SupabaseClientError.invalidResponse).eraseToAnyPublisher()
                }
                return self.ensureProfile(client: client)
            }
            .eraseToAnyPublisher()
    }

    private func ensureProfile(client: SupabaseClient) -> AnyPublisher<Void, Error> {
        let displayName = sessionStore.displayName ?? "Player-\(String(UUID().uuidString.prefix(6)))"
        return client.rpc(
            function: "ensure_user_profile",
            body: ["p_display_name": displayName],
            decodeAs: String.self
        )
        .map { [weak self] userId in
            self?.sessionStore.userId = userId
            self?.sessionStore.displayName = displayName
            return ()
        }
        .eraseToAnyPublisher()
    }

    private func signUpAnonymous() -> AnyPublisher<SupabaseSessionPayload, Error> {
        guard let endpoint = URL(string: "/auth/v1/signup", relativeTo: configuration.url) else {
            return Fail(error: SupabaseClientError.invalidURL).eraseToAnyPublisher()
        }

        let generatedDisplayName = "Player-\(String(UUID().uuidString.prefix(6)))"
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(configuration.anonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(configuration.anonKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "data": [
                "display_name": generatedDisplayName
            ]
        ])

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let http = response as? HTTPURLResponse else {
                    throw SupabaseClientError.invalidResponse
                }
                guard (200...299).contains(http.statusCode) else {
                    let message = String(data: data, encoding: .utf8) ?? "unknown"
                    throw SupabaseClientError.serverError(message)
                }
                guard
                    let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                    let user = json["user"] as? [String: Any],
                    let userId = user["id"] as? String
                else {
                    throw SupabaseClientError.invalidResponse
                }

                guard let accessToken = Self.parseToken(from: json, key: "access_token") else {
                    throw SupabaseClientError.serverError(
                        "Anonymous auth did not return a token. Enable Anonymous provider in Supabase Auth settings."
                    )
                }

                let userMetadataRaw =
                    (user["user_metadata"] as? [String: Any]) ??
                    (user["userMetadata"] as? [String: Any]) ??
                    [:]
                let displayName = (userMetadataRaw["display_name"] as? String) ?? generatedDisplayName
                let refreshToken = Self.parseToken(from: json, key: "refresh_token")
                let expiresAt = Self.parseExpiryDate(from: json)

                return SupabaseSessionPayload(
                    accessToken: accessToken,
                    refreshToken: refreshToken,
                    expiresAt: expiresAt,
                    user: SupabaseAuthUser(
                        id: userId,
                        userMetadata: SupabaseUserMetadata(displayName: displayName)
                    )
                )
            }
            .eraseToAnyPublisher()
    }

    private func refreshSession() -> AnyPublisher<Void, Error> {
        guard let refreshToken = sessionStore.refreshToken, !refreshToken.isEmpty else {
            return Fail(error: SupabaseClientError.serverError("Missing refresh token.")).eraseToAnyPublisher()
        }
        guard let endpoint = URL(string: "/auth/v1/token?grant_type=refresh_token", relativeTo: configuration.url) else {
            return Fail(error: SupabaseClientError.invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(configuration.anonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(configuration.anonKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "refresh_token": refreshToken
        ])

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let http = response as? HTTPURLResponse else {
                    throw SupabaseClientError.invalidResponse
                }
                guard (200...299).contains(http.statusCode) else {
                    let message = String(data: data, encoding: .utf8) ?? "unknown"
                    throw SupabaseClientError.serverError(message)
                }
                guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
                    throw SupabaseClientError.invalidResponse
                }
                guard let accessToken = Self.parseToken(from: json, key: "access_token") else {
                    throw SupabaseClientError.invalidResponse
                }

                let nextRefreshToken = Self.parseToken(from: json, key: "refresh_token") ?? refreshToken
                let expiresAt = Self.parseExpiryDate(from: json)
                let user = Self.parseUser(from: json)
                let payload = SupabaseSessionPayload(
                    accessToken: accessToken,
                    refreshToken: nextRefreshToken,
                    expiresAt: expiresAt,
                    user: user
                )
                return payload
            }
            .map { [weak self] payload in
                self?.persistSession(payload)
                return ()
            }
            .eraseToAnyPublisher()
    }

    private func persistSession(_ payload: SupabaseSessionPayload) {
        sessionStore.accessToken = payload.accessToken
        sessionStore.refreshToken = payload.refreshToken
        sessionStore.expiresAt = payload.expiresAt
        if let user = payload.user {
            sessionStore.userId = user.id
            if let displayName = user.userMetadata?.displayName {
                sessionStore.displayName = displayName
            }
        }
    }

    private static func parseToken(from json: [String: Any], key: String) -> String? {
        if let token = json[key] as? String, !token.isEmpty {
            return token
        }
        let camel = key.components(separatedBy: "_").enumerated().map { index, part in
            index == 0 ? part : part.capitalized
        }.joined()
        if let token = json[camel] as? String, !token.isEmpty {
            return token
        }
        return nil
    }

    private static func parseExpiryDate(from json: [String: Any]) -> Date? {
        if let timestamp = numberValue(json["expires_at"]) {
            return Date(timeIntervalSince1970: timestamp)
        }
        if let expiresIn = numberValue(json["expires_in"]) {
            return Date().addingTimeInterval(expiresIn)
        }
        return nil
    }

    private static func parseUser(from json: [String: Any]) -> SupabaseAuthUser? {
        guard let user = json["user"] as? [String: Any], let userId = user["id"] as? String else {
            return nil
        }
        let metadata = (user["user_metadata"] as? [String: Any]) ??
            (user["userMetadata"] as? [String: Any]) ??
            [:]
        return SupabaseAuthUser(
            id: userId,
            userMetadata: SupabaseUserMetadata(displayName: metadata["display_name"] as? String)
        )
    }

    private static func numberValue(_ value: Any?) -> TimeInterval? {
        if let number = value as? NSNumber {
            return number.doubleValue
        }
        if let string = value as? String, let parsed = Double(string) {
            return parsed
        }
        return nil
    }

    private func observeAppLifecycleForRefresh() {
        lifecycleCancellable = NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.refreshIfNeededInBackground()
            }
    }

    private func refreshIfNeededInBackground() {
        guard sessionStore.shouldRefreshSoon else { return }
        guard let client = authStateQueue.sync(execute: { mostRecentClient }) else {
            return
        }
        ensureAuthenticated(client: client)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Self.logger.error("Background token refresh failed: \(String(describing: error), privacy: .public)")
                }
            }, receiveValue: { })
            .store(in: &backgroundCancellables)
    }

    private func isTransientError(_ error: Error) -> Bool {
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
                    || lowered.contains("503")
                    || lowered.contains("504")
            default:
                return false
            }
        }
        return false
    }
}

private struct SupabaseSessionPayload: Decodable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date?
    let user: SupabaseAuthUser?
}

private struct SupabaseAuthUser: Decodable {
    let id: String
    let userMetadata: SupabaseUserMetadata?
}

private struct SupabaseUserMetadata: Decodable {
    let displayName: String?
}
