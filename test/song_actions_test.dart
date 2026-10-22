import 'package:auno/data/models/song_model.dart';
import 'package:auno/data/repositories/storage_repository.dart';
import 'package:auno/data/repositories/youtube_music_repository.dart';
import 'package:auno/presentation/providers/catalog_provider.dart';
import 'package:auno/presentation/providers/library_provider.dart';
import 'package:auno/presentation/providers/youtube_music_provider.dart';
import 'package:auno/presentation/widgets/add_to_playlist_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const track = SongModel(
  id: 'track',
  title: 'Song',
  artist: 'Artist',
  album: 'Album',
  coverUrl: '',
  highResCoverUrl: '',
  durationSeconds: 120,
);

class CatalogRepository extends YouTubeMusicRepository {
  List<SongModel> matches = [];
  String? requestedId;
  String? query;
  Map<String, List<SongModel>> pages = {};
  Map<String, Map<String, String>> metadata = {};
  @override
  Future<Map<String, String>> getCatalogMetadata(String id) async =>
      metadata[id] ?? {};
  @override
  Future<List<SongModel>> searchMusic(String query) async {
    this.query = query;
    return matches;
  }

  @override
  Future<List<SongModel>> getPlaylistTracks(String id) async {
    requestedId = id;
    return pages[id] ?? [track, track];
  }
}

