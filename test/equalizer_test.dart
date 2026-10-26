import 'package:auno/data/repositories/storage_repository.dart';
import 'package:auno/presentation/providers/equalizer_provider.dart';
import 'package:auno/presentation/screens/settings/equalizer_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late EqualizerController eq;
  late StorageRepository storage;
  final calls = <MethodCall>[];
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = StorageRepository(await SharedPreferences.getInstance());
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(EqualizerController.channel, (call) async {
          calls.add(call);
          if (call.method == 'attach') {
            return {
              'frequencies': [60.0, 1000.0, 14000.0],
              'min': -4.0,
              'max': 4.0,
              'bassSupported': true,
            };
          }
          return true;
        });
  });
  tearDown(() {
    eq.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(EqualizerController.channel, null);
  });
  testWidgets(
    'Device bands clamp presets and persist manual settings across sessions',
    (tester) async {
      eq = EqualizerController(storage);
      await eq.attachSession(10);
      eq.setEnabled(true);
      eq.setPreset('Bass Boost');
      expect(eq.gain(60), 4);
      eq.setGain(1000, -2);
      eq.setBass(400);
      await tester.pump(const Duration(milliseconds: 100));
      final restored = EqualizerController(storage);
      expect(restored.enabled, true);
      expect(restored.preset, 'Manual');
      expect(restored.gain(1000), -2);
      expect(restored.bass, 400);
      restored.dispose();
      await eq.attachSession(11);
      await tester.pump(const Duration(milliseconds: 100));
      expect(calls.last.arguments['session'], 11);
      expect(calls.last.arguments['gains'], [4.0, -2.0, 0.0]);
      eq.setEnabled(false);
      await tester.pump(const Duration(milliseconds: 100));
      expect(calls.last.arguments['enabled'], false);
      eq.reset();
      expect(eq.gain(60), 0);
      expect(eq.bass, 0);
      await tester.pump(const Duration(milliseconds: 100));
    },
  );
  testWidgets(
    'Unsupported device explains availability without active controls',
    (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            EqualizerController.channel,
            (_) async => {'frequencies': [], 'bassSupported': false},
          );
      eq = EqualizerController(storage);
      await eq.attachSession(10);
      expect(eq.ready, false);
      expect(eq.status, contains('tidak tersedia'));
      await tester.pump(const Duration(milliseconds: 100));
    },
  );
  testWidgets('Panel remains scrollable on narrow screens with enlarged text', (
    tester,
  ) async {
    eq = EqualizerController(storage);
    await eq.attachSession(10);
    eq.setEnabled(true);
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [equalizerProvider.overrideWith((ref) => eq)],
        child: MaterialApp(
          builder: (_, child) => MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: child!,
          ),
          home: const EqualizerSettingsScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.scrollUntilVisible(find.text('Reset suara'), 200);
    expect(tester.takeException(), isNull);
    // ProviderScope owns this instance once mounted.
    await tester.pumpWidget(const SizedBox());
    eq = EqualizerController(storage);
  });
}
