import 'dart:async';
import 'package:auno/data/models/lyric_line.dart';
import 'package:auno/data/models/song_model.dart';
import 'package:auno/data/repositories/lyrics_repository.dart';
import 'package:auno/data/repositories/storage_repository.dart';
import 'package:auno/data/repositories/youtube_audio_repository.dart';
import 'package:auno/presentation/providers/audio_player_provider.dart';
import 'package:auno/presentation/providers/catalog_provider.dart';
import 'package:auno/presentation/providers/library_provider.dart';
import 'package:auno/presentation/providers/lyrics_provider.dart';
import 'package:auno/presentation/providers/settings_provider.dart';
import 'package:auno/presentation/providers/sleep_timer_provider.dart';
import 'package:auno/presentation/providers/youtube_music_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'playback_regression_test.dart' as playback;
import 'song_actions_test.dart' as catalog;

class PendingLyrics extends LyricsRepository {
  final pending = <String, Completer<LyricsResult>>{};
  @override
  Future<LyricsResult> getLyrics(SongModel song) =>
      (pending[song.id] ??= Completer<LyricsResult>()).future;
}

class TimerPlayer extends AudioPlayerNotifier {
  TimerPlayer(super.repo) : super(player: playback.ControlledPlayer());
  int pauses = 0;
  void position(Duration value) => state = state.copyWith(position: value);
  @override
  Future<void> pause() async {
    pauses++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Selected playlist recording metadata also updates its queue entry',
    () async {
      final repo = playback.PendingRepository();
      final player = TimerPlayer(repo);
      addTearDown(() {
        player.dispose();
        repo.dispose();
      });
      final selected = catalog.track.copyWith(
        albumBrowseId: 'MPREcorrect',
        album: 'Correct album',
      );
      final queue = [catalog.track];
      final loading = player.playSong(selected, queue: queue);
      await Future<void>.delayed(Duration.zero);
      repo.pending[catalog.track.id]!.complete(playback.result);
      await loading;
      expect(player.state.currentSong!.albumBrowseId, 'MPREcorrect');
      expect(player.state.queue.single.albumBrowseId, 'MPREcorrect');
      expect(queue.single.albumBrowseId, isNull);
    },
  );

