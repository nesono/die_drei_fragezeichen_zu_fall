import Foundation

enum PlaybackService: String, CaseIterable, Identifiable {
    case appleMusic, spotify
    var id: String { rawValue }
    var name: String { self == .appleMusic ? "Apple Music" : "Spotify" }
}

struct Catalogue: Decodable {
    let serie: [Episode]

    func availableEpisodes(on date: Date = Date()) -> [Episode] {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Europe/Berlin")
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: date)
        return serie.filter {
            $0.nummer > 0 && !$0.titel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && ($0.releaseDate.map { $0 <= today } ?? true)
        }
    }
}

struct Episode: Decodable, Identifiable {
    let nummer: Int
    let titel: String
    let releaseDate: String?
    let links: Links?

    struct Links: Decodable {
        let appleMusic: String?
        let spotify: String?
        let cover: String?
        let cover_itunes: String?
        let cover_dreifragezeichen: String?
    }

    var artworkURL: URL? {
        // Older catalogue entries use HTTP; request the images securely.
        for value in [links?.cover_itunes, links?.cover_dreifragezeichen, links?.cover] {
            guard let value, var components = URLComponents(string: value),
                  let host = components.host, !host.isEmpty,
                  ["http", "https"].contains(components.scheme?.lowercased() ?? "") else { continue }
            components.scheme = "https"
            if let url = components.url { return url }
        }
        return nil
    }

    var id: Int { nummer }
    var numberLabel: String { String(format: "%03d", nummer) }
    var searchText: String { "Die drei ??? Folge \(numberLabel) – \(titel)" }

    var appleMusicURL: URL? { playbackURL(for: .appleMusic) }
    var searchURL: URL { searchURL(for: .appleMusic) }

    func playbackURL(for service: PlaybackService) -> URL? {
        let value = service == .appleMusic ? links?.appleMusic : links?.spotify
        let hosts = service == .appleMusic ? ["music.apple.com", "itunes.apple.com"] : ["open.spotify.com"]
        guard let value, var components = URLComponents(string: value),
              let host = components.host?.lowercased(), hosts.contains(host),
              ["http", "https"].contains(components.scheme?.lowercased() ?? "") else { return nil }
        components.scheme = "https"
        return components.url
    }

    func searchURL(for service: PlaybackService) -> URL {
        if service == .spotify {
            return URL(string: "https://open.spotify.com/search")!.appendingPathComponent(searchText)
        }
        var components = URLComponents(string: "https://music.apple.com/de/search")!
        components.queryItems = [URLQueryItem(name: "term", value: searchText)]
        return components.url!
    }

    enum CodingKeys: String, CodingKey {
        case nummer, titel, links
        case releaseDate = "veröffentlichungsdatum"
    }
}

enum CatalogueError: LocalizedError {
    case badResponse, empty, downloadRequired

    var errorDescription: String? {
        switch self {
        case .downloadRequired: "Bitte lade zuerst den Folgenkatalog herunter."
        case .badResponse: "Die Folgen konnten nicht geladen werden. Bitte versuche es erneut."
        case .empty: "Im Katalog wurden keine verfügbaren Folgen gefunden."
        }
    }
}

struct EpisodeService {
    private struct SavedCatalogue: Codable {
        let fetchedAt: Date
        let data: Data
    }

    let cacheURL: URL
    let fetch: () async throws -> Data

    init(
        cacheURL: URL = URL.applicationSupportDirectory
            .appendingPathComponent("EpisodeCatalogue", isDirectory: true)
            .appendingPathComponent("catalogue-v1.json"),
        fetch: @escaping () async throws -> Data = EpisodeService.download
    ) {
        self.cacheURL = cacheURL
        self.fetch = fetch
    }

    func load(now: Date = Date(), allowNetwork: Bool = true) async throws -> [Episode] {
        let saved = try? JSONDecoder().decode(SavedCatalogue.self, from: Data(contentsOf: cacheURL))
        // Reapply release-date filtering even when reading an older catalogue.
        let cachedEpisodes = saved.flatMap { try? decode($0.data, on: now) }
        if !allowNetwork {
            if let cachedEpisodes { return cachedEpisodes }
            throw CatalogueError.downloadRequired
        }
        if let saved, let cachedEpisodes,
           (0..<86_400).contains(now.timeIntervalSince(saved.fetchedAt)) {
            return cachedEpisodes
        }

        do {
            let data = try await fetch()
            try Task.checkCancellation()
            let episodes = try decode(data, on: now)
            // Never overwrite a usable cache with a bad response. Disk errors
            // should not prevent listening when the download itself succeeded.
            try? save(data, fetchedAt: now)
            return episodes
        } catch {
            if error is CancellationError || (error as? URLError)?.code == .cancelled {
                throw error
            }
            if let cachedEpisodes { return cachedEpisodes }
            throw error
        }
    }

    private func decode(_ data: Data, on date: Date) throws -> [Episode] {
        let episodes = try JSONDecoder().decode(Catalogue.self, from: data).availableEpisodes(on: date)
        guard !episodes.isEmpty else { throw CatalogueError.empty }
        return episodes
    }

    private func save(_ data: Data, fetchedAt: Date) throws {
        let directory = cacheURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        // Downloaded metadata is reproducible and need not occupy iCloud backup.
        var directoryURL = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? directoryURL.setResourceValues(values)
        let encoded = try JSONEncoder().encode(SavedCatalogue(fetchedAt: fetchedAt, data: data))
        try encoded.write(to: cacheURL, options: .atomic)
    }

    static func download() async throws -> Data {
        let url = URL(string: "https://dreimetadaten.de/data/Serie.json")!
        // The persistent cache controls freshness, rather than an older HTTP cache.
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw CatalogueError.badResponse
        }
        return data
    }
}
