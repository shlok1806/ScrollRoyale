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
}
