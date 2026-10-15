import 'package:everafter/routing/app_router.dart';
import 'package:everafter/theme/everafter_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EverAfterApp extends ConsumerWidget {
  const EverAfterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'EverAfter',
      debugShowCheckedModeBanner: false,
      theme: EverAfterTheme.light(),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
