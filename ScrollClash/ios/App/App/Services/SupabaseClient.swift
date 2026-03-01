import Foundation
import Combine

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

final class SupabaseClient {
    private let configuration: SupabaseConfiguration
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
        decoder.dateDecodingStrategy = .iso8601
    }

    func rpc<T: Decodable>(
        function: String,
        body: [String: Any],
        decodeAs: T.Type
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
            .decode(type: T.self, decoder: decoder)
            .eraseToAnyPublisher()
    }

    func rpcVoid(function: String, body: [String: Any]) -> AnyPublisher<Void, Error> {
        rpc(function: function, body: body, decodeAs: EmptyResponse.self)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}

private struct EmptyResponse: Decodable {}
