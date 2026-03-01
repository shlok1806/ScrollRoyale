import Foundation

/// Represents a single video item in the scroll feed
struct ContentItem: Identifiable, Codable, Equatable {
    let id: String
    let videoURL: URL
    let duration: TimeInterval
    let order: Int
    var thumbnailURL: URL?

    enum CodingKeys: String, CodingKey {
        case id
        case videoURL = "video_url"
        case duration
        case order
        case thumbnailURL = "thumbnail_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        videoURL = try container.decode(URL.self, forKey: .videoURL)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        order = try container.decode(Int.self, forKey: .order)
        thumbnailURL = try container.decodeIfPresent(URL.self, forKey: .thumbnailURL)
    }

    init(id: String, videoURL: URL, duration: TimeInterval, order: Int, thumbnailURL: URL? = nil) {
        self.id = id
        self.videoURL = videoURL
        self.duration = duration
        self.order = order
        self.thumbnailURL = thumbnailURL
    }
}
