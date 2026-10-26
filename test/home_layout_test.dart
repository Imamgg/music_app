import 'dart:io';
import 'dart:ui' as ui;
import 'package:auno/core/theme/app_theme.dart';
import 'package:auno/data/models/song_model.dart';
import 'package:auno/data/models/playlist_model.dart';
import 'package:auno/data/repositories/youtube_music_repository.dart';
import 'package:auno/data/repositories/youtube_audio_repository.dart';
import 'package:auno/data/repositories/storage_repository.dart';
import 'package:auno/presentation/providers/audio_player_provider.dart';
import 'package:auno/presentation/providers/library_provider.dart';
import 'package:auno/presentation/providers/youtube_music_provider.dart';
import 'package:auno/presentation/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'playback_regression_test.dart' as playback;

class HomeRepository extends YouTubeMusicRepository {
  final tracks = List.generate(
    20,
    (i) => SongModel(
      id: 'track-$i',
      title: ['Senja di Kota', 'Langit yang Sama', 'Cerita Hari Ini'][i % 3],
      artist: 'Artis ${i + 1}',
      album: '',
      coverUrl: '',
      highResCoverUrl: '',
      durationSeconds: 180,
    ),
  );
  String? searched;
  @override
  Future<List<SongModel>> getTopCharts() async => tracks;
  @override
  Future<List<PlaylistModel>> getCuratedPlaylists() async => [
    PlaylistModel(
      id: 'playlist',
      title: 'Pilihan Indonesia',
      description: 'Musik untuk menemani harimu',
      createdAt: DateTime(2026),
    ),
  ];
  @override
  Future<List<SongModel>> searchMusic(String query) async {
    searched = query;
    return tracks.take(3).toList();
  }
}

void main() {
  testWidgets(
    'Home fits enlarged text, exposes working mood navigation and section links',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageRepository.create();
      final repo = HomeRepository();
      await storage.addRecentSong(repo.tracks[0]);
      await storage.setCatalogSaved('artist:UCartist', true);
      await storage.saveFollowedArtists([
        repo.tracks[0].copyWith(
          id: 'artist:UCartist',
          artist: 'Artis favorit',
          artistBrowseId: 'UCartist',
        ),
      ]);
      final audioRepo = YoutubeAudioRepository();
      final player = AudioPlayerNotifier(
        audioRepo,
        player: playback.ControlledPlayer(),
      );
      final boundary = GlobalKey();
      await (FontLoader(
        'PlusJakartaSans',
      )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageRepoProvider.overrideWithValue(storage),
            youtubeMusicRepoProvider.overrideWithValue(repo),
            audioPlayerProvider.overrideWith((_) => player),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: RepaintBoundary(key: boundary, child: const HomeScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pilihan cepat'), findsOneWidget);
      expect(find.text('Putar lagi'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (Platform.environment['CAPTURE_HOME'] == '1') {
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build/home-preview').create(recursive: true);
          await File(
            'build/home-preview/home.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.tap(find.text('Santai'));
      await tester.pumpAndSettle();
      expect(repo.searched, 'lagu santai akustik Indonesia');
      expect(find.byType(HomeSongCollection), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byTooltip('Lihat semua: Playlist pilihan'),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Lihat semua: Playlist pilihan'));
      await tester.pumpAndSettle();
      expect(find.text('Pilihan Indonesia'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      audioRepo.dispose();
    },
  );
}
