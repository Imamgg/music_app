import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/playlist_model.dart';
import '../../data/models/song_model.dart';
import '../../data/repositories/youtube_music_repository.dart';
import 'library_provider.dart';

final youtubeMusicRepoProvider = Provider<YouTubeMusicRepository>((ref) {
  final repo = YouTubeMusicRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

class HomeMusicState {
  final List<SongModel> charts;
  final List<PlaylistModel> playlists;
  final bool isLoading;
  final String? errorMessage;

  const HomeMusicState({
    this.charts = const [],
    this.playlists = const [],
    this.isLoading = true,
    this.errorMessage,
  });

  HomeMusicState copyWith({
    List<SongModel>? charts,
    List<PlaylistModel>? playlists,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HomeMusicState(
      charts: charts ?? this.charts,
      playlists: playlists ?? this.playlists,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final homeMusicProvider =
    StateNotifierProvider<HomeMusicNotifier, HomeMusicState>((ref) {
  final repo = ref.watch(youtubeMusicRepoProvider);
  final storage = ref.watch(storageRepoProvider);
  return HomeMusicNotifier(repo, storage);
});

class HomeMusicNotifier extends StateNotifier<HomeMusicState> {
  final YouTubeMusicRepository _repo;
  final dynamic _storage;

  HomeMusicNotifier(this._repo, this._storage) : super(const HomeMusicState()) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // 1. Tampilkan cache lokal instan (<0.1s)
    try {
      final cachedCharts = _storage.getCachedCharts() as List<SongModel>;
      final cachedPlaylists = _storage.getCachedPlaylists() as List<PlaylistModel>;

      if (cachedCharts.isNotEmpty || cachedPlaylists.isNotEmpty) {
        state = state.copyWith(
          charts: cachedCharts,
          playlists: cachedPlaylists,
          isLoading: false,
        );
      }
    } catch (_) {}

    // 2. Fetch data mutakhir di latar belakang
    await refresh(showLoadingIfEmpty: state.charts.isEmpty);
  }

  Future<void> refresh({bool showLoadingIfEmpty = false}) async {
    if (showLoadingIfEmpty) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final futures = await Future.wait([
        _repo.getTopCharts(),
        _repo.getCuratedPlaylists(),
      ]);

      final freshCharts = futures[0] as List<SongModel>;
      final freshPlaylists = futures[1] as List<PlaylistModel>;

      if (freshCharts.isNotEmpty) {
        await _storage.cacheCharts(freshCharts);
      }
      if (freshPlaylists.isNotEmpty) {
        await _storage.cachePlaylists(freshPlaylists);
      }

      state = state.copyWith(
        charts: freshCharts.isNotEmpty ? freshCharts : state.charts,
        playlists: freshPlaylists.isNotEmpty ? freshPlaylists : state.playlists,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: state.charts.isEmpty ? 'Gagal memuat musik: $e' : null,
      );
    }
  }
}

// Provider untuk Playlist Detail
class PlaylistDetailState {
  final PlaylistModel playlist;
  final List<SongModel> tracks;
  final bool isLoading;
  final String? errorMessage;

  const PlaylistDetailState({
    required this.playlist,
    this.tracks = const [],
    this.isLoading = true,
    this.errorMessage,
  });

  PlaylistDetailState copyWith({
    PlaylistModel? playlist,
    List<SongModel>? tracks,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PlaylistDetailState(
      playlist: playlist ?? this.playlist,
      tracks: tracks ?? this.tracks,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final playlistDetailProvider = StateNotifierProvider.family<
    PlaylistDetailNotifier, PlaylistDetailState, PlaylistModel>((ref, playlist) {
  final repo = ref.watch(youtubeMusicRepoProvider);
  final storage = ref.watch(storageRepoProvider);
  return PlaylistDetailNotifier(repo, storage, playlist);
});

class PlaylistDetailNotifier extends StateNotifier<PlaylistDetailState> {
  final YouTubeMusicRepository _repo;
  final dynamic _storage;

  PlaylistDetailNotifier(this._repo, this._storage, PlaylistModel playlist)
      : super(PlaylistDetailState(playlist: playlist)) {
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    // 1. Cek cache lokal playlist
    try {
      final cached = _storage.getCachedPlaylistTracks(state.playlist.id) as List<SongModel>;
      if (cached.isNotEmpty) {
        state = state.copyWith(tracks: cached, isLoading: false);
      }
    } catch (_) {}

    // 2. Fetch tracklist dari YouTube Music
    try {
      final freshTracks = await _repo.getPlaylistTracks(state.playlist.id);
      if (freshTracks.isNotEmpty) {
        await _storage.cachePlaylistTracks(state.playlist.id, freshTracks);
        state = state.copyWith(tracks: freshTracks, isLoading: false);
      } else if (state.tracks.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Tidak ada lagu dalam playlist ini',
        );
      }
    } catch (e) {
      if (state.tracks.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Gagal memuat lagu playlist: $e',
        );
      }
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await _loadTracks();
  }
}