void main() {
  test('Browse metadata extracts artist and album destinations', () {
    final data = YouTubeMusicRepository.browseMetadata([
      {
        'text': 'Artist',
        'navigationEndpoint': {
          'browseEndpoint': {'browseId': 'UCartist'},
        },
      },
      {'text': ' • '},
      {
        'text': 'Album',
        'navigationEndpoint': {
          'browseEndpoint': {'browseId': 'MPREalbum'},
        },
      },
    ]);
    expect(data, {
      'artistId': 'UCartist',
      'albumId': 'MPREalbum',
      'album': 'Album',
    });
    final restored = SongModel.fromJson(
      track
          .copyWith(artistBrowseId: 'UCartist', albumBrowseId: 'MPREalbum')
          .toJson(),
    );
    expect(restored.artistBrowseId, 'UCartist');
    expect(restored.albumBrowseId, 'MPREalbum');
    expect(SongModel.fromJson(track.toJson()).albumBrowseId, isNull);
  });
  test('Album opens exact browse ID and deduplicates songs', () async {
    final repo = CatalogRepository();
    final container = ProviderContainer(
      overrides: [youtubeMusicRepoProvider.overrideWithValue(repo)],
    );
    addTearDown(() {
      container.dispose();
      repo.dispose();
    });
    final data = await container.read(
      catalogProvider((
        song: track.copyWith(albumBrowseId: 'MPREalbum'),
        kind: CatalogKind.album,
      )).future,
    );
    expect(repo.requestedId, 'MPREalbum');
    expect(data.songs, hasLength(1));
    expect(data.songs.first.albumBrowseId, 'MPREalbum');
  });
  test('Legacy song only resolves an exact title and artist match', () async {
    final repo = CatalogRepository()
      ..matches = [
        track.copyWith(artist: 'Someone else', artistBrowseId: 'UCwrong'),
      ];
    final container = ProviderContainer(
      overrides: [youtubeMusicRepoProvider.overrideWithValue(repo)],
    );
    addTearDown(() {
      container.dispose();
      repo.dispose();
    });
    final data = await container.read(
      catalogProvider((song: track, kind: CatalogKind.artist)).future,
    );
    expect(data.songs, isEmpty);
    expect(repo.requestedId, isNull);
  });
  test(
    'Parser finds linked performers across columns instead of view counts',
    () {
      Map<String, dynamic> credit(String name, String id) => {
        'text': name,
        'navigationEndpoint': {
          'browseEndpoint': {'browseId': id},
        },
      };
      final tracks = YouTubeMusicRepository.parseTracks({
        'items': [
          {
            'musicResponsiveListItemRenderer': {
              'playlistItemData': {'videoId': 'recording'},
              'flexColumns': [
                {
                  'musicResponsiveListItemFlexColumnRenderer': {
                    'text': {
                      'runs': [
                        {'text': 'Duka'},
                      ],
                    },
                  },
                },
                {
                  'musicResponsiveListItemFlexColumnRenderer': {
                    'text': {
                      'runs': [
                        {'text': '12M views'},
                      ],
                    },
                  },
                },
                {
                  'musicResponsiveListItemFlexColumnRenderer': {
                    'text': {
                      'runs': [
                        credit('Last Child', 'UClast'),
                        {'text': ' & '},
                        credit('Guest', 'UCguest'),
                        credit('Album', 'MPREalbum'),
                      ],
                    },
                  },
                },
              ],
            },
          },
        ],
      });
      final song = tracks.single;
      expect(song.artist, 'Last Child & Guest');
      expect(song.artistBrowseId, 'UClast');
      expect(song.artists.map((a) => a.browseId), ['UClast', 'UCguest']);
      expect(song.albumBrowseId, 'MPREalbum');
      final restored = SongModel.fromJson(song.toJson());
      expect(restored.artists.last.name, 'Guest');
      expect(
        restored.copyWith(title: 'Updated').artists.last.browseId,
        'UCguest',
      );
    },
  );
  Future<CatalogResult> artistPage(
    CatalogRepository repo,
    SongModel song,
  ) async {
    final container = ProviderContainer(
      overrides: [youtubeMusicRepoProvider.overrideWithValue(repo)],
    );
    try {
      return await container.read(
        catalogProvider((song: song, kind: CatalogKind.artist)).future,
      );
    } finally {
      container.dispose();
      repo.dispose();
    }
  }

  test(
    'Artist page excludes recommendations and conflicting artist IDs, keeps collaborations',
    () async {
      final repo = CatalogRepository()
        ..metadata = {
          'UCright': {'title': 'Artist'},
        }
        ..pages = {
          'UCright': [
            track.copyWith(id: 'own', artistBrowseId: 'UCright'),
            track.copyWith(
              id: 'other',
              artist: 'Another Artist',
              artistBrowseId: 'UCother',
            ),
            track.copyWith(id: 'namesake', artistBrowseId: 'UCother'),
            track.copyWith(
              id: 'collab',
              artist: 'Guest & Artist',
              artistBrowseId: 'UCguest',
              artists: [
                const ArtistCredit(name: 'Guest', browseId: 'UCguest'),
                const ArtistCredit(name: 'Artist', browseId: 'UCright'),
              ],
            ),
            track.copyWith(id: 'legacy'),
            track.copyWith(id: 'unknown', artist: 'Unknown Artist'),
          ],
        };
      final result = await artistPage(
        repo,
        track.copyWith(artistBrowseId: 'UCright'),
      );
      expect(result.songs.map((s) => s.id), ['own', 'collab', 'legacy']);
    },
  );
  test(
    'Wrong saved artist destination is repaired using the matching recording',
    () async {
      final repo = CatalogRepository()
        ..matches = [track.copyWith(artistBrowseId: 'UCright')]
        ..metadata = {
          'UCwrong': {'title': 'Someone Else'},
          'UCright': {'title': 'Artist'},
        }
        ..pages = {
          'UCright': [track.copyWith(artistBrowseId: 'UCright')],
        };
      final result = await artistPage(
        repo,
        track.copyWith(
          artistBrowseId: 'UCwrong',
          artists: [const ArtistCredit(name: 'Artist', browseId: 'UCwrong')],
        ),
      );
      expect(result.browseId, 'UCright');
      expect(result.title, 'Artist');
      expect(result.songs, hasLength(1));
      expect(repo.query, 'Artist Song');
    },
  );
  test(
    'An unrelated header is never shown when identity cannot be resolved',
    () async {
      final repo = CatalogRepository()
        ..metadata = {
          'UCwrong': {'title': 'Someone Else'},
        };
      final result = await artistPage(
        repo,
        track.copyWith(artistBrowseId: 'UCwrong'),
      );
      expect(result.title, 'Artist');
      expect(result.songs, isEmpty);
      expect(result.browseId, isNull);
    },
  );
  test(
    'Exact video identity wins over same-title singers and repairs legacy credit',
    () async {
      final repo = CatalogRepository()
        ..matches = [
          track.copyWith(
            artistBrowseId: 'UCnamesake',
            youtubeVideoId: 'other-video',
          ),
          track.copyWith(
            artist: 'Actual Singer',
            artistBrowseId: 'UCactual',
            youtubeVideoId: 'source-video',
          ),
        ]
        ..metadata = {
          'UCactual': {'title': 'Actual Singer'},
        }
        ..pages = {
          'UCactual': [
            track.copyWith(artist: 'Actual Singer', artistBrowseId: 'UCactual'),
          ],
        };
      final result = await artistPage(
        repo,
        track.copyWith(youtubeVideoId: 'source-video'),
      );
      expect(result.browseId, 'UCactual');
      expect(result.title, 'Actual Singer');
      expect(result.songs, hasLength(1));
    },
  );
  test(
    'Ambiguous same-title same-name search does not choose the first artist',
    () async {
      final repo = CatalogRepository()
        ..matches = [
          track.copyWith(artistBrowseId: 'UCone'),
          track.copyWith(artistBrowseId: 'UCtwo'),
        ];
      final result = await artistPage(repo, track);
      expect(result.songs, isEmpty);
      expect(repo.requestedId, isNull);
    },
  );
  test(
    'Resolving a collaboration keeps the selected singer even when listed second',
    () async {
      final collaboration = track.copyWith(
        artist: 'Guest & Artist',
        artistBrowseId: 'UCguest',
        youtubeVideoId: 'duet',
        artists: [
          const ArtistCredit(name: 'Guest', browseId: 'UCguest'),
          const ArtistCredit(name: 'Artist', browseId: 'UCright'),
        ],
      );
      final repo = CatalogRepository()
        ..matches = [collaboration]
        ..metadata = {
          'UCright': {'title': 'Artist'},
        }
        ..pages = {
          'UCright': [collaboration],
        };
      final result = await artistPage(
        repo,
        track.copyWith(youtubeVideoId: 'duet'),
      );
      expect(result.browseId, 'UCright');
      expect(result.title, 'Artist');
      expect(result.songs.single.id, collaboration.id);
    },
  );
  test(
    'New playlists persist initial song and reject duplicates and blank names',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageRepository.create();
      final library = LibraryNotifier(storage);
      addTearDown(library.dispose);
      final created = await library.createPlaylist(
        '  My mix  ',
        initialSong: track,
      );
      await library.addSongToPlaylist(created.id, track);
      final reopened = LibraryNotifier(await StorageRepository.create());
      addTearDown(reopened.dispose);
      expect(reopened.state.playlists.single.title, 'My mix');
      expect(reopened.state.playlists.single.songs, hasLength(1));
      await expectLater(library.createPlaylist('   '), throwsArgumentError);
    },
  );
  testWidgets('Picker creates playlist with selected song', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageRepository.create();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageRepoProvider.overrideWithValue(storage)],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showAddToPlaylist(context, track),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buat playlist baru'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Evening mix');
    await tester.tap(find.byTooltip('Simpan playlist'));
    await tester.pumpAndSettle();
    expect(storage.getPlaylists().single.songs.single.id, track.id);
    expect(find.text('Tambahkan ke playlist'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
