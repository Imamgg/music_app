import 'dart:convert';
import 'dart:io';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../models/search_artist.dart';

class YouTubeMusicRepository {
  final HttpClient _client = HttpClient();
  final Map<String, Map<String, dynamic>> _catalogResponses = {};

  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Content-Type': 'application/json',
    'Origin': 'https://music.youtube.com',
    'Referer': 'https://music.youtube.com/',
  };

  YouTubeMusicRepository({this.languageCode = 'id', this.countryCode = 'ID'});
  final String languageCode;
  final String countryCode;
  String get cacheLocale => '$languageCode-$countryCode';

  Map<String, dynamic> get _clientContext => {
    'client': {
      'clientName': 'WEB_REMIX',
      'clientVersion': '1.20240101.01.00',
      'hl': languageCode,
      'gl': countryCode,
    },
  };

  Future<Map<String, dynamic>?> _post(
    String endpoint,
    Map<String, dynamic> payload,
  ) async {
    try {
      final req = await _client.postUrl(
        Uri.parse(
          'https://music.youtube.com/youtubei/v1/$endpoint?prettyPrint=false',
        ),
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
    final tracks = await getPlaylistTracks(
      'VLPL4fGSI1pDJn5QPpj0R4vVgRWk8sSq549G',
    );
    if (tracks.isNotEmpty) {
      return tracks;
    }
    // Fallback ke Trending 20 Indonesia
    return await getPlaylistTracks(
      'VLOLAK5uy_n7Ig_LAUbKE6_ZeQ1pwHmJcEhwX7BekBo',
    );
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
            final subtitle =
                item['subtitle']?['runs']?[0]?['text']?.toString() ?? '';
            final browseId =
                item['navigationEndpoint']?['browseEndpoint']?['browseId']
                    ?.toString();
            final thumb =
                item['thumbnailRenderer']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails']
                    ?.last?['url']
                    ?.toString() ??
                '';
            if (browseId != null && title.isNotEmpty) {
              playlists.add(
                PlaylistModel(
                  id: browseId,
                  title: title,
                  description: subtitle.isNotEmpty
                      ? subtitle
                      : 'Playlist Resmi YouTube Music',
                  coverUrl: thumb,
                  createdAt: DateTime.now(),
                ),
              );
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
    if (playlists.isEmpty && countryCode == 'ID') {
      playlists.addAll([
        PlaylistModel(
          id: 'VLPL4fGSI1pDJn5QPpj0R4vVgRWk8sSq549G',
          title: '100 Musik Teratas Indonesia',
          description: 'Tangga lagu paling populer di Indonesia',
          coverUrl:
              'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500',
          createdAt: DateTime.now(),
        ),
        PlaylistModel(
          id: 'VLOLAK5uy_n7Ig_LAUbKE6_ZeQ1pwHmJcEhwX7BekBo',
          title: 'Trending 20 Indonesia',
          description: 'Lagu viral dan paling banyak diputar minggu ini',
          coverUrl:
              'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500',
          createdAt: DateTime.now(),
        ),
        PlaylistModel(
          id: 'VLPL4fGSI1pDJn4lW6MJA2q37CfnraqAizqE',
          title: 'Video Musik Teratas Harian',
          description: 'Update harian musik terpopuler',
          coverUrl:
              'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=500',
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

    _catalogResponses[browseId] = json;
    if (_catalogResponses.length > 12) {
      _catalogResponses.remove(_catalogResponses.keys.first);
    }

    final tracks = parseTracks(
      json,
      excludeRecommendations: browseId.startsWith('MPRE'),
    );
    if (!browseId.startsWith('MPRE')) return tracks;
    final metadata = parseCatalogMetadata(json);
    final credits = (jsonDecode(metadata['artistCredits'] ?? '[]') as List)
        .map(
          (value) =>
              ArtistCredit.fromJson(Map<String, dynamic>.from(value as Map)),
        )
        .toList();
    return tracks
        .where(
          (track) =>
              track.albumBrowseId == null || track.albumBrowseId == browseId,
        )
        .map(
          (track) => track.copyWith(
            album: metadata['title'] ?? track.album,
            albumBrowseId: browseId,
            artist: track.artist == 'Unknown Artist' && credits.isNotEmpty
                ? credits.map((c) => c.name).join(' & ')
                : track.artist,
            artists: track.artists.isEmpty ? credits : track.artists,
            artistBrowseId:
                track.artistBrowseId ??
                (credits.isEmpty ? null : credits.first.browseId),
            coverUrl: track.coverUrl.isEmpty
                ? metadata['image']
                : track.coverUrl,
            highResCoverUrl: track.highResCoverUrl.isEmpty
                ? metadata['image']
                : track.highResCoverUrl,
          ),
        )
        .toList();
  }

  /// Search songs using both the credited performer and the recording title.
  Future<List<SongModel>> searchMusic(String query) async {
    final json = await _post('search', {
      'context': _clientContext,
      'query': query,
      'params': 'EgWKAQIIAWoMEA4QChADEAQQCRAF',
    });
    if (json == null) throw StateError('Pencarian musik tidak dapat dimuat');
    return parseTracks(json);
  }

  Future<List<SearchArtist>> searchArtists(String query) async {
    final json = await _post('search', {
      'context': _clientContext,
      'query': query,
      'params': 'EgWKAQIgAWoMEA4QChADEAQQCRAF',
    });
    if (json == null) throw StateError('Pencarian artis tidak dapat dimuat');
    return parseArtists(json);
  }

  Future<List<String>> getSearchSuggestions(String query) async {
    final json = await _post('music/get_search_suggestions', {
      'context': _clientContext,
      'input': query,
    });
    if (json == null) return [];
    return parseSearchSuggestions(json);
  }

  static List<String> parseSearchSuggestions(Map<String, dynamic> json) {
    final suggestions = <String, String>{};
    void visit(dynamic node) {
      if (node is List) {
        for (final item in node) {
          visit(item);
        }
      }
      if (node is! Map) return;
      final item =
          node['searchSuggestionRenderer'] ?? node['historySuggestionRenderer'];
      if (item is Map) {
        final query =
            item['navigationEndpoint']?['searchEndpoint']?['query']
                ?.toString() ??
            (item['suggestion']?['runs'] as List? ?? [])
                .map((r) => r['text'] ?? '')
                .join();
        if (query.trim().isNotEmpty) {
          suggestions.putIfAbsent(normalizeSearch(query), () => query.trim());
        }
        return;
      }
      for (final value in node.values) {
        visit(value);
      }
    }

    visit(json);
    return suggestions.values.take(6).toList();
  }

  static List<SearchArtist> parseArtists(Map<String, dynamic> json) {
    final artists = <String, SearchArtist>{};
    void visit(dynamic node) {
      if (node is List) {
        for (final item in node) {
          visit(item);
        }
      }
      if (node is! Map) return;
      final item = node['musicResponsiveListItemRenderer'];
      if (item is Map) {
        final columns = item['flexColumns'] as List? ?? [];
        if (columns.isEmpty) return;
        final runs =
            columns.first['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']
                as List? ??
            [];
        final endpoint =
            item['navigationEndpoint']?['browseEndpoint'] ??
            (runs.isEmpty
                ? null
                : runs.first['navigationEndpoint']?['browseEndpoint']);
        final id = endpoint?['browseId']?.toString() ?? '';
        final type =
            endpoint?['browseEndpointContextSupportedConfigs']?['browseEndpointContextMusicConfig']?['pageType'];
        final name = runs.map((r) => r['text'] ?? '').join().trim();
        // Inspect the row's destination, never its song subtitle artist links.
        if (name.isEmpty ||
            id.isEmpty ||
            (type != null && type != 'MUSIC_PAGE_TYPE_ARTIST') ||
            (type != 'MUSIC_PAGE_TYPE_ARTIST' &&
                !id.startsWith('UC') &&
                !id.startsWith('MPLA'))) {
          return;
        }
        final images =
            item['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails']
                as List? ??
            [];
        artists.putIfAbsent(
          id,
          () => SearchArtist(
            id: id,
            name: name,
            imageUrl: images.isEmpty
                ? ''
                : images.last['url']?.toString() ?? '',
          ),
        );
        return;
      }
      for (final value in node.values) {
        visit(value);
      }
    }

    visit(json);
    return artists.values.toList();
  }

  static List<ArtistCredit> artistCredits(List runs) {
    final credits = <String, ArtistCredit>{};
    for (final run in runs.whereType<Map>()) {
      final endpoint = run['navigationEndpoint']?['browseEndpoint'];
      final id = endpoint?['browseId']?.toString() ?? '';
      final type =
          endpoint?['browseEndpointContextSupportedConfigs']?['browseEndpointContextMusicConfig']?['pageType'];
      final name = run['text']?.toString().trim() ?? '';
      if (name.isNotEmpty &&
          id.isNotEmpty &&
          (type == null || type == 'MUSIC_PAGE_TYPE_ARTIST') &&
          (type == 'MUSIC_PAGE_TYPE_ARTIST' ||
              id.startsWith('UC') ||
              id.startsWith('MPLA'))) {
        credits.putIfAbsent(id, () => ArtistCredit(name: name, browseId: id));
      }
    }
    return credits.values.toList();
  }

  /// Read every subtitle column; its position differs in charts, albums and
  /// artist shelves. Artist links take priority over labels such as view counts.
  static List<SongModel> parseTracks(
    Map<String, dynamic> json, {
    bool excludeRecommendations = false,
  }) {
    final songs = <SongModel>[];
    void visit(dynamic node) {
      if (node is List) {
        for (final item in node) {
          visit(item);
        }
        return;
      }
      if (node is! Map) return;
      if (excludeRecommendations &&
          node.containsKey('musicCarouselShelfRenderer')) {
        return;
      }
      final item = node['musicResponsiveListItemRenderer'];
      if (item is! Map) {
        for (final value in node.values) {
          visit(value);
        }
        return;
      }
      final flex = item['flexColumns'] as List? ?? [];
      List runsOf(dynamic column, String renderer) {
        if (column is! Map) return [];
        return column[renderer]?['text']?['runs'] as List? ?? [];
      }

      final titleRuns = flex.isEmpty
          ? []
          : runsOf(flex.first, 'musicResponsiveListItemFlexColumnRenderer');
      final title = titleRuns.map((r) => r['text'] ?? '').join().trim();
      final subtitles = [
        for (final column in flex.skip(1))
          ...runsOf(column, 'musicResponsiveListItemFlexColumnRenderer'),
      ];
      final credits = artistCredits(subtitles);
      final metadata = browseMetadata(subtitles);
      final videoId =
          item['playlistItemData']?['videoId']?.toString() ??
          item['navigationEndpoint']?['watchEndpoint']?['videoId']
              ?.toString() ??
          (titleRuns.isEmpty
              ? null
              : titleRuns
                    .first['navigationEndpoint']?['watchEndpoint']?['videoId']
                    ?.toString()) ??
          item['overlay']?['musicItemThumbnailOverlayRenderer']?['content']?['musicPlayButtonRenderer']?['playNavigationEndpoint']?['watchEndpoint']?['videoId']
              ?.toString();
      if (videoId == null || title.isEmpty) return;
      final thumbnails =
          item['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails']
              as List? ??
          [];
      final cover = thumbnails.isEmpty
          ? ''
          : thumbnails.last['url']?.toString() ?? '';
      final fixedRuns = [
        for (final column in item['fixedColumns'] as List? ?? [])
          ...runsOf(column, 'musicResponsiveListItemFixedColumnRenderer'),
      ];
      var seconds = 0;
      for (final run in [...subtitles, ...fixedRuns].whereType<Map>()) {
        final time = run['text']?.toString().trim() ?? '';
        if (!RegExp(r'^\d+:\d{2}(?::\d{2})?$').hasMatch(time)) continue;
        seconds = time
            .split(':')
            .fold(0, (total, part) => total * 60 + int.parse(part));
      }
      // A textual fallback preserves display for legacy/unlinked results. It
      // does not invent an artist ID; catalog membership is checked separately.
      const fallbackArtist = 'Unknown Artist';
      songs.add(
        SongModel(
          id: videoId,
          youtubeVideoId: videoId,
          title: title,
          artist: credits.isEmpty
              ? fallbackArtist
              : credits.map((a) => a.name).join(' & '),
          artists: credits,
          artistBrowseId: credits.isEmpty ? null : credits.first.browseId,
          album: metadata['album'] ?? '',
          albumBrowseId: metadata['albumId'],
          coverUrl: cover,
          highResCoverUrl: cover,
          durationSeconds: seconds,
        ),
      );
    }

    visit(json);
    return songs;
  }

  Future<Map<String, String>> getCatalogMetadata(String browseId) async {
    final json =
        _catalogResponses[browseId] ??
        await _post('browse', {
          'context': _clientContext,
          'browseId': browseId,
        });
    return json == null ? {} : parseCatalogMetadata(json);
  }

  static Map<String, String> parseCatalogMetadata(Map<String, dynamic> json) {
    final result = <String, String>{};
    String text(dynamic value) {
      if (value is! Map) return '';
      return value['simpleText']?.toString() ??
          (value['runs'] as List? ?? []).map((r) => r['text'] ?? '').join();
    }

    String image(dynamic node) {
      if (node is Map) {
        final thumbnails = node['thumbnails'];
        if (thumbnails is List && thumbnails.isNotEmpty) {
          return thumbnails.last['url']?.toString() ?? '';
        }
        for (final value in node.values) {
          final found = image(value);
          if (found.isNotEmpty) return found;
        }
      }
      return '';
    }

    void visit(dynamic node) {
      if (node is Map) {
        for (final entry in node.entries) {
          if ([
            'musicImmersiveHeaderRenderer',
            'musicDetailHeaderRenderer',
            'musicResponsiveHeaderRenderer',
            'musicVisualHeaderRenderer',
          ].contains(entry.key)) {
            if (result.containsKey('title')) continue;
            final header = entry.value as Map;
            for (final field in [
              'title',
              'description',
              'subtitle',
              'secondSubtitle',
            ]) {
              final value = text(header[field]);
              if (value.isNotEmpty) result[field] = value;
            }
            final credits = artistCredits([
              ...?header['subtitle']?['runs'] as List?,
              ...?header['straplineTextOne']?['runs'] as List?,
            ]);
            if (credits.isNotEmpty) {
              result['artistCredits'] = jsonEncode(
                credits.map((c) => c.toJson()).toList(),
              );
            }
            final cover = image(
              header['thumbnail'] ?? header['foregroundThumbnail'],
            );
            if (cover.isNotEmpty) result['image'] = cover;
            final subscribers = text(
              header['subscriptionButton']?['subscribeButtonRenderer']?['subscriberCountText'],
            );
            if (subscribers.isNotEmpty) result['subscribers'] = subscribers;
          }
          if (entry.key == 'musicDescriptionShelfRenderer') {
            final description = text(entry.value['description']);
            if (description.isNotEmpty) result['description'] = description;
          }
          visit(entry.value);
        }
      } else if (node is List) {
        for (final item in node) {
          visit(item);
        }
      }
    }

    visit(json);
    return result;
  }

  /// Preserve browse destinations supplied by YouTube Music subtitle runs.
  static Map<String, String> browseMetadata(List runs) {
    final result = <String, String>{};
    for (final run in runs) {
      if (run is! Map) continue;
      final endpoint = run['navigationEndpoint']?['browseEndpoint'];
      final id = endpoint?['browseId']?.toString();
      if (id == null) continue;
      final type =
          endpoint?['browseEndpointContextSupportedConfigs']?['browseEndpointContextMusicConfig']?['pageType'];
      if (type == 'MUSIC_PAGE_TYPE_ALBUM' || id.startsWith('MPRE')) {
        result['albumId'] = id;
        result['album'] = run['text']?.toString() ?? '';
      } else if (type == 'MUSIC_PAGE_TYPE_ARTIST' || id.startsWith('UC')) {
        result.putIfAbsent('artistId', () => id);
      }
    }
    return result;
  }

  void dispose() {
    _client.close();
  }
}
