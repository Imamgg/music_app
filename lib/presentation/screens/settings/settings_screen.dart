import 'package:auno/core/localization/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/settings_card_widget.dart';
import 'about_settings_screen.dart';
import 'appearance_settings_screen.dart';
import 'content_settings_screen.dart';
import 'player_audio_settings_screen.dart';
import 'storage_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const AppText('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
        children: [
          // ==============================
          // 1. INTERFACE
          // ==============================
          SettingsCardGroup(
            title: 'Tampilan',
            children: [
              SettingsCardTile(
                icon: Icons.palette_outlined,
                title: 'Tampilan aplikasi',
                subtitle: 'Tema dinamis, ukuran teks & auto-scroll lirik',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AppearanceSettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          // ==============================
          // 2. PLAYER & CONTENT (Multi-Item Group)
          // ==============================
          SettingsCardGroup(
            title: 'Pemutar & konten',
            children: [
              SettingsCardTile(
                icon: Icons.play_arrow,
                title: 'Pemutar & audio',
                subtitle: 'Kualitas streaming audio & waktu tidur',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PlayerAudioSettingsScreen(),
                    ),
                  );
                },
              ),
              const SettingsCardDivider(),
              SettingsCardTile(
                icon: Icons.translate,
                title: 'Bahasa aplikasi',
                subtitle: settings.contentLanguage.label,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ContentSettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          // ==============================
          // 3. STORAGE & DATA
          // ==============================
          SettingsCardGroup(
            title: 'Penyimpanan & data',
            children: [
              SettingsCardTile(
                icon: Icons.storage_outlined,
                title: 'Penyimpanan',
                subtitle: 'Cache: ${settings.cacheSize} • Riwayat pencarian',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StorageSettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          // ==============================
          // 4. SYSTEM & ABOUT
          // ==============================
          SettingsCardGroup(
            title: 'Informasi aplikasi',
            children: [
              SettingsCardTile(
                icon: Icons.info_outline,
                title: 'Tentang AUNO',
                subtitle: 'AUNO Music Player v1.0.0 (Build 1)',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AboutSettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
