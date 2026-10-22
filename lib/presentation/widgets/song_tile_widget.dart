import 'package:auno/core/localization/app_strings.dart';
import 'song_actions_sheet.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/song_model.dart';
import '../providers/audio_player_provider.dart';
import '../providers/library_provider.dart';

class SongTileWidget extends ConsumerWidget {
  final SongModel song;
  final List<SongModel>? playlistContext;
  final int? index;
  final VoidCallback? onTap;

  const SongTileWidget({
    super.key,
    required this.song,
    this.playlistContext,
    this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(audioPlayerProvider);
    final library = ref.watch(libraryProvider);
    final isCurrent = playerState.currentSong?.id == song.id;
    final isPlaying = isCurrent && playerState.isPlaying;
    final isLiked = library.isLiked(song.id);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: song.coverUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: song.coverUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 50,
                      height: 50,
                      color: AppColors.surfaceLight,
                      child: const Icon(
                        Icons.music_note,
                        color: AppColors.textMuted,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 50,
                      height: 50,
                      color: AppColors.surfaceLight,
                      child: const Icon(
                        Icons.music_note,
                        color: AppColors.textMuted,
                      ),
                    ),
                  )
                : Container(
                    width: 50,
                    height: 50,
                    color: AppColors.surfaceLight,
                    child: const Icon(
                      Icons.music_note,
                      color: AppColors.textMuted,
                    ),
                  ),
          ),
          if (isCurrent)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                isPlaying ? Icons.equalizer : Icons.pause,
                color: AppColors.primary,
                size: 24,
              ),
            ),
        ],
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isCurrent ? AppColors.primary : AppColors.textPrimary,
          fontSize: 15,
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          if (song.durationSeconds > 0) ...[
            const SizedBox(width: 8),
            Text(
              Formatters.formatSeconds(song.durationSeconds),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? AppColors.primary : AppColors.textMuted,
              size: 20,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(libraryProvider.notifier).toggleLike(song);
            },
          ),
          IconButton(
            tooltip: context.tr('Opsi lagu'),
            icon: const Icon(Icons.more_vert),
            onPressed: () => showSongActions(
              context,
              song,
              onAddToQueue: () {
                ref.read(audioPlayerProvider.notifier).addToQueue(song);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: AppText('Ditambahkan ke antrean: ${song.title}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      onTap:
          onTap ??
          () {
            ref
                .read(audioPlayerProvider.notifier)
                .playSong(song, queue: playlistContext);
          },
    );
  }
}
