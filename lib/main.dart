import 'presentation/providers/media_notification_handler.dart';
import 'presentation/widgets/liquid_aurora.dart';
import 'presentation/providers/settings_provider.dart';
import 'core/localization/app_strings.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';

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
    mediaNotificationHandler = await AudioService.init<AunoMediaHandler>(
      builder: AunoMediaHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.auno.app.channel.audio',
        androidNotificationChannelName: 'AUNO Music Playback',
        androidNotificationOngoing: true,
        androidNotificationIcon: 'drawable/auno_notification',
        notificationColor: Color(0xFF52BBA9),
        artDownscaleWidth: 512,
        artDownscaleHeight: 512,
      ),
    );
  } catch (e) {
    debugPrint('AudioService init warning: $e');
  }

  // Inisialisasi penyimpanan lokal untuk lagu favorit & playlist
  final storageRepo = await StorageRepository.create();

  runApp(
    ProviderScope(
      overrides: [storageRepoProvider.overrideWithValue(storageRepo)],
      child: const AunoApp(),
    ),
  );
}

class AunoApp extends ConsumerWidget {
  const AunoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(
      settingsProvider.select((s) => s.contentLanguage),
    );
    return MaterialApp(
      title: 'AUNO',
      locale: language == ContentLanguage.system ? null : Locale(language.code),
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      builder: (context, child) =>
          Stack(fit: StackFit.expand, children: [const LiquidAurora(), child!]),
      home: const MainShell(),
    );
  }
}
