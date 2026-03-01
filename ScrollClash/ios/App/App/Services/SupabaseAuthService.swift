import Foundation
import Combine

final class SupabaseSessionStore {
    static let shared = SupabaseSessionStore()

    private let defaults = UserDefaults.standard
    private let tokenKey = "supabase.access_token"
    private let userIdKey = "supabase.user_id"
    private let displayNameKey = "supabase.display_name"

    private init() {}

    var accessToken: String? {
        get { defaults.string(forKey: tokenKey) }
        set { defaults.set(newValue, forKey: tokenKey) }
    }

    var userId: String? {
        get { defaults.string(forKey: userIdKey) }
        set { defaults.set(newValue, forKey: userIdKey) }
    }

    var displayName: String? {
        get { defaults.string(forKey: displayNameKey) }
        set { defaults.set(newValue, forKey: displayNameKey) }
    }
}

/// Bootstraps an authenticated Supabase session for RPC calls that depend on auth.uid().
final class SupabaseAuthService {
    private let configuration: SupabaseConfiguration
    private let sessionStore: SupabaseSessionStore
    private let session: URLSession
    private let authStateQueue = DispatchQueue(label: "supabase.auth.state")
    private var inFlightAuthentication: AnyPublisher<Void, Error>?

    init(
        configuration: SupabaseConfiguration,
        sessionStore: SupabaseSessionStore = .shared,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.sessionStore = sessionStore
        self.session = session
    }

    func ensureAuthenticated(client: SupabaseClient) -> AnyPublisher<Void, Error> {
        if let token = sessionStore.accessToken, !token.isEmpty {
            // Fast path for recurring calls (e.g., score polling): avoid extra auth/profile RPCs.
            if let userId = sessionStore.userId, !userId.isEmpty {
                return Just(())
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            return ensureProfile(client: client).eraseToAnyPublisher()
        }

        return authStateQueue.sync {
            if let inFlightAuthentication {
                return inFlightAuthentication
            }

            let publisher = signUpAnonymous()
                .handleEvents(receiveOutput: { [weak self] response in
                    self?.sessionStore.accessToken = response.accessToken
                    self?.sessionStore.userId = response.user.id
                    self?.sessionStore.displayName = response.user.userMetadata?.displayName
                })
                .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
                    guard let self else {
                        return Fail(error: SupabaseClientError.invalidResponse).eraseToAnyPublisher()
                    }
                    return self.ensureProfile(client: client).eraseToAnyPublisher()
                }
                .handleEvents(
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
                .share()
                .eraseToAnyPublisher()

            inFlightAuthentication = publisher
            return publisher
        }
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

    private func signUpAnonymous() -> AnyPublisher<SupabaseSignUpResponse, Error> {
        guard let endpoint = URL(string: "/auth/v1/signup", relativeTo: configuration.url) else {
            return Fail(error: SupabaseClientError.invalidURL).eraseToAnyPublisher()
        }

        let displayName = "Player-\(String(UUID().uuidString.prefix(6)))"
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(configuration.anonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(configuration.anonKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "data": [
                "display_name": displayName
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

                let accessToken =
                    (json["access_token"] as? String) ??
                    (json["accessToken"] as? String) ??
                    ""
                guard !accessToken.isEmpty else {
                    throw SupabaseClientError.serverError(
                        "Anonymous auth did not return a token. Enable Anonymous provider in Supabase Auth settings."
                    )
                }

                let userMetadataRaw =
                    (user["user_metadata"] as? [String: Any]) ??
                    (user["userMetadata"] as? [String: Any]) ??
                    [:]
                let displayName = userMetadataRaw["display_name"] as? String

                return SupabaseSignUpResponse(
                    accessToken: accessToken,
                    user: SupabaseAuthUser(
                        id: userId,
                        userMetadata: SupabaseUserMetadata(displayName: displayName)
                    )
                )
            }
            .eraseToAnyPublisher()
    }
}

private struct SupabaseSignUpResponse: Decodable {
    let accessToken: String
    let user: SupabaseAuthUser
}

private struct SupabaseAuthUser: Decodable {
    let id: String
    let userMetadata: SupabaseUserMetadata?
}

private struct SupabaseUserMetadata: Decodable {
    let displayName: String?
}
