import 'package:auno/core/localization/app_strings.dart';
import 'playback_control_icon.dart';
import 'package:flutter/services.dart';
import 'glass_surface.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../providers/audio_player_provider.dart';
import '../providers/library_provider.dart';
import '../screens/player/now_playing_screen.dart';

class MiniPlayerWidget extends ConsumerWidget {
  const MiniPlayerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(audioPlayerProvider);
    final song = playerState.currentSong;

    if (song == null) {
      return const SizedBox.shrink();
    }

    final library = ref.watch(libraryProvider);
    final isLiked = library.isLiked(song.id);

    final durationMs = playerState.duration.inMilliseconds;
    final positionMs = playerState.position.inMilliseconds;
    final progress = (durationMs > 0 ? (positionMs / durationMs) : 0.0).clamp(
      0.0,
      1.0,
    );

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() < 150) return;
        HapticFeedback.lightImpact();
        final player = ref.read(audioPlayerProvider.notifier);
        if (velocity < 0) {
          player.playNext();
        } else {
          player.playPrevious();
        }
      },
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const NowPlayingScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 1.0);
                  const end = Offset.zero;
                  const curve = Curves.easeOutCubic;
                  final tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GlassSurface(
          radius: 99,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // Artwork
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: song.coverUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: song.coverUrl,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 44,
                                height: 44,
                                color: AppColors.surfaceLight,
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 44,
                                height: 44,
                                color: AppColors.surfaceLight,
                                child: const Icon(
                                  Icons.music_note,
                                  size: 20,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            )
                          : Container(
                              width: 44,
                              height: 44,
                              color: AppColors.surfaceLight,
                              child: const Icon(
                                Icons.music_note,
                                size: 20,
                                color: AppColors.textMuted,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),

                    // Song Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Like Button
                    IconButton(
                      tooltip: context.tr(
                        isLiked ? 'Hapus dari favorit' : 'Sukai lagu',
                      ),
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? AppColors.primary : Colors.white70,
                        size: 22,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.read(libraryProvider.notifier).toggleLike(song);
                      },
                    ),

                    // Play/Pause Button
                    IconButton(
                      tooltip: context.tr(
                        playerState.isPlaying ? 'Jeda' : 'Putar',
                      ),
                      icon: PlaybackControlIcon(
                        isPlaying: playerState.isPlaying,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref
                            .read(audioPlayerProvider.notifier)
                            .togglePlayPause();
                      },
                    ),

                    // Next Button
                    IconButton(
                      tooltip: context.tr('Lagu berikutnya'),
                      icon: const Icon(
                        Icons.skip_next,
                        color: Colors.white,
                        size: 26,
                      ),
                      onPressed: () {
                        ref.read(audioPlayerProvider.notifier).playNext();
                      },
                    ),
                  ],
                ),
              ),

              // Progress Bar at bottom
              LinearProgressIndicator(
                value: progress,
                minHeight: 2.5,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
