import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_strings.dart';
import '../providers/followed_artists_provider.dart';
import '../providers/catalog_provider.dart';
import '../screens/catalog/catalog_screen.dart';
import 'glass_surface.dart';

class FollowedArtistsSection extends ConsumerStatefulWidget {
  const FollowedArtistsSection({super.key});
  @override
  ConsumerState<FollowedArtistsSection> createState() =>
      _FollowedArtistsSectionState();
}

class _FollowedArtistsSectionState
    extends ConsumerState<FollowedArtistsSection> {
  String _query = '';
  bool _alphabetical = false;
  bool _searching = false;
  @override
  Widget build(BuildContext context) {
    final all = ref.watch(followedArtistsProvider);
    final artists = all
        .where(
          (artist) =>
              artist.artist.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    if (_alphabetical) {
      artists.sort(
        (a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppText(
            'Artis yang diikuti',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ActionChip(
                    avatar: const Icon(Icons.sort, size: 18),
                    label: AppText(
                      _alphabetical ? 'Nama A–Z' : 'Terbaru ditambahkan',
                    ),
                    onPressed: () =>
                        setState(() => _alphabetical = !_alphabetical),
                  ),
                ),
              ),
              IconButton(
                tooltip: context.tr('Cari artis'),
                icon: Icon(_searching ? Icons.close : Icons.search),
                onPressed: () => setState(() {
                  _searching = !_searching;
                  if (!_searching) _query = '';
                }),
              ),
            ],
          ),
          if (_searching)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: TextField(
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: context.tr('Cari artis'),
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ),
          const SizedBox(height: 8),
          GlassSurface(
            child: Column(
              children: [
                if (artists.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: AppText(
                      all.isEmpty
                          ? 'Artis yang Anda ikuti akan muncul di sini.'
                          : 'Artis tidak ditemukan.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (var index = 0; index < artists.length; index++) ...[
                  if (index > 0)
                    const Divider(
                      height: 1,
                      indent: 88,
                      endIndent: 16,
                      color: AppColors.divider,
                    ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: artists[index].coverUrl.isEmpty
                            ? const ColoredBox(
                                color: AppColors.surfaceLight,
                                child: Icon(Icons.person_outline),
                              )
                            : CachedNetworkImage(
                                imageUrl: artists[index].coverUrl,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) =>
                                    const Icon(Icons.person_outline),
                              ),
                      ),
                    ),
                    title: Text(
                      artists[index].artist.isEmpty
                          ? context.tr('Artis tersimpan')
                          : artists[index].artist,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.favorite,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: AppText(
                              'Diikuti',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: artists[index].artist.isEmpty
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CatalogScreen(
                                song: artists[index],
                                kind: CatalogKind.artist,
                              ),
                            ),
                          ),
                    trailing: PopupMenuButton<String>(
                      tooltip: context.tr('Opsi artis'),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'open',
                          enabled: artists[index].artist.isNotEmpty,
                          child: const AppText('Lihat artis'),
                        ),
                        const PopupMenuItem(
                          value: 'remove',
                          child: AppText('Berhenti mengikuti'),
                        ),
                      ],
                      onSelected: (value) async {
                        final artist = artists[index];
                        if (value == 'open') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CatalogScreen(
                                song: artist,
                                kind: CatalogKind.artist,
                              ),
                            ),
                          );
                        } else {
                          try {
                            await ref
                                .read(followedArtistsProvider.notifier)
                                .setFollowed(artist.id, artist, false);
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: AppText(
                                    'Gagal menyimpan. Coba lagi.',
                                  ),
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
