import 'dart:ui' as ui;
import 'package:auno/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Shared backdrop stays unchanged throughout push and pop', (
    tester,
  ) async {
    final captureKey = GlobalKey();
    final navigatorKey = GlobalKey<NavigatorState>();
    const backdrop = Color(0xFF26485A);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        theme: AppTheme.darkTheme,
        builder: (context, child) => RepaintBoundary(
          key: captureKey,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: backdrop),
              child!,
            ],
          ),
        ),
        home: const Scaffold(body: Center(child: Text('Settings'))),
      ),
    );
    Future<void> checkBackdrop() async {
      final boundary =
          captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final offset = ((image.height - 2) * image.width + image.width - 2) * 4;
      expect(bytes.getUint8(offset), 0x26);
      expect(bytes.getUint8(offset + 1), 0x48);
      expect(bytes.getUint8(offset + 2), 0x5A);
      image.dispose();
    }

    await tester.runAsync(checkBackdrop);
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Center(child: Text('Appearance'))),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(checkBackdrop);
    }
    navigatorKey.currentState!.pop();
    await tester.pump();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(checkBackdrop);
    }
    expect(tester.takeException(), isNull);
  });
}

