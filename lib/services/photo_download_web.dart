import 'package:web/web.dart' as web;

/// Download the original same-origin asset, not a screenshot of its frame.
Future<void> saveGalleryPhoto(String assetPath) async {
  final url = Uri.parse(web.document.baseURI).resolveUri(
    Uri(path: 'assets/$assetPath'),
  );
  final anchor = web.HTMLAnchorElement()
    ..href = url.toString()
    ..download = assetPath.split('/').last;
  web.document.body!.append(anchor);
  try {
    anchor.click();
  } finally {
    anchor.remove();
  }
}
