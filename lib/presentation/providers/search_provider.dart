import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/song_model.dart';
import '../../data/models/search_artist.dart';
import '../../data/repositories/youtube_music_repository.dart';
import '../../data/repositories/storage_repository.dart';
import 'library_provider.dart';
import 'youtube_music_provider.dart';

class SearchState {
  const SearchState({
    this.query = '',
    this.results = const [],
    this.artists = const [],
    this.suggestions = const [],
    this.searchHistory = const [],
    this.isLoading = false,
    this.isArtistsLoading = false,
    this.isSuggesting = false,
    this.errorMessage,
  });
  final String query;
  final List<SongModel> results;
  final List<SearchArtist> artists;
  final List<String> suggestions;
  final List<String> searchHistory;
  final bool isLoading, isArtistsLoading, isSuggesting;
  final String? errorMessage;

  List<String> get displaySuggestions {
    final unique = <String, String>{};
    for (final text in [
      ...artists.map((a) => a.name),
      ...suggestions,
      ...searchHistory.where((h) => artistSearchRelevance(h, query) > 0),
    ]) {
      if (text.trim().isNotEmpty) {
        unique.putIfAbsent(normalizeSearch(text), () => text.trim());
      }
    }
    return unique.values.take(6).toList();
  }

  SearchState copyWith({
    String? query,
    List<SongModel>? results,
    List<SearchArtist>? artists,
    List<String>? suggestions,
    List<String>? searchHistory,
    bool? isLoading,
    bool? isArtistsLoading,
    bool? isSuggesting,
    String? errorMessage,
    bool clearError = false,
  }) => SearchState(
    query: query ?? this.query,
    results: results ?? this.results,
    artists: artists ?? this.artists,
    suggestions: suggestions ?? this.suggestions,
    searchHistory: searchHistory ?? this.searchHistory,
    isLoading: isLoading ?? this.isLoading,
    isArtistsLoading: isArtistsLoading ?? this.isArtistsLoading,
    isSuggesting: isSuggesting ?? this.isSuggesting,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>(
  (ref) => SearchNotifier(
    ref.watch(youtubeMusicRepoProvider),
    ref.watch(storageRepoProvider),
  ),
);

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier(this._ytm, this._storage)
    : super(SearchState(searchHistory: _storage.getSearchHistory()));
  final YouTubeMusicRepository _ytm;
  final StorageRepository _storage;
  Timer? _debounce;
  int _generation = 0;
  bool _current(int generation) => mounted && generation == _generation;

  /// Invalidate immediately on each keystroke, before the debounce expires.
  void updateQuery(String query) {
    final generation = _begin(query);
    if (state.query.isEmpty) return;
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _load(state.query, generation),
    );
  }

  int _begin(String query) {
    _debounce?.cancel();
    final generation = ++_generation;
    final clean = query.trim().replaceAll(RegExp(r'\s+'), ' ');
    // Preserve only still-relevant items while the refined query refreshes.
    // This avoids a blank flash on every keystroke without showing unrelated data.
    bool relevant(String text) =>
        clean.isNotEmpty && artistSearchRelevance(text, clean) > 0;
    state = SearchState(
      query: clean,
      results: state.results
          .where((song) => relevant('${song.title} ${song.artist}'))
          .toList(),
      artists: state.artists
          .where(
            (artist) =>
                clean.isNotEmpty &&
                artistSearchRelevance(artist.name, clean) > 0,
          )
          .toList(),
      suggestions: state.suggestions.where(relevant).toList(),
      searchHistory: state.searchHistory,
      isLoading: clean.isNotEmpty,
      isArtistsLoading: clean.isNotEmpty,
      isSuggesting: clean.isNotEmpty,
    );
    return generation;
  }

  Future<void> search(String query) async {
    final generation = _begin(query);
    final clean = state.query;
    if (clean.isEmpty) return;
    await Future.wait([_load(clean, generation), _record(clean, generation)]);
  }

  Future<void> _record(String query, int generation) async {
    try {
      await _storage.addSearchQuery(query);
      if (_current(generation)) {
        state = state.copyWith(searchHistory: _storage.getSearchHistory());
      }
    } catch (_) {
      /* Search remains usable if history cannot be saved. */
    }
  }

  Future<void> _load(String query, int generation) async {
    if (!_current(generation)) return;
    // Each result group can appear independently; suggestions never wait for songs.
    await Future.wait([
      _songs(query, generation),
      _artists(query, generation),
      _suggestions(query, generation),
    ]);
  }

  Future<void> _songs(String query, int generation) async {
    try {
      final songs = await _ytm
          .searchMusic(query)
          .timeout(const Duration(seconds: 15));
      if (!_current(generation)) return;
      final unique = <String, SongModel>{};
      for (final song in songs) {
        unique.putIfAbsent(song.id, () => song);
      }
      state = state.copyWith(
        results: _rankSongs(unique.values.toList(), state.artists),
        isLoading: false,
      );
    } catch (_) {
      if (_current(generation)) {
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'Lagu belum dapat dimuat. Periksa koneksi dan coba lagi.',
        );
      }
    }
  }

  Future<void> _artists(String query, int generation) async {
    try {
      final found = await _ytm
          .searchArtists(query)
          .timeout(const Duration(seconds: 12));
      if (!_current(generation)) return;
      final unique = <String, SearchArtist>{};
      for (final artist in found) {
        if (artistSearchRelevance(artist.name, query) > 0) {
          unique.putIfAbsent(artist.id, () => artist);
        }
      }
      final ranked = unique.values.toList();
      // Preserve source order for equally relevant artist names.
      final order = {for (var i = 0; i < ranked.length; i++) ranked[i].id: i};
      ranked.sort((a, b) {
        final relevance = artistSearchRelevance(
          b.name,
          query,
        ).compareTo(artistSearchRelevance(a.name, query));
        return relevance == 0
            ? order[a.id]!.compareTo(order[b.id]!)
            : relevance;
      });
      final artists = ranked.take(3).toList();
      state = state.copyWith(
        artists: artists,
        results: _rankSongs(state.results, artists),
        isArtistsLoading: false,
      );
    } catch (_) {
      if (_current(generation)) state = state.copyWith(isArtistsLoading: false);
    }
  }

  List<SongModel> _rankSongs(
    List<SongModel> songs,
    List<SearchArtist> artists,
  ) {
    if (artists.isEmpty) return songs;
    final first = artists.first.id;
    bool matches(SongModel song) =>
        song.artists.any((a) => a.browseId == first) ||
        song.artistBrowseId == first;
    return [...songs.where(matches), ...songs.where((s) => !matches(s))];
  }

  Future<void> _suggestions(String query, int generation) async {
    try {
      final suggestions = await _ytm
          .getSearchSuggestions(query)
          .timeout(const Duration(seconds: 6));
      if (_current(generation)) {
        state = state.copyWith(suggestions: suggestions, isSuggesting: false);
      }
    } catch (_) {
      if (_current(generation)) state = state.copyWith(isSuggesting: false);
    }
  }

  void clearSearch() {
    _begin('');
  }

  Future<void> clearHistory() async {
    await _storage.clearSearchHistory();
    if (mounted) state = state.copyWith(searchHistory: []);
  }

  @override
  void dispose() {
    _generation++;
    _debounce?.cancel();
    super.dispose();
  }
}
