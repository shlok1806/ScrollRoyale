import Foundation

enum TelemetryEventType: String, Codable {
    case viewStart = "view_start"
    case viewEnd = "view_end"
    case scroll
    case like
}

struct TelemetryEvent: Codable, Identifiable {
    let id: UUID
    let reelId: String?
    let eventType: TelemetryEventType
    let occurredAt: Date
    let payload: [String: Double]

    init(
        id: UUID = UUID(),
        reelId: String?,
        eventType: TelemetryEventType,
        occurredAt: Date = Date(),
        payload: [String: Double] = [:]
    ) {
        self.id = id
        self.reelId = reelId
        self.eventType = eventType
        self.occurredAt = occurredAt
        self.payload = payload
    }

    var requestBody: [String: Any] {
        var body: [String: Any] = [
            "client_event_id": id.uuidString,
            "event_type": eventType.rawValue,
            "occurred_at": ISO8601DateFormatter().string(from: occurredAt),
            "payload": payload
        ]
        if let reelId {
            body["reel_id"] = reelId
        }
        return body
    }
}
