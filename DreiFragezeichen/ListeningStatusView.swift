import SwiftUI

struct ListeningStatusView: View {
    let episode: Episode
    @EnvironmentObject private var listening: ListeningStore
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Folge \(episode.numberLabel): \(episode.titel)")
                        .font(.headline)
                    DatePicker("Zuletzt gehört", selection: $date, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.compact)
                    Button("Heute gehört") { date = Date() }
                } footer: {
                    Text("Beim erfolgreichen Öffnen im gewählten Dienst (auch einer Suche) markieren wir die Folge als heute gehört. Das ist eine Annahme, keine Wiedergabeprüfung. Du kannst Datum und Status hier korrigieren.")
                }
                if listening.lastListened(to: episode.id) != nil {
                    Section {
                        Button("Als ungehört markieren", role: .destructive) {
                            listening.markUnheard(episode.id)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Hörstatus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        listening.markHeard(episode.id, on: date)
                        dismiss()
                    }
                }
            }
            .onAppear { date = min(listening.lastListened(to: episode.id) ?? Date(), Date()) }
        }
    }
}