  test(
    'Opening lyrics after playback started loads current track and position',
    () async {
      final repo = playback.PendingRepository();
      final player = TimerPlayer(repo);
      final lyrics = PendingLyrics();
      final container = ProviderContainer(
        overrides: [
          audioPlayerProvider.overrideWith((ref) => player),
          lyricsRepositoryProvider.overrideWithValue(lyrics),
        ],
      );
      addTearDown(() {
        container.dispose();
        repo.dispose();
      });
      final loading = player.playSong(catalog.track);
      await Future<void>.delayed(Duration.zero);
      repo.pending[catalog.track.id]!.complete(playback.result);
      await loading;
      player.position(const Duration(seconds: 25));
      container.read(lyricsProvider);
      expect(lyrics.pending.containsKey(catalog.track.id), isTrue);
      lyrics.pending[catalog.track.id]!.complete(
        LyricsResult(
          syncedLyrics: LyricLine.parseLrc('[00:05]First\n[00:20]Current'),
          hasSyncedLyrics: true,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(container.read(lyricsProvider).activeIndex, 1);
    },
  );
  test(
    'Late lyrics cannot replace current track and clear removes plain lyrics',
    () async {
      final repo = PendingLyrics();
      final notifier = LyricsNotifier(repo);
      addTearDown(notifier.dispose);
      final a = notifier.loadLyricsForSong(catalog.track);
      final b = notifier.loadLyricsForSong(catalog.track.copyWith(id: 'b'));
      notifier.updateActivePosition(const Duration(seconds: 25));
      repo.pending['b']!.complete(
        LyricsResult(
          syncedLyrics: LyricLine.parseLrc('[00:05]B1\n[00:20]B2'),
          hasSyncedLyrics: true,
        ),
      );
      await b;
      repo.pending['track']!.complete(
        const LyricsResult(plainLyrics: 'Old lyrics'),
      );
      await a;
      expect(notifier.state.lines.first.text, 'B1');
      expect(notifier.state.activeIndex, 1);
      expect(notifier.state.plainLyrics, isNull);
      await notifier.loadLyricsForSong(null);
      expect(notifier.state.lines, isEmpty);
      expect(notifier.state.hasSyncedLyrics, isFalse);
    },
  );
  test('Lyrics loading safely ignores completion after disposal', () async {
    final repo = PendingLyrics();
    final notifier = LyricsNotifier(repo);
    final task = notifier.loadLyricsForSong(catalog.track);
    notifier.dispose();
    repo.pending['track']!.complete(const LyricsResult(plainLyrics: 'Late'));
    await task;
  });
  test('Lyrics match performer, title and recording duration', () {
    final data = <String, dynamic>{
      'trackName': 'Song',
      'artistName': 'Artist',
      'albumName': 'Album',
      'duration': 120,
    };
    expect(LyricsRepository.matchScore(catalog.track, data), greaterThan(0));
    expect(
      LyricsRepository.matchScore(catalog.track, {
        ...data,
        'artistName': 'Cover singer',
      }),
      -1,
    );
    expect(
      LyricsRepository.matchScore(catalog.track, {...data, 'duration': 160}),
      -1,
    );
    expect(
      LyricsRepository.matchScore(catalog.track, {
        ...data,
        'trackName': 'Song Live',
      }),
      -1,
    );
  });
  test('LRC tenths and intro have correct timestamps', () {
    final lines = LyricLine.parseLrc('[00:05.5]Start');
    expect(lines.single.timestamp.inMilliseconds, 5500);
    expect(LyricLine.findActiveIndex(lines, Duration.zero), -1);
  });
  test(
    'Sleep deadline catches up after background and cancel prevents stop',
    () {
      final repo = YoutubeAudioRepository();
      final player = TimerPlayer(repo);
      var now = DateTime(2026);
      final timer = SleepTimerNotifier(player, now: () => now);
      addTearDown(() {
        timer.dispose();
        player.dispose();
        repo.dispose();
      });
      timer.setTimer(const Duration(minutes: 15));
      now = now.add(const Duration(minutes: 10));
      timer.checkDeadline();
      expect(timer.state.remainingSeconds, 300);
      now = now.add(const Duration(minutes: 6));
      timer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(player.pauses, 1);
      expect(timer.state.isActive, isFalse);
      timer.setTimer(const Duration(seconds: 1));
      timer.cancelTimer();
      now = now.add(const Duration(minutes: 1));
      timer.checkDeadline();
      expect(player.pauses, 1);
    },
  );
  test('End of track stops once and replacement clears callback', () {
    final repo = YoutubeAudioRepository();
    final player = TimerPlayer(repo);
    final timer = SleepTimerNotifier(player);
    addTearDown(() {
      timer.dispose();
      player.dispose();
      repo.dispose();
    });
    timer.setEndOfTrack();
    player.onTrackEnded!();
    expect(player.pauses, 1);
    expect(timer.state.isActive, isFalse);
    expect(player.onTrackEnded, isNull);
    timer.setEndOfTrack();
    timer.setTimer(const Duration(minutes: 15));
    expect(player.onTrackEnded, isNull);
  });
  test(
    'All settings persist and app language leaves music locale unchanged',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageRepository.create();
      final container = ProviderContainer(
        overrides: [storageRepoProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);
      final settings = container.read(settingsProvider.notifier);
      final audio = container.read(youtubeAudioRepoProvider);
      await settings.setContentLanguage(ContentLanguage.japanese);
      await settings.setAudioQuality(AudioQuality.low);
      await settings.setAutoScrollLyrics(false);
      await settings.setDynamicThemeEnabled(false);
      await settings.setLyricsFontSize(LyricsFontSize.large);
      final music = container.read(youtubeMusicRepoProvider);
      expect(music.countryCode, 'ID');
      expect(music.languageCode, 'id');
      expect(audio.quality, 'low');
      expect(
        identical(audio, container.read(youtubeAudioRepoProvider)),
        isTrue,
      );
      final restored = SettingsNotifier(storage);
      addTearDown(restored.dispose);
      expect(restored.state.contentLanguage, ContentLanguage.japanese);
      expect(restored.state.audioQuality, AudioQuality.low);
      expect(restored.state.lyricsFontSize, LyricsFontSize.large);
      expect(restored.state.autoScrollLyrics, isFalse);
      expect(restored.state.dynamicThemeEnabled, isFalse);
    },
  );
  test(
    'Regional cache is isolated and clearing preserves playlists and preferences',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageRepository.create();
      await storage.cacheCharts([catalog.track], locale: 'ja-JP');
      await storage.setContentLanguage('ja');
      final library = LibraryNotifier(storage);
      addTearDown(library.dispose);
      await library.createPlaylist('Saved', initialSong: catalog.track);
      expect(storage.getCachedCharts(locale: 'id-ID'), isEmpty);
      expect(storage.getCachedCharts(locale: 'ja-JP'), hasLength(1));
      await storage.clearNetworkCache();
      expect(storage.getCachedCharts(locale: 'ja-JP'), isEmpty);
      expect(storage.getPlaylists().single.songs.single.id, catalog.track.id);
      expect(storage.getContentLanguage(), 'ja');
    },
  );
  test('Local playlist uses saved songs and reacts to added tracks', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageRepository.create();
    final repo = catalog.CatalogRepository();
    final container = ProviderContainer(
      overrides: [
        storageRepoProvider.overrideWithValue(storage),
        youtubeMusicRepoProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(() {
      container.dispose();
      repo.dispose();
    });
    final library = container.read(libraryProvider.notifier);
    final playlist = await library.createPlaylist(
      'Local',
      initialSong: catalog.track,
    );
    final provider = playlistDetailProvider(playlist);
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    expect(container.read(provider).tracks.single.id, catalog.track.id);
    await container.read(provider.notifier).refresh();
    expect(repo.requestedId, isNull);
    await library.addSongToPlaylist(
      playlist.id,
      catalog.track.copyWith(id: 'second'),
    );
    expect(container.read(provider).tracks, hasLength(2));
  });
  test('Album rejects a stale ID pointing at another recording', () async {
    final repo = catalog.CatalogRepository()
      ..pages['MPREwrong'] = [
        catalog.track.copyWith(id: 'other', title: 'Unrelated'),
      ]
      ..metadata['MPREwrong'] = {'title': 'Wrong album'};
    final container = ProviderContainer(
      overrides: [youtubeMusicRepoProvider.overrideWithValue(repo)],
    );
    addTearDown(() {
      container.dispose();
      repo.dispose();
    });
    final data = await container.read(
      catalogProvider((
        song: catalog.track.copyWith(albumBrowseId: 'MPREwrong'),
        kind: CatalogKind.album,
      )).future,
    );
    expect(data.songs, isEmpty);
    expect(data.title, 'Album');
  });
  test(
    'Audio quality selects available bitrate without promising unavailable rates',
    () {
      expect(
        YoutubeAudioRepository.selectBitrate([48000, 128000, 256000], 'low'),
        48000,
      );
      expect(
        YoutubeAudioRepository.selectBitrate([48000, 128000, 256000], 'normal'),
        128000,
      );
      expect(
        YoutubeAudioRepository.selectBitrate([48000, 128000, 256000], 'high'),
        256000,
      );
    },
  );
}
