import SwiftUI

@main
struct DreiFragezeichenApp: App {
    @StateObject private var listening = ListeningStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(listening)
                .preferredColorScheme(.dark)
        }
    }
}
