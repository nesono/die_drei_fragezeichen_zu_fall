import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

actor Downloads {
    var count = 0
    let image: Data
    init(image: Data) { self.image = image }
    func fetch(_ url: URL) async throws -> Data {
        count += 1
        try await Task.sleep(nanoseconds: 30_000_000)
        return image
    }
}

@main
struct ArtworkCacheChecks {
    static func main() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let context = CGContext(data: nil, width: 2, height: 2, bitsPerComponent: 8,
                                bytesPerRow: 8, space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        let output = NSMutableData()
        let destination = CGImageDestinationCreateWithData(output, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, context.makeImage()!, nil)
        precondition(CGImageDestinationFinalize(destination))
        let image = output as Data
        let downloads = Downloads(image: image)
        let cache = ArtworkCache(directory: directory, fetch: { try await downloads.fetch($0) })
        let url = URL(string: "https://example.org/episode.png")!
        async let first = cache.data(for: url)
        async let second = cache.data(for: url)
        let results = try await [first, second]
        precondition(results == [image, image])
        let count = await downloads.count
        precondition(count == 1, "Concurrent requests must share one download")
        let memory = try await cache.data(for: url)
        precondition(memory == image)
        let afterMemory = await downloads.count
        precondition(afterMemory == 1)
        let reopened = ArtworkCache(directory: directory) { _ in throw URLError(.notConnectedToInternet) }
        let disk = try await reopened.data(for: url)
        precondition(disk == image, "Saved images must load after relaunch while offline")
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        precondition(files.count == 1)
        try Data("corrupt".utf8).write(to: files[0])
        let repaired = ArtworkCache(directory: directory, fetch: { try await downloads.fetch($0) })
        let recovered = try await repaired.data(for: url)
        precondition(recovered == image)
        let afterRepair = await downloads.count
        precondition(afterRepair == 2)
        let invalidDownloads = Downloads(image: Data("not an image".utf8))
        let invalid = ArtworkCache(directory: directory, fetch: { try await invalidDownloads.fetch($0) })
        let invalidURL = URL(string: "https://example.org/broken.png")!
        for _ in 0..<2 {
            do {
                _ = try await invalid.data(for: invalidURL)
                preconditionFailure("Invalid images must not be cached")
            } catch let error as URLError {
                precondition(error.code == .cannotDecodeContentData)
            }
        }
        let failedAttempts = await invalidDownloads.count
        precondition(failedAttempts == 2, "A failed request must be retryable")
        let finalFiles = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        precondition(finalFiles.count == 1)
        print("Artwork cache checks passed: shared requests, memory reuse, offline persistence, corruption recovery, invalid-image rejection and retry")
    }
}
