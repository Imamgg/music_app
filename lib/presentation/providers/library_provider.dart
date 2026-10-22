import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/playlist_model.dart';
import '../../data/models/song_model.dart';
import '../../data/repositories/storage_repository.dart';

final storageRepoProvider = Provider<StorageRepository>((ref) {
  throw UnimplementedError(
    'StorageRepository must be overridden in ProviderScope',
  );
});

class LibraryState {
  final List<SongModel> likedSongs;
  final List<PlaylistModel> playlists;

  const LibraryState({this.likedSongs = const [], this.playlists = const []});

  bool isLiked(String songId) => likedSongs.any((s) => s.id == songId);

  LibraryState copyWith({
    List<SongModel>? likedSongs,
    List<PlaylistModel>? playlists,
  }) {
    return LibraryState(
      likedSongs: likedSongs ?? this.likedSongs,
      playlists: playlists ?? this.playlists,
    );
  }
}

final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((
  ref,
) {
  final storage = ref.watch(storageRepoProvider);
  return LibraryNotifier(storage);
});

class LibraryNotifier extends StateNotifier<LibraryState> {
  final StorageRepository _storage;

  LibraryNotifier(this._storage) : super(const LibraryState()) {
    _loadInitialData();
  }

  void _loadInitialData() {
    final liked = _storage.getLikedSongs();
    final playlists = _storage.getPlaylists();

    state = state.copyWith(likedSongs: liked, playlists: playlists);
  }

  Future<void> toggleLike(SongModel song) async {
    await _storage.toggleLike(song);
    state = state.copyWith(likedSongs: _storage.getLikedSongs());
  }

  Future<PlaylistModel> createPlaylist(
    String title, {
    String description = '',
    SongModel? initialSong,
  }) async {
    if (title.trim().isEmpty) throw ArgumentError('Nama playlist wajib diisi');
    final newPlaylist = PlaylistModel(
      id: const Uuid().v4(),
      title: title.trim(),
      songs: initialSong == null ? const [] : [initialSong],
      description: description,
      createdAt: DateTime.now(),
    );
    await _storage.savePlaylist(newPlaylist);
    state = state.copyWith(playlists: _storage.getPlaylists());
    return newPlaylist;
  }

  Future<void> addSongToPlaylist(String playlistId, SongModel song) async {
    final playlists = _storage.getPlaylists();
    final index = playlists.indexWhere((p) => p.id == playlistId);
    if (index >= 0) {
      final playlist = playlists[index];
      if (!playlist.songs.any((s) => s.id == song.id)) {
        final updatedSongs = [...playlist.songs, song];
        final updatedPlaylist = playlist.copyWith(songs: updatedSongs);
        await _storage.savePlaylist(updatedPlaylist);
        state = state.copyWith(playlists: _storage.getPlaylists());
      }
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _storage.deletePlaylist(playlistId);
    state = state.copyWith(playlists: _storage.getPlaylists());
  }
}
