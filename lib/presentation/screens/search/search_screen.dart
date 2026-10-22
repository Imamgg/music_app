import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/search_provider.dart';
import '../../widgets/song_tile_widget.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;

  final List<Map<String, dynamic>> _genres = const [
    {'title': 'Pop', 'color': Color(0xFF8D67AB)},
    {'title': 'Hip Hop', 'color': Color(0xFFBA5D07)},
    {'title': 'Rock', 'color': Color(0xFFE91429)},
    {'title': 'K-Pop', 'color': Color(0xFF148A08)},
    {'title': 'Indie', 'color': Color(0xFF503750)},
    {'title': 'Akustik', 'color': Color(0xFF477D95)},
    {'title': 'R&B', 'color': Color(0xFFDC148C)},
    {'title': 'Chill', 'color': Color(0xFF006450)},
  ];

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchProvider.notifier).search(query);
    });
  }

  void _executeSearch(String query) {
    _controller.text = query;
    _debounceTimer?.cancel();
    ref.read(searchProvider.notifier).search(query);
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Pencarian',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _controller,
              onChanged: _onSearchChanged,
              onSubmitted: _executeSearch,
              style: const TextStyle(color: Colors.black, fontSize: 16),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Mau dengarkan apa?',
                hintStyle: const TextStyle(color: Colors.black54, fontSize: 15),
                prefixIcon: const Icon(Icons.search, color: Colors.black87),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.black87),
                        onPressed: () {
                          _controller.clear();
                          ref.read(searchProvider.notifier).clearSearch();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Content Area
          Expanded(
            child: searchState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : searchState.query.isNotEmpty
                    ? _buildResults(searchState)
                    : _buildBrowseCategories(searchState),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(SearchState state) {
    if (state.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'Tidak ditemukan lagu untuk "${state.query}"',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: state.results.length,
      itemBuilder: (context, index) {
        final song = state.results[index];
        return SongTileWidget(
          song: song,
          playlistContext: state.results,
        );
      },
    );
  }

  Widget _buildBrowseCategories(SearchState state) {
    return CustomScrollView(
      slivers: [
        if (state.searchHistory.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pencarian Terakhir',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(searchProvider.notifier).clearHistory();
                    },
                    child: const Text('Hapus',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state.searchHistory.map((query) {
                  return ActionChip(
                    label: Text(query),
                    backgroundColor: AppColors.surfaceLight,
                    labelStyle: const TextStyle(color: AppColors.textPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onPressed: () => _executeSearch(query),
                  );
                }).toList(),
              ),
            ),
          ),
        ],

        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              'Jelajahi Semua',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.7,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final genre = _genres[index];
                return GestureDetector(
                  onTap: () {
                    _executeSearch(genre['title'] as String);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: genre['color'] as Color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        genre['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
              childCount: _genres.length,
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }
}
