import '../../widgets/followed_artists_section.dart';
import '../downloads/downloads_screen.dart';
import 'package:auno/core/localization/app_strings.dart';
import '../../widgets/glass_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/playlist_model.dart';
import '../../providers/audio_player_provider.dart';
import '../../providers/library_provider.dart';
import '../../widgets/song_tile_widget.dart';
import '../settings/settings_screen.dart';

final _libraryFilterProvider = StateProvider.autoDispose<String>(
  (ref) => 'Semua',
);

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => GlassDialog(
        title: const AppText(
          'Buat Playlist Baru',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: context.tr('Nama Playlist'),
                hintStyle: TextStyle(color: AppColors.textMuted),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: context.tr('Deskripsi (opsional)'),
                hintStyle: TextStyle(color: AppColors.textMuted),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const AppText(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                ref
                    .read(libraryProvider.notifier)
                    .createPlaylist(
                      title,
                      description: descController.text.trim(),
                    );
                Navigator.pop(context);
              }
            },
            child: const AppText('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);
    final filter = ref.watch(_libraryFilterProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const AppText(
          'Koleksi Kamu',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: context.tr('Buat Playlist Baru'),
            onPressed: () => _showCreatePlaylistDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: context.tr('Pengaturan'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: ['Semua', 'Playlist', 'Artis']
                    .map(
                      (value) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: AppText(value),
                          selected: filter == value,
                          onSelected: (_) =>
                              ref.read(_libraryFilterProvider.notifier).state =
                                  value,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          if (filter != 'Artis')
            SliverToBoxAdapter(
              child: ListTile(
                leading: const Icon(Icons.offline_pin_outlined),
                title: const AppText('Unduhan'),
                subtitle: const AppText('Musik tanpa internet'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DownloadsScreen()),
                ),
              ),
            ),
          // Liked Songs Card
          if (filter != 'Artis')
            SliverToBoxAdapter(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF450AF5), Color(0xFFC4EFD9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Icon(Icons.favorite, color: Colors.white, size: 28),
                  ),
                ),
                title: const AppText(
                  'Lagu yang Disukai',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                subtitle: AppText(
                  '${library.likedSongs.length} lagu',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LikedSongsDetailScreen(),
                    ),
                  );
                },
              ),
            ),

          // Custom Playlists
          if (filter != 'Artis' && library.playlists.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: AppText(
                  'Playlist Saya',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final playlist = library.playlists[index];
                return ListTile(
                  leading: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.queue_music,
                      color: AppColors.textMuted,
                      size: 28,
                    ),
                  ),
                  title: Text(
                    playlist.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: AppText(
                    '${playlist.songs.length} lagu',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () {
                      ref
                          .read(libraryProvider.notifier)
                          .deletePlaylist(playlist.id);
                    },
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            PlaylistDetailScreen(playlist: playlist),
                      ),
                    );
                  },
                );
              }, childCount: library.playlists.length),
            ),
          ],

          if (filter != 'Playlist')
            const SliverToBoxAdapter(child: FollowedArtistsSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 140)),
        ],
      ),
    );
  }
}

class LikedSongsDetailScreen extends ConsumerWidget {
  const LikedSongsDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);
    final songs = library.likedSongs;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const AppText('Lagu yang Disukai')),
      floatingActionButton: songs.isNotEmpty
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              onPressed: () {
                ref
                    .read(audioPlayerProvider.notifier)
                    .playSong(songs.first, queue: songs);
              },
              child: const Icon(Icons.play_arrow, size: 32),
            )
          : null,
      body: songs.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(height: 16),
                  AppText(
                    'Belum ada lagu yang disukai',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 8),
                  AppText(
                    'Tekan tombol hati pada lagu apa pun untuk menyimpannya di sini',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                return SongTileWidget(
                  song: songs[index],
                  playlistContext: songs,
                );
              },
            ),
    );
  }
}

class PlaylistDetailScreen extends ConsumerWidget {
  final PlaylistModel playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);
    final updatedPlaylist = library.playlists.firstWhere(
      (p) => p.id == playlist.id,
      orElse: () => playlist,
    );
    final songs = updatedPlaylist.songs;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(updatedPlaylist.title)),
      floatingActionButton: songs.isNotEmpty
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              onPressed: () {
                ref
                    .read(audioPlayerProvider.notifier)
                    .playSong(songs.first, queue: songs);
              },
              child: const Icon(Icons.play_arrow, size: 32),
            )
          : null,
      body: songs.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.music_off,
                    size: 64,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  const AppText(
                    'Playlist ini masih kosong',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    updatedPlaylist.description.isNotEmpty
                        ? updatedPlaylist.description
                        : 'Tambahkan lagu dari menu opsi pada lagu',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                return SongTileWidget(
                  song: songs[index],
                  playlistContext: songs,
                );
              },
            ),
    );
  }
}
