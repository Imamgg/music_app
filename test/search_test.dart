import 'dart:async';
import 'package:auno/core/theme/app_theme.dart';
import 'package:auno/data/models/search_artist.dart';
import 'package:auno/data/models/song_model.dart';
import 'package:auno/data/repositories/storage_repository.dart';
import 'package:auno/data/repositories/youtube_audio_repository.dart';
import 'package:auno/data/repositories/youtube_music_repository.dart';
import 'package:auno/presentation/providers/audio_player_provider.dart';
import 'package:auno/presentation/providers/catalog_provider.dart';
import 'package:auno/presentation/providers/library_provider.dart';
import 'package:auno/presentation/providers/search_provider.dart';
import 'package:auno/presentation/providers/youtube_music_provider.dart';
import 'package:auno/presentation/screens/catalog/catalog_screen.dart';
import 'package:auno/presentation/screens/search/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'aurora_ui_test.dart' as fixture;

const bieber = SearchArtist(id: 'UCbieber', name: 'Justin Bieber');
const timberlake = SearchArtist(id: 'UCtimberlake', name: 'Justin Timberlake');
const song = SongModel(
  id: 'baby',
  title: 'Baby',
  artist: 'Justin Bieber',
  album: '',
  coverUrl: '',
  highResCoverUrl: '',
  durationSeconds: 210,
  artistBrowseId: 'UCbieber',
);

class PendingSearch extends YouTubeMusicRepository {
  final tracks = <String, Completer<List<SongModel>>>{};
  final artists = <String, Completer<List<SearchArtist>>>{};
  final suggestions = <String, Completer<List<String>>>{};
  @override
  Future<List<SongModel>> searchMusic(String query) =>
      (tracks[query] ??= Completer()).future;
  @override
  Future<List<SearchArtist>> searchArtists(String query) =>
      (artists[query] ??= Completer()).future;
  @override
  Future<List<String>> getSearchSuggestions(String query) =>
      (suggestions[query] ??= Completer()).future;
  void complete(
    String query, {
    List<SongModel> songs = const [],
    List<SearchArtist> performers = const [],
    List<String> hints = const [],
  }) {
    tracks[query]!.complete(songs);
    artists[query]!.complete(performers);
    suggestions[query]!.complete(hints);
  }
}

class ImmediateSearch extends YouTubeMusicRepository {
  final requests = <String>[];
  @override
  Future<List<SongModel>> searchMusic(String query) async {
    requests.add(query);
    return [song];
  }

  @override
  Future<List<SearchArtist>> searchArtists(String query) async => [
    bieber,
    timberlake,
  ];
  @override
  Future<List<String>> getSearchSuggestions(String query) async => [
    'justin bieber',
    'justin bieber baby',
  ];
}

