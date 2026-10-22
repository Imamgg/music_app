import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/playlist_model.dart';
import '../../providers/audio_player_provider.dart';
import '../../providers/youtube_music_provider.dart';
import '../../widgets/mini_player_widget.dart';
import '../../widgets/song_tile_widget.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final PlaylistModel playlist;

  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(playlistDetailProvider(playlist));
    final playerNotifier = ref.read(audioPlayerProvider.notifier);
    final tracks = detailState.tracks;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Sliver App Bar with Playlist Header
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.background,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gradient Background
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.primary.withValues(alpha: 0.35),
                              AppColors.surface,
                              AppColors.background,
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                        ),
                      ),
                      // Content inside Header
                      SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 16),
                            // Cover Art
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: playlist.coverUrl != null &&
                                      playlist.coverUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: playlist.coverUrl!,
                                      width: 140,
                                      height: 140,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        width: 140,
                                        height: 140,
                                        color: AppColors.surfaceLight,
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        width: 140,
                                        height: 140,
                                        color: AppColors.surfaceLight,
                                        child: const Icon(Icons.music_note,
                                            size: 48,
                                            color: AppColors.textMuted),
                                      ),
                                    )
                                  : Container(
                                      width: 140,
                                      height: 140,
                                      color: AppColors.surfaceLight,
                                      child: const Icon(Icons.queue_music,
                                          size: 48, color: AppColors.textMuted),
                                    ),
                            ),
                            const SizedBox(height: 14),
                            // Title
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                playlist.title,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Description / Track Count
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                playlist.description.isNotEmpty
                                    ? playlist.description
                                    : '${tracks.length} lagu',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action Buttons Row (Play All & Shuffle)
              if (tracks.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Play All Button
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow, color: Colors.black),
                            label: const Text(
                              'Putar Semua',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: () {
                              playerNotifier.playSong(tracks.first, queue: tracks);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Shuffle Button
                        OutlinedButton.icon(
                          icon: const Icon(Icons.shuffle, color: Colors.white),
                          label: const Text(
                            'Acak',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () {
                            final shuffled = List.of(tracks)..shuffle();
                            playerNotifier.playSong(shuffled.first, queue: shuffled);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

              // Track List
              if (detailState.isLoading && tracks.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (detailState.errorMessage != null && tracks.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.white54, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          detailState.errorMessage!,
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref
                                .read(playlistDetailProvider(playlist).notifier)
                                .refresh();
                          },
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = tracks[index];
                      return SongTileWidget(
                        song: song,
                        playlistContext: tracks,
                        index: index,
                      );
                    },
                    childCount: tracks.length,
                  ),
                ),

              // Bottom spacing for MiniPlayer
              const SliverToBoxAdapter(
                child: SizedBox(height: 90),
              ),
            ],
          ),

          // Mini Player overlay at bottom
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayerWidget(),
          ),
        ],
      ),
    );
  }
}
