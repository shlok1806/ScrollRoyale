import Foundation

struct ScoreSnapshot: Codable, Equatable {
    let matchId: String
    let userId: String
    let score: Double
    let metrics: [String: Double]
    let snapshotAt: Date
}
