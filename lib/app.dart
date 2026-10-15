import 'package:everafter/routing/app_router.dart';
import 'package:everafter/theme/everafter_theme.dart';
import 'package:everafter/widgets/landscape_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EverAfterApp extends ConsumerWidget {
  const EverAfterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Trip Highlights',
      debugShowCheckedModeBanner: false,
      theme: EverAfterTheme.light(),
      builder: (context, child) => LandscapeViewport(
        child: child ?? const SizedBox.shrink(),
      ),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
