import 'dart:async';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../core/utils/formatters.dart';
import '../models/song_model.dart';

class AudioStreamResult {
  final String streamUrl;
  final String videoId;
  final Duration? duration;

  const AudioStreamResult({
    required this.streamUrl,
    required this.videoId,
    this.duration,
  });
}

class YoutubeAudioRepository {
  final YoutubeExplode _yt;
  final Map<String, AudioStreamResult> _cache = {};
  final Map<String, String> _resolvedVideos = {};
  final Map<String, DateTime> _cachedAt = {};
  final Map<String, Future<AudioStreamResult?>> _pending = {};
  final Future<AudioStreamResult?> Function(SongModel, String, bool)?
  streamResolver;
  bool _disposed = false;
  String quality = 'normal';

  static int selectBitrate(List<int> rates, String quality) {
    if (rates.isEmpty) throw ArgumentError('No audio streams');
    final sorted = [...rates]..sort();
    if (quality == 'high') return sorted.last;
    final target = quality == 'low' ? 64000 : 128000;
    return sorted.reduce(
      (a, b) => (a - target).abs() <= (b - target).abs() ? a : b,
    );
  }

  YoutubeAudioRepository({YoutubeExplode? yt, this.streamResolver})
    : _yt = yt ?? YoutubeExplode();

  /// Ekstraksi URL audio untuk [song] dengan prioritas progressive stream (ratebypass=yes, MP4/AAC)
  /// yang didukung penuh oleh ExoPlayer Android tanpa kendala HTTP 403 Forbidden.
  Future<AudioStreamResult?> getAudioStream(
    SongModel song, {
    bool forceRefresh = false,
  }) async {
    if (_disposed) return null;
    final selectedQuality = quality;
    final cacheKey = '${song.youtubeVideoId ?? song.id}|$selectedQuality';
    if (!forceRefresh && _pending['$cacheKey|true'] != null) {
      return _pending['$cacheKey|true'];
    }
    if (forceRefresh) _cache.remove(cacheKey);
    final cached = _cache[cacheKey];
    final now = DateTime.now();
    final expires = cached == null
        ? null
        : int.tryParse(
            Uri.parse(cached.streamUrl).queryParameters['expire'] ?? '',
          );
    final fresh =
        cached != null &&
        now.difference(_cachedAt[cacheKey] ?? DateTime(1970)) <
            const Duration(minutes: 5) &&
        (expires == null ||
            DateTime.fromMillisecondsSinceEpoch(
              expires * 1000,
            ).isAfter(now.add(const Duration(minutes: 1))));
    if (!forceRefresh && fresh) return cached;
    final pendingKey = '$cacheKey|$forceRefresh';
    final existing = _pending[pendingKey];
    if (existing != null) return existing;
    // Refresh supersedes an older prefetch, without allowing its result to overwrite the cache.
    if (forceRefresh) {
      _pending.remove('$cacheKey|false');
    }
    final resolvedSong = song.youtubeVideoId?.isNotEmpty == true
        ? song
        : song.copyWith(youtubeVideoId: _resolvedVideos[song.id]);
    late Future<AudioStreamResult?> request;
    request =
        Future<AudioStreamResult?>.sync(
              () => streamResolver != null
                  ? streamResolver!(resolvedSong, selectedQuality, forceRefresh)
                  : _resolve(resolvedSong, selectedQuality, forceRefresh),
            )
            .then<AudioStreamResult?>((value) => value)
            .timeout(const Duration(seconds: 30), onTimeout: () => null)
            .catchError((Object _) => null)
            .then((result) {
              if (!_disposed && identical(_pending[pendingKey], request)) {
                _pending.remove(pendingKey);
                if (result != null) {
                  _resolvedVideos[song.id] = result.videoId;
                  _cache[cacheKey] = result;
                  _cachedAt[cacheKey] = DateTime.now();
                }
              }
              return result;
            });
    _pending[pendingKey] = request;
    return request;
  }

