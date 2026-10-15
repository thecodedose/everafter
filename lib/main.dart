import 'package:everafter/app.dart';
import 'package:everafter/data/gallery_layout.dart';
import 'package:everafter/data/trip_collections.dart';
import 'package:everafter/data/photo_metadata.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await loadTripCollections();
  await GalleryLayoutStore.instance.load();
  final photoAspectRatios = await loadPhotoAspectRatios();
  GalleryLayoutStore.instance.bindTripMedia(
    <String, List<String>>{
      for (final entry in tripCollections.entries)
        entry.key: <String>[
          for (final location in entry.value.locations)
            ...location.assetPaths,
        ],
    },
    videoCountsByTrip: <String, int>{
      for (final entry in tripCollections.entries)
        entry.key: entry.value.videoPosts.length,
    },
    photoAspectRatios: photoAspectRatios,
  );
  runApp(const ProviderScope(child: EverAfterApp()));
}
