import 'package:auno/core/localization/app_strings.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/settings_card_widget.dart';
import '../../widgets/glass_surface.dart';

class AboutSettingsScreen extends StatelessWidget {
  const AboutSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const AppText('Tentang AUNO')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: GlassSurface(
            padding: EdgeInsets.all(28),
            child: Column(
              children: [
                SettingsIconBadge(icon: Icons.graphic_eq),
                SizedBox(height: 16),
                AppText(
                  'AUNO',
                  style: TextStyle(
                    fontSize: 32,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                AppText(
                  'Ruang untuk musik favorit Anda',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                ),
                SizedBox(height: 16),
                AppText(
                  'Versi 1.0.0 • Build 1',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SettingsCardGroup(
          title: 'Pengalaman mendengarkan',
          children: [
            SettingsInfoTile(
              icon: Icons.auto_awesome_outlined,
              title: 'Liquid Aurora',
              description:
                  'Cahaya dan warna mengikuti musik, dipadukan dengan permukaan kaca yang lembut.',
            ),
            SettingsCardDivider(),
            SettingsInfoTile(
              icon: Icons.headphones_outlined,
              title: 'Musik menemani aktivitas Anda',
              description:
                  'Kontrol pemutaran melalui notifikasi dan layar kunci yang didukung perangkat.',
            ),
          ],
        ),
        SettingsCardGroup(
          title: 'Lisensi',
          children: [
            SettingsCardTile(
              icon: Icons.description_outlined,
              title: 'Lisensi sumber terbuka',
              subtitle: 'Lihat lisensi pustaka yang digunakan AUNO.',
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'AUNO',
                applicationVersion: '1.0.0',
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
