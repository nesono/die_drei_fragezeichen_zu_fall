import SwiftUI

struct EpisodeDescriptionView: View {
    let episode: Episode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("FOLGE \(episode.numberLabel)")
                        .font(.caption.monospaced().bold())
                        .foregroundStyle(.blue)
                    Text(episode.titel)
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)
                    Text(episode.synopsis ?? "Für diese Folge ist noch keine Kurzbeschreibung im Katalog vorhanden.")
                        .font(.body)
                        .textSelection(.enabled)
                        .accessibilityIdentifier("episodeSynopsis")
                    Text("Quelle: dreimetadaten.de · Beschreibung des Herausgebers")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: 600, alignment: .leading)
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .navigationTitle("Kurzbeschreibung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}
