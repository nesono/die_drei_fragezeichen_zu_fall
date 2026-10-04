#if DEBUG
import Foundation

/// Offline fixtures and separate preferences, available only in Debug builds.
enum UITestSupport {
    static var enabled: Bool { ProcessInfo.processInfo.arguments.contains("--ui-testing") }
    static let defaults: UserDefaults = {
        let suite = "de.local.dreifragezeichen.ui-tests"
        let defaults = UserDefaults(suiteName: suite)!
        if ProcessInfo.processInfo.arguments.contains("--reset-ui-testing") {
            defaults.removePersistentDomain(forName: suite)
        }
        return defaults
    }()
    static let episodes: [Episode] = (1...5).map {
        Episode(nummer: $0, titel: "Testfall \($0)", releaseDate: nil, links: nil)
    }
}
#endif
