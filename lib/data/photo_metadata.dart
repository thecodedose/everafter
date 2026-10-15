import 'dart:convert';

import 'package:flutter/services.dart';

final Map<String, double> galleryPhotoAspectRatios = <String, double>{};

Future<Map<String, double>> loadPhotoAspectRatios() async {
  final source = await rootBundle.loadString('assets/data/photo_dimensions.json');
  final document = jsonDecode(source) as Map<String, dynamic>;
  final photos = document['photos'] as Map<String, dynamic>;
  final ratios = <String, double>{
    for (final entry in photos.entries)
      if ((entry.value['width'] as num) > 0 &&
          (entry.value['height'] as num) > 0)
        entry.key: (entry.value['width'] as num) / (entry.value['height'] as num),
  };
  galleryPhotoAspectRatios
    ..clear()
    ..addAll(ratios);
  return ratios;
}
