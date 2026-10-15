import 'package:everafter/data/gallery_layout.dart';
import 'package:everafter/services/global_gallery_layout_file.dart';
import 'package:everafter/data/trip_catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _Exporter implements GlobalGalleryLayoutFile {
  String? saved;
  bool fail = false;
  @override
  String? get fileName => saved == null ? null : 'gallery_layouts.json';
  @override
  Future<void> save(String contents) async {
    if (fail) throw StateError('Export failed');
    saved = contents;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Royal Caribbean years keep independent layout edits', () async {
    final store = GalleryLayoutStore.forTesting(_Exporter());
    addTearDown(store.dispose);
    await store.load();
    final oldTrip = store.layoutFor('royal-caribbean-2024').toJson();
    final newFrame = store.layoutFor('royal-caribbean-2026').frames.first;
    store.updateFrame(
      'royal-caribbean-2026',
      newFrame.copyWith(title: '2026 only'),
    );
    expect(store.layoutFor('royal-caribbean-2024').toJson(), oldTrip);
    expect(
      store.layoutFor('royal-caribbean-2026').frames.first.title,
      '2026 only',
    );
  });

  test('global layout document round-trips every field', () {
    final original = <String, GalleryTripLayout>{
      'spain-2026': defaultGalleryLayoutFor('spain-2026'),
      'royal-caribbean-2024': defaultGalleryLayoutFor('royal-caribbean-2024'),
    };
    final decoded = decodeGlobalGalleryLayoutDocument(
      encodeGlobalGalleryLayoutDocument(original),
    );
    expect(decoded.keys, original.keys);
    for (final slug in original.keys) {
      expect(decoded[slug]!.toJson(), original[slug]!.toJson());
    }
  });

  test('bundled JSON contains every existing destination', () async {
    final contents = await rootBundle.loadString(
      GalleryLayoutStore.bundledGlobalLayoutPath,
    );
    final layouts = decodeGlobalGalleryLayoutDocument(contents);
    expect(
      layouts.keys,
      unorderedEquals(tripGalleryItems.map((trip) => trip.slug)),
    );
  });

  test(
    'export preserves edits and clears the pending flag after success',
    () async {
      final exporter = _Exporter();
      final store = GalleryLayoutStore.forTesting(exporter);
      addTearDown(store.dispose);
      await store.load();
      final original = store.layoutFor('spain-2026');
      store.updateFrame(
        'spain-2026',
        original.frames.first.copyWith(title: 'Exported title'),
      );
      expect(store.hasUnsavedChanges, isTrue);
      await store.save();
      final exported = decodeGlobalGalleryLayoutDocument(exporter.saved!);
      expect(exported['spain-2026']!.frames.first.title, 'Exported title');
      expect(store.hasUnsavedChanges, isFalse);
      await store.resetTrip('spain-2026');
      expect(store.layoutFor('spain-2026').toJson(), original.toJson());
      expect(store.hasUnsavedChanges, isTrue);
    },
  );

  test('failed export preserves pending edits', () async {
    final exporter = _Exporter()..fail = true;
    final store = GalleryLayoutStore.forTesting(exporter);
    addTearDown(store.dispose);
    await store.load();
    store.updateFrame(
      'spain-2026',
      store.layoutFor('spain-2026').frames.first.copyWith(title: 'Keep me'),
    );
    await expectLater(store.save(), throwsStateError);
    expect(store.hasUnsavedChanges, isTrue);
    expect(store.layoutFor('spain-2026').frames.first.title, 'Keep me');
  });
}
