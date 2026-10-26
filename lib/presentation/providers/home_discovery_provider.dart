import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/song_model.dart';
import '../../data/repositories/storage_repository.dart';
import 'library_provider.dart';
import 'audio_player_provider.dart';
import 'youtube_music_provider.dart';

final recentListeningProvider =
    StateNotifierProvider<RecentListeningNotifier, List<SongModel>>((ref) {
      final notifier = RecentListeningNotifier(ref.watch(storageRepoProvider));
      ref.listen(
        audioPlayerProvider.select(
          (state) => (
            state.currentSong,
            state.isPlaying,
            state.isLoadingStream,
            state.isBuffering,
          ),
        ),
        (_, next) {
          if (next.$1 != null && next.$2 && !next.$3 && !next.$4) {
            notifier.record(next.$1!);
          }
        },
      );
      return notifier;
    });

class RecentListeningNotifier extends StateNotifier<List<SongModel>> {
  RecentListeningNotifier(this.storage) : super(storage.getRecentSongs());
  final StorageRepository storage;
  Future<void> _writes = Future.value();
  void record(SongModel song) {
    if (state.isNotEmpty && state.first.id == song.id) return;
    state = [
      song,
      ...state.where((item) => item.id != song.id),
    ].take(30).toList();
    _writes = _writes
        .then((_) => storage.addRecentSong(song))
        .catchError((Object _) {});
  }
}

List<SongModel> uniqueHomeSongs(
  Iterable<SongModel> songs, {
  Set<String> exclude = const {},
}) {
  final seen = {...exclude};
  return songs
      .where(
        (song) => seen.add(
          song.youtubeVideoId?.isNotEmpty == true
              ? song.youtubeVideoId!
              : song.id,
        ),
      )
      .toList();
}

String homeSongKey(SongModel song) =>
    song.youtubeVideoId?.isNotEmpty == true ? song.youtubeVideoId! : song.id;

const homeMoods = {
  'Santai': 'lagu santai akustik Indonesia',
  'Fokus': 'instrumental piano fokus belajar',
  'Sedih': 'lagu galau Indonesia',
  'Perjalanan': 'lagu perjalanan Indonesia',
  'Olahraga': 'workout energetic music',
  'Tidur': 'calm sleep instrumental music',
};
final moodSongsProvider = FutureProvider.autoDispose
    .family<List<SongModel>, String>((ref, mood) async {
      final query = homeMoods[mood];
      if (query == null) return [];
      return uniqueHomeSongs(
        await ref
            .read(youtubeMusicRepoProvider)
            .searchMusic(query)
            .timeout(const Duration(seconds: 20)),
      );
    });
