import 'package:auno/data/models/song_model.dart';
import 'package:auno/data/repositories/storage_repository.dart';
import 'package:auno/presentation/providers/followed_artists_provider.dart';
import 'package:auno/presentation/providers/library_provider.dart';
import 'package:auno/presentation/widgets/followed_artists_section.dart';
import 'package:auno/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const artist = SongModel(
  id: 'song',
  title: 'Song',
  artist: 'Last Child',
  album: '',
  coverUrl: '',
  highResCoverUrl: '',
  durationSeconds: 0,
  artistBrowseId: 'UClast',
  artists: [ArtistCredit(name: 'Last Child', browseId: 'UClast')],
);
void main() {
  late StorageRepository storage;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = StorageRepository(await SharedPreferences.getInstance());
  });
  test(
    'Subscriptions persist exact artist identity and unsubscribe survives restart',
    () async {
      final notifier = FollowedArtistsNotifier(storage);
      await notifier.setFollowed('artist:UClast', artist, true);
      final restored = FollowedArtistsNotifier(storage);
      expect(restored.state.single.artist, 'Last Child');
      expect(restored.state.single.artists.single.browseId, 'UClast');
      await restored.setFollowed('artist:UClast', artist, false);
      final reopened = FollowedArtistsNotifier(storage);
      expect(reopened.state, isEmpty);
      notifier.dispose();
      restored.dispose();
      reopened.dispose();
    },
  );
  test(
    'Existing ID-only subscriptions retrieve metadata using the exact saved ID',
    () async {
      await storage.setCatalogSaved('artist:UClast', true);
      final notifier = FollowedArtistsNotifier(storage);
      await notifier.restoreDetails((id) async {
        expect(id, 'UClast');
        return {
          'title': 'Last Child',
          'image': 'https://example.test/artist.jpg',
        };
      });
      expect(notifier.state.single.artist, 'Last Child');
      expect(
        storage.getFollowedArtists().single.coverUrl,
        'https://example.test/artist.jpg',
      );
      notifier.dispose();
    },
  );
  testWidgets(
    'Artist rows fit small screens, search and unsubscribe update instantly',
    (tester) async {
      final notifier = FollowedArtistsNotifier(storage);
      await notifier.setFollowed('artist:UClast', artist, true);
      notifier.dispose();
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [storageRepoProvider.overrideWithValue(storage)],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: const Scaffold(
              body: SingleChildScrollView(child: FollowedArtistsSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Last Child'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Cari artis'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'unrelated');
      await tester.pumpAndSettle();
      expect(find.text('Artis tidak ditemukan.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'last');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Opsi artis'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Berhenti mengikuti'));
      await tester.pumpAndSettle();
      expect(storage.getSavedCatalogs(), isEmpty);
      expect(find.text('Last Child'), findsNothing);
    },
  );
}
