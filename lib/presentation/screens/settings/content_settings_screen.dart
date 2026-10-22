import 'package:auno/core/localization/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/settings_card_widget.dart';

class ContentSettingsScreen extends ConsumerWidget {
  const ContentSettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(title: const AppText('Bahasa aplikasi')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
        children: [
          SettingsCardGroup(
            title: 'Bahasa aplikasi',
            children: [
              for (final language in ContentLanguage.values) ...[
                SettingsChoiceTile(
                  title: language.label,
                  subtitle: language.description,
                  selected: language == settings.contentLanguage,
                  onTap: () => ref
                      .read(settingsProvider.notifier)
                      .setContentLanguage(language),
                ),
                if (language != ContentLanguage.values.last)
                  const SettingsCardDivider(),
              ],
            ],
          ),
          const SettingsCardGroup(
            title: 'Personalisasi',
            children: [
              SettingsInfoTile(
                icon: Icons.translate,
                title: 'Preferensi bahasa',
                description:
                    'Mengubah bahasa menu dan tombol aplikasi. Musik, rekomendasi, serta lirik asli tetap sama.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
