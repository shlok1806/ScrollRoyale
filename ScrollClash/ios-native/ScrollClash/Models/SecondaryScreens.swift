import Foundation

struct LeaderboardEntry: Identifiable, Decodable, Equatable {
    let userId: String
    let displayName: String
    let wins: Int
    let averageScore: Double

    var id: String { userId }
}

struct ProfileSummary: Decodable, Equatable {
    let userId: String
    let displayName: String
    let matchesPlayed: Int
    let wins: Int
    let bestScore: Double
}
