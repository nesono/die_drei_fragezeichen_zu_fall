import Foundation
import XCTest
@testable import DreiFragezeichen

final class ListeningChecks: XCTestCase {
    @MainActor func testRegressionChecks() {
        let suite = "ListeningChecks.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let earlier = now.addingTimeInterval(-86_400)
        let store = ListeningStore(defaults: defaults)
        XCTAssertTrue(store.lastListened(to: 1) == nil)
        store.markHeard(1, on: earlier, now: now)
        store.markHeard(2, on: now, now: now)
        let reopened = ListeningStore(defaults: defaults)
        XCTAssertTrue(reopened.lastListened(to: 1) == earlier)
        XCTAssertTrue(reopened.lastListened(to: 2) == now)
        reopened.markHeard(1, on: now.addingTimeInterval(86_400), now: now)
        XCTAssertTrue(reopened.lastListened(to: 1) == now, "No future listening dates")
        reopened.markHeard(1, on: earlier, now: now)
        XCTAssertTrue(reopened.lastListened(to: 1) == earlier, "Date corrections are persisted")
        reopened.markUnheard(1)
        let afterUndo = ListeningStore(defaults: defaults)
        XCTAssertTrue(afterUndo.lastListened(to: 1) == nil)
        XCTAssertTrue(afterUndo.lastListened(to: 2) == now, "Undo must not affect another episode")
        afterUndo.markHeard(-1, on: now, now: now)
        XCTAssertTrue(afterUndo.lastListened(to: -1) == nil)
        afterUndo.toggleFavourite(1)
        afterUndo.toggleListenLater(1)
        afterUndo.toggleFavourite(2)
        let savedCollections = ListeningStore(defaults: defaults)
        XCTAssertTrue(savedCollections.favourites == [1, 2])
        XCTAssertTrue(savedCollections.listenLater == [1])
        savedCollections.markHeard(1, on: now, now: now)
        XCTAssertTrue(savedCollections.listenLater.contains(1), "Listening does not silently remove a saved episode")
        savedCollections.toggleFavourite(1)
        savedCollections.toggleListenLater(1)
        let removed = ListeningStore(defaults: defaults)
        XCTAssertTrue(removed.favourites == [2] && removed.listenLater.isEmpty)
        XCTAssertTrue(removed.lastListened(to: 1) == now)
        removed.toggleFavourite(-1)
        removed.toggleListenLater(0)
        XCTAssertTrue(removed.favourites == [2] && removed.listenLater.isEmpty)
        removed.toggleFavourite(3)
        removed.toggleListenLater(3)
        removed.markHeard(4, on: now.addingTimeInterval(-40 * 86_400), now: now)
        let ids = [1, 2, 3, 4]
        XCTAssertTrue(removed.eligibleIDs(ids, pool: .all, now: now) == ids)
        XCTAssertTrue(removed.eligibleIDs(ids, pool: .unheard, now: now) == [3])
        XCTAssertTrue(removed.eligibleIDs(ids, pool: .favourites, now: now) == [2, 3])
        XCTAssertTrue(removed.eligibleIDs(ids, pool: .later, now: now) == [3])
        XCTAssertTrue(removed.eligibleIDs(ids, pool: .notRecent, now: now) == [3, 4])
        XCTAssertTrue(removed.eligibleIDs([], pool: .all, now: now).isEmpty)
        removed.recordPlayerOpen(3, now: now)
        removed.recordPlayerOpen(3, now: now)
        let afterOpen = ListeningStore(defaults: defaults)
        XCTAssertTrue(afterOpen.lastListened(to: 3) == now)
        XCTAssertTrue(afterOpen.favourites.contains(3))
        XCTAssertTrue(!afterOpen.listenLater.contains(3))
        XCTAssertTrue(afterOpen.eligibleIDs(ids, pool: .later, now: now).isEmpty)
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
                XCTAssertTrue(next != current, "No immediate repeats at cycle boundaries")
                XCTAssertTrue(round.insert(next).inserted, "No repeats inside a cycle")
                current = next
            }
            XCTAssertTrue(round == Set(cycleIDs))
        }
        let cycleStore = ListeningStore(defaults: cycleDefaults)
        cycleStore.toggleFavourite(10)
        cycleStore.toggleFavourite(20)
        let favouriteFirst = cycleStore.nextSuggestionID(from: cycleIDs, pool: .favourites, currentID: nil)!
        let favouriteSecond = cycleStore.nextSuggestionID(from: cycleIDs, pool: .favourites, currentID: favouriteFirst)!
        XCTAssertTrue(Set([favouriteFirst, favouriteSecond]) == [10, 20])
        XCTAssertTrue(cycleStore.nextSuggestionID(from: [], pool: .all, currentID: nil) == nil)
        XCTAssertTrue(cycleStore.nextSuggestionID(from: [10], pool: .later, currentID: nil) == nil)
        XCTAssertTrue(cycleStore.nextSuggestionID(from: [10], pool: .unheard, currentID: 10) == nil)
        XCTAssertTrue(cycleStore.nextSuggestionID(from: [10], pool: .unheard, currentID: nil) == 10)
        XCTAssertTrue(cycleStore.nextSuggestionID(from: [10, 20], pool: .unheard, currentID: 10) == 20)
        XCTAssertTrue(cycleStore.nextSuggestionID(from: [10, 20, 30], pool: .unheard, currentID: 10) == 30,
                     "Going back must not reset the cycle; newly eligible episodes join it")
        print("Shuffle-cycle checks passed: 20 complete cycles, relaunch persistence, pool isolation, empty/single pools and changing eligibility")
        let libraryIDs = [1, 2, 3, 4, 5]
        XCTAssertTrue(afterOpen.libraryIDs(libraryIDs, filter: .all) == libraryIDs)
        XCTAssertTrue(afterOpen.libraryIDs(libraryIDs, filter: .heard) == [1, 2, 3, 4])
        XCTAssertTrue(afterOpen.libraryIDs(libraryIDs, filter: .unheard) == [5])
        XCTAssertTrue(afterOpen.libraryIDs(libraryIDs, filter: .favourites) == [2, 3])
        XCTAssertTrue(afterOpen.libraryIDs(libraryIDs, filter: .later).isEmpty)
        afterOpen.markUnheard(3)
        XCTAssertTrue(afterOpen.libraryIDs(libraryIDs, filter: .heard) == [1, 2, 4])
        XCTAssertTrue(afterOpen.libraryIDs(libraryIDs, filter: .unheard) == [3, 5])
        XCTAssertTrue(afterOpen.libraryIDs([], filter: .heard).isEmpty)
        print("Library checks passed: all filters, empty collections, changes to heard status")
        print("Suggestion checks passed: all pools, empty pools, player-open removal and persistence")
        print("Collection checks passed: persistence, independent markers, removal, preserved listening status")
        print("Listening checks passed: persistence, independent episodes, date editing, future-date guard, undo")
    }
}
