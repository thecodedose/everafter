# EverAfter travel gallery

A mobile-first Flutter website for NFC travel magnets, adapted from
[EverAfter](https://github.com/thecodedose/everafter). The original decorated
gallery wall, frames, photo/video viewing, menu transitions, and layout editor
are retained.

## Run

Install Flutter with Dart 3.12.1 or later and Chrome:

```sh
flutter pub get
flutter run -d chrome
```

The root opens Spain 2026 directly. Each collection has a permanent path such
as `/trips/paris-2026` or `/trips/universal-2026`. Unknown trips show a recovery
page. Open `/admin/gallery` to customize frames, photos, decorations and dates.

The thirteen requested destinations are registered independently, including
Royal Caribbean 2024 and 2026. Each currently uses public preview media; no
personal trip archive is included. Register approved media in
`lib/data/trip_collections.dart` and the appropriate private build's pubspec.

## Customize and host

Export edits from the gallery editor, replace
`assets/data/gallery_layouts.json` in the source, and rebuild to distribute
changes. Reloading loses unexported edits. Export supports browser downloads
and the save picker where available.

```sh
dart format .
flutter analyze
flutter test
flutter build web --release
```

Host `build/web` over HTTPS with an index fallback for direct trip links.
The included `_redirects` supports hosts that recognize that file. Other
hosts need an equivalent rewrite. Write the full HTTPS trip URL to each NFC
magnet; the website needs no NFC permission or native application.

- [Web setup, destination URLs and editing](docs/WEB_SETUP.md)
- [Private media](docs/PRIVATE_MEDIA.md)
- [Security and persistence](docs/SECURITY.md)

Bundled assets on a public website are publicly retrievable. Review media
before publishing. The editor has no login or remote write access.
