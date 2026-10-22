import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/song_model.dart';
import '../../data/repositories/youtube_music_repository.dart';
import 'library_provider.dart';
import 'youtube_music_provider.dart';

class SearchState {
  final String query;
  final List<SongModel> results;
  final List<String> searchHistory;
  final bool isLoading;
  final String? errorMessage;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.searchHistory = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  SearchState copyWith({
    String? query,
    List<SongModel>? results,
    List<String>? searchHistory,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      searchHistory: searchHistory ?? this.searchHistory,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final ytm = ref.watch(youtubeMusicRepoProvider);
  final storage = ref.watch(storageRepoProvider);
  return SearchNotifier(ytm, storage);
});

class SearchNotifier extends StateNotifier<SearchState> {
  final YouTubeMusicRepository _ytm;
  final dynamic _storage;

  SearchNotifier(this._ytm, this._storage) : super(const SearchState()) {
    _loadHistory();
  }

  void _loadHistory() {
    final history = _storage.getSearchHistory() as List<String>;
    state = state.copyWith(searchHistory: history);
  }

  Future<void> search(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      state = state.copyWith(query: '', results: [], isLoading: false);
      return;
    }

    state = state.copyWith(query: clean, isLoading: true, clearError: true);

    try {
      final tracks = await _ytm.searchMusic(clean);
      await _storage.addSearchQuery(clean);
      final history = _storage.getSearchHistory() as List<String>;

      state = state.copyWith(
        results: tracks,
        searchHistory: history,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal melakukan pencarian: $e',
      );
    }
  }

  void clearSearch() {
    state = state.copyWith(query: '', results: [], isLoading: false);
  }

  Future<void> clearHistory() async {
    await _storage.clearSearchHistory();
    state = state.copyWith(searchHistory: []);
  }
}
