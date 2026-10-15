import 'package:everafter/theme/everafter_theme.dart';
import 'package:everafter/data/trip_catalog.dart';
import 'package:everafter/widgets/trip_journey.dart';
import 'package:everafter/widgets/trip_selector.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TripExperienceScreen extends StatelessWidget {
  const TripExperienceScreen({required this.trip, super.key});
  final TripGalleryItem trip;

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const ValueKey('trip-gallery-screen'),
    backgroundColor: EverAfterColors.ink,
    body: Column(children: <Widget>[
      SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: LayoutBuilder(builder: (context, constraints) => Row(children: <Widget>[
          if (constraints.maxWidth > 600) ...<Widget>[
            const Text('TRIP HIGHLIGHTS', style: TextStyle(color: Color(0xFFBCA17A),
              fontFamily: 'Georgia', fontSize: 12, letterSpacing: 3)),
          ],
          const SizedBox(width: 12),
          Expanded(child: Align(alignment: Alignment.centerRight,
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 340),
              child: TripSelector(trip: trip,
                onSelected: (slug) => context.go('/trips/$slug'))))),
        ])),
      )),
      Expanded(child: SafeArea(top: false,
        child: TripJourney(trip: trip))),
    ]),
  );
}
