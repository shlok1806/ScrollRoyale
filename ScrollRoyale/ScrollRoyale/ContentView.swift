import SwiftUI

struct ContentView: View {
    @State private var currentMatch: Match?
    @State private var lobbyViewModel = LobbyViewModel(matchmakingService: AppServices.matchmakingService())
    @State private var currentUserId = UUID().uuidString

    var body: some View {
        Group {
            if let match = currentMatch, match.status == .inProgress {
                GameView(
                    viewModel: GameViewModel(
                        match: match,
                        currentUserId: currentUserId,
                        contentService: AppServices.contentService(),
                        syncService: AppServices.syncService()
                    ),
                    onExit: {
                        currentMatch = nil
                        lobbyViewModel.reset()
                    }
                )
            } else {
                LobbyView(viewModel: lobbyViewModel) { match in
                    if let authenticatedUserId = SupabaseSessionStore.shared.userId {
                        currentUserId = authenticatedUserId
                    }
                    currentMatch = match
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
