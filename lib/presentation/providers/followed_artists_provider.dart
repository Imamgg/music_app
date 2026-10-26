import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/song_model.dart';
import '../../data/repositories/storage_repository.dart';
import 'library_provider.dart';
import 'youtube_music_provider.dart';

final followedArtistsProvider =
    StateNotifierProvider<FollowedArtistsNotifier, List<SongModel>>((ref) {
      final notifier = FollowedArtistsNotifier(ref.watch(storageRepoProvider));
      Future.microtask(
        () => notifier.restoreDetails(
          (id) => ref.read(youtubeMusicRepoProvider).getCatalogMetadata(id),
        ),
      );
      return notifier;
    });

class FollowedArtistsNotifier extends StateNotifier<List<SongModel>> {
  FollowedArtistsNotifier(this.storage) : super([]) {
    _reload();
  }
  final StorageRepository storage;
  final Set<String> _busy = {};
  void _reload() {
    final saved = {
      for (final artist in storage.getFollowedArtists()) artist.id: artist,
    };
    state = storage
        .getSavedCatalogs()
        .where((key) => key.startsWith('artist:'))
        .toList()
        .reversed
        .map((key) {
          final id = key.substring(7);
          return saved[key] ??
              SongModel(
                id: key,
                title: '',
                artist: id.startsWith('UC') ? '' : id,
                album: '',
                coverUrl: '',
                highResCoverUrl: '',
                durationSeconds: 0,
                artistBrowseId: id.startsWith('UC') ? id : null,
                artists: id.startsWith('UC')
                    ? [ArtistCredit(name: '', browseId: id)]
                    : [],
              );
        })
        .toList();
  }

  Future<void> setFollowed(String key, SongModel artist, bool followed) async {
    if (!_busy.add(key)) return;
    try {
      if (followed) {
        final saved =
            storage
                .getFollowedArtists()
                .where((entry) => entry.id != key)
                .toList()
              ..add(artist.copyWith(id: key));
        await storage.saveFollowedArtists(saved);
      }
      await storage.setCatalogSaved(key, followed);
      if (mounted) _reload();
    } finally {
      _busy.remove(key);
    }
  }

  Future<void> restoreDetails(
    Future<Map<String, String>> Function(String) fetch,
  ) async {
    for (final artist in [...state]) {
      if (!mounted) return;
      if (artist.artist.isNotEmpty || artist.artistBrowseId == null) continue;
      try {
        final details = await fetch(
          artist.artistBrowseId!,
        ).timeout(const Duration(seconds: 8));
        if (!mounted) return;
        final name = details['title'];
        if (name == null ||
            name.isEmpty ||
            !state.any((item) => item.id == artist.id && item.artist.isEmpty)) {
          continue;
        }
        final updated = artist.copyWith(
          artist: name,
          coverUrl: details['image'] ?? '',
          highResCoverUrl: details['image'] ?? '',
          artists: [ArtistCredit(name: name, browseId: artist.artistBrowseId!)],
        );
        final saved =
            storage
                .getFollowedArtists()
                .where((item) => item.id != artist.id)
                .toList()
              ..add(updated);
        await storage.saveFollowedArtists(saved);
        if (mounted) _reload();
      } catch (_) {
        /* Keep subscriptions when the network is unavailable. */
      }
    }
  }
}
