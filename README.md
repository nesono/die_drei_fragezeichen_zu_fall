# Nächster Fall — minimal SwiftUI app

A native iOS version of `die_drei_fragezeichen_select.py`. Requires Xcode 16 or later and iOS 17 or later. No third-party packages, API keys, or Python installation are needed.

## Try it in the simulator

1. Open `DreiFragezeichen.xcodeproj` in Xcode.
2. If no iPhone simulator is available, open **Xcode → Settings → Components** (called **Platforms** in older Xcode versions) and download an iOS Simulator runtime. This Mac had no available runtime when the app was built.
3. Select the **DreiFragezeichen** scheme and an iPhone simulator in the run destination menu.
4. Press **⌘R**. The app loads its catalogue from the internet and suggests an episode.

No signing team is needed for the simulator. Apple Music links can open in Safari there; use a real iPhone to check the Music app handoff.

## Try it on your iPhone

1. Connect your iPhone to the Mac, trust the computer, and select it as the run destination.
2. In the project editor, select the **DreiFragezeichen** target → **Signing & Capabilities**.
3. Select your Apple development team (a personal Apple ID can be added in Xcode Settings → Accounts). Leave automatic signing enabled. Change `de.local.dreifragezeichen` to a unique bundle identifier if Xcode requests it.
4. Enable Developer Mode on the iPhone if prompted, then press **⌘R**. Follow any device trust prompts.

The app opens Apple Music links; playback and any subscription requirements are handled by Apple Music.

## Included behavior

- German SwiftUI interface for iPhone and iPad. Landscape uses artwork and controls in two columns, with a compact header; portrait and accessibility text sizes use a scrollable single column. Layout follows the available window size, including iPad split-screen.
- Random selection from the published episode catalogue at https://dreimetadaten.de/data/Serie.json, loaded once per app session.
- Future release dates are excluded. Episodes without a release date remain eligible.
- **Nochmal neu** selects another episode without an immediate repeat.
- **Ja, in Apple Music öffnen** copies the album link and opens it.
- If no album link exists, the title is copied and an Apple Music web search opens.
- Native AirPlay output picker below the episode actions. Tap the full-width “Audioausgabe wählen” button to show available routes. Playback happens in Apple Music, so the destination may need to be selected again in Music or Control Center. The app does not activate an audio session or force another app’s output.
- Loading indicator, network timeout, and a retry button on failure.
- Dynamic Type, scrollable layout, and accessible button labels.

The original Python script is preserved at the project root. This is a personal prototype: it has no offline catalogue or App Store packaging. Metadata comes from dreimetadaten.de; no audio is bundled.

## Validation

The Debug iOS Simulator build passed with Xcode 26.6. Model checks also passed against the live catalogue (241 released episodes on 2026-10-03). Interactive UI behavior and the Music app handoff still need a simulator runtime or physical iPhone.

Build without device signing:

```sh
xcodebuild -project DreiFragezeichen.xcodeproj -scheme DreiFragezeichen \
  -sdk iphonesimulator -configuration Debug \
  -derivedDataPath /tmp/DreiFragezeichen-build CODE_SIGNING_ALLOWED=NO build
```

Run model checks on macOS:

```sh
swiftc -module-cache-path /tmp/drei-swift-cache \
  DreiFragezeichen/Episode.swift Tests/CatalogueChecks.swift -o /tmp/drei-checks
/tmp/drei-checks
```

Optionally pass a downloaded `Serie.json` path to `/tmp/drei-checks` to validate the current catalogue too.

## App icon

The app icon is included in `DreiFragezeichen/Assets.xcassets/AppIcon.appiconset`. It uses the same white, red, and blue question marks as the main screen. To regenerate the opaque 1024 × 1024 PNG on macOS, run `swift Scripts/GenerateAppIcon.swift` from the project root. iOS applies the rounded corners.

To check audio routing, run on a physical iPhone with an available AirPlay speaker: tap the “Audioausgabe wählen” button, choose the speaker, then open the episode in Apple Music and start playback. Confirm the destination in Music; also check the picker with no external devices available. Route discovery and the handoff have not been verified on hardware.

On short landscape windows (under 500 points high), the header and catalogue attribution sit in the artwork column to preserve vertical room for playback and audio-output controls. Artwork scales to the available height; long titles and larger text remain scrollable.

iPad windows at least 700 points wide and 500 points tall use a dedicated two-column card in either orientation, with larger artwork and a separate details/control area. The layout is restricted to iPad; existing phone layouts are unchanged. Narrow iPad windows and accessibility text sizes use the compact layouts.
