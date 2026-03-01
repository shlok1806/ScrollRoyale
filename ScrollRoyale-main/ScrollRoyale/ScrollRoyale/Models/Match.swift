import Foundation

/// Represents a 1v1 competitive scrolling match
struct Match: Identifiable, Codable, Equatable {
    let id: String
    let matchCode: String?
    let player1Id: String
    let player2Id: String?
    var status: MatchStatus
    let createdAt: Date
    var startedAt: Date?
    var endedAt: Date?
    let durationSec: Int
    let contentFeedIds: [String]

    enum MatchStatus: String, Codable, Equatable {
        case waiting
        case inProgress
        case ended

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            switch raw {
            case "waiting":
                self = .waiting
            case "in_progress", "inProgress":
                self = .inProgress
            case "ended":
                self = .ended
            default:
                self = .waiting
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .waiting: try container.encode("waiting")
            case .inProgress: try container.encode("in_progress")
            case .ended: try container.encode("ended")
            }
        }
    }

    var isReady: Bool {
        player2Id != nil && status == .waiting
    }
}

/// Represents a player in a match
struct Player: Identifiable, Codable, Equatable {
    let id: String
    let displayName: String
}
