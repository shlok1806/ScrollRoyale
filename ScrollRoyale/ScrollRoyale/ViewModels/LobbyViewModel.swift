import Foundation
import Combine

@MainActor
final class LobbyViewModel: ObservableObject {
    enum LobbyMode {
        case idle
        case joining
        case hosting
    }

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentMatch: Match?
    @Published var mode: LobbyMode = .idle
    @Published var selectedDuration: MatchDuration = .ninety
    @Published var joinCodeInput = ""
    @Published var hostedMatchCode = ""
    @Published var statusMessage = ""

    private let matchmakingService: MatchmakingServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var matchPoller: AnyCancellable?
    private var hostingStartedAt: Date?
    private let hostingTimeoutSeconds: TimeInterval = 60

    init(matchmakingService: MatchmakingServiceProtocol = MockMatchmakingService.shared) {
        self.matchmakingService = matchmakingService
    }

    func createMatch() {
        isLoading = true
        errorMessage = nil
        statusMessage = "Creating your match..."
        mode = .hosting

        matchmakingService.createMatch(duration: selectedDuration)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = self?.friendlyErrorMessage(error) ?? error.localizedDescription
                    self?.mode = .idle
                }
            } receiveValue: { [weak self] match in
                self?.currentMatch = match
                self?.hostedMatchCode = match.matchCode ?? ""
                self?.statusMessage = "Share this code. Match starts when opponent joins."
                self?.hostingStartedAt = Date()
                self?.startPollingMatchState(matchId: match.id)
            }
            .store(in: &cancellables)
    }

    func beginJoinFlow() {
        mode = .joining
        errorMessage = nil
    }

    func backToIdle() {
        mode = .idle
        errorMessage = nil
        joinCodeInput = ""
        statusMessage = ""
    }

    func joinMatchWithCode() {
        let code = normalizedJoinCode
        guard code.count == 6 else {
            errorMessage = "Enter a valid 6-character match code."
            return
        }

        isLoading = true
        errorMessage = nil
        statusMessage = "Joining match..."

        matchmakingService.joinMatch(withCode: code)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = self?.friendlyErrorMessage(error) ?? error.localizedDescription
                    self?.statusMessage = ""
                }
            } receiveValue: { [weak self] match in
                self?.currentMatch = match
                self?.statusMessage = "Match joined. Starting..."
            }
            .store(in: &cancellables)
    }

    func cancelHostedMatch() {
        guard let matchId = currentMatch?.id else {
            backToIdle()
            return
        }
        matchmakingService.leaveMatch(matchId: matchId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.backToIdle()
            } receiveValue: { _ in
            }
            .store(in: &cancellables)
    }

    func reset() {
        matchPoller?.cancel()
        matchPoller = nil
        hostingStartedAt = nil
        currentMatch = nil
        hostedMatchCode = ""
        joinCodeInput = ""
        statusMessage = ""
        mode = .idle
        errorMessage = nil
    }

    var normalizedJoinCode: String {
        joinCodeInput
            .uppercased()
            .filter { $0.isLetter || $0.isNumber }
            .prefix(6)
            .description
    }

    private func startPollingMatchState(matchId: String) {
        matchPoller?.cancel()
        matchPoller = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .flatMap { [weak self] _ -> AnyPublisher<Match, Never> in
                guard let self else {
                    return Empty().eraseToAnyPublisher()
                }
                return self.matchmakingService.getMatch(matchId: matchId)
                    .replaceError(with: Match(
                        id: matchId,
                        matchCode: self.hostedMatchCode,
                        player1Id: self.currentMatch?.player1Id ?? "",
                        player2Id: self.currentMatch?.player2Id,
                        status: .waiting,
                        createdAt: self.currentMatch?.createdAt ?? Date(),
                        startedAt: nil,
                        endedAt: nil,
                        durationSec: self.currentMatch?.durationSec ?? MatchDuration.ninety.rawValue,
                        contentFeedIds: self.currentMatch?.contentFeedIds ?? []
                    ))
                    .eraseToAnyPublisher()
            }
            .sink { [weak self] match in
                guard let self else { return }
                if
                    let started = self.hostingStartedAt,
                    Date().timeIntervalSince(started) >= self.hostingTimeoutSeconds,
                    match.status == .waiting
                {
                    self.errorMessage = "No opponent joined in time. Please create a new match."
                    self.cancelHostedMatch()
                    self.matchPoller?.cancel()
                    self.matchPoller = nil
                    return
                }

                self.currentMatch = match
                if match.status == .inProgress {
                    self.statusMessage = "Opponent joined. Starting match..."
                    self.matchPoller?.cancel()
                    self.matchPoller = nil
                }
            }
    }

    private func friendlyErrorMessage(_ error: Error) -> String {
        let raw = error.localizedDescription.lowercased()
        if raw.contains("match full") {
            return "That match is already full."
        }
        if raw.contains("invalid or unavailable match code")
            || (raw.contains("match code") && raw.contains("invalid"))
            || (raw.contains("match code") && raw.contains("unavailable"))
        {
            return "Match code is invalid, expired, or unavailable."
        }
        if raw.contains("create match succeeded but no valid match code was returned") {
            return "Supabase schema is out of date. Apply the latest SQL files, then try again."
        }
        if raw.contains("pgrst202")
            || raw.contains("could not find the function public.create_match_with_code")
        {
            return "Supabase is missing the latest matchmaking RPCs. Run supabase/sql/003_functions.sql in the Supabase SQL Editor, then retry."
        }
        return error.localizedDescription
    }
}

private extension Character {
    var isLetter: Bool {
        unicodeScalars.allSatisfy(CharacterSet.letters.contains)
    }

    var isNumber: Bool {
        unicodeScalars.allSatisfy(CharacterSet.decimalDigits.contains)
    }
}
