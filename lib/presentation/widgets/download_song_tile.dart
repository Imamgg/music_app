import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/song_model.dart';
import '../providers/offline_provider.dart';
import '../providers/audio_player_provider.dart';

class DownloadSongTile extends ConsumerStatefulWidget {
  const DownloadSongTile({super.key, required this.song});
  final SongModel song;
  @override
  ConsumerState<DownloadSongTile> createState() => _DownloadSongTileState();
}

class _DownloadSongTileState extends ConsumerState<DownloadSongTile> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      try {
        await ref.read(offlineProvider).initialize();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final offline = ref.watch(offlineProvider);
    final song = widget.song;
    final downloading = offline.progress.containsKey(song.id);
    final downloaded = offline.tracks.containsKey(song.id);
    return ListTile(
      leading: Icon(
        downloaded ? Icons.offline_pin_outlined : Icons.download_outlined,
      ),
      title: AppText(
        downloading
            ? 'Mengunduh lagu'
            : downloaded
            ? 'Tersedia offline'
            : 'Unduh untuk offline',
      ),
      subtitle: offline.errors[song.id] != null
          ? AppText(offline.errors[song.id]!)
          : downloading
          ? LinearProgressIndicator(value: offline.progress[song.id])
          : null,
      trailing: downloading
          ? IconButton(
              tooltip: context.tr('Batalkan unduhan'),
              icon: const Icon(Icons.close),
              onPressed: () => offline.cancel(song.id),
            )
          : downloaded
          ? const Icon(Icons.check)
          : null,
      onTap: downloading || downloaded
          ? null
          : () {
              final repo = ref.read(youtubeAudioRepoProvider);
              unawaited(
                offline.download(
                  song,
                  (s) => repo.getAudioStream(s, forceRefresh: true),
                ),
              );
            },
    );
  }
}
