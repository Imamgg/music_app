import 'dart:async';
import 'package:auno/data/models/song_model.dart';
import 'package:auno/data/models/playlist_model.dart';
import 'package:auno/data/repositories/youtube_music_repository.dart';
import 'package:auno/data/repositories/storage_repository.dart';
import 'package:auno/presentation/providers/home_discovery_provider.dart';
import 'package:auno/presentation/providers/youtube_music_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const track = SongModel(
  id: 'a',
  title: 'A',
  artist: 'Artist',
  album: '',
  coverUrl: '',
  highResCoverUrl: '',
  durationSeconds: 120,
  youtubeVideoId: 'video-a',
);

class DeferredHomeRepository extends YouTubeMusicRepository {
  final charts = Completer<List<SongModel>>();
  final playlists = Completer<List<PlaylistModel>>();
  @override
  Future<List<SongModel>> getTopCharts() => charts.future;
  @override
  Future<List<PlaylistModel>> getCuratedPlaylists() => playlists.future;
}

void main() {
  late StorageRepository storage;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await StorageRepository.create();
  });
  test('Charts are visible before slower playlists finish', () async {
    final repo = DeferredHomeRepository();
    final notifier = HomeMusicNotifier(repo, storage);
    repo.charts.complete([track]);
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.charts.single.id, 'a');
    expect(notifier.state.playlists, isEmpty);
    repo.playlists.complete([]);
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.isLoading, false);
    notifier.dispose();
    repo.dispose();
  });
  test('Recent listening deduplicates and survives restart', () async {
    final notifier = RecentListeningNotifier(storage);
    notifier.record(track);
    notifier.record(track.copyWith(id: 'b'));
    notifier.record(track);
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.map((s) => s.id), ['a', 'b']);
    final restored = RecentListeningNotifier(storage);
    expect(restored.state.map((s) => s.id), ['a', 'b']);
    notifier.dispose();
    restored.dispose();
  });
  test('Home deduplicates recordings across sources and exclusions', () {
    expect(
      uniqueHomeSongs([track, track.copyWith(id: 'another')]),
      hasLength(1),
    );
    expect(uniqueHomeSongs([track], exclude: {homeSongKey(track)}), isEmpty);
  });
}
