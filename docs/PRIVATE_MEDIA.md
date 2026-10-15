# Private media boundary

The public repository uses redistributable demo images and an abstract video.
This cleanup does not import personal photos, videos, travel dates, or archives.

Keep original media in the existing ignored paths, including
`assets/memories/`, `assets/images/japan/`, `assets/images/trips/`, and
private JPGs under `assets/images/taste/`. Keep a separate backup.
Do not remove these exclusions during the web-only cleanup.

Ignoring a file only prevents an ordinary new Git add. It does not protect
a file already tracked in Git, and it does not make a published web asset
private. A private Git repository also does not make a public website private.
Anyone able to load a static gallery can retrieve the media bundled with it.
A hard-to-guess trip URL is not access control.

For an intentionally private edition, keep media declarations and collection
bindings in a private checkout/overlay and choose hosting that restricts
access before deployment. Do not publish its generated build publicly.
No authentication or private-media backend is included in this project.

To register media for an approved audience:

1. Put files under `assets/memories/<trip-slug>/` in the private workspace.
2. Declare only the intended directories/files in that edition's pubspec.
3. Register photos and videos in the matching entry in `lib/data/trip_collections.dart`. Videos need
   poster images and appropriate `videoPosterPaths` entries.
4. Keep exported layout JSON private if it includes sensitive labels, dates,
   filenames, or embedded images. Review it before placing it in the public
   `assets/data/gallery_layouts.json`.

The editor does not upload media. Trinket artwork must be bundled and
registered in `galleryTrinketAssetChoices`. Existing embedded trinkets remain
readable for compatibility.

Before committing, review specific changed files with `git diff`,
`git status --short --ignored`, and `git add -n .`.
Do not stage personal media or private exports. Review the release asset
inventory separately before deploying.

See [Web setup](WEB_SETUP.md) for URL routing and layout export.
The 13 trip names are metadata, not evidence that any real media has been
imported. Keep year-specific folders and bindings separate, including the two
Royal Caribbean trips.
