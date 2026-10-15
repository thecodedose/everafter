enum GalleryMemoryKind { photo, video }

class GalleryMemoryAsset {
  const GalleryMemoryAsset({
    required this.assetPath,
    required this.kind,
    this.posterAssetPath,
    this.alignmentX,
    this.alignmentY,
    this.zoom = 1,
  });

  final String assetPath;
  final GalleryMemoryKind kind;
  final String? posterAssetPath;
  final double? alignmentX;
  final double? alignmentY;
  final double zoom;

  bool get isVideo => kind == GalleryMemoryKind.video;
  String get displayAssetPath => posterAssetPath ?? assetPath;
}

class GalleryMemoryLocation {
  const GalleryMemoryLocation({
    required this.slug,
    required this.label,
    required this.assetPaths,
    this.videoPosterPaths = const <String, String>{},
  });

  final String slug;
  final String label;
  final List<String> assetPaths;
  final Map<String, String> videoPosterPaths;

  List<GalleryMemoryAsset> get media => assetPaths
      .map(
        (assetPath) => GalleryMemoryAsset(
          assetPath: assetPath,
          kind: videoPosterPaths.containsKey(assetPath)
              ? GalleryMemoryKind.video
              : GalleryMemoryKind.photo,
          posterAssetPath: videoPosterPaths[assetPath],
        ),
      )
      .toList(growable: false);

  int get photoCount => assetPaths.length - videoPosterPaths.length;
  int get videoCount => videoPosterPaths.length;
}

class GalleryVideoPost {
  const GalleryVideoPost({
    required this.shortcode,
    required this.permalink,
    required this.coverAssetPath,
    required this.videoAssetPath,
  });

  final String shortcode;
  final String permalink;
  final String coverAssetPath;
  final String videoAssetPath;
}

class TasteMemory {
  const TasteMemory({
    required this.place,
    required this.city,
    required this.dish,
    required this.note,
    required this.detail,
    required this.assetPath,
    required this.accessionNumber,
  });

  final String place;
  final String city;
  final String dish;
  final String note;
  final String detail;
  final String assetPath;
  final String accessionNumber;
}

class GalleryTripCollection {
  const GalleryTripCollection({
    this.locations = const <GalleryMemoryLocation>[],
    this.videoPosts = const <GalleryVideoPost>[],
    this.tastes = const <TasteMemory>[],
  });

  final List<GalleryMemoryLocation> locations;
  final List<GalleryVideoPost> videoPosts;
  final List<TasteMemory> tastes;

  GalleryTripCollection copyWith({
    List<GalleryMemoryLocation>? locations,
    List<GalleryVideoPost>? videoPosts,
    List<TasteMemory>? tastes,
  }) => GalleryTripCollection(
    locations: locations ?? this.locations,
    videoPosts: videoPosts ?? this.videoPosts,
    tastes: tastes ?? this.tastes,
  );
}
