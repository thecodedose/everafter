import 'package:everafter/screens/gallery_admin_screen.dart';
import 'package:everafter/screens/taste_of_japan_screen.dart';
import 'package:everafter/screens/trip_experience_screen.dart';
import 'package:everafter/screens/trip_not_found_screen.dart';
import 'package:everafter/data/trip_catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

TripGalleryItem? tripForSlug(String? slug) {
  for (final trip in tripGalleryItems) {
    if (trip.slug == slug) return trip;
  }
  return null;
}

Widget _galleryFor(String? slug) {
  final trip = tripForSlug(slug);
  return trip == null
      ? const TripNotFoundScreen()
      : TripExperienceScreen(key: ValueKey(trip.slug), trip: trip);
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: _galleryFor(tripGalleryItems.first.slug),
        ),
      ),
      GoRoute(
        path: '/trips/:slug',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: _galleryFor(state.pathParameters['slug']),
        ),
      ),
      for (final legacyPath in <String>['/trip/:slug', '/nfc/:slug'])
        GoRoute(
          path: legacyPath,
          redirect: (context, state) => Uri(
            path: '/trips/${state.pathParameters['slug']}',
            query: state.uri.hasQuery ? state.uri.query : null,
          ).toString(),
        ),
      GoRoute(
        path: '/taste/:slug',
        pageBuilder: (context, state) {
          final trip = tripForSlug(state.pathParameters['slug']);
          return NoTransitionPage<void>(
            key: state.pageKey,
            child: trip == null
                ? const TripNotFoundScreen()
                : TripTasteMenuScreen(trip: trip),
          );
        },
      ),
      GoRoute(
        path: '/admin/gallery',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const GalleryAdminScreen(),
        ),
      ),
    ],
    errorBuilder: (context, state) => const TripNotFoundScreen(),
  );
  ref.onDispose(router.dispose);
  return router;
});
