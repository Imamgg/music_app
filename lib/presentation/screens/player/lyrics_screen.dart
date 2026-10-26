import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_strings.dart';
import '../../providers/audio_player_provider.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/synced_lyrics_widget.dart';
import '../../widgets/mini_player_widget.dart';

class LyricsScreen extends ConsumerWidget {
  const LyricsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(
      audioPlayerProvider.select((state) => state.currentSong),
    );
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const AppText('Lirik Lagu')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (song != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Column(
                  children: [
                    Text(
                      song.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: GlassSurface(child: SyncedLyricsWidget()),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      bottomNavigationBar: song == null
          ? null
          : const SafeArea(top: false, child: MiniPlayerWidget()),
    );
  }
}
