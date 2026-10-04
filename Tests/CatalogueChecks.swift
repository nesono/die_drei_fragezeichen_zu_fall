import Foundation

@main
struct CatalogueChecks {
    static func main() throws {
        let fixture = #"{"serie":[{"nummer":1,"titel":"First","veröffentlichungsdatum":"1979-10-12","links":{"appleMusic":"http://music.apple.com/de/album/123"}},{"nummer":2,"titel":"Future","veröffentlichungsdatum":"2099-01-01"},{"nummer":3,"titel":"No link","links":{"appleMusic":"https://music.apple.com.example.org/123"}}]}"#
        let catalogue = try JSONDecoder().decode(Catalogue.self, from: Data(fixture.utf8))
        let episodes = catalogue.availableEpisodes(on: Date(timeIntervalSince1970: 1_700_000_000))
        precondition(episodes.map(\.nummer) == [1, 3], "Future episodes should be excluded")
        precondition(episodes[0].appleMusicURL?.scheme == "https")
        precondition(episodes[1].appleMusicURL == nil, "Only real Apple hosts may be opened")
        let query = URLComponents(url: episodes[1].searchURL, resolvingAgainstBaseURL: false)?.queryItems?.first?.value
        precondition(query == episodes[1].searchText, "Search text should survive URL encoding")
        let artworkFixture = #"{"serie":[{"nummer":1,"titel":"Cover","links":{"cover_itunes":"http://a1.mzstatic.com/cover.jpg","cover":"https://dreimetadaten.de/cover.png"}},{"nummer":2,"titel":"Fallback","links":{"cover_itunes":"file:///cover.jpg","cover":"http://dreimetadaten.de/cover.png"}},{"nummer":3,"titel":"Missing"}]}"#
        let artwork = try JSONDecoder().decode(Catalogue.self, from: Data(artworkFixture.utf8)).serie
        precondition(artwork[0].artworkURL?.absoluteString == "https://a1.mzstatic.com/cover.jpg")
        precondition(artwork[1].artworkURL?.absoluteString == "https://dreimetadaten.de/cover.png")
        precondition(artwork[2].artworkURL == nil)
        if CommandLine.arguments.count > 1 {
            let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
            let live = try JSONDecoder().decode(Catalogue.self, from: data).availableEpisodes()
            precondition(!live.isEmpty)
            precondition(live.first(where: { $0.nummer == 1 })?.appleMusicURL != nil)
            print("Live catalogue: \(live.count) released episodes decoded successfully")
        }
        print("Catalogue checks passed")
    }
}
