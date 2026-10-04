import SwiftUI

struct EpisodeListView: View {
    let episodes: [Episode]
    let selectedID: Int?
    let onSelect: (Episode) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    @State private var positionedInitialSelection = false

    private var visibleEpisodes: [Episode] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return episodes
            .filter { query.isEmpty || $0.titel.localizedStandardContains(query)
                || $0.numberLabel.contains(query) }
            .sorted { $0.nummer < $1.nummer }
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    Section {
                        ForEach(visibleEpisodes) { episode in
                            Button { onSelect(episode) } label: {
                                HStack(spacing: 16) {
                                    EpisodeArtwork(episode: episode, thumbnail: true)
                                        .frame(width: 56, height: 56)
                                        .accessibilityHidden(true)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("FOLGE \(episode.numberLabel)")
                                            .font(.caption.monospacedDigit().weight(.semibold))
                                            .foregroundStyle(.blue)
                                        Text(episode.titel)
                                            .foregroundStyle(.primary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    if episode.id == selectedID {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                            }
                            .id(episode.id)
                            .buttonStyle(.plain)
                            .accessibilityLabel("Folge \(episode.numberLabel): \(episode.titel)")
                            .accessibilityAddTraits(episode.id == selectedID ? .isSelected : [])
                        }
                    } header: {
                        Text("\(visibleEpisodes.count) Folgen")
                    }
                }
                .overlay {
                    if visibleEpisodes.isEmpty {
                        ContentUnavailableView("Keine Folgen gefunden", systemImage: "magnifyingglass",
                            description: Text("Suche nach einem Titel oder einer Folgennummer."))
                    }
                }
                .task {
                    guard !positionedInitialSelection else { return }
                    // Let the list establish its rows before positioning it.
                    await Task.yield()
                    guard !Task.isCancelled else { return }
                    if let selectedID, episodes.contains(where: { $0.id == selectedID }) {
                        proxy.scrollTo(selectedID, anchor: .center)
                    }
                    positionedInitialSelection = true
                }
            }
            .navigationTitle("Alle Folgen")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Titel oder Folgennummer")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}
