import 'dart:async';
import 'package:auno/data/models/song_model.dart';
import 'package:auno/data/repositories/youtube_audio_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const song = SongModel(
  id: 'one',
  title: 'Song',
  artist: 'Artist',
  album: '',
  coverUrl: '',
  highResCoverUrl: '',
  durationSeconds: 180,
  youtubeVideoId: 'recording',
);
const audio = AudioStreamResult(
  streamUrl: 'https://example.test/audio',
  videoId: 'recording',
);
void main() {
  test(
    'Known source identity is reused when refreshing a legacy catalog song',
    () async {
      const legacy = SongModel(
        id: 'legacy',
        title: 'Song',
        artist: 'Artist',
        album: '',
        coverUrl: '',
        highResCoverUrl: '',
        durationSeconds: 180,
      );
      final requestedIds = <String?>[];
      final repo = YoutubeAudioRepository(
        streamResolver: (request, _, _) async {
          requestedIds.add(request.youtubeVideoId);
          return audio;
        },
      );
      addTearDown(repo.dispose);
      await repo.getAudioStream(legacy);
      await repo.getAudioStream(legacy, forceRefresh: true);
      expect(requestedIds, [null, 'recording']);
    },
  );
  test(
    'Prefetch and play share one request, even across IDs for the same recording',
    () async {
      var calls = 0;
      final pending = Completer<AudioStreamResult?>();
      final repo = YoutubeAudioRepository(
        streamResolver: (_, _, _) {
          calls++;
          return pending.future;
        },
      );
      addTearDown(repo.dispose);
      final first = repo.getAudioStream(song);
      final second = repo.getAudioStream(song.copyWith(id: 'another'));
      pending.complete(audio);
      expect(await first, audio);
      expect(await second, audio);
      expect(await repo.getAudioStream(song), audio);
      expect(calls, 1);
      repo.quality = 'high';
      await repo.getAudioStream(song);
      expect(calls, 2);
    },
  );
  test(
    'Expired CDN URL is re-resolved instead of waiting for player failure',
    () async {
      var calls = 0;
      final repo = YoutubeAudioRepository(
        streamResolver: (_, _, _) async {
          calls++;
          return const AudioStreamResult(
            streamUrl: 'https://example.test/audio?expire=1',
            videoId: 'recording',
          );
        },
      );
      addTearDown(repo.dispose);
      await repo.getAudioStream(song);
      await repo.getAudioStream(song);
      expect(calls, 2);
    },
  );
  test(
    'Refresh wins over slow prefetch and incoming playback shares refresh',
    () async {
      final pending = Completer<AudioStreamResult?>();
      final refreshed = Completer<AudioStreamResult?>();
      var calls = 0;
      final repo = YoutubeAudioRepository(
        streamResolver: (_, _, refresh) {
          calls++;
          return refresh ? refreshed.future : pending.future;
        },
      );
      addTearDown(repo.dispose);
      final old = repo.getAudioStream(song);
      final fresh = repo.getAudioStream(song, forceRefresh: true);
      final playback = repo.getAudioStream(song);
      const newAudio = AudioStreamResult(
        streamUrl: 'https://example.test/new',
        videoId: 'recording',
      );
      refreshed.complete(newAudio);
      expect(await fresh, newAudio);
      expect(await playback, newAudio);
      pending.complete(audio);
      await old;
      expect(await repo.getAudioStream(song), newAudio);
      expect(calls, 2);
    },
  );
}
