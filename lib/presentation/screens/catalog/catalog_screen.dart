import 'package:auno/core/localization/app_strings.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/song_model.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/audio_player_provider.dart';
import '../../providers/library_provider.dart';
import '../../widgets/song_tile_widget.dart';
import '../../widgets/song_actions_sheet.dart';
import '../../widgets/mini_player_widget.dart';
import '../../widgets/glass_surface.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key, required this.song, required this.kind});
  final SongModel song;
  final CatalogKind kind;
  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  bool _expanded = false;
  bool _saving = false;
  bool get _album => widget.kind == CatalogKind.album;
  String _key(CatalogResult data) =>
      '${widget.kind.name}:${data.browseId ?? data.title}';
  bool _saved(CatalogResult data) =>
      ref.read(storageRepoProvider).getSavedCatalogs().contains(_key(data));
  Future<void> _toggleSaved(CatalogResult data) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(storageRepoProvider)
          .setCatalogSaved(_key(data), !_saved(data));
      HapticFeedback.lightImpact();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: AppText('Gagal menyimpan. Coba lagi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _copyLink(CatalogResult data) async {
    if (data.browseId == null) return;
    await Clipboard.setData(
      ClipboardData(
        text: Uri.https(
          'music.youtube.com',
          '/browse/${data.browseId}',
        ).toString(),
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: AppText('Tautan disalin')));
    }
  }

  void _play(CatalogResult data, {bool shuffle = false}) {
    final songs = [...data.songs];
    if (songs.isEmpty) return;
    if (shuffle) songs.shuffle();
    HapticFeedback.lightImpact();
    ref.read(audioPlayerProvider.notifier).playSong(songs.first, queue: songs);
  }

  @override
  Widget build(BuildContext context) {
    final request = (song: widget.song, kind: widget.kind);
    final result = ref.watch(catalogProvider(request));
    final data = result.valueOrNull;
    final hasSong = ref.watch(
      audioPlayerProvider.select((s) => s.hasCurrentSong),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _album ? (data?.title ?? widget.song.album) : context.tr('Artis'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (data?.browseId != null)
            IconButton(
              tooltip: context.tr('Salin tautan'),
              onPressed: () => _copyLink(data!),
              icon: const Icon(Icons.link),
            ),
        ],
      ),
      bottomNavigationBar: hasSong
          ? const SafeArea(top: false, child: MiniPlayerWidget())
          : null,
      body: result.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppText(
                  'Katalog belum dapat dimuat. Periksa koneksi lalu coba lagi.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.invalidate(catalogProvider(request)),
                  child: const AppText('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (data) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  sliver: SliverToBoxAdapter(child: _header(data)),
                ),
                if (data.songs.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const AppText('Daftar lagu belum tersedia.'),
                          TextButton(
                            onPressed: () =>
                                ref.invalidate(catalogProvider(request)),
                            child: const AppText('Coba lagi'),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!_album && data.songs.isNotEmpty)
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
                    sliver: SliverToBoxAdapter(
                      child: AppText(
                        'Lagu populer',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                SliverList.builder(
                  itemCount: data.songs.length,
                  itemBuilder: (context, index) => _album
                      ? _albumTrack(data, index)
                      : SongTileWidget(
                          song: data.songs[index],
                          playlistContext: data.songs,
                        ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(CatalogResult data) {
    final cover = data.imageUrl.isNotEmpty
        ? data.imageUrl
        : (_album
              ? widget.song.highResCoverUrl.isNotEmpty
                    ? widget.song.highResCoverUrl
                    : widget.song.coverUrl
              : '');
    final total = data.songs.fold<int>(
      0,
      (sum, song) => sum + song.durationSeconds,
    );
    final completeDuration =
        data.songs.isNotEmpty && data.songs.every((s) => s.durationSeconds > 0);
    final details = [
      if (data.subtitle.isNotEmpty) data.subtitle,
      if (_album) '${data.songs.length} lagu',
      if (_album && completeDuration) Formatters.formatSeconds(total),
    ].join(' • ');
    Widget placeholder() => GlassSurface(
      child: Center(
        child: Icon(
          _album ? Icons.album_outlined : Icons.person_outline,
          size: 88,
          color: Colors.white54,
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _album ? 320 : 672),
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: cover.isEmpty
                    ? placeholder()
                    : CachedNetworkImage(
                        imageUrl: cover,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => placeholder(),
                        errorWidget: (_, _, _) => placeholder(),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _album ? details : context.tr('ARTIS'),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          data.title.isEmpty
              ? (_album ? context.tr('Album') : widget.song.artist)
              : data.title,
          style: TextStyle(
            fontSize: _album ? 30 : 38,
            fontWeight: FontWeight.w600,
            height: 1.15,
            letterSpacing: -1,
          ),
        ),
        if (_album) ...[
          const SizedBox(height: 12),
          Text(
            widget.song.artist,
            style: const TextStyle(fontSize: 18, color: Colors.white70),
          ),
        ],
        const SizedBox(height: 24),
        if (_album)
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
                  onPressed: data.songs.isEmpty ? null : () => _play(data),
                  icon: const Icon(Icons.play_arrow),
                  label: const AppText('Putar'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: _saved(data)
                    ? context.tr('Hapus album tersimpan')
                    : context.tr('Simpan album di perangkat'),
                onPressed: _saving ? null : () => _toggleSaved(data),
                icon: Icon(
                  _saved(data) ? Icons.favorite : Icons.favorite_border,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: context.tr('Opsi album'),
                onSelected: (action) {
                  if (action == 'shuffle') {
                    _play(data, shuffle: true);
                  } else {
                    _copyLink(data);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'shuffle',
                    enabled: data.songs.isNotEmpty,
                    child: const AppText('Putar acak'),
                  ),
                  PopupMenuItem(
                    value: 'link',
                    enabled: data.browseId != null,
                    child: const AppText('Salin tautan'),
                  ),
                ],
              ),
            ],
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton(
                onPressed: _saving ? null : () => _toggleSaved(data),
                child: AppText(_saved(data) ? 'Diikuti' : 'Ikuti artis'),
              ),
              OutlinedButton.icon(
                onPressed: data.songs.isEmpty ? null : () => _play(data),
                icon: const Icon(Icons.play_arrow),
                label: const AppText('Putar'),
              ),
              IconButton.outlined(
                tooltip: context.tr('Putar acak'),
                onPressed: data.songs.isEmpty
                    ? null
                    : () => _play(data, shuffle: true),
                icon: const Icon(Icons.shuffle),
              ),
            ],
          ),
        if (!_album) ...[
          const SizedBox(height: 24),
          GlassSurface(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText(
                  'Tentang',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                if (data.stats.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    data.stats,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  data.description.isEmpty
                      ? context.tr('Biografi artis belum tersedia.')
                      : data.description,
                  maxLines: _expanded ? null : 4,
                  overflow: _expanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: const TextStyle(height: 1.6, color: Colors.white70),
                ),
                if (data.description.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    child: AppText(
                      _expanded ? 'Tampilkan lebih sedikit' : 'Selengkapnya',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _albumTrack(CatalogResult data, int index) {
    final track = data.songs[index];
    final current = ref.watch(
      audioPlayerProvider.select((s) => s.currentSong?.id == track.id),
    );
    final playing = ref.watch(audioPlayerProvider.select((s) => s.isPlaying));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        tileColor: current
            ? Colors.white.withValues(alpha: .15)
            : Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: SizedBox(
          width: 28,
          child: Center(
            child: current
                ? Icon(
                    playing ? Icons.equalizer : Icons.pause,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : AppText(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white60),
                  ),
          ),
        ),
        title: Text(track.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${track.artist == 'Unknown Artist' ? widget.song.artist : track.artist}${track.durationSeconds > 0 ? ' • ${Formatters.formatSeconds(track.durationSeconds)}' : ''}',
        ),
        trailing: IconButton(
          tooltip: context.tr('Opsi lagu'),
          icon: const Icon(Icons.more_vert),
          onPressed: () => showSongActions(context, track),
        ),
        onTap: () {
          HapticFeedback.lightImpact();
          if (current) {
            ref.read(audioPlayerProvider.notifier).togglePlayPause();
          } else {
            ref
                .read(audioPlayerProvider.notifier)
                .playSong(track, queue: data.songs);
          }
        },
      ),
    );
  }
}
