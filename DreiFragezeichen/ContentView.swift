import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.openURL) private var openURL
    @State private var episodes: [Episode] = []
    @State private var selected: Episode?
    @State private var previousEpisodes: [Episode] = []
    @State private var forwardEpisodes: [Episode] = []
    @State private var loading = false
    @State private var errorMessage: String?
    @State private var notice: String?
    @State private var showingEpisodes = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let pageColor = Color(red: 0.035, green: 0.045, blue: 0.075)

    var body: some View {
        GeometryReader { geometry in
            // Use the actual window size, including iPad split-screen windows.
            let landscape = geometry.size.width > geometry.size.height
                && geometry.size.width >= 600 && !dynamicTypeSize.isAccessibilitySize
            // Opt in only on iPad: phone geometry and spacing remain unchanged.
            // Narrow Split View and accessibility sizes keep the stacked layout.
            let tabletLayout = UIDevice.current.userInterfaceIdiom == .pad
                && geometry.size.width >= 700 && geometry.size.height >= 500
                && !dynamicTypeSize.isAccessibilitySize
            let shortLandscape = landscape && geometry.size.height < 500
            // Reserve space for the header, title and full-sized controls first.
            // Shorter phones give up artwork size rather than touch-target size.
            let portraitArtworkSize = min(260, max(120, geometry.size.height - 510))
            ScrollView {
                VStack(alignment: .leading, spacing: tabletLayout ? 28 : (landscape ? 20 : 16)) {
                    if !shortLandscape { header(compact: landscape && !tabletLayout) }

                    if loading {
                        ProgressView("Folgen werden geladen …")
                            .frame(maxWidth: .infinity, minHeight: 180)
                    } else if let selected {
                        if tabletLayout {
                            tabletEpisode(selected, width: min(1100, geometry.size.width))
                        } else if landscape {
                            HStack(alignment: .center, spacing: shortLandscape ? 24 : 32) {
                                VStack(alignment: .leading, spacing: 12) {
                                    if shortLandscape { header(compact: true) }
                                    EpisodeArtwork(episode: selected)
                                        .id(selected.id)
                                        .frame(width: min(320, max(120, geometry.size.height - (shortLandscape ? 150 : 120))))
                                        .frame(maxWidth: .infinity)
                                    if shortLandscape {
                                        VStack(alignment: .leading, spacing: 4) {
                                            catalogueCount
                                            attribution
                                        }
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(width: shortLandscape ? min(280, geometry.size.width * 0.38) : 320)
                                VStack(alignment: .leading, spacing: shortLandscape ? 12 : 20) {
                                    episodeDetails(selected, alignment: .leading)
                                    actions(compact: true)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        } else {
                            VStack(spacing: 16) {
                                EpisodeArtwork(episode: selected)
                                    .id(selected.id)
                                    .frame(width: portraitArtworkSize)
                                episodeDetails(selected, alignment: .center)
                                actions(compact: false)
                            }
                            .padding(16)
                            .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 24))
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.secondary)
                        Button("Erneut versuchen") { Task { await load() } }
                            .buttonStyle(.borderedProminent)
                    }
                    if !shortLandscape { footer }
                }
                .padding(.horizontal, tabletLayout ? 32 : (landscape ? 24 : 20))
                .padding(.vertical, tabletLayout ? 32 : (shortLandscape ? 12 : (landscape ? 24 : 16)))
                .frame(maxWidth: tabletLayout ? 1100 : (landscape ? 1040 : 520))
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height, alignment: .center)
            }
        }
        .background(pageColor.ignoresSafeArea())
        .sheet(isPresented: $showingEpisodes) {
            EpisodeListView(episodes: episodes, selectedID: selected?.id) { episode in
                selectEpisode(episode)
                showingEpisodes = false
            }
        }
        .task { if episodes.isEmpty { await load() } }
        .alert("Apple Music", isPresented: Binding(
            get: { notice != nil },
            set: { if !$0 { notice = nil } }
        )) {
            Button("OK", role: .cancel) { notice = nil }
        } message: { Text(notice ?? "") }
    }

    private func tabletEpisode(_ episode: Episode, width: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 32) {
            EpisodeArtwork(episode: episode)
                .id(episode.id)
                .frame(width: min(380, (width - 144) * 0.42))
                .shadow(color: .black.opacity(0.25), radius: 20, y: 10)

            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("DEIN HÖRSPIEL FÜR HEUTE")
                        .font(.caption.weight(.semibold))
                        .tracking(2)
                        .foregroundStyle(.secondary)
                    episodeDetails(episode, alignment: .leading)
                }
                Divider().overlay(.white.opacity(0.06))
                actions(compact: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(24)
        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(.white.opacity(0.07), lineWidth: 1)
                .allowsHitTesting(false)
        }
    }

    private func header(compact: Bool) -> some View {
        HStack(alignment: .center, spacing: 16) {
            HStack(spacing: 2) {
                Text("?").foregroundStyle(.white)
                Text("?").foregroundStyle(.red)
                Text("?").foregroundStyle(.blue)
            }
            .font(.system(size: compact ? 38 : 48, weight: .black, design: .rounded))
            .accessibilityLabel("Die drei Fragezeichen")

            VStack(alignment: .leading, spacing: 4) {
                Text("Dein nächster Fall")
                    .font(compact ? .headline : .title2.bold())
                if !compact {
                    Text("Eine Folge. Ein neues Abenteuer.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func episodeDetails(_ episode: Episode, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 10) {
            Text("FOLGE \(episode.numberLabel)")
                .font(.caption.monospaced().weight(.bold))
                .tracking(2)
                .foregroundStyle(.blue)
            Text(episode.titel)
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(alignment == .leading ? .leading : .center)
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .center)
    }

    private func actions(compact: Bool) -> some View {
        VStack(spacing: 12) {
            Button(action: listen) {
                Label("In Apple Music öffnen", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 36)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 14))

            ViewThatFits(in: .horizontal) {
                historyControls(showLabels: true)
                historyControls(showLabels: false)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle(radius: 14))

            AudioOutputPicker()

            Text("Falls nötig, wähle die Ausgabe in Apple Music erneut.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: compact ? .leading : .center)
                .multilineTextAlignment(compact ? .leading : .center)
        }
    }

    private func historyControls(showLabels: Bool) -> some View {
        HStack(spacing: 8) {
            Button(action: goBack) {
                navigationLabel("Zurück", symbol: "chevron.left", showText: showLabels)
            }
            .disabled(previousEpisodes.isEmpty)
            .accessibilityLabel("Zurück")
            .accessibilityHint("Zeigt die vorherige Folge im Verlauf")

            Button(action: goForward) {
                navigationLabel("Vorwärts", symbol: "chevron.right", showText: showLabels)
            }
            .disabled(forwardEpisodes.isEmpty)
            .accessibilityLabel("Vorwärts")
            .accessibilityHint("Stellt die nächste Folge im Verlauf wieder her")

            Button(action: shuffle) {
                Label("Nochmal neu", systemImage: "shuffle")
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(maxWidth: .infinity, minHeight: 36)
            }
            .disabled(episodes.count < 2)
        }
    }

    private func navigationLabel(_ title: String, symbol: String, showText: Bool) -> some View {
        Group {
            if showText {
                Label(title, systemImage: symbol)
                    .fixedSize(horizontal: true, vertical: false)
            } else {
                Image(systemName: symbol)
                    .frame(minWidth: 24)
            }
        }
        .frame(minHeight: 36)
    }

    private var footer: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                catalogueCount
                Spacer(minLength: 16)
                attribution
            }
            VStack(alignment: .leading, spacing: 8) {
                catalogueCount
                attribution
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    @ViewBuilder private var catalogueCount: some View {
        if !episodes.isEmpty {
            Button { showingEpisodes = true } label: {
                Label("Alle Folgen (\(episodes.count))", systemImage: "list.bullet")
            }
            .foregroundStyle(.blue)
            .accessibilityHint("Öffnet die vollständige Folgenliste")
        }
    }

    private var attribution: some View {
        Link("dreimetadaten.de", destination: URL(string: "https://dreimetadaten.de/")!)
    }

    @MainActor private func load() async {
        guard !loading else { return }
        loading = true
        errorMessage = nil
        defer { loading = false }
        do {
            episodes = try await EpisodeService().load()
            shuffle()
        } catch is CancellationError {
            // SwiftUI cancels the request when this view disappears.
        } catch {
            errorMessage = "Der Katalog ist gerade nicht erreichbar. Prüfe deine Internetverbindung und versuche es erneut."
        }
    }

    private func shuffle() {
        guard let next = episodes.filter({ $0.id != selected?.id }).randomElement() ?? episodes.first else { return }
        selectEpisode(next)
    }

    private func selectEpisode(_ next: Episode) {
        guard next.id != selected?.id else { return }
        if let selected { previousEpisodes.append(selected) }
        forwardEpisodes.removeAll()
        selected = next
    }

    private func goBack() {
        guard let previous = previousEpisodes.popLast() else { return }
        if let selected { forwardEpisodes.append(selected) }
        selected = previous
    }

    private func goForward() {
        guard let next = forwardEpisodes.popLast() else { return }
        if let selected { previousEpisodes.append(selected) }
        selected = next
    }

    private func listen() {
        guard let selected else { return }
        UIPasteboard.general.string = selected.appleMusicURL?.absoluteString ?? selected.searchText
        if let url = selected.appleMusicURL {
            openURL(url) { accepted in
                if !accepted { notice = "Der Link konnte nicht geöffnet werden. Er wurde in die Zwischenablage kopiert." }
            }
        } else {
            notice = "Für diese Folge gibt es keinen direkten Apple-Music-Link. Der Titel wurde kopiert."
            openURL(selected.searchURL)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View { ContentView().preferredColorScheme(.dark) }
}
