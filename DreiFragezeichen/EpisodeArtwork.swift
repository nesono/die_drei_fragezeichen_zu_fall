import SwiftUI
import UIKit

struct EpisodeArtwork: View {
    let episode: Episode
    var thumbnail = false

    private var cornerRadius: CGFloat { thumbnail ? 8 : 16 }

    @State private var artwork: UIImage?
    @State private var loading = true

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.white.opacity(0.04))
            if let artwork {
                Image(uiImage: artwork).resizable().scaledToFit()
            } else if loading && episode.artworkURL != nil {
                ProgressView().accessibilityLabel("Cover wird geladen")
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "headphones")
                        .font(thumbnail ? .title3 : .largeTitle)
                        .foregroundStyle(.blue)
                    if !thumbnail {
                        Text("Kein Cover verfügbar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .task(id: episode.artworkURL) {
            artwork = nil
            loading = true
            guard let url = episode.artworkURL else {
                loading = false
                return
            }
            do {
                let data = try await ArtworkCache.shared.data(for: url)
                // A completed request may belong to a view already navigated away from.
                guard !Task.isCancelled else { return }
                artwork = UIImage(data: data)
            } catch {
                guard !Task.isCancelled else { return }
            }
            loading = false
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Cover zu Folge \(episode.numberLabel): \(episode.titel)")
    }
}
