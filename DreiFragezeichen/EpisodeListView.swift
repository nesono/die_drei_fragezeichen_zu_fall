import SwiftUI

struct EpisodeListView: View {
    let episodes: [Episode]
    let selectedID: Int?
    let onSelect: (Episode) -> Void

    @EnvironmentObject private var listening: ListeningStore
    @State private var editingListening: Episode?
    @Environment(\.dismiss) private var dismiss
    private enum Collection: String, CaseIterable {
        case all = "Alle Folgen", favourites = "Favoriten", later = "Später hören"
    }
    @State private var collection: Collection = .all
    @State private var search = ""
    @State private var positionedInitialSelection = false

    private var visibleEpisodes: [Episode] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return episodes
            .filter { episode in
                switch collection {
                case .all: true
                case .favourites: listening.favourites.contains(episode.id)
                case .later: listening.listenLater.contains(episode.id)
                }
            }
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
                            description: Text(collection == .all ? "Suche nach einem Titel oder einer Folgennummer." : "Speichere Folgen über das Lesezeichen-Menü oder durch Wischen in der Folgenliste. Prüfe auch deinen Suchtext."))
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
                        Picker("Sammlung", selection: $collection) {
                            ForEach(Collection.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                    } label: {
                        Label("Sammlung", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}
