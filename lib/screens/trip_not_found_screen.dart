import 'package:everafter/theme/everafter_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TripNotFoundScreen extends StatelessWidget {
  const TripNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('trip-not-found'),
      backgroundColor: EverAfterColors.paper,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Trip not found',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                const Text(
                  'This location is not available yet.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Open gallery'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
