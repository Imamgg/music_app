import 'dart:io';
import 'package:auno/core/theme/app_theme.dart';
import 'package:auno/data/models/song_model.dart';
import 'package:auno/data/repositories/offline_repository.dart';
import 'package:auno/presentation/providers/offline_provider.dart';
import 'package:auno/presentation/screens/downloads/downloads_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryDownloads extends OfflineRepository {
  @override
  Future<Directory> initialize() async => Directory('unused');
  @override
  Future<void> remove(String id) async {
    tracks.remove(id);
    notifyListeners();
  }
}

void main() {
  testWidgets('Offline library fits narrow screens and confirms removal', (
    tester,
  ) async {
    final repo = MemoryDownloads();
    const song = SongModel(
      id: '1',
      title: 'A long downloaded song title',
      artist: 'The artist',
      album: '',
      coverUrl: '',
      highResCoverUrl: '',
      durationSeconds: 100,
    );
    repo.tracks[song.id] = const OfflineTrack(song, 'unused', 1024);
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [offlineProvider.overrideWith((_) => repo)],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: const DownloadsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(song.title), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Hapus unduhan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(repo.tracks, hasLength(1));
    await tester.tap(find.byTooltip('Hapus unduhan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    expect(repo.tracks, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
