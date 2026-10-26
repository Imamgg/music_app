import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:auno/presentation/widgets/auno_logo.dart';
import 'package:auno/presentation/widgets/auno_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Splash blocks taps, reveals mounted content and never replays', (
    tester,
  ) async {
    var taps = 0;
    var homeBuilds = 0;
    final previewKey = GlobalKey();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Widget app(String label) => MaterialApp(
      home: RepaintBoundary(
        key: previewKey,
        child: AunoSplash(
          child: Builder(
            builder: (context) {
              homeBuilds++;
              return Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => taps++,
                    child: Text(label),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpWidget(app('Home'));
    expect(find.byKey(const ValueKey('auno-splash')), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    await tester.tap(find.text('Home'), warnIfMissed: false);
    expect(taps, 0);
    await tester.runAsync(
      () => precacheImage(
        const AssetImage(AunoLogo.asset),
        tester.element(find.byType(AunoSplash)),
      ),
    );
    await tester.pump();
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(microseconds: 16667));
    }
    expect(
      homeBuilds,
      1,
      reason: 'Splash ticks must not rebuild the home screen',
    );
    if (Platform.environment['CAPTURE_SPLASH'] == '1') {
      await tester.runAsync(() async {
        final boundary =
            previewKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/splash-preview/splash.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('auno-splash')), findsNothing);
    await tester.tap(find.text('Home'));
    expect(taps, 1);
    await tester.pumpWidget(app('Beranda'));
    expect(find.byKey(const ValueKey('auno-splash')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduced motion opens content without a splash delay', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: AunoSplash(child: Scaffold(body: Text('Home'))),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('auno-splash')), findsNothing);
    expect(find.text('Home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
