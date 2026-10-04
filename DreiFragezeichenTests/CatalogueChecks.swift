import Foundation
import XCTest
@testable import DreiFragezeichen

final class CatalogueChecks: XCTestCase {
    func testRegressionChecks() throws {
        let fixture = #"{"serie":[{"nummer":1,"titel":"First","veröffentlichungsdatum":"1979-10-12","links":{"appleMusic":"http://music.apple.com/de/album/123"}},{"nummer":2,"titel":"Future","veröffentlichungsdatum":"2099-01-01"},{"nummer":3,"titel":"No link","links":{"appleMusic":"https://music.apple.com.example.org/123"}}]}"#
        let catalogue = try JSONDecoder().decode(Catalogue.self, from: Data(fixture.utf8))
        let episodes = catalogue.availableEpisodes(on: Date(timeIntervalSince1970: 1_700_000_000))
        XCTAssertTrue(episodes.map(\.nummer) == [1, 3], "Future episodes should be excluded")
        XCTAssertTrue(episodes[0].appleMusicURL?.scheme == "https")
        XCTAssertTrue(episodes[1].appleMusicURL == nil, "Only real Apple hosts may be opened")
        let query = URLComponents(url: episodes[1].searchURL, resolvingAgainstBaseURL: false)?.queryItems?.first?.value
        XCTAssertTrue(query == episodes[1].searchText, "Search text should survive URL encoding")
        let artworkFixture = #"{"serie":[{"nummer":1,"titel":"Cover","links":{"cover_itunes":"http://a1.mzstatic.com/cover.jpg","cover":"https://dreimetadaten.de/cover.png"}},{"nummer":2,"titel":"Fallback","links":{"cover_itunes":"file:///cover.jpg","cover":"http://dreimetadaten.de/cover.png"}},{"nummer":3,"titel":"Missing"}]}"#
        let artwork = try JSONDecoder().decode(Catalogue.self, from: Data(artworkFixture.utf8)).serie
        XCTAssertTrue(artwork[0].artworkURL?.absoluteString == "https://a1.mzstatic.com/cover.jpg")
        XCTAssertTrue(artwork[1].artworkURL?.absoluteString == "https://dreimetadaten.de/cover.png")
        XCTAssertTrue(artwork[2].artworkURL == nil)
        let playerFixture = #"{"serie":[{"nummer":1,"titel":"A / B & Frage?","links":{"spotify":"http://open.spotify.com/intl-de/album/123","appleMusic":"https://music.apple.com/de/album/456"}},{"nummer":2,"titel":"Missing","links":{"spotify":"https://open.spotify.com.evil.test/album/123"}}]}"#
        let players = try JSONDecoder().decode(Catalogue.self, from: Data(playerFixture.utf8)).serie
        XCTAssertTrue(players[0].playbackURL(for: .spotify)?.absoluteString == "https://open.spotify.com/intl-de/album/123")
        XCTAssertTrue(players[0].playbackURL(for: .appleMusic)?.host == "music.apple.com")
        XCTAssertTrue(players[1].playbackURL(for: .spotify) == nil)
        XCTAssertTrue(players[1].playbackURL(for: .appleMusic) == nil)
        let spotifySearch = players[0].searchURL(for: .spotify)
        XCTAssertTrue(spotifySearch.host == "open.spotify.com")
        XCTAssertTrue(spotifySearch.query == nil && spotifySearch.fragment == nil)
        XCTAssertTrue(spotifySearch.path == "/search/" + players[0].searchText)

        print("Catalogue checks passed")
    }
}
