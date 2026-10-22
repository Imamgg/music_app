import 'dart:io';
import 'dart:ui' as ui;
import 'package:auno/core/theme/app_theme.dart';
import 'package:auno/data/repositories/storage_repository.dart';
import 'package:auno/data/repositories/youtube_audio_repository.dart';
import 'package:auno/data/repositories/youtube_music_repository.dart';
import 'package:auno/presentation/providers/audio_player_provider.dart';
import 'package:auno/presentation/providers/catalog_provider.dart';
import 'package:auno/presentation/providers/library_provider.dart';
import 'package:auno/presentation/screens/catalog/catalog_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
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
  test(
    'Catalog metadata reads header and biography without invented statistics',
    () {
      final details = YouTubeMusicRepository.parseCatalogMetadata({
        'header': {
          'musicImmersiveHeaderRenderer': {
            'title': {
              'runs': [
                {'text': 'Last Child'},
              ],
            },
            'thumbnail': {
              'musicThumbnailRenderer': {
                'thumbnail': {
                  'thumbnails': [
                    {'url': 'artist-photo'},
                  ],
                },
              },
            },
            'description': {
              'runs': [
                {'text': 'Artist biography'},
              ],
            },
          },
        },
      });
      expect(details['title'], 'Last Child');
      expect(details['image'], 'artist-photo');
      expect(details['description'], 'Artist biography');
      expect(details.containsKey('subscribers'), isFalse);
    },
  );
  for (final kind in CatalogKind.values) {
    testWidgets('${kind.name} detail fits mobile, saves locally and scrolls', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageRepository.create();
      final repo = YoutubeAudioRepository();
      final player = fixture.TestPlayer(repo);
      final tracks = List.generate(
        9,
        (i) => fixture.song.copyWith(
          id: 'song-$i',
          title: 'Track ${i + 1}',
          artist: 'Last Child',
        ),
      );
      final data = CatalogResult(
        kind == CatalogKind.album
            ? 'Everything We Are Everything'
            : 'Last Child',
        tracks,
        browseId: 'catalog-test',
        description: 'An artist biography. ' * 20,
        subtitle: kind == CatalogKind.album ? '2015' : '',
      );
      final key = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageRepoProvider.overrideWithValue(storage),
            audioPlayerProvider.overrideWith((ref) => player),
            catalogProvider((
              song: fixture.song,
              kind: kind,
            )).overrideWith((ref) async => data),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            builder: (context, child) => RepaintBoundary(
              key: key,
              child: ColoredBox(color: const Color(0xFF24343D), child: child),
            ),
            home: CatalogScreen(song: fixture.song, kind: kind),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('CAPTURE_CATALOG')) {
        await tester.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build/catalog-previews').create(recursive: true);
          await File(
            'build/catalog-previews/${kind.name}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      final save = kind == CatalogKind.album
          ? find.byTooltip('Simpan album di perangkat')
          : find.text('Ikuti artis');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(storage.getSavedCatalogs(), contains('${kind.name}:catalog-test'));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -650));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      repo.dispose();
    });
  }
}
