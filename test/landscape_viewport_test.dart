import 'package:everafter/widgets/landscape_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in <Size>[Size(390, 844), Size(844, 390), Size(320, 568), Size(1280, 800)]) {
    testWidgets('landscape viewport fills $size with correct hit testing', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.binding.setSurfaceSize(size);
      addTearDown(() async {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        await tester.binding.setSurfaceSize(null);
      });
      var taps = 0;
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => LandscapeViewport(child: child!),
        home: Builder(builder: (context) {
          final logical = MediaQuery.sizeOf(context);
          expect(logical.width, greaterThanOrEqualTo(logical.height));
          return GestureDetector(
            key: const ValueKey('horizontal-content'),
            onTap: () => taps++,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          );
        }),
      ));
      expect(tester.getSize(find.byKey(const ValueKey('horizontal-content'))), Size(size.longestSide, size.shortestSide));
      expect(tester.getRect(find.byKey(const ValueKey('horizontal-content'))), Offset.zero & size);
      await tester.tap(find.byKey(const ValueKey('horizontal-content')));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('portrait safe-area insets rotate with the landscape content', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(390, 844), padding: EdgeInsets.fromLTRB(1, 2, 3, 4)),
      child: LandscapeViewport(child: Builder(builder: (context) {
        expect(MediaQuery.paddingOf(context), const EdgeInsets.fromLTRB(2, 3, 4, 1));
        return const SizedBox.expand();
      })),
    ));
  });
}
