import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/audio_player_provider.dart';
import '../../providers/youtube_music_provider.dart';
import '../../widgets/song_tile_widget.dart';
import '../playlist/playlist_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return 'Selamat pagi';
    if (hour >= 11 && hour < 15) return 'Selamat siang';
    if (hour >= 15 && hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeMusicProvider);
    final tracks = homeState.charts;
    final playlists = homeState.playlists;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _getGreeting(),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceLight,
        onRefresh: () async {
          await ref.read(homeMusicProvider.notifier).refresh();
        },
        child: homeState.isLoading && tracks.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : homeState.errorMessage != null && tracks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off,
                              size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            homeState.errorMessage!,
                            style: const TextStyle(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () => ref
                                .read(homeMusicProvider.notifier)
                                .refresh(showLoadingIfEmpty: true),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      // Quick Access 2-Column Grid (Spotify Top Cards)
                      if (tracks.isNotEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 3.0,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final song = tracks[index];
                                return GestureDetector(
                                  onTap: () {
                                    ref
                                        .read(audioPlayerProvider.notifier)
                                        .playSong(song, queue: tracks);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Row(
                                      children: [
                                        song.coverUrl.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: song.coverUrl,
                                                width: 56,
                                                height: 56,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                width: 56,
                                                height: 56,
                                                color:
                                                    AppColors.surfaceHighlight,
                                                child: const Icon(
                                                    Icons.music_note,
                                                    color: AppColors.textMuted),
                                              ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            song.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              childCount: tracks.length >= 6 ? 6 : tracks.length,
                            ),
                          ),
                        ),

                      // Section 1: Playlist Terpopuler YouTube Music
                      if (playlists.isNotEmpty) ...[
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                            child: Text(
                              'Playlist Pilihan YouTube Music',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 195,
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              scrollDirection: Axis.horizontal,
                              itemCount: playlists.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 14),
                              itemBuilder: (context, index) {
                                final pl = playlists[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PlaylistDetailScreen(playlist: pl),
                                      ),
                                    );
                                  },
                                  child: SizedBox(
                                    width: 135,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: pl.coverUrl != null &&
                                                  pl.coverUrl!.isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: pl.coverUrl!,
                                                  width: 135,
                                                  height: 135,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) =>
                                                      Container(
                                                    width: 135,
                                                    height: 135,
                                                    color: AppColors.surfaceLight,
                                                  ),
                                                  errorWidget:
                                                      (context, url, err) =>
                                                          Container(
                                                    width: 135,
                                                    height: 135,
                                                    color: AppColors.surfaceLight,
                                                    child: const Icon(
                                                        Icons.queue_music,
                                                        color: AppColors.textMuted),
                                                  ),
                                                )
                                              : Container(
                                                  width: 135,
                                                  height: 135,
                                                  color: AppColors.surfaceLight,
                                                  child: const Icon(
                                                      Icons.queue_music,
                                                      color: AppColors.textMuted),
                                                ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          pl.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          pl.description,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],

                      // Section 2: Tangga Lagu Terpopuler
                      if (tracks.isNotEmpty) ...[
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                            child: Text(
                              'Tangga Lagu Terpopuler',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 200,
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              scrollDirection: Axis.horizontal,
                              itemCount: tracks.length >= 10 ? 10 : tracks.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 14),
                              itemBuilder: (context, index) {
                                final song = tracks[index];
                                return GestureDetector(
                                  onTap: () {
                                    ref
                                        .read(audioPlayerProvider.notifier)
                                        .playSong(song, queue: tracks);
                                  },
                                  child: SizedBox(
                                    width: 135,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: song.coverUrl.isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: song.coverUrl,
                                                  width: 135,
                                                  height: 135,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  width: 135,
                                                  height: 135,
                                                  color: AppColors.surfaceLight,
                                                  child: const Icon(
                                                      Icons.music_note,
                                                      size: 40,
                                                      color: AppColors.textMuted),
                                                ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          song.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          song.artist,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],

                      // Section 3: Semua Lagu Charts
                      if (tracks.length > 6) ...[
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                            child: Text(
                              'Trending Musik Indonesia',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final song = tracks[index + 6];
                              return SongTileWidget(
                                song: song,
                                playlistContext: tracks,
                                index: index + 6,
                              );
                            },
                            childCount: tracks.length - 6,
                          ),
                        ),
                      ],

                      // Bottom spacing for MiniPlayer
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 100),
                      ),
                    ],
                  ),
      ),
    );
  }
}
