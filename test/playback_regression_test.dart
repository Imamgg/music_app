import 'dart:async';
import 'package:auno/data/models/song_model.dart';
import 'package:auno/data/repositories/youtube_audio_repository.dart';
import 'package:auno/presentation/providers/audio_player_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

const track = SongModel(
  id: 'a',
  title: 'Track',
  artist: 'Artist',
  album: '',
  coverUrl: '',
  highResCoverUrl: '',
  durationSeconds: 180,
);
const result = AudioStreamResult(
  streamUrl: 'https://example.com/audio.mp4',
  videoId: 'a',
);

class PendingRepository extends YoutubeAudioRepository {
  final pending = <String, Completer<AudioStreamResult?>>{};
  @override
  Future<AudioStreamResult?> getAudioStream(
    SongModel song, {
    bool forceRefresh = false,
  }) => (pending[song.id] ??= Completer<AudioStreamResult?>()).future;
}

class ControlledPlayer extends AudioPlayer {
  final playback = Completer<void>();
  int plays = 0;
  AudioSource? loaded;
  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();
  @override
  Stream<PlaybackEvent> get playbackEventStream => const Stream.empty();
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();
  @override
  ProcessingState get processingState => ProcessingState.ready;
  @override
  Future<void> stop() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<Duration?> setAudioSource(
    AudioSource source, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
  }) async {
    loaded = source;
    return const Duration(seconds: 180);
  }

  @override
  Future<void> play() {
    plays++;
    return playback.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PendingRepository repo;
  late ControlledPlayer engine;
  late AudioPlayerNotifier notifier;
  setUp(() {
    repo = PendingRepository();
    engine = ControlledPlayer();
    notifier = AudioPlayerNotifier(repo, player: engine);
  });
  tearDown(() {
    notifier.dispose();
    repo.dispose();
  });
  test(
    'Loading clears without waiting for playback to end; pause/resume responds immediately',
    () async {
      final loading = notifier.playSong(track);
      await Future<void>.delayed(Duration.zero);
      repo.pending['a']!.complete(result);
      await loading.timeout(const Duration(seconds: 1));
      expect(engine.playback.isCompleted, isFalse);
      expect(notifier.state.isLoadingStream, isFalse);
      expect(notifier.state.isPlaying, isTrue);
      await notifier.togglePlayPause();
      expect(notifier.state.isPlaying, isFalse);
      await notifier.togglePlayPause().timeout(const Duration(seconds: 1));
      expect(notifier.state.isPlaying, isTrue);
      expect(engine.plays, 2);
    },
  );
  test(
    'Pause during extraction prevents auto-play when source becomes ready',
    () async {
      final loading = notifier.playSong(track);
      await Future<void>.delayed(Duration.zero);
      await notifier.togglePlayPause();
      repo.pending['a']!.complete(result);
      await loading;
      expect(engine.plays, 0);
      expect(notifier.state.isPlaying, isFalse);
      expect(notifier.state.isLoadingStream, isFalse);
    },
  );
  test('Older extraction cannot replace a newer song', () async {
    final first = notifier.playSong(track);
    await Future<void>.delayed(Duration.zero);
    final secondTrack = SongModel(
      id: 'b',
      title: 'B',
      artist: '',
      album: '',
      coverUrl: '',
      highResCoverUrl: '',
      durationSeconds: 100,
    );
    final second = notifier.playSong(secondTrack);
    await Future<void>.delayed(Duration.zero);
    repo.pending['b']!.complete(result);
    await second;
    repo.pending['a']!.complete(result);
    await first;
    expect(notifier.state.currentSong!.id, 'b');
    expect(engine.plays, 1);
    expect(notifier.state.isLoadingStream, isFalse);
  });
  test('Failed extraction clears both playing and loading', () async {
    final loading = notifier.playSong(track);
    await Future<void>.delayed(Duration.zero);
    repo.pending['a']!.complete(null);
    await loading;
    expect(notifier.state.isPlaying, isFalse);
    expect(notifier.state.isLoadingStream, isFalse);
    expect(notifier.state.errorMessage, isNotNull);
  });
}
