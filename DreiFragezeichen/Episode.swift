import Foundation

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

    var appleMusicURL: URL? {
        guard let value = links?.appleMusic,
              var components = URLComponents(string: value),
              let host = components.host?.lowercased(),
              ["music.apple.com", "itunes.apple.com"].contains(host),
              ["http", "https"].contains(components.scheme?.lowercased() ?? "") else { return nil }
        components.scheme = "https"
        return components.url
    }

    var searchURL: URL {
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
    case badResponse, empty

    var errorDescription: String? {
        switch self {
        case .badResponse: "Die Folgen konnten nicht geladen werden. Bitte versuche es erneut."
        case .empty: "Im Katalog wurden keine verfügbaren Folgen gefunden."
        }
    }
}

struct EpisodeService {
    func load() async throws -> [Episode] {
        let url = URL(string: "https://dreimetadaten.de/data/Serie.json")!
        let request = URLRequest(url: url, timeoutInterval: 30)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw CatalogueError.badResponse
        }
        let episodes = try JSONDecoder().decode(Catalogue.self, from: data).availableEpisodes()
        guard !episodes.isEmpty else { throw CatalogueError.empty }
        return episodes
    }
}
