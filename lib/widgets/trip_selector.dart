import 'dart:math' as math;

import 'package:everafter/data/gallery_memory_content.dart';
import 'package:everafter/data/trip_catalog.dart';
import 'package:flutter/material.dart';

class TripSelector extends StatelessWidget {
  const TripSelector({required this.trip, required this.onSelected, super.key});

  final TripGalleryItem trip;
  final ValueChanged<String> onSelected;

  Future<void> _choose(BuildContext context) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        key: const ValueKey('trip-picker'),
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: const Color(0xFF251C18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF846B47)),
        ),
        child: SizedBox(
          width: 560,
          height: math.max(160.0, math.min(560.0, MediaQuery.sizeOf(context).height - 48)),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 8, 10),
                child: Row(children: <Widget>[
                  const Expanded(child: Text("Monica's Travels",
                    style: TextStyle(color: Color(0xFFE1C89D), fontFamily: 'Georgia',
                      fontSize: 16, letterSpacing: 2))),
                  IconButton(tooltip: 'Close trip picker',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFFB7A58C))),
                ]),
              ),
              const Divider(height: 1, color: Color(0xFF514334)),
              Expanded(child: ListView.separated(
                key: const ValueKey('trip-picker-list'),
                padding: const EdgeInsets.all(12),
                itemCount: tripGalleryItemsByYear.length,
                separatorBuilder: (_, _) => const SizedBox(height: 7),
                itemBuilder: (context, index) {
                  final item = tripGalleryItemsByYear[index];
                  final active = item.slug == trip.slug;
                  return Material(
                    color: active ? const Color(0xFF463724) : const Color(0xFF30251F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                      side: BorderSide(color: active
                        ? const Color(0xFFB69B6C) : const Color(0xFF514033))),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      key: ValueKey('choose-trip-${item.slug}'),
                      selected: active,
                      leading: _TripThumbnail(trip: item),
                      title: Text(item.location, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFF0E6D6), fontFamily: 'Georgia')),
                      subtitle: Text('${item.year}', style: const TextStyle(color: Color(0xFFBBA588))),
                      trailing: Icon(active ? Icons.check_circle_outline : Icons.arrow_forward_ios,
                        color: const Color(0xFFD0B47E), size: active ? 22 : 14),
                      onTap: () => Navigator.pop(context, item.slug),
                    ),
                  );
                },
              )),
            ],
          ),
        ),
      ),
    );
    if (selected != null && context.mounted && selected != trip.slug) onSelected(selected);
  }

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF2B211B),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFF8E744F))),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: const ValueKey('gallery-trip-selector'),
      onTap: () => _choose(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(children: <Widget>[
          _TripThumbnail(trip: trip),
          const SizedBox(width: 10),
          Expanded(child: Text(trip.name, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFE6D4B5), fontFamily: 'Georgia', fontSize: 15))),
          const SizedBox(width: 8),
          const Icon(Icons.unfold_more, color: Color(0xFFBDA476), size: 21),
        ]),
      ),
    ),
  );
}

class _TripThumbnail extends StatelessWidget {
  const _TripThumbnail({required this.trip});
  final TripGalleryItem trip;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(7),
    child: Image.asset(galleryPhotoChoicesFor(trip).first,
      width: 36, height: 36, cacheWidth: 96, fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const SizedBox(width: 36, height: 36,
        child: Icon(Icons.photo_album_outlined, color: Color(0xFFD0B47E)))),
  );
}
