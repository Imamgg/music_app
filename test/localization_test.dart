import 'package:auno/core/localization/app_strings.dart';
import 'package:auno/data/repositories/storage_repository.dart';
import 'package:auno/main.dart';
import 'package:auno/presentation/providers/library_provider.dart';
import 'package:auno/presentation/providers/settings_provider.dart';
import 'package:auno/presentation/providers/youtube_music_provider.dart';
import 'package:auno/presentation/screens/settings/content_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'song_actions_test.dart' as fixture;

void main() {
  testWidgets(
    'App language updates UI immediately without changing music or repository',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageRepository.create();
      await storage.setContentLanguage('id');
      // A recording title that is also a UI translation key must stay original.
      await storage.cacheCharts([fixture.track.copyWith(title: 'Pengaturan')]);
      final container = ProviderContainer(
        overrides: [storageRepoProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const AunoApp()),
      );
      await tester.pumpAndSettle();
      final repository = container.read(youtubeMusicRepoProvider);
      final charts = container.read(homeMusicProvider).charts;
      for (final entry in [
        (ContentLanguage.english, 'Home'),
        (ContentLanguage.japanese, 'ホーム'),
        (ContentLanguage.korean, '홈'),
        (ContentLanguage.indonesian, 'Beranda'),
      ]) {
        await container
            .read(settingsProvider.notifier)
            .setContentLanguage(entry.$1);
        await tester.pumpAndSettle();
        expect(find.text(entry.$2), findsOneWidget);
        expect(find.text('Pengaturan'), findsWidgets);
        expect(
          identical(container.read(youtubeMusicRepoProvider), repository),
          isTrue,
        );
        expect(container.read(homeMusicProvider).charts, same(charts));
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets('Language screen changes while it remains open', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageRepository.create();
    await storage.setContentLanguage('id');
    final container = ProviderContainer(
      overrides: [storageRepoProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const AunoApp()),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.text('Beranda'));
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ContentSettingsScreen()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('App language'), findsOneWidget);
    expect(
      container.read(settingsProvider).contentLanguage,
      ContentLanguage.english,
    );
    expect(storage.getContentLanguage(), 'en');
  });
  test('Every interface key has all supported translations', () {
    for (final entry in AppStrings.translations.entries) {
      expect(entry.value, hasLength(3), reason: entry.key);
      expect(
        entry.value.every((v) => v.trim().isNotEmpty),
        isTrue,
        reason: entry.key,
      );
    }
  });
}
