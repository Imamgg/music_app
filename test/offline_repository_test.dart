import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:auno/data/models/song_model.dart';
import 'package:auno/data/repositories/offline_repository.dart';
import 'package:auno/data/repositories/youtube_audio_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

const song = SongModel(
  id: '../recording',
  title: 'Song',
  artist: 'Artist',
  album: 'Album',
  coverUrl: '',
  highResCoverUrl: '',
  durationSeconds: 180,
  youtubeVideoId: 'exact-video',
);
const stream = AudioStreamResult(
  streamUrl: 'https://example.test/audio',
  videoId: 'exact-video',
);

class AudioAdapter implements HttpClientAdapter {
  int calls = 0;
  String type = 'audio/mp4';
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    return ResponseBody.fromBytes(
      List<int>.filled(128, 1),
      200,
      headers: {
        'content-length': ['128'],
        'content-type': [type],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory root;
  late OfflineRepository repo;
  late AudioAdapter adapter;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('auno-offline-test-');
    adapter = AudioAdapter();
    repo = OfflineRepository(
      directory: () async => root,
      dio: Dio()..httpClientAdapter = adapter,
    );
  });
  tearDown(() async {
    repo.dispose();
    await root.delete(recursive: true);
  });
  test(
    'Completed audio and exact metadata survive restart and missing files are removed',
    () async {
      await repo.download(song, (_) async => stream);
      expect(repo.errors, isEmpty);
      final path = await repo.localPath(song.id);
      expect(path, startsWith(root.path));
      expect(await File(path!).length(), 128);
      final restored = OfflineRepository(directory: () async => root);
      await restored.initialize();
      expect(restored.tracks[song.id]!.song.artist, 'Artist');
      expect(restored.tracks[song.id]!.song.youtubeVideoId, 'exact-video');
      expect(await restored.localPath(song.id), path);
      await File(path).writeAsBytes([1]);
      expect(await restored.localPath(song.id), isNull);
      restored.dispose();
    },
  );
  test(
    'Duplicate requests download once; removal only removes offline files',
    () async {
      final resolved = Completer<AudioStreamResult?>();
      final first = repo.download(song, (_) => resolved.future);
      await repo.download(song, (_) async => stream);
      resolved.complete(stream);
      await first;
      await repo.download(song, (_) async => stream);
      expect(adapter.calls, 1);
      await repo.remove(song.id);
      expect(await repo.localPath(song.id), isNull);
      expect(
        await Directory('${root.path}/offline_audio').list().toList(),
        isEmpty,
      );
    },
  );
  test(
    'Cancellation during stream resolution does not publish a completed track',
    () async {
      final resolving = Completer<void>();
      final resolved = Completer<AudioStreamResult?>();
      final task = repo.download(song, (_) {
        resolving.complete();
        return resolved.future;
      });
      await resolving.future;
      repo.cancel(song.id);
      resolved.complete(stream);
      await task;
      expect(adapter.calls, 0);
      expect(repo.tracks, isEmpty);
      expect(repo.errors, isEmpty);
      expect(repo.progress, isEmpty);
    },
  );
  test('HTML error responses are not saved as music and retry works', () async {
    adapter.type = 'text/html';
    await repo.download(song, (_) async => stream);
    expect(repo.tracks, isEmpty);
    expect(repo.errors[song.id], isNotNull);
    expect(
      await Directory('${root.path}/offline_audio').list().toList(),
      isEmpty,
    );
    adapter.type = 'audio/mp4';
    await repo.download(song, (_) async => stream);
    expect(repo.tracks, hasLength(1));
    expect(repo.errors, isEmpty);
  });
  test(
    'Startup removes interrupted partial files and ignores broken metadata',
    () async {
      final dir = await Directory('${root.path}/offline_audio').create();
      await File('${dir.path}/interrupted.part').writeAsBytes([1]);
      await File('${dir.path}/broken.json').writeAsString('{');
      await repo.initialize();
      expect(repo.tracks, isEmpty);
      expect(await File('${dir.path}/interrupted.part').exists(), false);
    },
  );
}
