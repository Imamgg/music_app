import 'equalizer_settings_screen.dart';
import 'package:auno/core/localization/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../providers/sleep_timer_provider.dart';
import '../../widgets/settings_card_widget.dart';
import '../../widgets/sleep_timer_bottom_sheet.dart';
import '../../widgets/glass_dialog.dart';

class PlayerAudioSettingsScreen extends ConsumerWidget {
  const PlayerAudioSettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final timer = ref.watch(sleepTimerProvider);
    return Scaffold(
      appBar: AppBar(title: const AppText('Pemutar & audio')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
        children: [
          SettingsCardGroup(
            title: 'Kualitas audio',
            children: [
              SettingsCardTile(
                icon: Icons.graphic_eq,
                title: 'Kualitas audio streaming',
                subtitle: settings.audioQuality.label,
                onTap: () async {
                  final quality = await showSettingsChoice(
                    context,
                    title: 'Kualitas audio',
                    values: AudioQuality.values,
                    selected: settings.audioQuality,
                    label: (q) => q.label,
                    description: (q) => q.description,
                  );
                  if (context.mounted && quality != null) {
                    ref
                        .read(settingsProvider.notifier)
                        .setAudioQuality(quality);
                  }
                },
              ),
            ],
          ),
          SettingsCardGroup(
            title: 'Equalizer',
            children: [
              SettingsCardTile(
                icon: Icons.tune,
                title: 'Equalizer',
                subtitle: 'Sesuaikan karakter suara dan bass.',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EqualizerSettingsScreen(),
                  ),
                ),
              ),
            ],
          ),
          SettingsCardGroup(
            title: 'Waktu & istirahat',
            children: [
              SettingsCardTile(
                icon: Icons.bedtime_outlined,
                title: 'Pengatur waktu tidur',
                subtitle: timer.isActive
                    ? 'Timer aktif: ${timer.formattedRemaining}'
                    : 'Hentikan musik secara otomatis saat Anda tertidur.',
                trailing: timer.isActive
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: .25),
                          ),
                        ),
                        child: AppText(
                          timer.formattedRemaining,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : null,
                onTap: () => SleepTimerBottomSheet.show(context),
              ),
            ],
          ),
          const SettingsCardGroup(
            title: 'Tentang pemutaran',
            children: [
              SettingsInfoTile(
                icon: Icons.headphones_outlined,
                title: 'Dengarkan dengan nyaman',
                description:
                    'Perubahan kualitas berlaku mulai lagu berikutnya. Bitrate menyesuaikan stream yang tersedia dari sumber lagu.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
