import 'package:auno/core/theme/app_theme.dart';
import 'package:auno/data/models/lyric_line.dart';
import 'package:auno/data/repositories/lyrics_repository.dart';
import 'package:auno/data/repositories/storage_repository.dart';
import 'package:auno/presentation/providers/lyrics_provider.dart';
import 'package:auno/presentation/providers/library_provider.dart';
import 'package:auno/presentation/widgets/synced_lyrics_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ControlledLyrics extends LyricsNotifier {
  ControlledLyrics(super.repo) {
    state = LyricsState(
      hasSyncedLyrics: true,
      activeIndex: 0,
      lines: List.generate(
        24,
        (i) => LyricLine(
          timestamp: Duration(seconds: i * 5),
          text: 'Baris lirik nomor $i',
        ),
      ),
    );
  }
  void active(int index) {
    state = state.copyWith(activeIndex: index);
  }

  void plain() {
    state = const LyricsState(
      plainLyrics: 'Lirik tanpa waktu\nTetap mudah dibaca',
    );
  }
}

void main() {
  late LyricsRepository repo;
  late ControlledLyrics lyrics;
  late StorageRepository storage;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await StorageRepository.create();
    repo = LyricsRepository();
    lyrics = ControlledLyrics(repo);
  });
  tearDown(() {
    repo.dispose();
  });
  Future<void> mount(WidgetTester tester, {double height = 420}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageRepoProvider.overrideWithValue(storage),
          lyricsProvider.overrideWith((_) => lyrics),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: height,
                child: SyncedLyricsWidget(onExpand: () {}),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Manual reading pauses auto-follow until the resume button is tapped',
    (tester) async {
      await mount(tester);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -220),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kembali ke lirik aktif'), findsOneWidget);
      final controller = tester
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .controller!;
      final offset = controller.offset;
      lyrics.active(15);
      await tester.pumpAndSettle();
      expect(controller.offset, closeTo(offset, .1));
      await tester.tap(find.text('Kembali ke lirik aktif'));
      await tester.pumpAndSettle();
      expect(controller.offset, greaterThan(offset));
      expect(find.text('Kembali ke lirik aktif'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Highlight changes keep line geometry stable and compact mode can expand',
    (tester) async {
      await mount(tester, height: 140);
      final before = tester.getSize(find.text('Baris lirik nomor 0'));
      lyrics.active(1);
      await tester.pumpAndSettle();
      expect(tester.getSize(find.text('Baris lirik nomor 0')), before);
      expect(find.byTooltip('Lirik layar penuh'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Plain lyrics are identified and have no seek targets', (
    tester,
  ) async {
    lyrics.plain();
    await mount(tester);
    expect(find.text('Lirik tanpa sinkronisasi waktu'), findsOneWidget);
    expect(find.byType(InkWell), findsOneWidget); // Expand button only.
    expect(find.text('Kembali ke lirik aktif'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
