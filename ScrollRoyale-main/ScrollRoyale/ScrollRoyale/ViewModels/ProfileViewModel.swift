import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var profile: ProfileSummary?
    @Published var errorMessage: String?

    private let service: ProfileServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(service: ProfileServiceProtocol = MockProfileService.shared) {
        self.service = service
    }

    func load() {
        isLoading = true
        errorMessage = nil
        service.fetchProfileSummary()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] summary in
                self?.profile = summary
            }
            .store(in: &cancellables)
    }
}
