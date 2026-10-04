import AVKit
import SwiftUI

/// The native route control remains the hit target across the whole button.
/// The label is decorative, so taps and VoiceOver activation reach iOS directly.
struct AudioOutputPicker: View {
    @ScaledMetric(relativeTo: .subheadline) private var buttonHeight = 52.0

    var body: some View {
        NativeAudioOutputPicker()
            .frame(maxWidth: .infinity)
            .frame(height: buttonHeight)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                HStack(spacing: 12) {
                    Image(systemName: "airplay.audio")
                        .foregroundStyle(.blue)
                    Text("Audioausgabe wählen")
                        .font(.subheadline.weight(.medium))
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .accessibilityLabel("Audioausgabe wählen")
            .accessibilityHint("Öffnet die Liste verfügbarer Audiogeräte")
    }
}

/// Does not activate an audio session or interrupt Apple Music playback.
private struct NativeAudioOutputPicker: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.prioritizesVideoDevices = false
        // Replace only the visual glyph; keep the system control interactive.
        picker.tintColor = .clear
        picker.activeTintColor = .clear
        return picker
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
