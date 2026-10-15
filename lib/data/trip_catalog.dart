import 'package:everafter/data/public_demo_assets.dart';

class TripGalleryItem {
  const TripGalleryItem({
    required this.number,
    required this.location,
    required this.year,
    required this.slug,
    this.assetPath = publicMemoryPlaceholderAsset,
    this.startDateLabel,
    this.endDateLabel,
    this.totalDays,
  });

  final int number;
  final String location;
  final int year;
  final String slug;
  final String assetPath;
  final String? startDateLabel;
  final String? endDateLabel;
  final int? totalDays;

  String get name => '$location $year';
  String get portraitAssetPath => assetPath;
  String get dateRangeLabel => startDateLabel != null && endDateLabel != null
      ? '$startDateLabel  →  $endDateLabel'
      : '$year';
  String? get durationLabel => totalDays == null ? null : '$totalDays DAYS';
}

const List<TripGalleryItem> tripGalleryItems = <TripGalleryItem>[
  TripGalleryItem(number: 1, location: 'Spain', year: 2026, slug: 'spain-2026'),
  TripGalleryItem(number: 2, location: 'Paris', year: 2026, slug: 'paris-2026'),
  TripGalleryItem(
    number: 3,
    location: 'Georgia Aquarium',
    year: 2026,
    slug: 'georgia-aquarium-2026',
  ),
  TripGalleryItem(
    number: 4,
    location: 'Philippines',
    year: 2025,
    slug: 'philippines-2025',
  ),
  TripGalleryItem(
    number: 5,
    location: 'Washington',
    year: 2022,
    slug: 'washington-2022',
  ),
  TripGalleryItem(
    number: 6,
    location: 'New York',
    year: 2024,
    slug: 'new-york-2024',
  ),
  TripGalleryItem(
    number: 7,
    location: 'Carnival',
    year: 2024,
    slug: 'carnival-2024',
  ),
  TripGalleryItem(
    number: 8,
    location: 'Royal Caribbean',
    year: 2024,
    slug: 'royal-caribbean-2024',
  ),
  TripGalleryItem(number: 9, location: 'MSC', year: 2025, slug: 'msc-2025'),
  TripGalleryItem(
    number: 10,
    location: 'EPIC Universal',
    year: 2025,
    slug: 'epic-universal-2025',
  ),
  TripGalleryItem(
    number: 11,
    location: 'Norwegian',
    year: 2025,
    slug: 'norwegian-2025',
  ),
  TripGalleryItem(
    number: 12,
    location: 'Royal Caribbean',
    year: 2026,
    slug: 'royal-caribbean-2026',
  ),
  TripGalleryItem(
    number: 13,
    location: 'Universal',
    year: 2026,
    slug: 'universal-2026',
  ),
];
