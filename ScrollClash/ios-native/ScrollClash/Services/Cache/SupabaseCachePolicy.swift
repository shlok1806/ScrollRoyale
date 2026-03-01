import Foundation

struct SupabaseCachePolicy {
    let feedTTL: TimeInterval
    let scoreTTL: TimeInterval
    let resolvedURLTTL: TimeInterval

    static let `default` = SupabaseCachePolicy(
        feedTTL: 30,
        scoreTTL: 1.0,
        resolvedURLTTL: 600
    )
}
