# ??? Zu-Fall — minimal SwiftUI app

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
- Random selection from the published episode catalogue at https://dreimetadaten.de/data/Serie.json, saved locally after a successful download. New launches reuse it for 24 hours, then attempt a refresh; if the refresh fails, the saved catalogue remains usable offline.
- Future release dates are excluded. Episodes without a release date remain eligible.
- **Alle Folgen** opens a scrollable list of all available episodes, ordered by number, with title/number search. Selecting a row returns to the main view and adds the selection to back/forward history. The list uses the loaded catalogue and loads cover thumbnails as rows appear. Thumbnails share the same permanent memory/disk cache as the main episode view.
- **Nochmal neu** selects another episode without an immediate repeat. **Zurück** and **Vorwärts** navigate suggestion history, including covers and playback links. Drawing a new episode after going back replaces the forward history. On narrow screens the navigation buttons use arrow icons. History is kept for the current app session; the back button is disabled when there is no earlier suggestion.
- **Ja, in Apple Music öffnen** copies the album link and opens it.
- If no album link exists, the title is copied and an Apple Music web search opens.
- Native AirPlay output picker below the episode actions. Tap the full-width “Audioausgabe wählen” button to show available routes. Playback happens in Apple Music, so the destination may need to be selected again in Music or Control Center. The app does not activate an audio session or force another app’s output.
- Loading indicator, network timeout, and a retry button on failure.
- Dynamic Type, scrollable layout, and accessible button labels.

The original Python script is preserved at the project root. This is a personal prototype: it has no App Store packaging. The first launch needs internet to populate the catalogue cache. Viewed artwork is cached separately for offline use; Apple Music manages audio playback and downloads. Metadata comes from dreimetadaten.de; no audio is bundled.

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

## Catalogue cache checks

Run `swiftc DreiFragezeichen/Episode.swift Tests/CacheChecks.swift -o /tmp/drei-cache-checks && /tmp/drei-cache-checks` on macOS to verify persistence, the 24-hour refresh boundary, offline fallback, invalid responses, cancellation, and corrupted-cache recovery. The catalogue is stored in Application Support, excluded from backup, and replaced atomically only after validation. Failed refreshes retain the previous timestamp and are retried on a later launch. Refresh attempts time out after 15 seconds before falling back; new releases are filtered using the current date even for cached data.

## Artwork cache

Viewed covers are validated and saved atomically in Application Support, excluded from backup, with no expiry or periodic revalidation. A bounded 32 MB memory cache speeds up revisits; evicted images remain on disk. The image URL identifies each entry, so a changed catalogue URL can download a new cover. Concurrent requests share a download, which finishes even if you navigate away. Failed responses are not cached; corrupt files are downloaded again. Only viewed covers are fetched. Unviewed covers still require internet, and uninstalling the app removes its saved artwork.

Run `swiftc DreiFragezeichen/ArtworkCache.swift Tests/ArtworkCacheChecks.swift -o /tmp/drei-artwork-checks && /tmp/drei-artwork-checks` to check memory reuse, disk persistence while offline, concurrent requests, corruption recovery, and invalid-image retries.