  Future<AudioStreamResult?> _resolve(
    SongModel song,
    String selectedQuality,
    bool forceRefresh,
  ) async {
    try {
      // 2. Jika sudah memiliki videoId spesifik, ambil manifest langsung
      if (song.youtubeVideoId != null && song.youtubeVideoId!.isNotEmpty) {
        final directResult = await _extractBestAudio(
          song.youtubeVideoId!,
          selectedQuality,
          compatibility: forceRefresh,
        );
        if (directResult != null) {
          return directResult;
        }
      }

      if (song.youtubeVideoId?.isNotEmpty == true) return null;

      // 3. Cari di YouTube
      // Utamakan kueri natural "$artist $cleanTitle", lalu fallback dengan "Official Audio"
      final cleanTitle = Formatters.cleanTrackTitle(song.title);
      final naturalQuery = '${song.artist} $cleanTitle';
      var searchResults = await _searchWithRetry(naturalQuery);

      if (searchResults.isEmpty) {
        searchResults = await _searchWithRetry(
          Formatters.buildYouTubeSearchQuery(song.artist, song.title),
        );
      }

      if (searchResults.isEmpty) {
        return null;
      }

      // 4. Filter & Scoring Kandidat Video:
      // Mencegah terpilihnya video "Full Album", "Kompilasi", atau video berdurasi puluhan menit
      // yang sering muncul pada lagu-lagu lokal/indie.
      final targetDuration = song.durationSeconds;
      final scoredCandidates = <MapEntry<Video, int>>[];

      for (final video in searchResults.take(12)) {
        final dur = video.duration?.inSeconds;
        final titleLower = video.title.toLowerCase();

        // A. Abaikan video kompilasi / full album
        final isAlbumOrCompilation =
            titleLower.contains('full album') ||
            titleLower.contains('kompilasi') ||
            titleLower.contains('kumpulan') ||
            titleLower.contains('playlist') ||
            titleLower.contains('best songs') ||
            titleLower.contains('nonstop');

        if (isAlbumOrCompilation && (dur == null || dur > 360)) {
          continue;
        }

        // B. Abaikan video dengan durasi yang jauh melebihi durasi lagu
        // Contoh: Lagu berdurasi 3 menit (180 detik), tapi videonya > 7 menit (420 detik)
        if (targetDuration > 0 && dur != null) {
          if (dur > targetDuration * 2.2 && dur > 420) {
            continue;
          }
        }

        // C. Hitung bobot skor kecocokan (makin pas durasinya dengan lagu target, makin tinggi skor)
        int score = 1000;
        if (dur != null && targetDuration > 0) {
          final delta = (dur - targetDuration).abs();
          score -= delta;
        }

        // Bonus untuk video resmi/lirik/audio
        if (titleLower.contains('official audio') ||
            titleLower.contains('official lyric') ||
            titleLower.contains('official video') ||
            titleLower.contains('official music video') ||
            titleLower.contains('video lirik') ||
            titleLower.contains('lyrics video')) {
          score += 50;
        }

        // Penalti jika judul berisi banyak pemisah lagu (indikasi medley/kompilasi spammed)
        if (RegExp(r'\s-\s[A-Z\s]{3,}\s-\s').hasMatch(video.title)) {
          score -= 500;
        }

        scoredCandidates.add(MapEntry(video, score));
      }

      // Urutkan dari skor tertinggi (durasi paling pas dan paling relevan)
      scoredCandidates.sort((a, b) => b.value.compareTo(a.value));

      // Jika ada kandidat yang lolos filter, coba ekstraksi secara berurutan
      final candidatesToTry = scoredCandidates.isNotEmpty
          ? scoredCandidates.map((e) => e.key).toList()
          : searchResults.take(3).toList();

      for (final video in candidatesToTry.take(3)) {
        if (_disposed) return null;
        final result = await _extractBestAudio(
          video.id.value,
          selectedQuality,
          compatibility: forceRefresh,
        );
        if (result != null) {
          return result;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Video>> _searchWithRetry(String query) async {
    try {
      final res = await _yt.search
          .search(query)
          .timeout(const Duration(seconds: 8));
      return res.toList();
    } catch (_) {
      // A search failure must not close concurrent playback/prefetch requests.
      if (_disposed) return [];
      try {
        final res = await _yt.search
            .search(query)
            .timeout(const Duration(seconds: 8));
        return res.toList();
      } catch (_) {
        return [];
      }
    }
  }

  Future<AudioStreamResult?> _extractBestAudio(
    String videoId,
    String selectedQuality, {
    bool compatibility = false,
  }) async {
    try {
      final manifest = await _yt.videos.streamsClient
          .getManifest(videoId)
          .timeout(const Duration(seconds: 10));

      final audioOnly = manifest.audioOnly.toList();
      if (audioOnly.isNotEmpty && !compatibility) {
        final rate = selectBitrate(
          audioOnly.map((s) => s.bitrate.bitsPerSecond).toList(),
          selectedQuality,
        );
        final selected = audioOnly.firstWhere(
          (s) => s.bitrate.bitsPerSecond == rate,
        );
        return AudioStreamResult(
          streamUrl: selected.url.toString(),
          videoId: videoId,
        );
      }

      // 1. Prioritas Utama: Progressive MP4 streams dengan ratebypass=yes (misalnya itag 18 atau 22).
      // Format ini didukung 100% oleh hardware decoder Android ExoPlayer tanpa kendala HTTP 403 Forbidden,
      // karena YouTube CDN mengizinkan open-ended byte range request (bytes=0-) dari ExoPlayer.
      final rateBypassMuxed = manifest.muxed.where((s) {
        final urlStr = s.url.toString();
        return urlStr.contains('ratebypass=yes') || s.tag == 18 || s.tag == 22;
      }).toList();

      if (rateBypassMuxed.isNotEmpty) {
        // Prioritaskan itag 18 (MP4/AAC 360p) karena paling stabil & ringan untuk pemutar musik
        final bestMuxed = rateBypassMuxed.firstWhere(
          (s) => s.tag == 18,
          orElse: () => rateBypassMuxed.first,
        );
        return AudioStreamResult(
          streamUrl: bestMuxed.url.toString(),
          videoId: videoId,
        );
      }

      // 2. Prioritas Kedua: Seluruh muxed MP4 yang tersedia
      final anyMuxed = manifest.muxed
          .where((s) => s.container.name.toLowerCase() == 'mp4')
          .toList();
      if (anyMuxed.isNotEmpty) {
        return AudioStreamResult(
          streamUrl: anyMuxed.first.url.toString(),
          videoId: videoId,
        );
      }

      // 3. Prioritas Ketiga: Adaptive audio-only streams (fallback)
      final audioStreams = manifest.audioOnly;
      if (audioStreams.isNotEmpty) {
        final mp4Streams = audioStreams.where(
          (s) =>
              s.container.name.toLowerCase() == 'mp4' ||
              s.container.name.toLowerCase() == 'm4a',
        );

        final selectedStream = mp4Streams.isNotEmpty
            ? mp4Streams.withHighestBitrate()
            : audioStreams.withHighestBitrate();

        return AudioStreamResult(
          streamUrl: selectedStream.url.toString(),
          videoId: videoId,
        );
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  void invalidateCache(String songId) {
    _cache.removeWhere(
      (key, value) => key.startsWith('$songId|') || value.videoId == songId,
    );
  }

  void dispose() {
    _disposed = true;
    _pending.clear();
    _cache.clear();
    _resolvedVideos.clear();
    _yt.close();
  }
}
