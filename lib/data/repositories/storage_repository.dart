import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';

class StorageRepository {
  static const String _keyLikedSongs = 'auno_liked_songs';
  static const String _keyPlaylists = 'auno_playlists';
  static const String _keyRecentSongs = 'auno_recent_songs';
  static const String _keySearchHistory = 'auno_search_history';
  static const String _keyCachedCharts = 'auno_cached_charts';
  static const String _keyCachedPlaylists = 'auno_cached_playlists';
  static const String _keyPrefixPlaylistTracks = 'auno_playlist_tracks_';

  final SharedPreferences _prefs;

  StorageRepository(this._prefs);

  static Future<StorageRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageRepository(prefs);
  }

  // --- Liked Songs ---
  List<SongModel> getLikedSongs() {
    final raw = _prefs.getString(_keyLikedSongs);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => SongModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> toggleLike(SongModel song) async {
    final current = getLikedSongs();
    final index = current.indexWhere((s) => s.id == song.id);

    if (index >= 0) {
      current.removeAt(index);
    } else {
      current.insert(0, song.copyWith(isLiked: true));
    }

    final raw = jsonEncode(current.map((s) => s.toJson()).toList());
    await _prefs.setString(_keyLikedSongs, raw);
  }

  bool isLiked(String songId) {
    final current = getLikedSongs();
    return current.any((s) => s.id == songId);
  }

  // --- Playlists ---
  List<PlaylistModel> getPlaylists() {
    final raw = _prefs.getString(_keyPlaylists);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => PlaylistModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePlaylist(PlaylistModel playlist) async {
    final current = getPlaylists();
    final index = current.indexWhere((p) => p.id == playlist.id);

    if (index >= 0) {
      current[index] = playlist;
    } else {
      current.add(playlist);
    }

    final raw = jsonEncode(current.map((p) => p.toJson()).toList());
    await _prefs.setString(_keyPlaylists, raw);
  }

  Future<void> deletePlaylist(String playlistId) async {
    final current = getPlaylists();
    current.removeWhere((p) => p.id == playlistId);
    final raw = jsonEncode(current.map((p) => p.toJson()).toList());
    await _prefs.setString(_keyPlaylists, raw);
  }

  // --- Recent Songs ---
  List<SongModel> getRecentSongs() {
    final raw = _prefs.getString(_keyRecentSongs);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => SongModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addRecentSong(SongModel song) async {
    final current = getRecentSongs();
    current.removeWhere((s) => s.id == song.id);
    current.insert(0, song);
    if (current.length > 30) {
      current.removeRange(30, current.length);
    }
    final raw = jsonEncode(current.map((s) => s.toJson()).toList());
    await _prefs.setString(_keyRecentSongs, raw);
  }

  // --- Search History ---
  List<String> getSearchHistory() {
    return _prefs.getStringList(_keySearchHistory) ?? [];
  }

  Future<void> addSearchQuery(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;
    final current = getSearchHistory();
    current.remove(clean);
    current.insert(0, clean);
    if (current.length > 10) {
      current.removeRange(10, current.length);
    }
    await _prefs.setStringList(_keySearchHistory, current);
  }

  Future<void> clearSearchHistory() async {
    await _prefs.remove(_keySearchHistory);
  }

  // --- YouTube Music Cache ---
  List<SongModel> getCachedCharts() {
    final raw = _prefs.getString(_keyCachedCharts);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => SongModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> cacheCharts(List<SongModel> songs) async {
    final raw = jsonEncode(songs.map((s) => s.toJson()).toList());
    await _prefs.setString(_keyCachedCharts, raw);
  }

  List<PlaylistModel> getCachedPlaylists() {
    final raw = _prefs.getString(_keyCachedPlaylists);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => PlaylistModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> cachePlaylists(List<PlaylistModel> playlists) async {
    final raw = jsonEncode(playlists.map((p) => p.toJson()).toList());
    await _prefs.setString(_keyCachedPlaylists, raw);
  }

  List<SongModel> getCachedPlaylistTracks(String playlistId) {
    final raw = _prefs.getString('$_keyPrefixPlaylistTracks$playlistId');
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => SongModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> cachePlaylistTracks(String playlistId, List<SongModel> tracks) async {
    final raw = jsonEncode(tracks.map((s) => s.toJson()).toList());
    await _prefs.setString('$_keyPrefixPlaylistTracks$playlistId', raw);
  }
}
