import 'package:auno/core/localization/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/song_model.dart';
import '../providers/library_provider.dart';

Future<void> showAddToPlaylist(BuildContext context, SongModel song) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _PlaylistPicker(song: song),
    );

class _PlaylistPicker extends ConsumerStatefulWidget {
  const _PlaylistPicker({required this.song});
  final SongModel song;
  @override
  ConsumerState<_PlaylistPicker> createState() => _PlaylistPickerState();
}

class _PlaylistPickerState extends ConsumerState<_PlaylistPicker> {
  final _name = TextEditingController();
  bool _creating = false;
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save(Future<void> Function() operation) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await operation();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: AppText('Lagu ditambahkan ke playlist')),
      );
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Gagal menyimpan. Coba lagi.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlists = ref.watch(libraryProvider).playlists;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AppText(
                'Tambahkan ke playlist',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Text(
                widget.song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AppText(_error!),
              ),
            if (_creating)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _name,
                        autofocus: true,
                        enabled: !_busy,
                        maxLength: 80,
                        decoration: InputDecoration(
                          labelText: context.tr('Nama playlist'),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: context.tr('Simpan playlist'),
                      onPressed: _busy
                          ? null
                          : () {
                              if (_name.text.trim().isEmpty) {
                                setState(
                                  () => _error = 'Nama playlist wajib diisi',
                                );
                                return;
                              }
                              _save(() async {
                                await ref
                                    .read(libraryProvider.notifier)
                                    .createPlaylist(
                                      _name.text,
                                      initialSong: widget.song,
                                    );
                              });
                            },
                      icon: const Icon(Icons.check),
                    ),
                  ],
                ),
              )
            else
              ListTile(
                enabled: !_busy,
                leading: const Icon(Icons.add),
                title: const AppText('Buat playlist baru'),
                onTap: () => setState(() => _creating = true),
              ),
            if (_busy) const LinearProgressIndicator(),
            Expanded(
              child: playlists.isEmpty
                  ? const Center(
                      child: AppText('Belum ada playlist. Buat yang pertama.'),
                    )
                  : ListView.builder(
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        final contains = playlist.songs.any(
                          (s) => s.id == widget.song.id,
                        );
                        return ListTile(
                          enabled: !_busy && !contains,
                          leading: const Icon(Icons.queue_music),
                          title: Text(playlist.title),
                          subtitle: AppText(
                            contains
                                ? 'Lagu sudah ditambahkan'
                                : '${playlist.songs.length} lagu',
                          ),
                          trailing: contains
                              ? const Icon(Icons.check)
                              : const Icon(Icons.add),
                          onTap: () => _save(
                            () => ref
                                .read(libraryProvider.notifier)
                                .addSongToPlaylist(playlist.id, widget.song),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
