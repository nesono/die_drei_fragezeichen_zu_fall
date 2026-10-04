import Foundation
import Combine

enum SuggestionPool: String, CaseIterable, Identifiable {
    case all, unheard, favourites, later, notRecent
    var id: String { rawValue }
    var title: String {
        switch self {
        case .all: "Alle Folgen"
        case .unheard: "Nur ungehörte Folgen"
        case .favourites: "Favoriten"
        case .later: "Später hören"
        case .notRecent: "Seit 30 Tagen nicht gehört"
        }
    }
}

/// Listening records are personal data, separate from disposable caches.
@MainActor
final class ListeningStore: ObservableObject {
    @Published private(set) var dates: [String: Date]
    @Published private(set) var favourites: Set<Int>
    @Published private(set) var listenLater: Set<Int>
    private let defaults: UserDefaults
    private let key = "listeningDates.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        dates = (defaults.dictionary(forKey: key) ?? [:]).compactMapValues { $0 as? Date }
        favourites = Set((defaults.array(forKey: "favourites.v1") as? [Int] ?? []).filter { $0 > 0 })
        listenLater = Set((defaults.array(forKey: "listenLater.v1") as? [Int] ?? []).filter { $0 > 0 })
    }

    func eligibleIDs(_ ids: [Int], pool: SuggestionPool, now: Date = Date()) -> [Int] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        return ids.filter { id in
            switch pool {
            case .all: true
            case .unheard: lastListened(to: id) == nil
            case .favourites: favourites.contains(id)
            case .later: listenLater.contains(id)
            case .notRecent: lastListened(to: id).map { $0 <= cutoff } ?? true
            }
        }
    }

    func recordPlayerOpen(_ episodeID: Int, now: Date = Date()) {
        guard episodeID > 0 else { return }
        markHeard(episodeID, on: now, now: now)
        listenLater.remove(episodeID)
        defaults.set(listenLater.sorted(), forKey: "listenLater.v1")
    }

    func toggleFavourite(_ episodeID: Int) {
        guard episodeID > 0 else { return }
        if !favourites.insert(episodeID).inserted { favourites.remove(episodeID) }
        defaults.set(favourites.sorted(), forKey: "favourites.v1")
    }

    func toggleListenLater(_ episodeID: Int) {
        guard episodeID > 0 else { return }
        if !listenLater.insert(episodeID).inserted { listenLater.remove(episodeID) }
        defaults.set(listenLater.sorted(), forKey: "listenLater.v1")
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
