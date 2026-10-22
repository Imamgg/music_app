import 'song_model.dart';

class SearchArtist {
  const SearchArtist({
    required this.id,
    required this.name,
    this.imageUrl = '',
  });
  final String id;
  final String name;
  final String imageUrl;

  SongModel get catalogSeed => SongModel(
    id: 'artist:$id',
    title: '',
    artist: name,
    album: '',
    coverUrl: '',
    highResCoverUrl: '',
    durationSeconds: 0,
    artistBrowseId: id,
    artists: [ArtistCredit(name: name, browseId: id)],
  );
}

String normalizeSearch(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

/// Complete words and the unfinished final word must match the artist name.
/// Substrings such as "tin" in "Justin" do not promote unrelated artists.
int artistSearchRelevance(String name, String query) {
  final value = normalizeSearch(name);
  final input = normalizeSearch(query);
  if (input.isEmpty) return 0;
  if (value == input) return 100;
  if (value.startsWith(input)) return 80;
  final names = value.split(RegExp(r'[\s,./&()\-]+'));
  final terms = input.split(' ');
  if (terms.every((term) => names.any((word) => word.startsWith(term)))) {
    return 60;
  }
  return 0;
}
