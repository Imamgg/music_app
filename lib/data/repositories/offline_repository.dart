import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/song_model.dart';
import 'youtube_audio_repository.dart';

class OfflineTrack {
  const OfflineTrack(this.song, this.path, this.bytes);
  final SongModel song;
  final String path;
  final int bytes;
}

class OfflineRepository extends ChangeNotifier {
  OfflineRepository({Future<Directory> Function()? directory, Dio? dio})
    : _directory = directory ?? getApplicationSupportDirectory,
      _dio =
          dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 20)));
  final Future<Directory> Function() _directory;
  final Dio _dio;
  final Map<String, OfflineTrack> tracks = {};
  final Map<String, SongModel> jobs = {};
  final Map<String, double?> progress = {};
  final Map<String, String> errors = {};
  final Map<String, CancelToken> _tokens = {};
  Future<Directory>? _ready;
  bool _disposed = false;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  String _key(String id) =>
      base64Url.encode(utf8.encode(id)).replaceAll('=', '');
  Future<Directory> initialize() =>
      _ready ??= _load().catchError((Object error) {
        _ready = null;
        throw error;
      });
  Future<Directory> _load() async {
    final root = Directory('${(await _directory()).path}/offline_audio');
    await root.create(recursive: true);
    await for (final entity in root.list()) {
      if (entity is! File) continue;
      if (entity.path.endsWith('.part')) {
        await entity.delete();
        continue;
      }
      if (!entity.path.endsWith('.json')) continue;
      try {
        final json =
            jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
        final song = SongModel.fromJson(json['song'] as Map<String, dynamic>);
        final path = '${root.path}/${_key(song.id)}.audio';
        final size = json['bytes'] as int;
        if (size > 0 &&
            await File(path).exists() &&
            await File(path).length() == size) {
          tracks[song.id] = OfflineTrack(song, path, size);
        }
      } catch (_) {
        /* Incomplete entries never appear as downloaded songs. */
      }
    }
    final validPaths = tracks.values
        .map((track) => File(track.path).absolute.uri)
        .toSet();
    await for (final entity in root.list()) {
      if (entity is File &&
          entity.path.endsWith('.audio') &&
          !validPaths.contains(entity.absolute.uri)) {
        await entity.delete();
      }
    }
    _notify();
    return root;
  }

  Future<String?> localPath(String id) async {
    try {
      await initialize();
    } catch (_) {
      return null;
    }
    final entry = tracks[id];
    if (entry == null) return null;
    final file = File(entry.path);
    if (await file.exists() && await file.length() == entry.bytes) {
      return entry.path;
    }
    tracks.remove(id);
    _notify();
    return null;
  }

  Future<void> download(
    SongModel song,
    Future<AudioStreamResult?> Function(SongModel) resolve,
  ) async {
    if (_tokens.containsKey(song.id) || _disposed) return;
    final token = CancelToken();
    _tokens[song.id] = token;
    jobs[song.id] = song;
    progress[song.id] = null;
    errors.remove(song.id);
    _notify();
    File? partial;
    File? audio;
    File? metadata;
    var committed = false;
    try {
      final root = await initialize();
      if (await localPath(song.id) != null) return;
      final stream = await Future.any<AudioStreamResult?>([
        resolve(song),
        token.whenCancel.then((_) => null),
      ]);
      if (token.isCancelled) return;
      if (stream == null) throw StateError('Stream unavailable');
      final base = '${root.path}/${_key(song.id)}';
      partial = File('$base.part');
      audio = File('$base.audio');
      metadata = File('$base.json');
      final response = await _dio.download(
        stream.streamUrl,
        partial.path,
        cancelToken: token,
        options: Options(
          receiveTimeout: const Duration(seconds: 45),
          headers: {
            'User-Agent': 'Mozilla/5.0',
            'Referer': 'https://www.youtube.com/',
            'Accept': '*/*',
          },
        ),
        onReceiveProgress: (received, total) {
          final value = total > 0 ? received / total : null;
          if (value == null ||
              progress[song.id] == null ||
              (value - progress[song.id]!).abs() >= .01) {
            progress[song.id] = value;
            _notify();
          }
        },
      );
      if (token.isCancelled) return;
      final bytes = await partial.length();
      final expected = int.tryParse(
        response.headers.value('content-length') ?? '',
      );
      final type = response.headers.value('content-type') ?? '';
      if (bytes == 0 ||
          (expected != null && expected != bytes) ||
          type.contains('text/') ||
          type.contains('json')) {
        throw StateError('Incomplete audio');
      }
      await partial.rename(audio.path);
      final savedSong = song.copyWith(youtubeVideoId: stream.videoId);
      await metadata.writeAsString(
        jsonEncode({'song': savedSong.toJson(), 'bytes': bytes}),
        flush: true,
      );
      if (token.isCancelled) return;
      tracks[song.id] = OfflineTrack(savedSong, audio.path, bytes);
      committed = true;
    } catch (_) {
      if (!token.isCancelled) {
        errors[song.id] =
            'Unduhan gagal. Periksa koneksi dan ruang penyimpanan, lalu coba lagi.';
      }
    } finally {
      if (!committed) {
        for (final file in [partial, audio, metadata]) {
          try {
            if (file != null && await file.exists()) await file.delete();
          } catch (_) {}
        }
      }
      _tokens.remove(song.id);
      progress.remove(song.id);
      _notify();
    }
  }

  void cancel(String id) {
    _tokens[id]?.cancel();
  }

  Future<void> remove(String id) async {
    final root = await initialize();
    if (_tokens.containsKey(id)) {
      cancel(id);
      return;
    }
    try {
      for (final suffix in ['audio', 'json']) {
        final file = File('${root.path}/${_key(id)}.$suffix');
        if (await file.exists()) await file.delete();
      }
      tracks.remove(id);
      errors.remove(id);
    } catch (_) {
      errors[id] =
          'Unduhan belum dapat dihapus. Coba lagi setelah lagu berhenti.';
    }
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final token in _tokens.values) {
      token.cancel();
    }
    _dio.close(force: true);
    super.dispose();
  }
}
