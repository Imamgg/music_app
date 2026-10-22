import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/song_model.dart';
import '../../core/utils/formatters.dart';
import 'youtube_music_provider.dart';

enum CatalogKind { album, artist }

class CatalogResult {
  const CatalogResult(
    this.title,
    this.songs, {
    this.imageUrl = '',
    this.description = '',
    this.subtitle = '',
    this.stats = '',
    this.browseId,
  });
  final String imageUrl, description, subtitle, stats;
  final String? browseId;
  final String title;
  final List<SongModel> songs;
}

final catalogProvider = FutureProvider.autoDispose
    .family<CatalogResult, ({SongModel song, CatalogKind kind})>((
      ref,
      request,
    ) async {
      final repo = ref.watch(youtubeMusicRepoProvider);
      final original = request.song;
      var song = original;
      final album = request.kind == CatalogKind.album;
      String? id = album ? song.albumBrowseId : song.artistBrowseId;
      var resolved = false;
      String? destinationOf(SongModel candidate) {
        if (album) return candidate.albumBrowseId;
        final selectedName = normalizeCatalogName(
          artistNameFor(original, original.artistBrowseId),
        );
        for (final credit in candidate.artists) {
          if (normalizeCatalogName(credit.name) == selectedName) {
            return credit.browseId;
          }
        }
        return candidate.artistBrowseId;
      }

      Future<bool> resolve() async {
        if (resolved) return false;
        resolved = true;
        final query =
            '${original.artist.trim()} ${Formatters.cleanTrackTitle(original.title)}';
        final matches = await repo
            .searchMusic(query)
            .timeout(const Duration(seconds: 20));
        final candidates = matches
            .where((candidate) => sameRecording(original, candidate))
            .where(
              (candidate) =>
                  !album ||
                  original.album.isEmpty ||
                  original.album == 'YouTube Music' ||
                  normalizeCatalogName(original.album) ==
                      normalizeCatalogName(candidate.album),
            )
            .where((candidate) => destinationOf(candidate)?.isNotEmpty == true)
            .toList();
        // Prefer the exact source video over other recordings with the same name.
        final exact = candidates
            .where(
              (candidate) =>
                  original.youtubeVideoId != null &&
                  candidate.youtubeVideoId == original.youtubeVideoId,
            )
            .toList();
        final eligible = exact.isNotEmpty ? exact : candidates;
        final destinations = eligible.map(destinationOf).toSet();
        if (destinations.length != 1) return false;
        song = eligible.first;
        id = destinationOf(song);
        return true;
      }

      if (id == null || id!.isEmpty || (!album && original.artists.isEmpty)) {
        await resolve();
      }
      var title = album ? song.album : artistNameFor(song, id);
      if (id == null || id!.isEmpty) return CatalogResult(title, const []);
      Future<({List<SongModel> tracks, Map<String, String> metadata})> fetch(
        String destination,
      ) async {
        final tracks = await repo
            .getPlaylistTracks(destination)
            .timeout(const Duration(seconds: 20));
        Map<String, String> metadata = {};
        try {
          metadata = await repo
              .getCatalogMetadata(destination)
              .timeout(const Duration(seconds: 8));
        } catch (_) {
          /* Details are optional. */
        }
        return (tracks: tracks, metadata: metadata);
      }

      var page = await fetch(id!);
      bool wrongArtist() =>
          !album &&
          page.metadata['title']?.isNotEmpty == true &&
          normalizeCatalogName(page.metadata['title']!) !=
              normalizeCatalogName(title);
      // Previously saved IDs can be wrong. Re-resolve using the recording credit
      // instead of displaying a different artist under the requested name.
      bool wrongAlbum() =>
          album &&
          ((title.isNotEmpty &&
                  title != 'YouTube Music' &&
                  page.metadata['title']?.isNotEmpty == true &&
                  normalizeCatalogName(page.metadata['title']!) !=
                      normalizeCatalogName(title)) ||
              (page.tracks.isNotEmpty &&
                  !page.tracks.any((track) => sameRecording(original, track))));
      if (wrongArtist() || wrongAlbum()) {
        if (!await resolve()) {
          return CatalogResult(
            album ? original.album : original.artist,
            const [],
          );
        }
        title = album ? song.album : artistNameFor(song, id);
        page = await fetch(id!);
        if (wrongArtist() || wrongAlbum()) {
          return CatalogResult(
            album ? original.album : original.artist,
            const [],
          );
        }
      }
      if (album && page.metadata['title']?.isNotEmpty == true) {
        title = page.metadata['title']!;
      }
      final unique = <String, SongModel>{};
      for (final track in page.tracks) {
        if (album &&
            track.albumBrowseId?.isNotEmpty == true &&
            track.albumBrowseId != id) {
          continue;
        }
        if (!album && !belongsToArtist(track, id!, title)) continue;
        unique.putIfAbsent(
          track.id,
          () => album ? track.copyWith(album: title, albumBrowseId: id) : track,
        );
      }
      final metadata = page.metadata;
      return CatalogResult(
        metadata['title'] ?? title,
        unique.values.toList(),
        browseId: id,
        imageUrl: metadata['image'] ?? (album ? song.highResCoverUrl : ''),
        description: metadata['description'] ?? '',
        subtitle: metadata['subtitle'] ?? '',
        stats: [
          metadata['subscribers'],
          metadata['secondSubtitle'],
        ].whereType<String>().join(' • '),
      );
    });

String normalizeCatalogName(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r"[’‘`´]"), "'")
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String artistNameFor(SongModel song, String? id) {
  for (final credit in song.artists) {
    if (credit.browseId == id) return credit.name;
  }
  return song.artist;
}

bool sameRecording(SongModel original, SongModel candidate) {
  if (original.youtubeVideoId?.isNotEmpty == true &&
      original.youtubeVideoId == candidate.youtubeVideoId) {
    return true;
  }
  if (original.durationSeconds > 0 &&
      candidate.durationSeconds > 0 &&
      (original.durationSeconds - candidate.durationSeconds).abs() > 5) {
    return false;
  }
  final name = normalizeCatalogName(
    artistNameFor(original, original.artistBrowseId),
  );
  final artistMatches =
      normalizeCatalogName(candidate.artist) == name ||
      candidate.artists.any(
        (credit) => normalizeCatalogName(credit.name) == name,
      );
  if (name.isEmpty || name == 'unknown artist' || !artistMatches) return false;
  return normalizeCatalogName(Formatters.cleanTrackTitle(original.title)) ==
      normalizeCatalogName(Formatters.cleanTrackTitle(candidate.title));
}

bool belongsToArtist(SongModel track, String id, String name) {
  if (track.artists.isNotEmpty) {
    return track.artists.any((credit) => credit.browseId == id);
  }
  if (track.artistBrowseId?.isNotEmpty == true) {
    return track.artistBrowseId == id;
  }
  // Only accept unlinked credits when the complete performer name matches.
  return name.isNotEmpty &&
      normalizeCatalogName(track.artist) == normalizeCatalogName(name);
}
