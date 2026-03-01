import Capacitor
import Combine
import Foundation

// MARK: - Codable → [String: Any] helper

private extension Encodable {
    /// Converts a Codable value to the [String: Any] dictionary Capacitor's bridge expects.
    func toCAPData() -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard
            let data = try? encoder.encode(self),
            let obj = try? JSONSerialization.jsonObject(with: data),
            let dict = obj as? [String: Any]
        else {
            return [:]
        }
        return dict
    }
}

// MARK: - Plugin

@objc(ScrollRoyalePlugin)
public class ScrollRoyalePlugin: CAPPlugin {
    private var cancellables = Set<AnyCancellable>()

    private lazy var matchmaking: MatchmakingServiceProtocol = AppServices.matchmakingService()
    private lazy var content: ContentServiceProtocol = AppServices.contentService()

    // Subscribing to publishers wires up the event listeners immediately on first access.
    private lazy var sync: SyncServiceProtocol = {
        let svc = AppServices.syncService()
        svc.gameStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.notifyListeners("gameStateUpdate", data: state.toCAPData())
            }
            .store(in: &cancellables)
        svc.scorePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                self?.notifyListeners("scoreUpdate", data: snapshot.toCAPData())
            }
            .store(in: &cancellables)
        return svc
    }()

    // MARK: Matchmaking

    @objc func createMatch(_ call: CAPPluginCall) {
        let durationSec = call.getInt("durationSec") ?? 90
        let duration = MatchDuration(rawValue: durationSec) ?? .ninety
        matchmaking.createMatch(duration: duration)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        call.reject(error.localizedDescription)
                    }
                },
                receiveValue: { match in
                    call.resolve(match.toCAPData())
                }
            )
            .store(in: &cancellables)
    }

    @objc func joinMatch(_ call: CAPPluginCall) {
        guard let code = call.getString("code") else {
            call.reject("Missing required parameter: code")
            return
        }
        matchmaking.joinMatch(withCode: code)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        call.reject(error.localizedDescription)
                    }
                },
                receiveValue: { match in
                    call.resolve(match.toCAPData())
                }
            )
            .store(in: &cancellables)
    }

    @objc func getMatch(_ call: CAPPluginCall) {
        guard let matchId = call.getString("matchId") else {
            call.reject("Missing required parameter: matchId")
            return
        }
        matchmaking.getMatch(matchId: matchId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        call.reject(error.localizedDescription)
                    }
                },
                receiveValue: { match in
                    call.resolve(match.toCAPData())
                }
            )
            .store(in: &cancellables)
    }

    @objc func leaveMatch(_ call: CAPPluginCall) {
        guard let matchId = call.getString("matchId") else {
            call.reject("Missing required parameter: matchId")
            return
        }
        matchmaking.leaveMatch(matchId: matchId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished: call.resolve()
                    case .failure(let error): call.reject(error.localizedDescription)
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    // MARK: Content

    @objc func fetchContentFeed(_ call: CAPPluginCall) {
        guard let matchId = call.getString("matchId") else {
            call.reject("Missing required parameter: matchId")
            return
        }
        content.fetchContentFeed(matchId: matchId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        call.reject(error.localizedDescription)
                    }
                },
                receiveValue: { items in
                    let encoder = JSONEncoder()
                    encoder.dateEncodingStrategy = .iso8601
                    let mapped: [[String: Any]] = items.compactMap { item in
                        guard
                            let data = try? encoder.encode(item),
                            let obj = try? JSONSerialization.jsonObject(with: data),
                            let dict = obj as? [String: Any]
                        else { return nil }
                        return dict
                    }
                    call.resolve(["items": mapped])
                }
            )
            .store(in: &cancellables)
    }

    // MARK: Sync

    @objc func connect(_ call: CAPPluginCall) {
        guard
            let matchId = call.getString("matchId"),
            let userId = call.getString("userId")
        else {
            call.reject("Missing required parameters: matchId and userId")
            return
        }
        // Accessing sync triggers lazy initialisation and publisher subscriptions.
        sync.connect(to: matchId, userId: userId)
        call.resolve()
    }

    @objc func disconnect(_ call: CAPPluginCall) {
        sync.disconnect()
    }

    @objc func sendGameState(_ call: CAPPluginCall) {
        guard let stateDict = call.getObject("state") else {
            call.reject("Missing required parameter: state")
            return
        }
        let reelId = call.getString("reelId")
        do {
            let data = try JSONSerialization.data(withJSONObject: stateDict)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let state = try decoder.decode(GameState.self, from: data)
            sync.sendGameState(state, reelId: reelId)
        } catch {
            call.reject("Invalid GameState: \(error.localizedDescription)")
            return
        }
    }

    @objc func sendTelemetry(_ call: CAPPluginCall) {
        guard
            let matchId = call.getString("matchId"),
            let eventsRaw = call.getArray("events") as? [[String: Any]]
        else {
            call.reject("Missing required parameters: matchId and events")
            return
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: eventsRaw)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let events = try decoder.decode([TelemetryEvent].self, from: data)
            sync.sendTelemetry(events: events, matchId: matchId)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished: call.resolve()
                        case .failure(let error): call.reject(error.localizedDescription)
                        }
                    },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
        } catch {
            call.reject("Invalid events payload: \(error.localizedDescription)")
        }
    }
}
