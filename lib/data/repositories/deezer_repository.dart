import 'package:dio/dio.dart';
import '../models/song_model.dart';

class DeezerRepository {
  final Dio _dio;

  DeezerRepository({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://api.deezer.com',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {
                'Accept': 'application/json',
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              },
            ),
          );

  /// Mengambil daftar lagu Top Charts terpopuler global
  Future<List<SongModel>> getTopCharts({int limit = 30}) async {
    try {
      final response = await _dio.get(
        '/chart',
        queryParameters: {'limit': limit},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final tracksObj = data['tracks'] as Map<String, dynamic>?;
        final trackList = (tracksObj?['data'] as List<dynamic>?) ?? [];

        return trackList
            .map(
              (item) => SongModel.fromDeezerJson(item as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    } catch (e) {
      // Fallback data jika terjadi masalah jaringan
      return [];
    }
  }

  /// Mencari lagu berdasarkan kata kunci (judul, artis, album)
  Future<List<SongModel>> searchTracks(String query, {int limit = 25}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    try {
      final response = await _dio.get(
        '/search',
        queryParameters: {'q': cleanQuery, 'limit': limit},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final trackList = (data['data'] as List<dynamic>?) ?? [];

        return trackList
            .map(
              (item) => SongModel.fromDeezerJson(item as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Mengambil daftar lagu rekomendasi/populer berdasarkan artis
  Future<List<SongModel>> getArtistTopTracks(
    String artistId, {
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/artist/$artistId/top',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final trackList = (data['data'] as List<dynamic>?) ?? [];

        return trackList
            .map(
              (item) => SongModel.fromDeezerJson(item as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
