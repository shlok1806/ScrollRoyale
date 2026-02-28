import Foundation

/// Real-time game state synced between players
struct GameState: Codable, Equatable {
    var scrollOffset: Double
    var scrollVelocity: Double
    var currentVideoIndex: Int
    var videoPlaybackTime: Double
    var lastUpdated: Date
    var player1Score: Double?
    var player2Score: Double?

    static let initial = GameState(
        scrollOffset: 0,
        scrollVelocity: 0,
        currentVideoIndex: 0,
        videoPlaybackTime: 0,
        lastUpdated: Date(),
        player1Score: 0,
        player2Score: 0
    )
}
