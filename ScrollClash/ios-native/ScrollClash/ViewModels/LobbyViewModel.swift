import Foundation
import Combine
import os

@MainActor
final class LobbyViewModel: ObservableObject {
    private static let logger = Logger(subsystem: "com.scrollroyale.app", category: "LobbyViewModel")

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
        Self.logger.info("LobbyViewModel init — service: \(String(describing: type(of: matchmakingService)), privacy: .public)")
    }

    func createMatch() {
        Self.logger.info("createMatch() called — duration: \(self.selectedDuration.rawValue, privacy: .public)s")
        isLoading = true
        errorMessage = nil
        statusMessage = "Creating your match..."
        mode = .hosting

        matchmakingService.createMatch(duration: selectedDuration)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    Self.logger.error("createMatch FAILED: \(error.localizedDescription, privacy: .public)")
                    self?.errorMessage = self?.friendlyErrorMessage(error) ?? error.localizedDescription
                    self?.mode = .idle
                }
            } receiveValue: { [weak self] match in
                Self.logger.info("createMatch SUCCESS — matchId: \(match.id, privacy: .public) code: \(match.matchCode ?? "nil", privacy: .public) status: \(match.status.rawValue, privacy: .public)")
                self?.currentMatch = match
                self?.hostedMatchCode = match.matchCode ?? ""
                self?.statusMessage = "Share this code. Match starts when opponent joins."
                self?.hostingStartedAt = Date()
                self?.startPollingMatchState(matchId: match.id)
            }
            .store(in: &cancellables)
    }

    func beginJoinFlow() {
        Self.logger.info("beginJoinFlow() — switching mode to .joining")
        mode = .joining
        errorMessage = nil
    }

    func backToIdle() {
        Self.logger.info("backToIdle() called")
        mode = .idle
        errorMessage = nil
        joinCodeInput = ""
        statusMessage = ""
    }

    func joinMatchWithCode() {
        let code = normalizedJoinCode
        Self.logger.info("joinMatchWithCode() — code: \(code, privacy: .public) (raw: \(self.joinCodeInput, privacy: .public))")
        guard code.count == 6 else {
            Self.logger.warning("joinMatchWithCode: code '\(code, privacy: .public)' is not 6 chars, aborting")
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
                    Self.logger.error("joinMatch FAILED for code '\(code, privacy: .public)': \(error.localizedDescription, privacy: .public)")
                    self?.errorMessage = self?.friendlyErrorMessage(error) ?? error.localizedDescription
                    self?.statusMessage = ""
                }
            } receiveValue: { [weak self] match in
                Self.logger.info("joinMatch SUCCESS — matchId: \(match.id, privacy: .public) status: \(match.status.rawValue, privacy: .public) player2Id: \(match.player2Id ?? "nil", privacy: .public)")
                self?.currentMatch = match
                self?.statusMessage = "Match joined. Starting..."
                // If joinMatch already returned inProgress (the happy path), the
                // onChange handler transitions us immediately — no polling needed.
                // Only start polling if the status is still waiting (timing race edge case).
                if match.status != .inProgress {
                    Self.logger.info("joinMatch: status not inProgress yet, starting poll fallback")
                    self?.startPollingMatchState(matchId: match.id)
                } else {
                    Self.logger.info("joinMatch: status already inProgress, skipping poller")
                }
            }
            .store(in: &cancellables)
    }

    func cancelHostedMatch() {
        guard let matchId = currentMatch?.id else {
            backToIdle()
            return
        }
        Self.logger.info("cancelHostedMatch() — matchId: \(matchId, privacy: .public)")
        matchmakingService.leaveMatch(matchId: matchId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.backToIdle()
            } receiveValue: { _ in
            }
            .store(in: &cancellables)
    }

    func reset() {
        Self.logger.info("reset() — cancelling matchPoller and clearing state")
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
        matchPoller = nil
        Self.logger.info("startPollingMatchState — matchId: \(matchId, privacy: .public)")

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

                Self.logger.debug("poll tick — matchId: \(match.id, privacy: .public) status: \(match.status.rawValue, privacy: .public) player2Id: \(match.player2Id ?? "nil", privacy: .public)")

                // CRITICAL: never let a poll result downgrade a match that is already
                // confirmed inProgress. This prevents mock/stale get_match responses
                // from erasing the confirmed inProgress state set by joinMatch.
                if self.currentMatch?.status == .inProgress && match.status == .waiting {
                    Self.logger.warning("poll: ignoring stale waiting response — match already inProgress, stopping poller")
                    DispatchQueue.main.async { [weak self] in
                        self?.matchPoller?.cancel()
                        self?.matchPoller = nil
                    }
                    return
                }

                // Hosting timeout check
                if
                    let started = self.hostingStartedAt,
                    Date().timeIntervalSince(started) >= self.hostingTimeoutSeconds,
                    match.status == .waiting
                {
                    Self.logger.warning("Hosting timeout for matchId \(match.id, privacy: .public) — no opponent joined in time")
                    self.errorMessage = "No opponent joined in time. Please create a new match."
                    self.cancelHostedMatch()
                    DispatchQueue.main.async { [weak self] in
                        self?.matchPoller?.cancel()
                        self?.matchPoller = nil
                    }
                    return
                }

                self.currentMatch = match
                if match.status == .inProgress {
                    Self.logger.info("Match \(match.id, privacy: .public) is now inProgress — stopping poller")
                    self.statusMessage = "Opponent joined. Starting match..."
                    DispatchQueue.main.async { [weak self] in
                        self?.matchPoller?.cancel()
                        self?.matchPoller = nil
                    }
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
