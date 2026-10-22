import 'dart:io';
import 'dart:ui' as ui;
import 'package:auno/core/theme/app_theme.dart';
import 'package:auno/data/repositories/storage_repository.dart';
import 'package:auno/data/repositories/youtube_audio_repository.dart';
import 'package:auno/presentation/providers/audio_player_provider.dart';
import 'package:auno/presentation/providers/library_provider.dart';
import 'package:auno/presentation/providers/settings_provider.dart';
import 'package:auno/presentation/screens/settings/settings_screen.dart';
import 'package:auno/presentation/screens/settings/appearance_settings_screen.dart';
import 'package:auno/presentation/screens/settings/player_audio_settings_screen.dart';
import 'package:auno/presentation/screens/settings/content_settings_screen.dart';
import 'package:auno/presentation/screens/settings/storage_settings_screen.dart';
import 'package:auno/presentation/screens/settings/about_settings_screen.dart';
import 'package:auno/presentation/widgets/glass_dialog.dart';
import 'package:auno/presentation/widgets/glass_surface.dart';
import 'package:auno/presentation/widgets/sleep_timer_bottom_sheet.dart';
import 'package:auno/presentation/widgets/settings_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'aurora_ui_test.dart' as fixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'PlusJakartaSans',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  Future<ProviderContainer> mount(
    WidgetTester tester,
    Widget screen, {
    String? capture,
  }) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageRepository.create();
    final audio = YoutubeAudioRepository();
    final container = ProviderContainer(
      overrides: [
        storageRepoProvider.overrideWithValue(storage),
        audioPlayerProvider.overrideWith((ref) => fixture.TestPlayer(audio)),
      ],
    );
    addTearDown(() {
      container.dispose();
      audio.dispose();
    });
    final boundary = GlobalKey();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: RepaintBoundary(
              key: boundary,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF263A52),
                      Color(0xFF38304F),
                      Color(0xFF153C3D),
                    ],
                  ),
                ),
                child: child,
              ),
            ),
          ),
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    if (capture != null && const bool.fromEnvironment('CAPTURE_SETTINGS')) {
      await tester.runAsync(() async {
        final image =
            await (boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('build/settings-previews').create(recursive: true);
        await File(
          'build/settings-previews/$capture.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    return container;
  }

  final screens = <String, Widget>{
    'settings': const SettingsScreen(),
    'appearance': const AppearanceSettingsScreen(),
    'audio': const PlayerAudioSettingsScreen(),
    'content': const ContentSettingsScreen(),
    'storage': const StorageSettingsScreen(),
    'about': const AboutSettingsScreen(),
  };
  for (final entry in screens.entries) {
    testWidgets(
      '${entry.key} glass cards fit a small screen with larger text',
      (tester) async {
        await mount(tester, entry.value, capture: entry.key);
        expect(find.byType(GlassSurface), findsWidgets);
        await tester.drag(find.byType(ListView).first, const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets(
    'Appearance uses a scrollable glass choice dialog and persists selection',
    (tester) async {
      final container = await mount(tester, const AppearanceSettingsScreen());
      await tester.ensureVisible(find.text('Ukuran teks lirik'));
      await tester.tap(find.text('Ukuran teks lirik'));
      await tester.pumpAndSettle();
      expect(find.byType(GlassDialog), findsOneWidget);
      await tester.ensureVisible(find.text('Besar'));
      await tester.tap(find.text('Besar'));
      await tester.pumpAndSettle();
      expect(
        container.read(settingsProvider).lyricsFontSize,
        LyricsFontSize.large,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('Audio quality uses the shared glass dialog', (tester) async {
    final container = await mount(tester, const PlayerAudioSettingsScreen());
    await tester.tap(find.text('Kualitas audio streaming'));
    await tester.pumpAndSettle();
    expect(find.byType(GlassDialog), findsOneWidget);
    await tester.ensureVisible(find.text(AudioQuality.low.label));
    await tester.tap(find.text(AudioQuality.low.label));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).audioQuality, AudioQuality.low);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Cache deletion can be cancelled in the glass confirmation', (
    tester,
  ) async {
    final container = await mount(tester, const StorageSettingsScreen());
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    expect(find.byType(GlassDialog), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).isClearingCache, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Sleep timer sheet scrolls within a small screen', (
    tester,
  ) async {
    await mount(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => SleepTimerBottomSheet.show(context),
            child: const Text('Timer'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Timer'));
    await tester.pumpAndSettle();
    expect(find.byType(GlassSurface), findsOneWidget);
    expect(find.byType(SettingsChoiceTile), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
