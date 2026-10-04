import XCTest

final class AppFlowTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-ui-testing", "-AppleLanguages", "(de)", "-AppleLocale", "de_DE"]
        app.launch()
        XCTAssertTrue(app.staticTexts["selectedEpisodeTitle"].waitForExistence(timeout: 10))
    }

    override func tearDownWithError() throws {
        app.terminate()
        XCUIDevice.shared.orientation = .portrait
    }

    func testHistoryAndLibrarySelection() {
        XCTAssertEqual(app.staticTexts["selectedEpisodeTitle"].label, "Testfall 1")
        XCTAssertFalse(app.buttons["back"].isEnabled)
        app.buttons["shuffle"].tap()
        let next = app.staticTexts["selectedEpisodeTitle"].label
        XCTAssertNotEqual(next, "Testfall 1")
        app.buttons["back"].tap()
        XCTAssertEqual(app.staticTexts["selectedEpisodeTitle"].label, "Testfall 1")
        app.buttons["forward"].tap()
        XCTAssertEqual(app.staticTexts["selectedEpisodeTitle"].label, next)
        app.buttons["library"].tap()
        app.buttons["episode-3"].tap()
        XCTAssertEqual(app.staticTexts["selectedEpisodeTitle"].label, "Testfall 3")
    }

    func testPlayerChoicePersistsAcrossLaunches() {
        app.buttons["settings"].tap()
        app.buttons["Spotify"].tap()
        app.buttons["Fertig"].tap()
        XCTAssertTrue(app.buttons["openPlayer"].label.contains("Spotify"))
        app.terminate()
        app.launchArguments.removeAll { $0 == "--reset-ui-testing" }
        app.launch()
        XCTAssertTrue(app.buttons["openPlayer"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["openPlayer"].label.contains("Spotify"))
    }

    func testFavouriteFilterAndLandscapeControls() {
        app.buttons["Favoriten und Später hören"].tap()
        app.buttons["Zu Favoriten hinzufügen"].tap()
        app.buttons["library"].tap()
        app.buttons["Folgen filtern"].tap()
        app.buttons["Favoriten"].tap()
        XCTAssertTrue(app.buttons["episode-1"].exists)
        XCTAssertFalse(app.buttons["episode-2"].exists)
        app.buttons["Fertig"].tap()
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.buttons["shuffle"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["shuffle"].isHittable)
        XCTAssertTrue(app.buttons["openPlayer"].isHittable)
    }
}
