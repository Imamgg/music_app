import 'package:auno/core/localization/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/settings_card_widget.dart';
import '../../widgets/glass_dialog.dart';

class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const AppText('Tampilan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
        children: [
          SettingsCardGroup(
            title: 'Tema & warna',
            children: [
              SettingsSwitchTile(
                icon: Icons.palette_outlined,
                title: 'Warna latar dinamis',
                subtitle: 'Aurora mengikuti warna sampul album yang diputar.',
                value: settings.dynamicThemeEnabled,
                onChanged: notifier.setDynamicThemeEnabled,
              ),
            ],
          ),
          SettingsCardGroup(
            title: 'Lirik lagu',
            children: [
              SettingsCardTile(
                icon: Icons.format_size,
                title: 'Ukuran teks lirik',
                subtitle: settings.lyricsFontSize.label,
                onTap: () async {
                  final size = await showSettingsChoice(
                    context,
                    title: 'Ukuran teks lirik',
                    values: LyricsFontSize.values,
                    selected: settings.lyricsFontSize,
                    label: (s) => s.label,
                  );
                  if (context.mounted && size != null) {
                    notifier.setLyricsFontSize(size);
                  }
                },
              ),
              const SettingsCardDivider(),
              SettingsSwitchTile(
                icon: Icons.subtitles_outlined,
                title: 'Gulir otomatis lirik',
                subtitle: 'Ikuti baris lirik yang sedang dinyanyikan.',
                value: settings.autoScrollLyrics,
                onChanged: notifier.setAutoScrollLyrics,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
