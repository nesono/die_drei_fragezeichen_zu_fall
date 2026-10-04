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
        afterUndo.toggleFavourite(1)
        afterUndo.toggleListenLater(1)
        afterUndo.toggleFavourite(2)
        let savedCollections = ListeningStore(defaults: defaults)
        precondition(savedCollections.favourites == [1, 2])
        precondition(savedCollections.listenLater == [1])
        savedCollections.markHeard(1, on: now, now: now)
        precondition(savedCollections.listenLater.contains(1), "Listening does not silently remove a saved episode")
        savedCollections.toggleFavourite(1)
        savedCollections.toggleListenLater(1)
        let removed = ListeningStore(defaults: defaults)
        precondition(removed.favourites == [2] && removed.listenLater.isEmpty)
        precondition(removed.lastListened(to: 1) == now)
        removed.toggleFavourite(-1)
        removed.toggleListenLater(0)
        precondition(removed.favourites == [2] && removed.listenLater.isEmpty)
        removed.toggleFavourite(3)
        removed.toggleListenLater(3)
        removed.markHeard(4, on: now.addingTimeInterval(-40 * 86_400), now: now)
        let ids = [1, 2, 3, 4]
        precondition(removed.eligibleIDs(ids, pool: .all, now: now) == ids)
        precondition(removed.eligibleIDs(ids, pool: .unheard, now: now) == [3])
        precondition(removed.eligibleIDs(ids, pool: .favourites, now: now) == [2, 3])
        precondition(removed.eligibleIDs(ids, pool: .later, now: now) == [3])
        precondition(removed.eligibleIDs(ids, pool: .notRecent, now: now) == [3, 4])
        precondition(removed.eligibleIDs([], pool: .all, now: now).isEmpty)
        removed.recordPlayerOpen(3, now: now)
        removed.recordPlayerOpen(3, now: now)
        let afterOpen = ListeningStore(defaults: defaults)
        precondition(afterOpen.lastListened(to: 3) == now)
        precondition(afterOpen.favourites.contains(3))
        precondition(!afterOpen.listenLater.contains(3))
        precondition(afterOpen.eligibleIDs(ids, pool: .later, now: now).isEmpty)
        let cycleSuite = "ShuffleChecks.\(UUID().uuidString)"
        let cycleDefaults = UserDefaults(suiteName: cycleSuite)!
        defer { cycleDefaults.removePersistentDomain(forName: cycleSuite) }
        let cycleIDs = [10, 20, 30, 40, 50]
        var current: Int?
        for _ in 0..<20 {
            var round = Set<Int>()
            for _ in cycleIDs {
                // Recreate the store to verify the cycle survives reopening.
                let cycleStore = ListeningStore(defaults: cycleDefaults)
                let next = cycleStore.nextSuggestionID(from: cycleIDs, pool: .all, currentID: current)!
                precondition(next != current, "No immediate repeats at cycle boundaries")
                precondition(round.insert(next).inserted, "No repeats inside a cycle")
                current = next
            }
            precondition(round == Set(cycleIDs))
        }
        let cycleStore = ListeningStore(defaults: cycleDefaults)
        cycleStore.toggleFavourite(10)
        cycleStore.toggleFavourite(20)
        let favouriteFirst = cycleStore.nextSuggestionID(from: cycleIDs, pool: .favourites, currentID: nil)!
        let favouriteSecond = cycleStore.nextSuggestionID(from: cycleIDs, pool: .favourites, currentID: favouriteFirst)!
        precondition(Set([favouriteFirst, favouriteSecond]) == [10, 20])
        precondition(cycleStore.nextSuggestionID(from: [], pool: .all, currentID: nil) == nil)
        precondition(cycleStore.nextSuggestionID(from: [10], pool: .later, currentID: nil) == nil)
        precondition(cycleStore.nextSuggestionID(from: [10], pool: .unheard, currentID: 10) == nil)
        precondition(cycleStore.nextSuggestionID(from: [10], pool: .unheard, currentID: nil) == 10)
        precondition(cycleStore.nextSuggestionID(from: [10, 20], pool: .unheard, currentID: 10) == 20)
        precondition(cycleStore.nextSuggestionID(from: [10, 20, 30], pool: .unheard, currentID: 10) == 30,
                     "Going back must not reset the cycle; newly eligible episodes join it")
        print("Shuffle-cycle checks passed: 20 complete cycles, relaunch persistence, pool isolation, empty/single pools and changing eligibility")
        let libraryIDs = [1, 2, 3, 4, 5]
        precondition(afterOpen.libraryIDs(libraryIDs, filter: .all) == libraryIDs)
        precondition(afterOpen.libraryIDs(libraryIDs, filter: .heard) == [1, 2, 3, 4])
        precondition(afterOpen.libraryIDs(libraryIDs, filter: .unheard) == [5])
        precondition(afterOpen.libraryIDs(libraryIDs, filter: .favourites) == [2, 3])
        precondition(afterOpen.libraryIDs(libraryIDs, filter: .later).isEmpty)
        afterOpen.markUnheard(3)
        precondition(afterOpen.libraryIDs(libraryIDs, filter: .heard) == [1, 2, 4])
        precondition(afterOpen.libraryIDs(libraryIDs, filter: .unheard) == [3, 5])
        precondition(afterOpen.libraryIDs([], filter: .heard).isEmpty)
        print("Library checks passed: all filters, empty collections, changes to heard status")
        print("Suggestion checks passed: all pools, empty pools, player-open removal and persistence")
        print("Collection checks passed: persistence, independent markers, removal, preserved listening status")
        print("Listening checks passed: persistence, independent episodes, date editing, future-date guard, undo")
    }
}
