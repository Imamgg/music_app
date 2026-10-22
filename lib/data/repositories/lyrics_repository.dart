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
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://lrclib.net/api',
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              headers: {
                'User-Agent':
                    'AUNO Music Player v1.0 (https://github.com/auno)',
              },
            ),
          );

  /// Mengambil lirik sinkron waktu dari LRCLIB
  Future<LyricsResult> getLyrics(SongModel song) async {
    final key =
        '${song.id}|${song.artist}|${song.title}|${song.album}|${song.durationSeconds}';
    if (_cache.containsKey(key)) return _cache[key]!;

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
        final data = response.data as Map<String, dynamic>;
        if (matchScore(song, data) < 0) throw StateError('Different recording');
        final result = _parseResponse(data);
        _cache[key] = result;
        return result;
      }
    } catch (_) {
      // Abaikan dan lanjut ke pencarian fleksibel
    }

    try {
      // 2. Fallback pencarian fleksibel /api/search
      final searchResponse = await _dio.get(
        '/search',
        queryParameters: {'q': '${song.artist} $cleanTitle'},
      );

      if (searchResponse.statusCode == 200 && searchResponse.data is List) {
        final list =
            (searchResponse.data as List)
                .whereType<Map<String, dynamic>>()
                .where((data) => matchScore(song, data) >= 0)
                .toList()
              ..sort(
                (a, b) => matchScore(song, b).compareTo(matchScore(song, a)),
              );
        if (list.isNotEmpty) {
          final first = list.first;
          final result = _parseResponse(first);
          _cache[key] = result;
          return result;
        }
      }
    } catch (_) {
      // Gagal mengambil lirik
    }

    final emptyResult = const LyricsResult();
    return emptyResult;
  }

  /// Reject covers, other recordings and incompatible timings before ranking.
  static int matchScore(SongModel song, Map<String, dynamic> data) {
    String normal(String value) => value
        .toLowerCase()
        .replaceAll(RegExp(r"[’‘]"), "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final title = normal(Formatters.cleanTrackTitle(song.title));
    if (title.isEmpty ||
        normal(
              Formatters.cleanTrackTitle(data['trackName']?.toString() ?? ''),
            ) !=
            title) {
      return -1;
    }
    final artist = normal(data['artistName']?.toString() ?? '');
    if (artist.isEmpty ||
        artist == 'unknown artist' ||
        artist != normal(song.artist)) {
      return -1;
    }
    final duration = (data['duration'] as num?)?.toDouble();
    final delta = duration == null
        ? null
        : (duration - song.durationSeconds).abs();
    if (song.durationSeconds > 0 && (delta == null || delta > 3)) return -1;
    var score = 100;
    if (song.album.isNotEmpty &&
        normal(data['albumName']?.toString() ?? '') == normal(song.album)) {
      score += 30;
    }
    if (delta != null && song.durationSeconds > 0) score += 10 - delta.round();
    if (data['syncedLyrics']?.toString().trim().isNotEmpty == true) score += 5;
    return score;
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
