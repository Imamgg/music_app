import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/storage_repository.dart';
import 'presentation/providers/library_provider.dart';
import 'presentation/screens/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Inisialisasi background audio service
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.auno.app.channel.audio',
      androidNotificationChannelName: 'AUNO Music Playback',
      androidNotificationOngoing: true,
    );
  } catch (e) {
    debugPrint('JustAudioBackground init warning: $e');
  }

  // Inisialisasi penyimpanan lokal untuk lagu favorit & playlist
  final storageRepo = await StorageRepository.create();

  runApp(
    ProviderScope(
      overrides: [
        storageRepoProvider.overrideWithValue(storageRepo),
      ],
      child: const AunoApp(),
    ),
  );
}

class AunoApp extends StatelessWidget {
  const AunoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AUNO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainShell(),
    );
  }
}
