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
            return ensureProfile(client: client).eraseToAnyPublisher()
        }

        return signUpAnonymous()
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

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

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
            .decode(type: SupabaseSignUpResponse.self, decoder: decoder)
            .tryMap { response in
                guard !response.accessToken.isEmpty else {
                    throw SupabaseClientError.serverError(
                        "No access token returned. Enable Anonymous Auth in Supabase Auth settings."
                    )
                }
                return response
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
