import SwiftUI

struct EpisodeListView: View {
    let episodes: [Episode]
    let selectedID: Int?
    let onSelect: (Episode) -> Void

    @EnvironmentObject private var listening: ListeningStore
    @State private var editingListening: Episode?
    @Environment(\.dismiss) private var dismiss
    @State private var collection: LibraryFilter = .all
    @State private var search = ""
    @State private var positionedInitialSelection = false

    private var visibleEpisodes: [Episode] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        let matchingIDs = Set(listening.libraryIDs(episodes.map(\.id), filter: collection))
        return episodes
            .filter { matchingIDs.contains($0.id) }
            .filter { query.isEmpty || $0.titel.localizedStandardContains(query)
                || $0.numberLabel.contains(query) }
            .sorted { $0.nummer < $1.nummer }
    }

    private var emptyMessage: String {
        if !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Keine Treffer in „\(collection.rawValue)“. Ändere den Suchtext oder den Filter."
        }
        switch collection {
        case .all: return "Es sind noch keine Folgen verfügbar."
        case .heard: return "Noch keine Folge als gehört markiert. Öffne eine Folge im Player oder bearbeite ihren Hörstatus."
        case .unheard: return "Du hast alle verfügbaren Folgen als gehört markiert. Über den Filter kannst du wieder alle anzeigen."
        case .favourites: return "Füge Folgen über das Lesezeichen-Menü oder durch Wischen zu deinen Favoriten hinzu."
        case .later: return "Speichere Folgen über das Lesezeichen-Menü oder durch Wischen für später."
        }
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
                                        HStack(spacing: 8) {
                                            Text("FOLGE \(episode.numberLabel)")
                                                .font(.caption.monospacedDigit().weight(.semibold))
                                                .foregroundStyle(.blue)
                                            if listening.favourites.contains(episode.id) {
                                                Image(systemName: "heart.fill").foregroundStyle(.pink)
                                            }
                                            if listening.listenLater.contains(episode.id) {
                                                Image(systemName: "bookmark.fill").foregroundStyle(.blue)
                                            }
                                        }
                                        .font(.caption)
                                        Text(episode.titel)
                                            .foregroundStyle(.primary)
                                            .fixedSize(horizontal: false, vertical: true)
                                        if let date = listening.lastListened(to: episode.id) {
                                            Label("Gehört · \(date.formatted(date: .abbreviated, time: .omitted))", systemImage: "checkmark.circle")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
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
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button { listening.toggleFavourite(episode.id) } label: {
                                    Label("Favorit", systemImage: listening.favourites.contains(episode.id) ? "heart.slash" : "heart")
                                }.tint(.pink)
                                Button { listening.toggleListenLater(episode.id) } label: {
                                    Label("Später", systemImage: listening.listenLater.contains(episode.id) ? "bookmark.slash" : "bookmark")
                                }.tint(.blue)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Hörstatus", systemImage: "checkmark.circle") { editingListening = episode }
                                    .tint(.blue)
                            }
                            .contextMenu {
                                EpisodeCollectionActions(episodeID: episode.id)
                                Button("Hörstatus bearbeiten", systemImage: "checkmark.circle") { editingListening = episode }
                            }
                            .id(episode.id)
                            .buttonStyle(.plain)
                            .accessibilityLabel("Folge \(episode.numberLabel): \(episode.titel)")
                            .accessibilityValue(listening.lastListened(to: episode.id).map { "Gehört am \($0.formatted(date: .abbreviated, time: .omitted))" } ?? "Ungehört")
                            .accessibilityAddTraits(episode.id == selectedID ? .isSelected : [])
                        }
                    } header: {
                        Text("\(visibleEpisodes.count) Folgen")
                    }
                }
                .overlay {
                    if visibleEpisodes.isEmpty {
                        ContentUnavailableView("Keine Folgen gefunden", systemImage: "magnifyingglass",
                            description: Text(emptyMessage))
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
            .sheet(item: $editingListening) { ListeningStatusView(episode: $0) }
            .navigationTitle(collection.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Titel oder Folgennummer")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Folgen filtern", selection: $collection) {
                            ForEach(LibraryFilter.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                    } label: {
                        Label("Folgen filtern", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}
