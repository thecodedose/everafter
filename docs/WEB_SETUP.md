# Web setup and NFC URLs

## Local preview

Use Flutter with Dart 3.12.1 or later and Chrome:

```sh
flutter pub get
flutter run -d chrome --web-hostname 0.0.0.0 --web-port 8080
```

For a phone on the same network, open the computer's LAN IP on port 8080.
Device/firewall access still needs to be available. This is a development
preview, not the permanent URL to write onto a magnet.

## Routes and destinations

`/` opens Spain 2026 directly. Registered paths are:

- `/trips/spain-2026` — Spain 2026
- `/trips/paris-2026` — Paris 2026
- `/trips/georgia-aquarium-2026` — Georgia Aquarium 2026
- `/trips/philippines-2025` — Philippines 2025
- `/trips/washington-2022` — Washington 2022
- `/trips/new-york-2024` — New York 2024
- `/trips/carnival-2024` — Carnival 2024
- `/trips/royal-caribbean-2024` — Royal Caribbean 2024
- `/trips/msc-2025` — MSC 2025
- `/trips/epic-universal-2025` — EPIC Universal 2025
- `/trips/norwegian-2025` — Norwegian 2025
- `/trips/royal-caribbean-2026` — Royal Caribbean 2026
- `/trips/universal-2026` — Universal 2026

Old demo destination names are not aliases to your own trips. Unknown slugs
show a recovery page. `/trip/<slug>` and `/nfc/<slug>` redirect to the canonical
year-specific path when that new slug is supplied.

The selector opens the existing collection. The gallery wall fills the screen;
swipe horizontally, tap a frame to focus it, use previous/next, pinch to zoom,
and tap outside or use Back to close focus. Food-menu decorations retain
their opening transition and destination menu. Videos begin muted; their
sound button enables audio after an explicit tap.

## Edit and export

Open `/admin/gallery`. On phones choose Canvas or Inspector. Existing
frame styles, media selection/crop, position/rotation/size, decorations,
dates, visibility, and fit/reset tools remain available.

Export layout uses the browser save picker when available. Otherwise it
downloads `gallery_layouts.json`. Cancelled/failed export retains edits.
There is no browser upload or automatic remote save.

To distribute a change, replace `assets/data/gallery_layouts.json` with
the exported file in the source checkout, review it, rebuild, and redeploy.
The browser cannot overwrite the hosted file. Reloading loses unexported
edits; preserve exported copies and original media separately.

## Build and host

```sh
flutter pub get
dart format .
flutter analyze
flutter test
flutter run -d chrome
flutter build web --release
```

The bootstrap uses the bundled CanvasKit renderer and licensed local Roboto
and Noto Sans Symbols fonts. Initial rendering does not need Google CDN
requests. If adding text in another script, bundle its fallback font under
web/fonts with its license before publishing.

Deploy the contents of `build/web` at the domain root over HTTPS.
The host must serve real assets normally and fall back to `/index.html`
for app routes. A direct visit and refresh at `/trips/spain-2026` must work.

`web/_redirects` is copied into the build and supplies the fallback for
Netlify and other hosts supporting that file. Other hosts need their own
equivalent rewrite. GitHub Pages does not provide this rewrite behavior
automatically; choosing it would require a separate routing workaround.
Do not claim deployment is verified until the chosen host passes direct-link
and refresh checks. Subdirectory hosting also needs a matching Flutter
`--base-href` and manifest paths.

The themed unknown-trip screen is client-side recovery. A static SPA fallback
may still return HTTP 200 for it; that is different from a server HTTP 404.

## Program a magnet

Write the full permanent HTTPS URL as an NDEF URL record, for example
`https://your-domain.example/trips/spain-2026`. The phone's operating system
reads the tag and offers/opens that URL in its browser. The website needs
no NFC permission, native app, hardware UID mapping, or reader integration.
Test each physical tag on an iPhone and Android phone after hosting.

## Add a destination later

Register a new TripGalleryItem in `lib/data/trip_catalog.dart` with a
unique explicit slug and year. Add its grouped media, video posts and optional
food records to its entry in `lib/data/trip_collections.dart`. Declare only approved media in the
appropriate pubspec. Existing default layouts support a new slug; curate
it in the editor and export its baseline. Geographic boundaries, globe
sprites, native NFC UIDs, and new launch screens are unnecessary.

## Media privacy

Read PRIVATE_MEDIA.md before adding photos or videos. An ignored source
file can still be exposed in a publicly deployed build if it is bundled.
Private Git source and unguessable URLs do not restrict public asset access.
This project adds no login or private-media hosting system.

## Register actual media later

No actual trip photos or videos have been supplied. The initial content table
uses one public still and one abstract video, clearly documented as previews.
For approved media, keep an original backup, use a private year-specific folder
such as `assets/memories/royal-caribbean-2026/`, and register files/posters only
in that trip's collection and the private build's asset declarations. Keep
the two Royal Caribbean years independent. Do not publish personal media merely
because it is ignored by Git. Publicly hosted build assets are retrievable.

## Validation

Checked on 2026-10-15 with Flutter 3.44.1, Dart 3.12.1 and Google Chrome
for Testing 151 (headless):

- All six documented Flutter commands completed. All 49 automated tests pass
  and static analysis reports no issues.
- Gallery, editor and curated food menus fit 320 × 568, 390 × 844,
  430 × 932 and 844 × 390 test viewports.
- Cold URLs and refreshes work for all 13 trips on a local server configured
  with an index fallback. Unknown-trip recovery and legacy query redirects pass.
- Browser video plays inline, starts muted, permits sound only after a tap,
  and is disposed on close. The browser JSON download works; file-picker
  interop was checked with a simulated file handle.
- The final browser check recorded no page or console errors. All 26 retained
  original gallery assets are unchanged.

The release compiler emits a warning about the optional CupertinoIcons font.
App widgets use Material icons and the unused cupertino_icons package remains
removed. The release build succeeds.

Phone sizes were emulated in Chrome. Physical iPhone Safari, Android browsers,
the final hosting rewrite and real NFC tags still need checks after a host
and permanent domain are chosen. No deployment or GitHub push was performed.
