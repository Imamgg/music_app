import 'package:auno/core/localization/app_strings.dart';
import 'package:auno/core/constants/app_colors.dart';
import 'package:auno/presentation/providers/audio_player_provider.dart';
import 'package:auno/presentation/widgets/song_tile_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(audioPlayerProvider);
    final currentSong = playerState.currentSong;
    final queue = playerState.queue;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const AppText('Antrean Pemutaran')),
      body: queue.isEmpty && currentSong == null
          ? const Center(
              child: AppText(
                'Antrean masih kosong',
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          : CustomScrollView(
              slivers: [
                if (currentSong != null) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: AppText(
                        'Sedang Diputar',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: SongTileWidget(song: currentSong)),
                  const SliverToBoxAdapter(
                    child: Divider(color: AppColors.divider, height: 24),
                  ),
                ],
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: AppText(
                      'Berikutnya dalam Antrean',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SliverReorderableList(
                  itemCount: queue.length,
                  onReorder: (oldIndex, newIndex) {
                    ref
                        .read(audioPlayerProvider.notifier)
                        .reorderQueue(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final song = queue[index];
                    final isCurrent = index == playerState.currentIndex;

                    return Dismissible(
                      key: ValueKey('${song.id}_$index'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: AppColors.error,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        ref
                            .read(audioPlayerProvider.notifier)
                            .removeFromQueue(index);
                      },
                      child: ListTile(
                        key: ValueKey('${song.id}_$index'),
                        leading: ReorderableDragStartListener(
                          index: index,
                          child: const Icon(
                            Icons.drag_handle,
                            color: AppColors.textMuted,
                          ),
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isCurrent
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          song.artist,
                          maxLines: 1,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                          onPressed: () {
                            ref
                                .read(audioPlayerProvider.notifier)
                                .removeFromQueue(index);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
