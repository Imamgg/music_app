import 'dart:convert';
import 'dart:typed_data';
import 'package:auno/data/models/lyric_line.dart';
import 'package:auno/data/models/song_model.dart';
import 'package:auno/data/repositories/lyrics_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

const ttml =
    '<tt xmlns="http://www.w3.org/ns/ttml"><body><div>'
    '<p begin="1:02.125"><span>Hel</span><span>lo</span> <span>world</span></p>'
    '<p begin="00:00:03.500">First &amp; foremost</p>'
    '</div></body></tt>';
const song = SongModel(
  id: 'one',
  title: 'Test Song',
  artist: 'Test Artist',
  album: 'Test Album',
  coverUrl: '',
  highResCoverUrl: '',
  durationSeconds: 180,
  youtubeVideoId: 'recording',
);

class LyricsAdapter implements HttpClientAdapter {
  LyricsAdapter(this.respond);
  final ResponseBody Function(RequestOptions) respond;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(Object data, [int status = 200]) =>
    ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        'content-type': ['application/json'],
      },
    );

void main() {
  test('TTML preserves syllables, spaces, entities and both clock formats', () {
    final lines = LyricLine.parseTtml(ttml);
    expect(lines.map((line) => line.text), ['First & foremost', 'Hello world']);
    expect(lines.last.timestamp, const Duration(milliseconds: 62125));
    expect(LyricLine.parseTtml('<broken'), isEmpty);
    expect(
      LyricLine.parseTtml('<tt><body><p begin="bad">Invalid</p></body></tt>'),
      isEmpty,
    );
  });
  test(
    'Better Lyrics is primary and receives full recording metadata',
    () async {
      final primary = LyricsAdapter(
        (_) => jsonBody({'ttml': ttml, 'score': .97}),
      );
      final fallback = LyricsAdapter((_) => jsonBody({}, 404));
      final repo = LyricsRepository(
        betterDio: Dio()..httpClientAdapter = primary,
        dio: Dio()..httpClientAdapter = fallback,
      );
      addTearDown(repo.dispose);
      final result = await repo.getLyrics(song);
      expect(result.hasSyncedLyrics, true);
      expect(primary.requests.single.path, '/getLyrics');
      expect(primary.requests.single.queryParameters, {
        's': 'Test Song',
        'a': 'Test Artist',
        'al': 'Test Album',
        'd': '180',
        'videoId': 'recording',
      });
      expect(fallback.requests, isEmpty);
      await repo.getLyrics(song);
      expect(primary.requests, hasLength(1));
    },
  );
  test(
    'Authentication restriction uses Better Lyrics line-timed endpoint',
    () async {
      final primary = LyricsAdapter(
        (request) => request.path == '/getLyrics'
            ? jsonBody({'error': 'API key required'}, 401)
            : jsonBody({
                'lyrics': '[00:01.00]A test line',
                'provider': 'kugou',
              }),
      );
      final repo = LyricsRepository(
        betterDio: Dio()..httpClientAdapter = primary,
      );
      addTearDown(repo.dispose);
      final result = await repo.getLyrics(song);
      expect(result.syncedLyrics.single.text, 'A test line');
      expect(
        primary.requests.last.queryParameters.containsKey('videoId'),
        false,
      );
    },
  );
  test(
    'Rate limit falls back without retrying Better Lyrics endpoints',
    () async {
      final primary = LyricsAdapter((_) => jsonBody({}, 429));
      final fallback = LyricsAdapter(
        (_) => jsonBody({
          'trackName': song.title,
          'artistName': song.artist,
          'albumName': song.album,
          'duration': 180,
          'syncedLyrics': '[00:01.00]Fallback line',
        }),
      );
      final repo = LyricsRepository(
        betterDio: Dio()..httpClientAdapter = primary,
        dio: Dio()..httpClientAdapter = fallback,
      );
      addTearDown(repo.dispose);
      expect(
        (await repo.getLyrics(song)).syncedLyrics.single.text,
        'Fallback line',
      );
      expect(primary.requests, hasLength(1));
    },
  );
}
