import SwiftUI

/// A heart badge keeps both independent collection states visible.
struct CollectionStatusIcon: View {
    let favourite: Bool
    let later: Bool

    var body: some View {
        Image(systemName: later ? "bookmark.fill" : (favourite ? "heart.fill" : "bookmark"))
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(favourite && !later ? Color.pink : Color.blue)
            .overlay(alignment: .bottomTrailing) {
                if favourite && later {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.pink)
                        .padding(3)
                        .background(Color(red: 0.035, green: 0.045, blue: 0.075), in: Circle())
                        .offset(x: 7, y: 5)
                }
            }
            .accessibilityHidden(true)
    }
}
