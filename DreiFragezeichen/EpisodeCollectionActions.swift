import SwiftUI

struct EpisodeCollectionActions: View {
    let episodeID: Int
    @EnvironmentObject private var listening: ListeningStore

    var body: some View {
        Button {
            listening.toggleFavourite(episodeID)
        } label: {
            Label(listening.favourites.contains(episodeID) ? "Aus Favoriten entfernen" : "Zu Favoriten hinzufügen",
                  systemImage: listening.favourites.contains(episodeID) ? "heart.slash" : "heart")
        }
        Button {
            listening.toggleListenLater(episodeID)
        } label: {
            Label(listening.listenLater.contains(episodeID) ? "Aus Später hören entfernen" : "Später hören",
                  systemImage: listening.listenLater.contains(episodeID) ? "bookmark.slash" : "bookmark")
        }
    }
}
