import Foundation
import Combine

@MainActor
final class LeaderboardViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var entries: [LeaderboardEntry] = []
    @Published var errorMessage: String?

    private let service: LeaderboardServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(service: LeaderboardServiceProtocol = MockLeaderboardService.shared) {
        self.service = service
    }

    func load() {
        isLoading = true
        errorMessage = nil
        service.fetchTopPlayers(limit: 20)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] entries in
                self?.entries = entries
            }
            .store(in: &cancellables)
    }
}
