import 'package:everafter/theme/everafter_theme.dart';
import 'package:everafter/data/trip_catalog.dart';
import 'package:everafter/widgets/trip_journey.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TripExperienceScreen extends StatefulWidget {
  const TripExperienceScreen({required this.trip, super.key});

  final TripGalleryItem trip;

  @override
  State<TripExperienceScreen> createState() => _TripExperienceScreenState();
}

class _TripExperienceScreenState extends State<TripExperienceScreen> {
  final _galleryKey = GlobalKey<TripJourneyState>();

  Future<void> _returnToGallery() async {
    if (await _galleryKey.currentState?.dismissFocusedMemoryIfNeeded() ??
        false) {
      return;
    }
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('trip-gallery-screen'),
      backgroundColor: EverAfterColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          TripJourney(
            key: _galleryKey,
            trip: widget.trip,
            onTasteTap: () async {
              await context.push<void>('/taste/${widget.trip.slug}');
            },
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: <Widget>[
                    IconButton.filledTonal(
                      key: const ValueKey('trip-back-to-gallery'),
                      tooltip: 'Back to gallery',
                      onPressed: _returnToGallery,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Material(
                        color: const Color(0xE6231815),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              key: const ValueKey('gallery-trip-selector'),
                              value: widget.trip.slug,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF231815),
                              style: const TextStyle(
                                color: EverAfterColors.paper,
                              ),
                              items: <DropdownMenuItem<String>>[
                                for (final trip in tripGalleryItems)
                                  DropdownMenuItem(
                                    value: trip.slug,
                                    child: Text(
                                      trip.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (slug) {
                                if (slug != null && slug != widget.trip.slug) {
                                  context.go('/trips/$slug');
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
