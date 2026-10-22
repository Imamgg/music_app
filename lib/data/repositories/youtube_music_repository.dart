import 'dart:convert';
import 'dart:io';
import '../models/playlist_model.dart';
import '../models/song_model.dart';

class YouTubeMusicRepository {
  final HttpClient _client = HttpClient();

  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Content-Type': 'application/json',
    'Origin': 'https://music.youtube.com',
    'Referer': 'https://music.youtube.com/',
  };

  static const Map<String, dynamic> _clientContext = {
    'client': {
      'clientName': 'WEB_REMIX',
      'clientVersion': '1.20240101.01.00',
      'hl': 'id',
      'gl': 'ID',
    }
  };

  Future<Map<String, dynamic>?> _post(
    String endpoint,
    Map<String, dynamic> payload,
  ) async {
    try {
      final req = await _client.postUrl(
        Uri.parse('https://music.youtube.com/youtubei/v1/$endpoint?prettyPrint=false'),
      );
      _headers.forEach((k, v) => req.headers.set(k, v));
      req.write(jsonEncode(payload));
      final res = await req.close();
      if (res.statusCode != 200) return null;
      final body = await res.transform(utf8.decoder).join();
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Mengambil daftar Top Charts Indonesia & Global
  Future<List<SongModel>> getTopCharts() async {
    // Ambil dari playlist chart resmi YouTube Music: 100 Video Musik Teratas Indonesia
    final tracks = await getPlaylistTracks('VLPL4fGSI1pDJn5QPpj0R4vVgRWk8sSq549G');
    if (tracks.isNotEmpty) {
      return tracks;
    }
    // Fallback ke Trending 20 Indonesia
    return await getPlaylistTracks('VLOLAK5uy_n7Ig_LAUbKE6_ZeQ1pwHmJcEhwX7BekBo');
  }

  /// Mengambil playlist-playlist terpopuler (Top Charts, Pop Indo, Viral Hits, Santai)
  Future<List<PlaylistModel>> getCuratedPlaylists() async {
    final json = await _post('browse', {
      'context': _clientContext,
      'browseId': 'FEmusic_charts',
    });

    final playlists = <PlaylistModel>[];

    if (json != null) {
      void findPlaylists(dynamic node) {
        if (node is Map) {
          if (node.containsKey('musicTwoRowItemRenderer')) {
            final item = node['musicTwoRowItemRenderer'];
            final title = item['title']?['runs']?[0]?['text']?.toString() ?? '';
            final subtitle = item['subtitle']?['runs']?[0]?['text']?.toString() ?? '';
            final browseId = item['navigationEndpoint']?['browseEndpoint']?['browseId']?.toString();
            final thumb = item['thumbnailRenderer']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails']?.last?['url']?.toString() ?? '';
            if (browseId != null && title.isNotEmpty) {
              playlists.add(PlaylistModel(
                id: browseId,
                title: title,
                description: subtitle.isNotEmpty ? subtitle : 'Playlist Resmi YouTube Music',
                coverUrl: thumb,
                createdAt: DateTime.now(),
              ));
            }
          } else {
            node.forEach((_, v) => findPlaylists(v));
          }
        } else if (node is List) {
          for (final elem in node) {
            findPlaylists(elem);
          }
        }
      }

      findPlaylists(json);
    }

    // Default static curated backup jika jaringan offline/terbatas
    if (playlists.isEmpty) {
      playlists.addAll([
        PlaylistModel(
          id: 'VLPL4fGSI1pDJn5QPpj0R4vVgRWk8sSq549G',
          title: '100 Musik Teratas Indonesia',
          description: 'Tangga lagu paling populer di Indonesia',
          coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500',
          createdAt: DateTime.now(),
        ),
        PlaylistModel(
          id: 'VLOLAK5uy_n7Ig_LAUbKE6_ZeQ1pwHmJcEhwX7BekBo',
          title: 'Trending 20 Indonesia',
          description: 'Lagu viral dan paling banyak diputar minggu ini',
          coverUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500',
          createdAt: DateTime.now(),
        ),
        PlaylistModel(
          id: 'VLPL4fGSI1pDJn4lW6MJA2q37CfnraqAizqE',
          title: 'Video Musik Teratas Harian',
          description: 'Update harian musik terpopuler',
          coverUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=500',
          createdAt: DateTime.now(),
        ),
      ]);
    }

    return playlists;
  }

  /// Mengambil semua daftar lagu lengkap dari sebuah playlist
  Future<List<SongModel>> getPlaylistTracks(String browseIdOrPlaylistId) async {
    // Normalisasi browseId: jika diawali 'PL...', tambahkan prefix 'VL' untuk YouTube Music
    String browseId = browseIdOrPlaylistId;
    if (browseId.startsWith('PL') && !browseId.startsWith('VL')) {
      browseId = 'VL$browseId';
    }

    final json = await _post('browse', {
      'context': _clientContext,
      'browseId': browseId,
    });
    if (json == null) return [];

    final result = <SongModel>[];
    void findTracks(dynamic node) {
      if (node is Map) {
        if (node.containsKey('musicResponsiveListItemRenderer')) {
          final item = node['musicResponsiveListItemRenderer'];
          final flex = item['flexColumns'] as List?;
          final title = flex?[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0]?['text']?.toString() ?? '';
          final runs = flex?[1]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List?;
          final artist = runs?.isNotEmpty == true ? runs![0]['text']?.toString() ?? 'Unknown Artist' : 'Unknown Artist';
          final videoId = item['playlistItemData']?['videoId']?.toString();
          final thumb = item['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails']?.last?['url']?.toString() ?? '';

          // Ekstraksi durasi jika tersedia
          int durationSec = 0;
          if (runs != null && runs.length > 2) {
            final durText = runs.last['text']?.toString() ?? '';
            final cleanDur = durText.replaceAll('.', ':');
            final parts = cleanDur.split(':');
            if (parts.length == 2) {
              final m = int.tryParse(parts[0]) ?? 0;
              final s = int.tryParse(parts[1]) ?? 0;
              durationSec = m * 60 + s;
            }
          }

          if (videoId != null && title.isNotEmpty) {
            result.add(SongModel(
              id: videoId,
              title: title,
              artist: artist,
              album: 'YouTube Music',
              coverUrl: thumb,
              highResCoverUrl: thumb,
              durationSeconds: durationSec > 0 ? durationSec : 210,
              youtubeVideoId: videoId,
            ));
          }
        } else {
          node.forEach((_, v) => findTracks(v));
        }
      } else if (node is List) {
        for (final elem in node) {
          findTracks(elem);
        }
      }
    }

    findTracks(json);
    return result;
  }

  /// Pencarian lagu langsung di YouTube Music
  Future<List<SongModel>> searchMusic(String query) async {
    final json = await _post('search', {
      'context': _clientContext,
      'query': query,
      'params': 'EgWKAQIIAWoQEAMQBBAJEA4QChAFEBEQEBA%3D', // filter khusus lagu (songs)
    });
    if (json == null) return [];

    final result = <SongModel>[];
    void findTracks(dynamic node) {
      if (node is Map) {
        if (node.containsKey('musicResponsiveListItemRenderer')) {
          final item = node['musicResponsiveListItemRenderer'];
          final flex = item['flexColumns'] as List?;
          final title = flex?[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0]?['text']?.toString() ?? '';
          final runs = flex?[1]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List?;
          final artist = runs?.isNotEmpty == true ? runs![0]['text']?.toString() ?? 'Unknown Artist' : 'Unknown Artist';
          final videoId = item['playlistItemData']?['videoId']?.toString();
          final thumb = item['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails']?.last?['url']?.toString() ?? '';

          int durationSec = 0;
          if (runs != null && runs.length > 2) {
            final durText = runs.last['text']?.toString() ?? '';
            final cleanDur = durText.replaceAll('.', ':');
            final parts = cleanDur.split(':');
            if (parts.length == 2) {
              final m = int.tryParse(parts[0]) ?? 0;
              final s = int.tryParse(parts[1]) ?? 0;
              durationSec = m * 60 + s;
            }
          }

          if (videoId != null && title.isNotEmpty) {
            result.add(SongModel(
              id: videoId,
              title: title,
              artist: artist,
              album: 'YouTube Music',
              coverUrl: thumb,
              highResCoverUrl: thumb,
              durationSeconds: durationSec > 0 ? durationSec : 200,
              youtubeVideoId: videoId,
            ));
          }
        } else {
          node.forEach((_, v) => findTracks(v));
        }
      } else if (node is List) {
        for (final elem in node) {
          findTracks(elem);
        }
      }
    }

    findTracks(json);
    return result;
  }

  void dispose() {
    _client.close();
  }
}
