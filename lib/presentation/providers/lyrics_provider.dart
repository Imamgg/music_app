import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/lyric_line.dart';
import '../../data/models/song_model.dart';
import '../../data/repositories/lyrics_repository.dart';
import 'audio_player_provider.dart';

final lyricsRepositoryProvider = Provider<LyricsRepository>((ref) {
  return LyricsRepository();
});

class LyricsState {
  final List<LyricLine> lines;
  final String? plainLyrics;
  final bool hasSyncedLyrics;
  final bool isLoading;
  final int activeIndex;

  const LyricsState({
    this.lines = const [],
    this.plainLyrics,
    this.hasSyncedLyrics = false,
    this.isLoading = false,
    this.activeIndex = -1,
  });

  LyricsState copyWith({
    List<LyricLine>? lines,
    String? plainLyrics,
    bool? hasSyncedLyrics,
    bool? isLoading,
    int? activeIndex,
  }) {
    return LyricsState(
      lines: lines ?? this.lines,
      plainLyrics: plainLyrics ?? this.plainLyrics,
      hasSyncedLyrics: hasSyncedLyrics ?? this.hasSyncedLyrics,
      isLoading: isLoading ?? this.isLoading,
      activeIndex: activeIndex ?? this.activeIndex,
    );
  }
}

final lyricsProvider = StateNotifierProvider<LyricsNotifier, LyricsState>((
  ref,
) {
  final lyricsRepo = ref.watch(lyricsRepositoryProvider);
  final notifier = LyricsNotifier(lyricsRepo);

  // Perbarui lirik saat lagu berganti
  ref.listen(audioPlayerProvider.select((s) => s.currentSong), (prev, next) {
    if (next?.id != prev?.id) notifier.loadLyricsForSong(next);
  });

  // Perbarui baris aktif saat posisi lagu berjalan
  ref.listen(audioPlayerProvider.select((s) => s.position), (_, pos) {
    notifier.updateActivePosition(pos);
  });

  notifier.updateActivePosition(ref.read(audioPlayerProvider).position);
  notifier.loadLyricsForSong(ref.read(audioPlayerProvider).currentSong);
  return notifier;
});

class LyricsNotifier extends StateNotifier<LyricsState> {
  final LyricsRepository _repo;

  LyricsNotifier(this._repo) : super(const LyricsState());

  int _generation = 0;
  Duration _position = Duration.zero;

  Future<void> loadLyricsForSong(SongModel? song) async {
    final generation = ++_generation;
    state = LyricsState(isLoading: song != null);
    if (song == null) return;
    try {
      final result = await _repo.getLyrics(song);
      if (!mounted || generation != _generation) return;
      state = LyricsState(
        lines: result.syncedLyrics,
        plainLyrics: result.plainLyrics,
        hasSyncedLyrics: result.hasSyncedLyrics,
        activeIndex: LyricLine.findActiveIndex(result.syncedLyrics, _position),
      );
    } catch (_) {
      if (mounted && generation == _generation) state = const LyricsState();
    }
  }

  void updateActivePosition(Duration position) {
    _position = position;
    if (state.lines.isEmpty) return;
    final index = LyricLine.findActiveIndex(state.lines, position);
    if (index != state.activeIndex) {
      state = state.copyWith(activeIndex: index);
    }
  }
}
