import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/song_model.dart';
import '../../../data/models/playlist_model.dart';
import '../../providers/home_discovery_provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/followed_artists_provider.dart';
import '../../providers/audio_player_provider.dart';
import '../../providers/youtube_music_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/song_tile_widget.dart';
import '../../widgets/mini_player_widget.dart';
import '../../widgets/followed_artists_section.dart';
import '../catalog/catalog_screen.dart';
import '../playlist/playlist_detail_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return 'Selamat pagi';
    if (hour >= 11 && hour < 15) return 'Selamat siang';
    if (hour >= 15 && hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeMusicProvider);
    final recent = uniqueHomeSongs(ref.watch(recentListeningProvider));
    final liked = ref.watch(libraryProvider.select((s) => s.likedSongs));
    final artists = ref
        .watch(followedArtistsProvider)
        .where((a) => a.artist.isNotEmpty)
        .toList();
    final recentKeys = recent.take(8).map(homeSongKey).toSet();
    final quick = uniqueHomeSongs([
      ...liked,
      ...home.charts.skip(10),
      ...home.charts,
    ], exclude: recentKeys).take(6).toList();
    final trending = uniqueHomeSongs(
      home.charts,
      exclude: {...recentKeys, ...quick.map(homeSongKey)},
    );
    final playlists = {for (final p in home.playlists) p.id: p}.values.toList();
    void songsPage(String title, List<SongModel> songs) => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomeSongCollection(title: title, songs: songs),
      ),
    );
    void play(SongModel song, List<SongModel> queue) =>
        ref.read(audioPlayerProvider.notifier).playSong(song, queue: queue);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: AppText(
          _greeting(),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: context.tr('Pengaturan'),
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(homeMusicProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: AppText(
                  'Musik untuk setiap suasana',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 66,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: homeMoods.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final mood = homeMoods.keys.elementAt(index);
                    const icons = [
                      Icons.wb_sunny_outlined,
                      Icons.headphones_outlined,
                      Icons.water_drop_outlined,
                      Icons.directions_car_outlined,
                      Icons.fitness_center,
                      Icons.bedtime_outlined,
                    ];
                    return ActionChip(
                      avatar: Icon(
                        icons[index],
                        size: 18,
                        color: AppColors.primary,
                      ),
                      label: AppText(mood),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MoodMusicScreen(mood: mood),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (quick.isNotEmpty) ...[
              _heading(
                context,
                'Pilihan cepat',
                () => songsPage('Pilihan cepat', quick),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LayoutBuilder(
                    builder: (context, bounds) {
                      final scale =
                          MediaQuery.textScalerOf(context).scale(14) / 14;
                      final columns = bounds.maxWidth < 300 || scale > 1.4
                          ? 1
                          : 2;
                      final width =
                          (bounds.maxWidth - (columns - 1) * 10) / columns;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: quick
                            .map(
                              (song) => SizedBox(
                                width: width,
                                height: 76 + (scale - 1).clamp(0, 2) * 32,
                                child: GlassSurface(
                                  radius: 20,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => play(song, quick),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Row(
                                          children: [
                                            HomeCover(
                                              url: song.coverUrl,
                                              size: 44,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    song.title,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    song.artist,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.white60,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ),
              ),
            ],
            if (recent.isNotEmpty) ...[
              _heading(
                context,
                'Putar lagi',
                () => songsPage('Putar lagi', recent),
              ),
              SliverToBoxAdapter(
                child: HomeCardRail(
                  items: recent
                      .take(8)
                      .map(
                        (song) => HomeCardData(
                          song.title,
                          song.artist,
                          song.coverUrl,
                          () => play(song, recent),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            if (home.isLoading && quick.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: GlassSurface(
                    padding: EdgeInsets.all(24),
                    child: AppText('Menyiapkan pilihan musik…'),
                  ),
                ),
              ),
            if (home.errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GlassSurface(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        AppText(
                          home.errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        TextButton.icon(
                          onPressed: () => ref
                              .read(homeMusicProvider.notifier)
                              .refresh(showLoadingIfEmpty: true),
                          icon: const Icon(Icons.refresh),
                          label: const AppText('Coba lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (trending.isNotEmpty) ...[
              _heading(
                context,
                'Trending Indonesia',
                () => songsPage(
                  'Trending Indonesia',
                  uniqueHomeSongs(home.charts),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => SongTileWidget(
                    song: trending[index],
                    playlistContext: trending,
                    index: home.charts.indexWhere(
                      (s) => homeSongKey(s) == homeSongKey(trending[index]),
                    ),
                  ),
                  childCount: trending.length.clamp(0, 8),
                ),
              ),
            ],
            if (artists.isNotEmpty) ...[
              _heading(
                context,
                'Artis yang kamu ikuti',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const _ArtistsPage()),
                ),
              ),
              SliverToBoxAdapter(
                child: HomeCardRail(
                  items: artists
                      .take(8)
                      .map(
                        (artist) => HomeCardData(
                          artist.artist,
                          context.tr('Diikuti'),
                          artist.coverUrl,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CatalogScreen(
                                song: artist,
                                kind: CatalogKind.artist,
                              ),
                            ),
                          ),
                          artist: true,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            if (playlists.isNotEmpty) ...[
              _heading(
                context,
                'Playlist pilihan',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _PlaylistsPage(playlists: playlists),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: HomeCardRail(
                  items: playlists
                      .take(8)
                      .map(
                        (playlist) => HomeCardData(
                          playlist.title,
                          playlist.description,
                          playlist.coverUrl ?? '',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PlaylistDetailScreen(playlist: playlist),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _heading(BuildContext context, String title, VoidCallback onAll) =>
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 10, 10),
          child: Row(
            children: [
              Expanded(
                child: AppText(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: '${context.tr('Lihat semua')}: ${context.tr(title)}',
                onPressed: onAll,
                icon: const Icon(Icons.arrow_forward_rounded, size: 22),
              ),
            ],
          ),
        ),
      );
}

class HomeCover extends StatelessWidget {
  const HomeCover({
    super.key,
    required this.url,
    required this.size,
    this.artist = false,
  });
  final String url;
  final double size;
  final bool artist;
  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: AppColors.surfaceLight,
      child: Center(
        child: Icon(
          artist ? Icons.person_outline : Icons.music_note,
          color: AppColors.primary,
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(artist ? 999 : 14),
      child: SizedBox(
        width: size,
        height: size,
        child: url.isEmpty
            ? fallback
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                memCacheWidth: (size * 3).round(),
                placeholder: (_, _) => fallback,
                errorWidget: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

class HomeCardData {
  HomeCardData(
    this.title,
    this.subtitle,
    this.cover,
    this.onTap, {
    this.artist = false,
  });
  final String title, subtitle, cover;
  final VoidCallback onTap;
  final bool artist;
}

class HomeCardRail extends StatelessWidget {
  const HomeCardRail({super.key, required this.items});
  final List<HomeCardData> items;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 174 + MediaQuery.textScalerOf(context).scale(14) * 5,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return SizedBox(
          width: 158,
          child: GlassSurface(
            radius: 22,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: item.onTap,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: HomeCover(
                          url: item.cover,
                          size: 126,
                          artist: item.artist,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class HomeSongCollection extends StatelessWidget {
  const HomeSongCollection({
    super.key,
    required this.title,
    required this.songs,
  });
  final String title;
  final List<SongModel> songs;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    appBar: AppBar(title: AppText(title)),
    body: ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: songs.length,
      itemBuilder: (_, index) =>
          SongTileWidget(song: songs[index], playlistContext: songs),
    ),
    bottomNavigationBar: const SafeArea(top: false, child: MiniPlayerWidget()),
  );
}

class MoodMusicScreen extends ConsumerWidget {
  const MoodMusicScreen({super.key, required this.mood});
  final String mood;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(moodSongsProvider(mood));
    return result.when(
      data: (songs) => songs.isNotEmpty
          ? HomeSongCollection(title: mood, songs: songs)
          : _status(context, ref, 'Belum ada lagu untuk suasana ini.'),
      loading: () => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: AppText(mood)),
        body: const Center(child: AppText('Menyiapkan pilihan musik…')),
      ),
      error: (_, _) =>
          _status(context, ref, 'Musik belum dapat dimuat. Coba lagi.'),
    );
  }

  Widget _status(BuildContext context, WidgetRef ref, String message) =>
      Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: AppText(mood)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(message, textAlign: TextAlign.center),
                TextButton(
                  onPressed: () => ref.invalidate(moodSongsProvider(mood)),
                  child: const AppText('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      );
}

class _ArtistsPage extends StatelessWidget {
  const _ArtistsPage();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    appBar: AppBar(title: const AppText('Artis yang kamu ikuti')),
    body: const SingleChildScrollView(child: FollowedArtistsSection()),
    bottomNavigationBar: const SafeArea(top: false, child: MiniPlayerWidget()),
  );
}

class _PlaylistsPage extends StatelessWidget {
  const _PlaylistsPage({required this.playlists});
  final List<PlaylistModel> playlists;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    appBar: AppBar(title: const AppText('Playlist pilihan')),
    body: ListView.builder(
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return ListTile(
          leading: HomeCover(url: playlist.coverUrl ?? '', size: 50),
          title: Text(playlist.title),
          subtitle: Text(
            playlist.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlaylistDetailScreen(playlist: playlist),
            ),
          ),
        );
      },
    ),
    bottomNavigationBar: const SafeArea(top: false, child: MiniPlayerWidget()),
  );
}
