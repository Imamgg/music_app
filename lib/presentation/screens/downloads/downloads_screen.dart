import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_strings.dart';
import '../../providers/audio_player_provider.dart';
import '../../providers/offline_provider.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/glass_dialog.dart';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});
  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  late Future<void> _loading;
  @override
  void initState() {
    super.initState();
    _loading = ref.read(offlineProvider).initialize();
  }

  @override
  Widget build(BuildContext context) {
    final offline = ref.watch(offlineProvider);
    final tracks = offline.tracks.values.toList();
    final queue = tracks.map((t) => t.song).toList();
    return Scaffold(
      appBar: AppBar(title: const AppText('Unduhan')),
      body: FutureBuilder<void>(
        future: _loading,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: TextButton(
                onPressed: () => setState(() {
                  _loading = offline.initialize();
                }),
                child: const AppText('Coba lagi'),
              ),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              GlassSurface(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText(
                      'Musik tanpa internet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppText('${tracks.length} lagu'),
                    Text(
                      '${(tracks.fold<int>(0, (sum, t) => sum + t.bytes) / 1048576).toStringAsFixed(1)} MB',
                    ),
                    const SizedBox(height: 8),
                    const AppText(
                      'Unduh lagu melalui menu lagu. Biarkan aplikasi terbuka sampai unduhan selesai.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (final id in offline.progress.keys)
                ListTile(
                  title: Text(
                    offline.jobs[id]?.title ?? context.tr('Mengunduh lagu'),
                  ),
                  subtitle: LinearProgressIndicator(
                    value: offline.progress[id],
                  ),
                  trailing: IconButton(
                    tooltip: context.tr('Batalkan unduhan'),
                    icon: const Icon(Icons.close),
                    onPressed: () => offline.cancel(id),
                  ),
                ),
              for (final entry in tracks)
                ListTile(
                  leading: const Icon(Icons.offline_pin_outlined),
                  title: Text(entry.song.title),
                  subtitle: Text(entry.song.artist),
                  onTap: () => ref
                      .read(audioPlayerProvider.notifier)
                      .playSong(entry.song, queue: queue),
                  trailing: IconButton(
                    tooltip: context.tr('Hapus unduhan'),
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final remove = await showDialog<bool>(
                        context: context,
                        builder: (context) => GlassDialog(
                          title: const AppText('Hapus unduhan?'),
                          content: Text(entry.song.title),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const AppText('Batal'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const AppText('Hapus'),
                            ),
                          ],
                        ),
                      );
                      if (remove == true) await offline.remove(entry.song.id);
                      if (context.mounted &&
                          offline.errors[entry.song.id] != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: AppText(offline.errors[entry.song.id]!),
                          ),
                        );
                      }
                    },
                  ),
                ),
              for (final error in offline.errors.entries.where(
                (e) => !offline.tracks.containsKey(e.key),
              ))
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(offline.jobs[error.key]?.title ?? ''),
                      AppText(error.value),
                      TextButton(
                        onPressed: () {
                          final song = offline.jobs[error.key];
                          if (song != null) {
                            offline.download(
                              song,
                              (s) => ref
                                  .read(youtubeAudioRepoProvider)
                                  .getAudioStream(s, forceRefresh: true),
                            );
                          }
                        },
                        child: const AppText('Coba lagi'),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
