import Foundation

/// Chooses Supabase-backed services when configuration is present.
enum AppServices {
    private static var supabaseBundle: (SupabaseClient, SupabaseAuthService)? {
        guard let config = SupabaseConfiguration.fromBundle else {
            return nil
        }
        let client = SupabaseClient(configuration: config)
        let authService = SupabaseAuthService(configuration: config)
        return (client, authService)
    }

    static func matchmakingService() -> MatchmakingServiceProtocol {
        guard let (client, authService) = supabaseBundle else {
            return MockMatchmakingService.shared
        }
        return SupabaseMatchmakingService(client: client, authService: authService)
    }

    static func contentService() -> ContentServiceProtocol {
        guard let (client, authService) = supabaseBundle else {
            return MockContentService.shared
        }
        return SupabaseContentService(client: client, authService: authService)
    }

    static func syncService() -> SyncServiceProtocol {
        guard let (client, authService) = supabaseBundle else {
            return MockSyncService.shared
        }
        return SupabaseSyncService(client: client, authService: authService)
    }

    static func leaderboardService() -> LeaderboardServiceProtocol {
        guard let (client, authService) = supabaseBundle else {
            return MockLeaderboardService.shared
        }
        return SupabaseLeaderboardService(client: client, authService: authService)
    }

    static func profileService() -> ProfileServiceProtocol {
        guard let (client, authService) = supabaseBundle else {
            return MockProfileService.shared
        }
        return SupabaseProfileService(client: client, authService: authService)
    }

    /// Content service for the demo arena — fetches directly from the reels table,
    /// no auth required. Falls back to MockContentService if Supabase isn't configured.
    static func demoContentService() -> ContentServiceProtocol {
        guard let (client, _) = supabaseBundle else {
            return MockContentService.shared
        }
        return DemoContentService(client: client, limit: 12)
    }
}
