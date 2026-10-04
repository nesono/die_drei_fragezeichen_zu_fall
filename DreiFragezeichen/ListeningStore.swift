import Foundation
import Combine

/// Listening records are personal data, separate from disposable caches.
@MainActor
final class ListeningStore: ObservableObject {
    @Published private(set) var dates: [String: Date]
    private let defaults: UserDefaults
    private let key = "listeningDates.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        dates = (defaults.dictionary(forKey: key) ?? [:]).compactMapValues { $0 as? Date }
    }

    func lastListened(to episodeID: Int) -> Date? { dates[String(episodeID)] }

    func markHeard(_ episodeID: Int, on date: Date = Date(), now: Date = Date()) {
        guard episodeID > 0 else { return }
        dates[String(episodeID)] = min(date, now)
        defaults.set(dates, forKey: key)
    }

    func markUnheard(_ episodeID: Int) {
        dates.removeValue(forKey: String(episodeID))
        defaults.set(dates, forKey: key)
    }
}
