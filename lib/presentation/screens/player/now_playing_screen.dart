import 'package:auno/core/localization/app_strings.dart';
import '../../widgets/playback_control_icon.dart';
import 'package:auno/core/constants/app_colors.dart';
import 'package:auno/presentation/providers/audio_player_provider.dart';
import 'package:auno/presentation/providers/library_provider.dart';
import 'package:flutter/services.dart';
import '../../widgets/glass_surface.dart';
import 'package:auno/presentation/widgets/custom_seek_bar.dart';
import 'package:auno/presentation/widgets/synced_lyrics_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/song_actions_sheet.dart';
import 'queue_screen.dart';

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  bool _showLyrics = false;

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(audioPlayerProvider);
    final currentSong = playerState.currentSong;
    final library = ref.watch(libraryProvider);

    if (currentSong == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: AppText('Tidak ada lagu yang sedang diputar')),
      );
    }

    final isLiked = library.isLiked(currentSong.id);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        AppText(
                          currentSong.album.isNotEmpty &&
                                  currentSong.album.toLowerCase() !=
                                      'auno music' &&
                                  currentSong.album.toLowerCase() !=
                                      currentSong.title.toLowerCase()
                              ? 'MEMUTAR DARI ALBUM'
                              : 'MEMUTAR DARI ARTIS',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentSong.album.isNotEmpty &&
                                  currentSong.album.toLowerCase() !=
                                      'auno music' &&
                                  currentSong.album.toLowerCase() !=
                                      currentSong.title.toLowerCase()
                              ? currentSong.album
                              : currentSong.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.queue_music,
                          color: Colors.white,
                          size: 26,
                        ),
                        tooltip: context.tr('Antrean Musik'),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const QueueScreen(),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: context.tr('Opsi lagu'),
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => showSongActions(
                          context,
                          currentSong,
                          playerOptions: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content Area (Album Artwork or Synced Lyrics)
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showLyrics
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: GlassSurface(
                          child: SyncedLyricsWidget(key: ValueKey('lyrics')),
                        ),
                      )
                    : _buildArtwork(
                        currentSong.highResCoverUrl.isNotEmpty
                            ? currentSong.highResCoverUrl
                            : currentSong.coverUrl,
                      ),
              ),
            ),

            // Song Info & Like Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentSong.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentSong.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? AppColors.primary : Colors.white70,
                      size: 28,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref
                          .read(libraryProvider.notifier)
                          .toggleLike(currentSong);
                    },
                  ),
                ],
              ),
            ),

            // Seek Bar
            CustomSeekBar(
              position: playerState.position,
              duration: playerState.duration.inSeconds > 0
                  ? playerState.duration
                  : Duration(seconds: currentSong.durationSeconds),
              onChangeEnd: (pos) {
                ref.read(audioPlayerProvider.notifier).seek(pos);
              },
            ),

            const SizedBox(height: 12),

            // Playback Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Shuffle
                  IconButton(
                    icon: Icon(
                      Icons.shuffle,
                      color: playerState.isShuffle
                          ? AppColors.primary
                          : Colors.white60,
                      size: 24,
                    ),
                    onPressed: () {
                      ref.read(audioPlayerProvider.notifier).toggleShuffle();
                    },
                  ),

                  // Previous
                  IconButton(
                    icon: const Icon(
                      Icons.skip_previous,
                      color: Colors.white,
                      size: 36,
                    ),
                    onPressed: () {
                      ref.read(audioPlayerProvider.notifier).playPrevious();
                    },
                  ),

                  // Play/Pause / Loading FAB
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(audioPlayerProvider.notifier).togglePlayPause();
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: PlaybackControlIcon(
                          isPlaying: playerState.isPlaying,
                          isBusy:
                              playerState.isLoadingStream ||
                              playerState.isBuffering,
                          color: Colors.black,
                          size: 36,
                        ),
                      ),
                    ),
                  ),

                  // Next
                  IconButton(
                    icon: const Icon(
                      Icons.skip_next,
                      color: Colors.white,
                      size: 36,
                    ),
                    onPressed: () {
                      ref.read(audioPlayerProvider.notifier).playNext();
                    },
                  ),

                  // Repeat
                  IconButton(
                    icon: Icon(
                      playerState.repeatMode == PlaybackRepeatMode.one
                          ? Icons.repeat_one
                          : Icons.repeat,
                      color: playerState.repeatMode != PlaybackRepeatMode.off
                          ? AppColors.primary
                          : Colors.white60,
                      size: 24,
                    ),
                    onPressed: () {
                      ref.read(audioPlayerProvider.notifier).toggleRepeat();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Bottom Lyrics Toggle Pill
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _showLyrics
                          ? AppColors.primary
                          : Colors.white70,
                      side: BorderSide(
                        color: _showLyrics ? AppColors.primary : Colors.white24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                    ),
                    icon: Icon(
                      _showLyrics ? Icons.music_note : Icons.lyrics,
                      size: 18,
                    ),
                    label: AppText(
                      _showLyrics ? 'Tampilkan Sampul' : 'Lirik Lagu',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onPressed: () {
                      setState(() {
                        _showLyrics = !_showLyrics;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtwork(String coverUrl) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: coverUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.surfaceLight,
                        child: const Icon(
                          Icons.music_note,
                          size: 80,
                          color: AppColors.textMuted,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.surfaceLight,
                        child: const Icon(
                          Icons.music_note,
                          size: 80,
                          color: AppColors.textMuted,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.surfaceLight,
                      child: const Icon(
                        Icons.music_note,
                        size: 80,
                        color: AppColors.textMuted,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
