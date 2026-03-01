import Foundation
import os

final class SupabaseCacheStore {
    static let shared = SupabaseCacheStore()

    private static let logger = Logger(subsystem: "com.scrollroyale.app", category: "SupabaseCache")

    private struct TimedEntry<Value> {
        let value: Value
        let expiresAt: Date

        var isExpired: Bool {
            Date() >= expiresAt
        }
    }

    private struct PersistedFeedEntry: Codable {
        let items: [ContentItem]
        let expiresAt: Date
    }

    private let queue = DispatchQueue(label: "supabase.cache.store", attributes: .concurrent)
    private let policy: SupabaseCachePolicy

    private var feedEntries: [String: TimedEntry<[ContentItem]>] = [:]
    private var scoreEntries: [String: TimedEntry<ScoreSnapshot>] = [:]
    private var resolvedURLEntries: [String: TimedEntry<URL>] = [:]

    init(policy: SupabaseCachePolicy = .default) {
        self.policy = policy
    }

    func feed(matchId: String) -> [ContentItem]? {
        if let memory = getFeedEntry(matchId: matchId) {
            return memory
        }
        guard let disk = readPersistedFeed(matchId: matchId) else {
            return nil
        }
        setFeed(disk, matchId: matchId)
        return disk
    }

    func setFeed(_ items: [ContentItem], matchId: String) {
        setFeedEntry(items, matchId: matchId, ttl: policy.feedTTL)
        persistFeed(items, matchId: matchId, ttl: policy.feedTTL)
    }

    func score(matchId: String, userId: String) -> ScoreSnapshot? {
        getScoreEntry(matchId: matchId, userId: userId)
    }

    func setScore(_ snapshot: ScoreSnapshot) {
        setScoreEntry(snapshot, ttl: policy.scoreTTL)
    }

    func resolvedURL(for key: String) -> URL? {
        getResolvedURLEntry(for: key)
    }

    func setResolvedURL(_ url: URL, key: String) {
        setResolvedURLEntry(url, key: key, ttl: policy.resolvedURLTTL)
    }

    func invalidateFeed(matchId: String) {
        queue.async(flags: .barrier) {
            self.feedEntries.removeValue(forKey: matchId)
        }
        removePersistedFeed(matchId: matchId)
    }

    private func scoreKey(matchId: String, userId: String) -> String {
        "\(matchId)|\(userId)"
    }

    private func getFeedEntry(matchId: String) -> [ContentItem]? {
        var result: [ContentItem]?
        queue.sync {
            guard let entry = feedEntries[matchId], !entry.isExpired else { return }
            result = entry.value
        }
        if result == nil {
            queue.async(flags: .barrier) {
                if let entry = self.feedEntries[matchId], entry.isExpired {
                    self.feedEntries.removeValue(forKey: matchId)
                }
            }
        }
        return result
    }

    private func setFeedEntry(_ items: [ContentItem], matchId: String, ttl: TimeInterval) {
        let entry = TimedEntry(value: items, expiresAt: Date().addingTimeInterval(ttl))
        queue.async(flags: .barrier) {
            self.feedEntries[matchId] = entry
        }
    }

    private func getScoreEntry(matchId: String, userId: String) -> ScoreSnapshot? {
        let key = scoreKey(matchId: matchId, userId: userId)
        var result: ScoreSnapshot?
        queue.sync {
            guard let entry = scoreEntries[key], !entry.isExpired else { return }
            result = entry.value
        }
        if result == nil {
            queue.async(flags: .barrier) {
                if let entry = self.scoreEntries[key], entry.isExpired {
                    self.scoreEntries.removeValue(forKey: key)
                }
            }
        }
        return result
    }

    private func setScoreEntry(_ snapshot: ScoreSnapshot, ttl: TimeInterval) {
        let key = scoreKey(matchId: snapshot.matchId, userId: snapshot.userId)
        let entry = TimedEntry(value: snapshot, expiresAt: Date().addingTimeInterval(ttl))
        queue.async(flags: .barrier) {
            self.scoreEntries[key] = entry
        }
    }

    private func getResolvedURLEntry(for key: String) -> URL? {
        var result: URL?
        queue.sync {
            guard let entry = resolvedURLEntries[key], !entry.isExpired else { return }
            result = entry.value
        }
        if result == nil {
            queue.async(flags: .barrier) {
                if let entry = self.resolvedURLEntries[key], entry.isExpired {
                    self.resolvedURLEntries.removeValue(forKey: key)
                }
            }
        }
        return result
    }

    private func setResolvedURLEntry(_ url: URL, key: String, ttl: TimeInterval) {
        let entry = TimedEntry(value: url, expiresAt: Date().addingTimeInterval(ttl))
        queue.async(flags: .barrier) {
            self.resolvedURLEntries[key] = entry
        }
    }

    private func cacheDirectory() -> URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("supabase-cache", isDirectory: true)
    }

    private func feedFileURL(matchId: String) -> URL? {
        cacheDirectory()?.appendingPathComponent("feed-\(matchId).json")
    }

    private func persistFeed(_ items: [ContentItem], matchId: String, ttl: TimeInterval) {
        guard let dir = cacheDirectory(), let url = feedFileURL(matchId: matchId) else { return }
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let payload = PersistedFeedEntry(items: items, expiresAt: Date().addingTimeInterval(ttl))
            let data = try JSONEncoder().encode(payload)
            try data.write(to: url, options: .atomic)
        } catch {
            Self.logger.debug("Unable to persist feed cache: \(String(describing: error), privacy: .public)")
        }
    }

    private func readPersistedFeed(matchId: String) -> [ContentItem]? {
        guard let url = feedFileURL(matchId: matchId), FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let payload = try JSONDecoder().decode(PersistedFeedEntry.self, from: data)
            if payload.expiresAt <= Date() {
                try? FileManager.default.removeItem(at: url)
                return nil
            }
            return payload.items
        } catch {
            Self.logger.debug("Unable to read persisted feed cache: \(String(describing: error), privacy: .public)")
            return nil
        }
    }

    private func removePersistedFeed(matchId: String) {
        guard let url = feedFileURL(matchId: matchId) else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
