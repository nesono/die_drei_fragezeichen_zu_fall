import SwiftUI

struct PlayerSettingsView: View {
    @Binding var player: PlaybackService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Player", selection: $player) {
                        ForEach(PlaybackService.allCases) { service in
                            Text(service.name).tag(service)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Wiedergabe")
                } footer: {
                    Text("Deine Auswahl wird gespeichert. Folgen werden im gewählten Dienst geöffnet. Die Wiedergabe und Geräteauswahl steuerst du dort. Wenn ein direkter Link fehlt, öffnen wir die Suche und kopieren den Folgentitel.")
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}
