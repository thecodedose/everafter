import 'package:everafter/app.dart';
import 'package:everafter/data/gallery_layout.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await GalleryLayoutStore.instance.load();
  runApp(const ProviderScope(child: EverAfterApp()));
}
