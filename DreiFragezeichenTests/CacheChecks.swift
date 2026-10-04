import Foundation
import XCTest
@testable import DreiFragezeichen

final class CacheChecks: XCTestCase {
    func testRegressionChecks() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("catalogue.json")
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let original = Data(#"{"serie":[{"nummer":1,"titel":"First"}]}"#.utf8)
        let updated = Data(#"{"serie":[{"nummer":2,"titel":"Updated"}]}"#.utf8)
        var requests = 0
        let service = EpisodeService(cacheURL: file) {
            requests += 1
            return original
        }
        do {
            _ = try await service.load(now: now, allowNetwork: false)
            XCTFail("First download must require consent")
        } catch CatalogueError.downloadRequired {}
        XCTAssertTrue(requests == 0)
        let first = try await service.load(now: now)
        XCTAssertTrue(first.first?.nummer == 1 && requests == 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
        // A new service instance simulates reopening the app.
        let reopened = EpisodeService(cacheURL: file) {
            requests += 1
            return updated
        }
        let existing = try await reopened.load(now: now.addingTimeInterval(172_800), allowNetwork: false)
        XCTAssertTrue(existing.first?.nummer == 1 && requests == 1)
        let fresh = try await reopened.load(now: now.addingTimeInterval(86_399))
        XCTAssertTrue(fresh.first?.nummer == 1 && requests == 1)
        let refreshed = try await reopened.load(now: now.addingTimeInterval(86_400))
        XCTAssertTrue(refreshed.first?.nummer == 2 && requests == 2)
        let offline = EpisodeService(cacheURL: file) { throw URLError(.notConnectedToInternet) }
        let fallback = try await offline.load(now: now.addingTimeInterval(172_800))
        XCTAssertTrue(fallback.first?.nummer == 2)
        let bad = EpisodeService(cacheURL: file) { Data("bad json".utf8) }
        let kept = try await bad.load(now: now.addingTimeInterval(172_800))
        XCTAssertTrue(kept.first?.nummer == 2)
        let empty = EpisodeService(cacheURL: file) { Data(#"{"serie":[]}"#.utf8) }
        let keptAfterEmpty = try await empty.load(now: now.addingTimeInterval(172_800))
        XCTAssertTrue(keptAfterEmpty.first?.nummer == 2)
        let cancelled = EpisodeService(cacheURL: file) { throw CancellationError() }
        do {
            _ = try await cancelled.load(now: now.addingTimeInterval(172_800))
            XCTFail("Cancellation must propagate")
        } catch is CancellationError {}
        try Data("corrupted cache".utf8).write(to: file)
        let recovered = try await service.load(now: now)
        XCTAssertTrue(recovered.first?.nummer == 1 && requests == 3)
        try FileManager.default.removeItem(at: file)
        do {
            _ = try await offline.load(now: now)
            XCTFail("First launch offline must report failure")
        } catch let error as URLError {
            XCTAssertTrue(error.code == .notConnectedToInternet)
        }
        print("Cache checks passed: persistence, freshness, refresh, offline fallback, invalid responses, cancellation, corruption, first launch")
    }
}
