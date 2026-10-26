import 'download_song_tile.dart';
import '../screens/settings/equalizer_settings_screen.dart';
import 'package:auno/core/localization/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/song_model.dart';
import '../providers/catalog_provider.dart';
import '../screens/catalog/catalog_screen.dart';
import '../screens/settings/settings_screen.dart';
import 'add_to_playlist_sheet.dart';
import 'sleep_timer_bottom_sheet.dart';
import 'glass_surface.dart';

enum SongAction { playlist, artist, album, queue, timer, settings, equalizer }

Future<void> showSongActions(
  BuildContext context,
  SongModel song, {
  VoidCallback? onAddToQueue,
  bool playerOptions = false,
}) async {
  final action = await showModalBottomSheet<SongAction>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: const Color(0xF0182031),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => SingleChildScrollView(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: song.coverUrl.isEmpty
                      ? const Icon(Icons.music_note, size: 48)
                      : CachedNetworkImage(
                          imageUrl: song.coverUrl,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) =>
                              const Icon(Icons.music_note),
                        ),
                ),
                title: Text(
                  song.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(song.artist),
              ),
              const SizedBox(height: 16),
              GlassSurface(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.playlist_add),
                      title: const AppText('Tambahkan ke playlist'),
                      onTap: () => Navigator.pop(context, SongAction.playlist),
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const AppText('Lihat artis'),
                      subtitle: Text(song.artist),
                      onTap: () => Navigator.pop(context, SongAction.artist),
                    ),
                    ListTile(
                      leading: const Icon(Icons.album_outlined),
                      title: const AppText('Lihat album'),
                      subtitle: Text(
                        song.album.isEmpty || song.album == 'YouTube Music'
                            ? context.tr('Cari informasi album')
                            : song.album,
                      ),
                      onTap: () => Navigator.pop(context, SongAction.album),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (onAddToQueue != null)
                ListTile(
                  leading: const Icon(Icons.queue_music),
                  title: const AppText('Tambah ke antrean'),
                  onTap: () => Navigator.pop(context, SongAction.queue),
                ),
              DownloadSongTile(song: song),
              if (playerOptions) ...[
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: const AppText('Equalizer'),
                  onTap: () => Navigator.pop(context, SongAction.equalizer),
                ),
                ListTile(
                  leading: const Icon(Icons.bedtime_outlined),
                  title: const AppText('Waktu tidur'),
                  onTap: () => Navigator.pop(context, SongAction.timer),
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const AppText('Pengaturan'),
                  onTap: () => Navigator.pop(context, SongAction.settings),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
  if (!context.mounted || action == null) return;
  switch (action) {
    case SongAction.playlist:
      await showAddToPlaylist(context, song);
    case SongAction.artist:
    case SongAction.album:
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CatalogScreen(
            song: song,
            kind: action == SongAction.album
                ? CatalogKind.album
                : CatalogKind.artist,
          ),
        ),
      );
    case SongAction.queue:
      onAddToQueue?.call();
    case SongAction.timer:
      SleepTimerBottomSheet.show(context);
    case SongAction.equalizer:
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EqualizerSettingsScreen()),
      );
    case SongAction.settings:
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
  }
}
