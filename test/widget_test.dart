import 'package:auno/data/models/song_model.dart';
import 'package:auno/data/repositories/storage_repository.dart';
import 'package:auno/main.dart';
import 'package:auno/presentation/providers/library_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('AunoApp smoke test - mounts successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageRepo = await StorageRepository.create();
    await storageRepo.cacheCharts([
      const SongModel(
        id: '1',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        coverUrl: '',
        highResCoverUrl: '',
        durationSeconds: 200,
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageRepoProvider.overrideWithValue(storageRepo),
        ],
        child: const AunoApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verifikasi navigasi bawah dan lagu muncul
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Cari'), findsOneWidget);
    expect(find.text('Koleksi Kamu'), findsOneWidget);
    expect(find.text('Test Song'), findsWidgets);
  });
}
