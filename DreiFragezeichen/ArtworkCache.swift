import Foundation
import CryptoKit
import ImageIO

/// Artwork has no expiry. Only images actually requested by a view are stored.
actor ArtworkCache {
    static let shared = ArtworkCache()

    private let directory: URL
    private let fetch: (URL) async throws -> Data
    private let memory = NSCache<NSURL, NSData>()
    private var generation = 0
    private var pending: [URL: Task<Data, Error>] = [:]

    init(
        directory: URL = URL.applicationSupportDirectory.appendingPathComponent("Artwork", isDirectory: true),
        fetch: @escaping (URL) async throws -> Data = ArtworkCache.download
    ) {
        self.directory = directory
        self.fetch = fetch
        memory.totalCostLimit = 32 * 1024 * 1024
    }

    func data(for url: URL) async throws -> Data {
        if let data = memory.object(forKey: url as NSURL) { return data as Data }
        if let task = pending[url] { return try await task.value }

        let filename = SHA256.hash(data: Data(url.absoluteString.utf8))
            .map { String(format: "%02x", $0) }.joined()
        let file = directory.appendingPathComponent(filename)
        if let data = try? Data(contentsOf: file), Self.isImage(data) {
            memory.setObject(data as NSData, forKey: url as NSURL, cost: data.count)
            return data
        }

        // Sharing this task avoids duplicate downloads during rotation or quick
        // history navigation. Leaving the view does not cancel a useful download.
        let requestGeneration = generation
        let fetch = self.fetch
        let task = Task {
            let data = try await fetch(url)
            guard Self.isImage(data) else { throw URLError(.cannotDecodeContentData) }
            return data
        }
        pending[url] = task
        defer { if generation == requestGeneration { pending[url] = nil } }
        let data = try await task.value
        guard generation == requestGeneration else { throw CancellationError() }
        memory.setObject(data as NSData, forKey: url as NSURL, cost: data.count)
        // A disk-write failure must not prevent showing the downloaded cover.
        try? save(data, to: file)
        return data
    }

    func clear() throws {
        generation += 1
        for task in pending.values { task.cancel() }
        pending.removeAll()
        memory.removeAllObjects()
        if FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.removeItem(at: directory)
        }
    }

    func image(for url: URL, maxPixelSize: Int) async throws -> CGImage {
        let data = try await data(for: url)
        guard let image = Self.downsample(data, maxPixelSize: maxPixelSize) else {
            throw URLError(.cannotDecodeContentData)
        }
        return image
    }

    static func downsample(_ data: Data, maxPixelSize: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData,
            [kCGImageSourceShouldCache: false] as CFDictionary) else { return nil }
        return CGImageSourceCreateThumbnailAtIndex(source, 0, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary)
    }

    private func save(_ data: Data, to file: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var folder = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? folder.setResourceValues(values)
        try data.write(to: file, options: .atomic)
    }

    private static func isImage(_ data: Data) -> Bool {
        downsample(data, maxPixelSize: 1) != nil
    }

    static func download(_ url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url, timeoutInterval: 20))
        guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}
