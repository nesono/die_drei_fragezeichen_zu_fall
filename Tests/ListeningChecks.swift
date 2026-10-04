import Foundation

@main
struct ListeningChecks {
    @MainActor static func main() {
        let suite = "ListeningChecks.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let earlier = now.addingTimeInterval(-86_400)
        let store = ListeningStore(defaults: defaults)
        precondition(store.lastListened(to: 1) == nil)
        store.markHeard(1, on: earlier, now: now)
        store.markHeard(2, on: now, now: now)
        let reopened = ListeningStore(defaults: defaults)
        precondition(reopened.lastListened(to: 1) == earlier)
        precondition(reopened.lastListened(to: 2) == now)
        reopened.markHeard(1, on: now.addingTimeInterval(86_400), now: now)
        precondition(reopened.lastListened(to: 1) == now, "No future listening dates")
        reopened.markHeard(1, on: earlier, now: now)
        precondition(reopened.lastListened(to: 1) == earlier, "Date corrections are persisted")
        reopened.markUnheard(1)
        let afterUndo = ListeningStore(defaults: defaults)
        precondition(afterUndo.lastListened(to: 1) == nil)
        precondition(afterUndo.lastListened(to: 2) == now, "Undo must not affect another episode")
        afterUndo.markHeard(-1, on: now, now: now)
        precondition(afterUndo.lastListened(to: -1) == nil)
        print("Listening checks passed: persistence, independent episodes, date editing, future-date guard, undo")
    }
}
