import Foundation
import CryptoKit
import ImageIO

/// Artwork has no expiry. Only images actually requested by a view are stored.
actor ArtworkCache {
    static let shared = ArtworkCache()

    private let directory: URL
    private let fetch: (URL) async throws -> Data
    private let memory = NSCache<NSURL, NSData>()
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
        let fetch = self.fetch
        let task = Task {
            let data = try await fetch(url)
            guard Self.isImage(data) else { throw URLError(.cannotDecodeContentData) }
            return data
        }
        pending[url] = task
        defer { pending[url] = nil }
        let data = try await task.value
        memory.setObject(data as NSData, forKey: url as NSURL, cost: data.count)
        // A disk-write failure must not prevent showing the downloaded cover.
        try? save(data, to: file)
        return data
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
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return false }
        return CGImageSourceCreateImageAtIndex(source, 0, nil) != nil
    }

    static func download(_ url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url, timeoutInterval: 20))
        guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}
