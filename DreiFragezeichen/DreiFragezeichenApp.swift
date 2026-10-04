import SwiftUI

@main
struct DreiFragezeichenApp: App {
    @StateObject private var listening: ListeningStore
    private let defaults: UserDefaults

    init() {
        #if DEBUG
        let defaults = UITestSupport.enabled ? UITestSupport.defaults : UserDefaults.standard
        #else
        let defaults = UserDefaults.standard
        #endif
        self.defaults = defaults
        _listening = StateObject(wrappedValue: ListeningStore(defaults: defaults))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(listening)
                .defaultAppStorage(defaults)
                .preferredColorScheme(.dark)
        }
    }
}
