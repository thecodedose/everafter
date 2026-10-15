@JS()
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'global_gallery_layout_file.dart';

@JS()
extension type _SaveFilePickerOptions._(JSObject _) implements JSObject {
  external factory _SaveFilePickerOptions({String suggestedName});
}

@JS('showSaveFilePicker')
external JSPromise<web.FileSystemFileHandle> _showSaveFilePicker(
  _SaveFilePickerOptions options,
);

@JS('Reflect.has')
external bool _hasProperty(JSObject object, JSString key);

GlobalGalleryLayoutFile createPlatformGlobalGalleryLayoutFile() =>
    _WebGlobalGalleryLayoutFile();

class _WebGlobalGalleryLayoutFile implements GlobalGalleryLayoutFile {
  web.FileSystemFileHandle? _handle;
  String? _fileName;

  @override
  String? get fileName => _fileName;

  @override
  Future<void> save(String contents) async {
    if (_hasProperty(web.window, 'showSaveFilePicker'.toJS)) {
      final handle =
          _handle ??
          await _showSaveFilePicker(
            _SaveFilePickerOptions(suggestedName: 'gallery_layouts.json'),
          ).toDart;
      final writable = await handle.createWritable().toDart;
      await writable.write(contents.toJS).toDart;
      await writable.close().toDart;
      _handle = handle;
      _fileName = handle.name;
      return;
    }

    final blob = web.Blob(
      <JSAny>[contents.toJS].toJS,
      web.BlobPropertyBag(type: 'application/json'),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = 'gallery_layouts.json';
    web.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    _fileName = 'gallery_layouts.json';
    Timer(const Duration(seconds: 1), () => web.URL.revokeObjectURL(url));
  }
}