Map<String, dynamic> artistRow(
  String name,
  String id, {
  String type = 'MUSIC_PAGE_TYPE_ARTIST',
}) => {
  'musicResponsiveListItemRenderer': {
    'navigationEndpoint': {
      'browseEndpoint': {
        'browseId': id,
        'browseEndpointContextSupportedConfigs': {
          'browseEndpointContextMusicConfig': {'pageType': type},
        },
      },
    },
    'flexColumns': [
      {
        'musicResponsiveListItemFlexColumnRenderer': {
          'text': {
            'runs': [
              {'text': name},
            ],
          },
        },
      },
    ],
  },
};
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StorageRepository storage;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await StorageRepository.create();
  });
  test(
    'Artist parsing does not turn songs, albums or user profiles into performers',
    () {
      final parsed = YouTubeMusicRepository.parseArtists({
        'contents': [
          artistRow('Justin Bieber', 'UCbieber'),
          artistRow('Justin Bieber', 'UCbieber'),
          artistRow(
            'Fan channel',
            'UCfan',
            type: 'MUSIC_PAGE_TYPE_USER_CHANNEL',
          ),
          artistRow('Album', 'MPREalbum', type: 'MUSIC_PAGE_TYPE_ALBUM'),
          {
            'musicResponsiveListItemRenderer': {
              'playlistItemData': {'videoId': 'song'},
              'flexColumns': [
                {
                  'musicResponsiveListItemFlexColumnRenderer': {
                    'text': {
                      'runs': [
                        {'text': 'Baby'},
                      ],
                    },
                  },
                },
                {
                  'musicResponsiveListItemFlexColumnRenderer': {
                    'text': {
                      'runs': [
                        {
                          'text': 'Justin Bieber',
                          'navigationEndpoint': {
                            'browseEndpoint': {'browseId': 'UCbieber'},
                          },
                        },
                      ],
                    },
                  },
                },
              ],
            },
          },
        ],
      });
      expect(parsed.map((a) => a.name), ['Justin Bieber']);
      expect(parsed.single.catalogSeed.artistBrowseId, 'UCbieber');
    },
  );
  test(
    'Suggestions use search endpoints, combine text runs and deduplicate',
    () {
      final parsed = YouTubeMusicRepository.parseSearchSuggestions({
        'contents': [
          {
            'searchSuggestionRenderer': {
              'navigationEndpoint': {
                'searchEndpoint': {'query': 'justin bieber'},
              },
            },
          },
          {
            'historySuggestionRenderer': {
              'suggestion': {
                'runs': [
                  {'text': 'justin '},
                  {'text': 'bieber'},
                ],
              },
            },
          },
          {
            'searchSuggestionRenderer': {
              'suggestion': {
                'runs': [
                  {'text': 'justin '},
                  {'text': 'timberlake'},
                ],
              },
            },
          },
        ],
      });
      expect(parsed, ['justin bieber', 'justin timberlake']);
    },
  );
  test(
    'Missing singer credits are never filled with Song or view-count labels',
    () {
      final parsed = YouTubeMusicRepository.parseTracks({
        'musicResponsiveListItemRenderer': {
          'flexColumns': [
            {
              'musicResponsiveListItemFlexColumnRenderer': {
                'text': {
                  'runs': [
                    {
                      'text': 'Baby',
                      'navigationEndpoint': {
                        'watchEndpoint': {'videoId': 'baby'},
                      },
                    },
                  ],
                },
              },
            },
            {
              'musicResponsiveListItemFlexColumnRenderer': {
                'text': {
                  'runs': [
                    {'text': 'Song'},
                    {'text': '12M views'},
                  ],
                },
              },
            },
          ],
        },
      });
      expect(parsed.single.artist, 'Unknown Artist');
      expect(parsed.single.artistBrowseId, isNull);
    },
  );
  test(
    'New query wins over slower songs, artists and suggestions from an earlier query',
    () async {
      final repo = PendingSearch();
      final notifier = SearchNotifier(repo, storage);
      addTearDown(() {
        notifier.dispose();
        repo.dispose();
      });
      final older = notifier.search('just');
      final newer = notifier.search('justin');
      repo.complete(
        'justin',
        songs: [song],
        performers: [bieber],
        hints: ['justin bieber baby'],
      );
      await newer;
      repo.complete(
        'just',
        songs: [song.copyWith(id: 'old')],
        performers: [const SearchArtist(id: 'old', name: 'Just Old')],
        hints: ['old suggestion'],
      );
      await older;
      expect(notifier.state.query, 'justin');
      expect(notifier.state.results.single.id, 'baby');
      expect(notifier.state.artists.single.id, 'UCbieber');
      expect(notifier.state.suggestions, ['justin bieber baby']);
    },
  );
  test('Clearing input invalidates every in-flight result group', () async {
    final repo = PendingSearch();
    final notifier = SearchNotifier(repo, storage);
    addTearDown(() {
      notifier.dispose();
      repo.dispose();
    });
    final pending = notifier.search('justin');
    notifier.clearSearch();
    repo.complete(
      'justin',
      songs: [song],
      performers: [bieber],
      hints: ['justin bieber'],
    );
    await pending;
    expect(notifier.state.query, isEmpty);
    expect(notifier.state.results, isEmpty);
    expect(notifier.state.artists, isEmpty);
    expect(notifier.state.suggestions, isEmpty);
  });
  test(
    'Suggestions arrive independently of songs and retain their query',
    () async {
      final repo = PendingSearch();
      final notifier = SearchNotifier(repo, storage);
      addTearDown(() {
        notifier.dispose();
        repo.dispose();
      });
      final pending = notifier.search('justin');
      repo.suggestions['justin']!.complete(['justin bieber']);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.suggestions, ['justin bieber']);
      expect(notifier.state.isLoading, isTrue);
      repo.tracks['justin']!.complete([song]);
      repo.artists['justin']!.complete([bieber]);
      await pending;
    },
  );
  test(
    'Partial artist ranking promotes credited songs without changing another singer',
    () async {
      final repo = PendingSearch();
      final notifier = SearchNotifier(repo, storage);
      addTearDown(() {
        notifier.dispose();
        repo.dispose();
      });
      final pending = notifier.search('justin');
      final other = song.copyWith(
        id: 'other',
        artist: 'Justin Timberlake',
        artistBrowseId: 'UCtimberlake',
      );
      repo.complete(
        'justin',
        songs: [other, song, song],
        performers: [
          const SearchArtist(id: 'wrong', name: 'Kristin'),
          bieber,
          timberlake,
        ],
      );
      await pending;
      expect(notifier.state.artists.map((a) => a.id), [
        'UCbieber',
        'UCtimberlake',
      ]);
      expect(notifier.state.results.map((s) => s.id), ['baby', 'other']);
      expect(notifier.state.results.last.artist, 'Justin Timberlake');
      expect(artistSearchRelevance('Justin Bieber', 'just b'), greaterThan(0));
      expect(artistSearchRelevance('Justin Bieber', 'tin'), 0);
    },
  );
  testWidgets(
    'Refining input retains matching content without keeping unrelated results',
    (tester) async {
      final repo = PendingSearch();
      final notifier = SearchNotifier(repo, storage);
      final initial = notifier.search('justin');
      repo.complete(
        'justin',
        songs: [
          song,
          song.copyWith(
            id: 'mirrors',
            title: 'Mirrors',
            artist: 'Justin Timberlake',
            artistBrowseId: 'UCtimberlake',
          ),
        ],
        performers: [bieber, timberlake],
        hints: ['justin bieber baby', 'justin timberlake mirrors'],
      );
      await tester.pump();
      await initial;
      notifier.updateQuery('justin b');
      expect(notifier.state.results.map((s) => s.id), ['baby']);
      expect(notifier.state.artists.map((a) => a.id), ['UCbieber']);
      expect(notifier.state.suggestions, ['justin bieber baby']);
      expect(notifier.state.isLoading, isTrue);
      notifier.updateQuery('adele');
      expect(notifier.state.results, isEmpty);
      expect(notifier.state.artists, isEmpty);
      expect(notifier.state.suggestions, isEmpty);
      notifier.dispose();
      repo.dispose();
    },
  );
  testWidgets(
    'Typing invalidates the old response before debounce and clear cancels the pending query',
    (tester) async {
      final repo = PendingSearch();
      final notifier = SearchNotifier(repo, storage);
      final pending = notifier.search('just');
      notifier.updateQuery('justin');
      repo.complete('just', songs: [song], performers: [bieber]);
      await tester.pump();
      expect(notifier.state.query, 'justin');
      expect(notifier.state.results, isEmpty);
      notifier.clearSearch();
      await tester.pump(const Duration(milliseconds: 400));
      expect(repo.tracks.containsKey('justin'), isFalse);
      await pending;
      notifier.dispose();
      repo.dispose();
    },
  );
  testWidgets(
    'Suggestions are above artists without progress lines; arrow fills input and clear cancels debounce',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = ImmediateSearch();
      final audioRepo = YoutubeAudioRepository();
      final player = fixture.TestPlayer(audioRepo);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageRepoProvider.overrideWithValue(storage),
            youtubeMusicRepoProvider.overrideWithValue(repo),
            audioPlayerProvider.overrideWith((ref) => player),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const SearchScreen(),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('search-field')),
        'justin',
      );
      await tester.pump(const Duration(milliseconds: 349));
      expect(repo.requests, isEmpty);
      await tester.pumpAndSettle();
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('artist-result-UCbieber')))
            .dy,
        greaterThan(tester.getTopLeft(find.text('Saran pencarian')).dy),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('fill-suggestion-Justin Bieber')),
      );
      await tester.tap(
        find.byKey(const ValueKey('fill-suggestion-Justin Bieber')),
      );
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Justin Bieber',
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(storage.getSearchHistory(), isEmpty);
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();
      expect(find.text('Jelajahi Semua'), findsOneWidget);
      expect(repo.requests, ['justin']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      repo.dispose();
      audioRepo.dispose();
    },
  );
  testWidgets('Recommended artist opens its own browse destination', (
    tester,
  ) async {
    final repo = ImmediateSearch();
    final audioRepo = YoutubeAudioRepository();
    final player = fixture.TestPlayer(audioRepo);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageRepoProvider.overrideWithValue(storage),
          youtubeMusicRepoProvider.overrideWithValue(repo),
          audioPlayerProvider.overrideWith((ref) => player),
          catalogProvider((
            song: bieber.catalogSeed,
            kind: CatalogKind.artist,
          )).overrideWith(
            (ref) async =>
                const CatalogResult('Justin Bieber', [], browseId: 'UCbieber'),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SearchScreen(),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'justin');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('artist-result-UCbieber')));
    await tester.pumpAndSettle();
    expect(find.byType(CatalogScreen), findsOneWidget);
    expect(
      tester
          .widget<CatalogScreen>(find.byType(CatalogScreen))
          .song
          .artistBrowseId,
      'UCbieber',
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    repo.dispose();
    audioRepo.dispose();
  });
}
