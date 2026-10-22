import 'package:dio/dio.dart';
import '../../core/utils/formatters.dart';
import '../models/lyric_line.dart';
import '../models/song_model.dart';

class LyricsResult {
  final List<LyricLine> syncedLyrics;
  final String? plainLyrics;
  final bool hasSyncedLyrics;

  const LyricsResult({
    this.syncedLyrics = const [],
    this.plainLyrics,
    this.hasSyncedLyrics = false,
  });
}

class LyricsRepository {
  final Dio _dio;
  final Map<String, LyricsResult> _cache = {};

  LyricsRepository({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://lrclib.net/api',
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
                headers: {
                  'User-Agent': 'AUNO Music Player v1.0 (https://github.com/auno)',
                },
              ),
            );

  /// Mengambil lirik sinkron waktu dari LRCLIB
  Future<LyricsResult> getLyrics(SongModel song) async {
    if (_cache.containsKey(song.id)) {
      return _cache[song.id]!;
    }

    final cleanTitle = Formatters.cleanTrackTitle(song.title);

    try {
      // 1. Coba pencarian spesifik /api/get
      final response = await _dio.get(
        '/get',
        queryParameters: {
          'track_name': cleanTitle,
          'artist_name': song.artist,
          if (song.album.isNotEmpty) 'album_name': song.album,
          if (song.durationSeconds > 0) 'duration': song.durationSeconds,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final result = _parseResponse(response.data as Map<String, dynamic>);
        _cache[song.id] = result;
        return result;
      }
    } catch (_) {
      // Abaikan dan lanjut ke pencarian fleksibel
    }

    try {
      // 2. Fallback pencarian fleksibel /api/search
      final searchResponse = await _dio.get(
        '/search',
        queryParameters: {
          'q': '${song.artist} $cleanTitle',
        },
      );

      if (searchResponse.statusCode == 200 && searchResponse.data is List) {
        final list = searchResponse.data as List<dynamic>;
        if (list.isNotEmpty) {
          final first = list.first as Map<String, dynamic>;
          final result = _parseResponse(first);
          _cache[song.id] = result;
          return result;
        }
      }
    } catch (_) {
      // Gagal mengambil lirik
    }

    final emptyResult = const LyricsResult();
    _cache[song.id] = emptyResult;
    return emptyResult;
  }

  LyricsResult _parseResponse(Map<String, dynamic> data) {
    final syncedRaw = data['syncedLyrics'] as String?;
    final plainRaw = data['plainLyrics'] as String?;

    if (syncedRaw != null && syncedRaw.trim().isNotEmpty) {
      final parsed = LyricLine.parseLrc(syncedRaw);
      if (parsed.isNotEmpty) {
        return LyricsResult(
          syncedLyrics: parsed,
          plainLyrics: plainRaw,
          hasSyncedLyrics: true,
        );
      }
    }

    return LyricsResult(
      syncedLyrics: const [],
      plainLyrics: plainRaw,
      hasSyncedLyrics: false,
    );
  }
}
