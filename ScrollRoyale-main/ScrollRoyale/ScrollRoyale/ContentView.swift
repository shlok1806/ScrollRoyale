import SwiftUI

struct ContentView: View {
    enum AppTab: Hashable {
        case play
        case leaderboard
        case profile
    }

    @State private var selectedTab: AppTab = .play
    @State private var currentMatch: Match?
    @StateObject private var lobbyViewModel: LobbyViewModel
    @StateObject private var leaderboardViewModel: LeaderboardViewModel
    @StateObject private var profileViewModel: ProfileViewModel
    @State private var currentUserId = UUID().uuidString

    init() {
        _lobbyViewModel = StateObject(
            wrappedValue: LobbyViewModel(matchmakingService: AppServices.matchmakingService())
        )
        _leaderboardViewModel = StateObject(
            wrappedValue: LeaderboardViewModel(service: AppServices.leaderboardService())
        )
        _profileViewModel = StateObject(
            wrappedValue: ProfileViewModel(service: AppServices.profileService())
        )
    }

    var body: some View {
        TabView(selection: $selectedTab) {
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
                .tag(AppTab.play)
                .tabItem {
                    Label("Play", systemImage: "gamecontroller.fill")
                }
            } else {
                LobbyView(viewModel: lobbyViewModel) { match in
                    if let authenticatedUserId = SupabaseSessionStore.shared.userId {
                        currentUserId = authenticatedUserId
                    }
                    currentMatch = match
                }
                .tag(AppTab.play)
                .tabItem {
                    Label("Play", systemImage: "gamecontroller.fill")
                }
            }

            LeaderboardView(viewModel: leaderboardViewModel)
                .tag(AppTab.leaderboard)
                .tabItem {
                    Label("Leaderboard", systemImage: "list.number")
                }

            ProfileView(viewModel: profileViewModel)
                .tag(AppTab.profile)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}
