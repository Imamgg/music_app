import 'package:auno/data/models/song_model.dart';
import 'package:auno/presentation/providers/audio_player_provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:auno/presentation/providers/media_notification_handler.dart';
import 'package:flutter_test/flutter_test.dart';

const song = SongModel(
  id: 'track',
  title: 'Boyfriend',
  artist: 'Justin Bieber',
  album: 'Believe',
  coverUrl: '',
  highResCoverUrl: '',
  durationSeconds: 0,
);
void main() {
  test(
    'Duration and artwork refresh even when recording ID stays unchanged',
    () {
      final handler = AunoMediaHandler();
      handler.publish(const AudioPlayerState(currentSong: song), false);
      expect(handler.mediaItem.value?.artUri, isNull);
      handler.publish(
        AudioPlayerState(
          currentSong: song.copyWith(
            highResCoverUrl: 'https://example.test/cover.jpg',
          ),
          duration: const Duration(seconds: 171),
        ),
        true,
      );
      expect(handler.mediaItem.value?.duration, const Duration(seconds: 171));
      expect(
        handler.mediaItem.value?.artUri.toString(),
        'https://example.test/cover.jpg',
      );
      expect(
        handler.playbackState.value.controls.last.androidIcon,
        'drawable/auno_favorite',
      );
      expect(handler.playbackState.value.androidCompactActionIndices, [
        1,
        2,
        3,
      ]);
      expect(handler.playbackState.value.systemActions, {MediaAction.seek});
    },
  );
  test(
    'Normal progress avoids rebuilding controls but seeking and state changes publish',
    () {
      final handler = AunoMediaHandler();
      const initial = AudioPlayerState(currentSong: song, isPlaying: true);
      handler.publish(initial, false);
      final first = handler.playbackState.value;
      handler.publish(
        initial.copyWith(position: const Duration(milliseconds: 100)),
        false,
      );
      expect(identical(handler.playbackState.value, first), true);
      handler.publish(
        initial.copyWith(position: const Duration(seconds: 30)),
        false,
      );
      expect(
        handler.playbackState.value.updatePosition,
        const Duration(seconds: 30),
      );
      handler.publish(
        initial.copyWith(isPlaying: false, isShuffle: true),
        false,
      );
      expect(handler.playbackState.value.controls[2], MediaControl.play);
      expect(
        handler.playbackState.value.controls.first.androidIcon,
        'drawable/auno_shuffle_on',
      );
    },
  );
  test(
    'Seek is bounded and clearing playback removes stale notification metadata',
    () async {
      final handler = AunoMediaHandler();
      handler.publish(
        const AudioPlayerState(
          currentSong: song,
          duration: Duration(seconds: 171),
        ),
        false,
      );
      Duration? sought;
      handler.onSeek = (position) async {
        sought = position;
      };
      await handler.seek(const Duration(seconds: 300));
      expect(sought, const Duration(seconds: 171));
      handler.publish(const AudioPlayerState(), false);
      expect(handler.mediaItem.value, isNull);
      expect(
        handler.playbackState.value.processingState,
        AudioProcessingState.idle,
      );
      handler.detach();
      expect(handler.onSeek, isNull);
    },
  );

  test('Notification commands reach player and library callbacks', () async {
    final handler = AunoMediaHandler();
    final calls = <String>[];
    handler.onPlay = () async {
      calls.add('play');
    };
    handler.onPause = () async {
      calls.add('pause');
    };
    handler.onNext = () async {
      calls.add('next');
    };
    handler.onPrevious = () async {
      calls.add('previous');
    };
    handler.onSeek = (value) async {
      calls.add('seek:${value.inSeconds}');
    };
    handler.onShuffle = () {
      calls.add('shuffle');
    };
    handler.onLike = () async {
      calls.add('like');
    };
    await handler.play();
    await handler.pause();
    await handler.skipToNext();
    await handler.skipToPrevious();
    await handler.seek(const Duration(seconds: 30));
    await handler.customAction('shuffle');
    await handler.customAction('like');
    expect(calls, [
      'play',
      'pause',
      'next',
      'previous',
      'seek:30',
      'shuffle',
      'like',
    ]);
  });
}
