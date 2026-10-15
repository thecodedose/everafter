# Web security and persistence

This is a static Flutter website. It has no remote database, login system,
upload service, or automatic synchronization.

`/admin/gallery` has no administrator authentication. Edits affect the
current session. Export writes a user-selected local JSON file or requests
a browser download; it cannot modify the hosted website or repository.

The bundled `assets/data/gallery_layouts.json` is the shared baseline.
Replace it in the source and rebuild/redeploy to distribute edits.
Reloading discards unexported session edits. The native preferences and
device-override migration paths have been removed.

When the browser supports the File System Access save picker, the editor
can reuse the selected file handle within that session. Other browsers
download `gallery_layouts.json`. Cancellation/failure keeps pending edits.
The app cannot verify that a downloaded file was retained or installed.

All media included in a publicly served build is retrievable by visitors.
Trip slugs and an NFC URL are navigation, not authentication or encryption.
See [Private media](PRIVATE_MEDIA.md) before adding personal content.

Use HTTPS hosting. Existing local/bundled trinket validation is retained;
legacy HTTP-only trinket sources are not restored by this cleanup.
