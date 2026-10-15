import 'package:everafter/data/gallery_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('frame opening matches each photo ratio without cropping or letterboxing', () {
    for (final ratio in <double>[0.5, 2 / 3, 0.75, 1, 4 / 3, 1.5, 16 / 9, 3]) {
      final layout = singlePhotoLayoutFor(defaultGalleryLayoutFor('spain-2026'),
        <String>['photo.jpeg'], photoAspectRatios: <String, double>{'photo.jpeg': ratio});
      final frame = layout.frames.single;
      final wide = frame.style == GalleryFrameStyle.landscape;
      final openingRatio = frame.width / frame.height * (wide
        ? landscapeApertureWidth / landscapeApertureHeight
        : portraitApertureWidth / portraitApertureHeight);
      expect(openingRatio, closeTo(ratio, 0.000001));
    }
  });

  test('all 52 photos get distinct frames and the wall grows to contain them', () {
    final original = defaultGalleryLayoutFor('philippines-2025');
    final photos = List<String>.generate(52, (index) => 'assets/memories/philippines-2025/$index.jpeg');
    final sizes = <String, double>{
      for (var index = 0; index < photos.length; index++)
        photos[index]: index.isEven ? 4 / 3 : 3 / 4,
    };
    final layout = singlePhotoLayoutFor(original, photos, photoAspectRatios: sizes);
    expect(layout.frames, hasLength(52));
    expect(layout.frames.map((frame) => frame.id).toSet(), hasLength(52));
    expect(layout.frames.map((frame) => frame.effectivePhotoEdits.single.assetPath), photos);
    expect(layout.instagramPosts, isEmpty);
    for (var index = 0; index < layout.frames.length; index++) {
      final frame = layout.frames[index];
      expect(frame.style, index.isEven ? GalleryFrameStyle.landscape : GalleryFrameStyle.portrait);
      expect(frame.height * 2.3 * frame.scale, closeTo(560, 0.001));
      if (index > 0) {
        final previous = layout.frames[index - 1];
        final previousRight = previous.left + (previous.width * 2.3 * previous.scale + previous.width) / 2;
        final left = frame.left - (frame.width * 2.3 * frame.scale - frame.width) / 2;
        expect(left - previousRight, closeTo(80, 0.001));
      }
    }
    for (final frame in layout.frames) {
      final right = frame.left + (frame.width * 2.3 * frame.scale + frame.width) / 2;
      expect(right - layout.leadingTrim, lessThan(layout.stripWidth));
    }
    final repeat = singlePhotoLayoutFor(layout, photos);
    expect(repeat.toJson(), layout.toJson());
  });

  test('a trip with three photos has three frames without repeated defaults', () {
    final layout = singlePhotoLayoutFor(defaultGalleryLayoutFor('washington-2022'), <String>['a.jpeg', 'b.jpeg', 'c.jpeg']);
    expect(layout.frames, hasLength(3));
    expect(layout.frames.map((frame) => frame.effectivePhotoEdits.single.assetPath).toSet(), hasLength(3));
    expect(singlePhotoLayoutFor(layout, const <String>[]).frames, isEmpty);
  });

  test('saved crops and decorations survive one-photo binding', () {
    final base = defaultGalleryLayoutFor('spain-2026');
    final selected = base.frames.first.copyWith(
      left: 300,
      photoEdits: const <GalleryPhotoEdit>[
        GalleryPhotoEdit(assetPath: 'b.jpeg', alignmentX: 0.4, zoom: 1.8),
      ],
    );
    final original = base.copyWith(mediaLayoutVersion: 2, frames: <GalleryFramePlacement>[selected, ...base.frames.skip(1)]);
    final layout = singlePhotoLayoutFor(original, <String>['a.jpeg', 'b.jpeg']);
    final saved = layout.frames.singleWhere((frame) => frame.effectivePhotoEdits.single.assetPath == 'b.jpeg');
    expect(saved.id, selected.id);
    expect(saved.left, 300);
    expect(saved.effectivePhotoEdits.single.zoom, 1.8);
    expect(layout.trinkets, original.trinkets);
  });

  test('every video gets its own existing or added video placement', () {
    final layout = singlePhotoLayoutFor(defaultGalleryLayoutFor('spain-2026'), const <String>[], videoCount: 10);
    expect(layout.instagramPosts, hasLength(10));
    expect(layout.instagramPosts.map((post) => post.postIndex), List<int>.generate(10, (index) => index));
  });
}
