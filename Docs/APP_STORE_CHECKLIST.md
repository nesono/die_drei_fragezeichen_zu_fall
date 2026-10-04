# App Store submission checklist

This is a readiness checklist, not a guarantee of approval. Nothing has been uploaded.

## Implemented

- App privacy manifest declares app-only UserDefaults use (CA92.1), no tracking, and no developer-collected data. Reassess if adding telemetry, accounts, SDKs, or services.
- Offline-readable privacy information and source/licence credits in Settings.
- Fresh installations explain the approximately 2 MB catalogue download and variable cover downloads before downloading. The current reference catalogue is about 1.7 MB; reassess the estimate before release. Existing cached installations remain usable.
- Clear artwork cache in Settings, including in-flight invalidation; failed deletions are reported.
- ImageIO downsampling (168-pixel thumbnails, up to 1140 pixels for main covers) instead of full-resolution UI decoding.
- Existing iPhone/iPad layouts, player selection, cache behavior, and history remain in place.

## Owner actions before submission

1. **Resolve content rights.** Confirm documented permission/terms for the app name, white/red/blue question-mark icon, displaying covers, and retaining downloaded covers indefinitely. The metadata provider explicitly excludes covers and description texts from its CC BY licence. The independent-app notice does not provide permission. Supply permission evidence to App Review when requested; change the icon/name or omit covers if rights cannot be established.
2. **Publish and complete the privacy policy.** Review `PRIVACY_POLICY_DRAFT.md`, add the actual operator identity, contact details, and legally applicable information, and publish it at a stable public HTTPS URL. Provide that URL so it can be linked in Settings, and enter it in App Store Connect. In-app factual privacy information is included now, but it is not a complete operator-specific legal policy.
3. **Provide support details.** Create a public support page with a working contact method. Enter the Support URL and App Review contact details in App Store Connect; provide the URL for an in-app support link.
4. **Confirm privacy disclosures.** Review the third-party metadata/image providers' processing practices and complete App Privacy accurately. The code has no analytics or ads and stores preferences locally, but network providers receive IP addresses and resource requests. The manifest does not replace App Store Connect privacy answers.
5. **Finalize the release identity.** Confirm your Apple Developer Program distribution membership, registered bundle ID (currently `de.local.dreifragezeichen`), signing team, app name, version, build number, and availability. Choose the permanent bundle ID before the first submission; the current identifier is not inherently forbidden. Use a new build number for subsequent uploads.
6. **Complete store metadata.** Supply accurate iPhone/iPad screenshots, description, category, copyright, age-rating answers, content-rights declarations, pricing/territories, and export-compliance answers. The app links out to streaming services and does not play or download audio itself. Do not describe it as an official franchise app or promise automatic playback/device control.
7. **Test the signed build via TestFlight.** Cover iPhone 17e and iPad, both orientations, Split View, large text, VoiceOver, fresh install/download consent, offline relaunch, search/history, cache deletion, and each service installed/uninstalled. Verify actual Spotify/Apple Music and AirPlay behavior on hardware. The standalone checks do not exercise system UI or external apps.
8. **Address product-review risk.** Decide whether the current episode browser/randomizer offers enough standalone value under guideline 4.2. Explain its discovery/search/offline features in Review Notes. Favourites or listening history could strengthen it, but extra features do not guarantee approval.
9. **Validate and upload.** Archive a signed Release build in Xcode, run Organizer's Validate App, inspect its privacy report, resolve validation issues, and submit with reviewer notes. No signed archive validation or App Store Connect review has been performed here.

## Suggested Review Notes (adapt before submitting)

This independent companion app helps users discover numbered Die drei ??? episodes. It includes random selection, searchable browsing, back/forward selection history, and offline metadata/previously viewed artwork. On first launch choose “Katalog herunterladen” to download the catalogue (approximately 2 MB). “Alle Folgen” opens the searchable list. The gear icon opens Settings, including the Apple Music/Spotify preference, privacy information, and artwork-cache deletion. Playback opens the selected service's content link; the companion app has no login and does not stream or download audio. Playback availability and accounts are managed by the external service. Attach the applicable content-rights evidence here.

## Sources

- https://developer.apple.com/app-store/review/guidelines/ (4.2, 5.1.1, 5.2)
- https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/
- https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype
- https://github.com/YourMJK/dreimetadaten#verwendung
