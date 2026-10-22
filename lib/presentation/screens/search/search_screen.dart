import 'package:auno/core/localization/app_strings.dart';
import '../../widgets/glass_surface.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/catalog_provider.dart';
import '../catalog/catalog_screen.dart';
import '../../../data/models/search_artist.dart';
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
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _resultsScroll = ScrollController();

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
    _resultsScroll.dispose();
    _searchFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _resetResultsScroll();
    ref.read(searchProvider.notifier).updateQuery(query);
  }

  void _resetResultsScroll() {
    if (_resultsScroll.hasClients && _resultsScroll.offset != 0) {
      _resultsScroll.jumpTo(0);
    }
  }

  void _fillSuggestion(String query) {
    _resetResultsScroll();
    _controller.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    _searchFocus.requestFocus();
    ref.read(searchProvider.notifier).updateQuery(query);
  }

  void _executeSearch(String query) {
    _resetResultsScroll();
    _controller.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    _searchFocus.unfocus();
    ref.read(searchProvider.notifier).search(query);
  }

  void _openArtist(SearchArtist artist) {
    _searchFocus.unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CatalogScreen(song: artist.catalogSeed, kind: CatalogKind.artist),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const AppText(
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
              key: const ValueKey('search-field'),
              controller: _controller,
              focusNode: _searchFocus,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onSubmitted: _executeSearch,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: .1),
                hintText: context.tr('Mau dengarkan apa?'),
                hintStyle: const TextStyle(color: Colors.white60, fontSize: 15),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _controller.clear();
                          ref.read(searchProvider.notifier).clearSearch();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(99),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
              ),
            ),
          ),

          // Content Area
          Expanded(
            child: searchState.query.isNotEmpty
                ? _buildResults(searchState)
                : _buildBrowseCategories(searchState),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(SearchState state) {
    final loading =
        state.isLoading || state.isArtistsLoading || state.isSuggesting;
    final suggestions = state.displaySuggestions;
    return CustomScrollView(
      key: const PageStorageKey('search-results'),
      controller: _resultsScroll,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        _animatedSection(
          suggestions.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
                      child: AppText(
                        'Saran pencarian',
                        style: TextStyle(fontSize: 15, color: Colors.white70),
                      ),
                    ),
                    for (final suggestion in suggestions)
                      ListTile(
                        key: ValueKey('suggestion-$suggestion'),
                        leading: const Icon(
                          Icons.search,
                          color: Colors.white60,
                        ),
                        title: _suggestionText(suggestion, state.query),
                        trailing: IconButton(
                          key: ValueKey('fill-suggestion-$suggestion'),
                          tooltip: context.tr('Gunakan saran $suggestion'),
                          icon: const Icon(Icons.north_west),
                          onPressed: () => _fillSuggestion(suggestion),
                        ),
                        onTap: () => _executeSearch(suggestion),
                      ),
                  ],
                ),
        ),
        _animatedSection(
          state.artists.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: AppText(
                        'Rekomendasi artis',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GlassSurface(
                        child: Column(
                          children: [
                            for (final artist in state.artists)
                              ListTile(
                                key: ValueKey('artist-result-${artist.id}'),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                leading: ClipOval(
                                  child: SizedBox(
                                    width: 52,
                                    height: 52,
                                    child: artist.imageUrl.isEmpty
                                        ? const ColoredBox(
                                            color: Colors.white12,
                                            child: Icon(Icons.person_outline),
                                          )
                                        : CachedNetworkImage(
                                            imageUrl: artist.imageUrl,
                                            fit: BoxFit.cover,
                                            errorWidget: (_, _, _) =>
                                                const Icon(
                                                  Icons.person_outline,
                                                ),
                                          ),
                                  ),
                                ),
                                title: Text(
                                  artist.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: const AppText('Artis'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _openArtist(artist),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        if (state.errorMessage != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  AppText(state.errorMessage!, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: () => _executeSearch(state.query),
                    child: const AppText('Coba lagi'),
                  ),
                ],
              ),
            ),
          ),
        if (state.results.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: AppText(
                'Lagu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SliverList.builder(
            itemCount: state.results.length,
            itemBuilder: (context, index) => SongTileWidget(
              song: state.results[index],
              playlistContext: state.results,
            ),
          ),
        ],
        if (!loading &&
            state.results.isEmpty &&
            state.artists.isEmpty &&
            suggestions.isEmpty &&
            state.errorMessage == null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 48, color: Colors.white54),
                  const SizedBox(height: 12),
                  AppText(
                    'Tidak ada hasil untuk "${state.query}"',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const AppText(
                    'Coba lengkapi nama artis atau judul lagu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _animatedSection(Widget child) => SliverToBoxAdapter(
    child: AnimatedSize(
      alignment: Alignment.topCenter,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: child,
    ),
  );

  Widget _suggestionText(String suggestion, String query) {
    final index = suggestion.toLowerCase().indexOf(query.toLowerCase());
    if (index < 0) {
      return Text(suggestion, maxLines: 2, overflow: TextOverflow.ellipsis);
    }
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: suggestion.substring(0, index)),
          TextSpan(
            text: suggestion.substring(index, index + query.length),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: suggestion.substring(index + query.length)),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
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
                  const AppText(
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
                    child: const AppText(
                      'Hapus',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
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
            child: AppText(
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
            delegate: SliverChildBuilderDelegate((context, index) {
              final genre = _genres[index];
              return GestureDetector(
                onTap: () {
                  _executeSearch(genre['title'] as String);
                },
                child: GlassSurface(
                  tint: genre['color'] as Color,
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
            }, childCount: _genres.length),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}
