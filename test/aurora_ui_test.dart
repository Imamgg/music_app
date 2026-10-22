import 'package:auno/core/theme/app_theme.dart';
import 'package:auno/data/models/song_model.dart';
import 'package:auno/data/repositories/storage_repository.dart';
import 'package:auno/data/repositories/youtube_audio_repository.dart';
import 'package:auno/presentation/providers/audio_player_provider.dart';
import 'package:auno/presentation/providers/library_provider.dart';
import 'package:auno/presentation/widgets/mini_player_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const song = SongModel(
  id: 'aurora-test',
  title: 'A long song title for a compact screen',
  artist: 'AUNO',
  album: '',
  coverUrl: '',
  highResCoverUrl: '',
  durationSeconds: 200,
);

class TestPlayer extends AudioPlayerNotifier {
  TestPlayer(super.repo) {
    state = const AudioPlayerState(currentSong: song);
  }
  int nextCount = 0;
  int previousCount = 0;
  int toggleCount = 0;
  @override
  Future<void> playNext() async {
    nextCount++;
  }

  @override
  Future<void> playPrevious() async {
    previousCount++;
  }

  @override
  Future<void> togglePlayPause() async {
    toggleCount++;
  }
}

void main() {
  testWidgets('Compact mini-player supports swipe and accessible controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageRepository.create();
    final repo = YoutubeAudioRepository();
    final player = TestPlayer(repo);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageRepoProvider.overrideWithValue(storage),
          audioPlayerProvider.overrideWith((ref) => player),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(body: Center(child: MiniPlayerWidget())),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.fling(
      find.byType(MiniPlayerWidget),
      const Offset(-200, 0),
      800,
    );
    await tester.pump();
    expect(player.nextCount, 1);
    await tester.fling(
      find.byType(MiniPlayerWidget),
      const Offset(200, 0),
      800,
    );
    await tester.pump();
    expect(player.previousCount, 1);
    await tester.tap(find.byTooltip('Putar'));
    expect(player.toggleCount, 1);
    await tester.tap(find.byTooltip('Sukai lagu'));
    await tester.pump();
    expect(find.byTooltip('Hapus dari favorit'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    repo.dispose();
  });
}
