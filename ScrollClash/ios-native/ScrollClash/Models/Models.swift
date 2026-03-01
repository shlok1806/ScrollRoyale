import SwiftUI

// MARK: - Leaderboard

struct LeaderboardPlayer: Identifiable {
    let id = UUID()
    let rank: Int
    let name: String
    let score: Int
    let badge: String
    let rotLevel: Int
}

// MARK: - Graveyard

struct GraveyardDay: Identifiable {
    let id = UUID()
    let date: String
    let rot: Int
    let streak: Int
    let flicks: Int
    let stability: Int
}

// MARK: - Boosts

enum BoostRarity: String {
    case common, rare, epic, legendary

    var color: Color {
        switch self {
        case .common:    return Color(hex: "9D9D9D")
        case .rare:      return Color(hex: "4895EF")
        case .epic:      return Color(hex: "9D4EDD")
        case .legendary: return Color(hex: "FFD60A")
        }
    }

    var glowColor: Color {
        switch self {
        case .common:    return Color.white.opacity(0.2)
        case .rare:      return Color(hex: "4895EF").opacity(0.5)
        case .epic:      return Color(hex: "9D4EDD").opacity(0.5)
        case .legendary: return Color(hex: "FFD60A").opacity(0.6)
        }
    }
}

enum BoostCategory: String, CaseIterable {
    case control, damage, utility, defense

    var displayName: String { rawValue.uppercased() }
}

struct Boost: Identifiable {
    let id: String
    let name: String
    let category: BoostCategory
    let rarity: BoostRarity
    let focusCost: Int
    let cooldown: Int
    let description: String
    let flavorText: String
    let effect: String
    var owned: Bool
    var equipped: Bool
    let iconType: String
}

// MARK: - User Profile

struct UserProfile {
    let username: String
    let level: Int
    let rank: Int
    let trophies: Int
    let winRate: Int
    let totalDuels: Int
    let bestStreak: Int
    let bestStability: Int
    let avgRot: Int
    let rankTitle: String
}

// MARK: - Duel Opponent

struct DuelOpponent {
    let name: String
    let rank: Int
    let rotLevel: Int
    let wins: Int
}

// MARK: - Badge

struct PlayerBadge: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
}

// MARK: - Brain Skin (profile display)

struct BrainSkin: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    let owned: Bool
}
