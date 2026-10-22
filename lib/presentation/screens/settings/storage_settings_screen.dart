import 'package:auno/core/localization/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../providers/search_provider.dart';
import '../../widgets/settings_card_widget.dart';
import '../../widgets/glass_dialog.dart';

class StorageSettingsScreen extends ConsumerWidget {
  const StorageSettingsScreen({super.key});
  Future<void> _confirm(
    BuildContext context,
    WidgetRef ref, {
    required bool cache,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .6),
      builder: (context) => GlassDialog(
        title: AppText(
          cache ? 'Hapus cache aplikasi?' : 'Hapus riwayat pencarian?',
        ),
        content: AppText(
          cache
              ? 'File sementara dan gambar sampul yang tersimpan akan dibersihkan. Playlist dan lagu favorit tetap aman.'
              : 'Semua kata kunci pencarian yang tersimpan akan dihapus.',
          style: const TextStyle(color: AppColors.textSecondary, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const AppText('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: AppText(cache ? 'Hapus cache' : 'Hapus riwayat'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final notifier = ref.read(settingsProvider.notifier);
    try {
      if (cache) {
        await notifier.clearCache();
      } else {
        await ref.read(searchProvider.notifier).clearHistory();
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: AppText(
              'Data belum dapat dibersihkan. Silakan coba lagi.',
            ),
          ),
        );
      }
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(
            cache ? 'Cache aplikasi dibersihkan' : 'Riwayat pencarian dihapus',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(title: const AppText('Penyimpanan & data')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
        children: [
          SettingsCardGroup(
            title: 'Memori & cache',
            children: [
              SettingsCardTile(
                icon: Icons.storage_outlined,
                title: 'Cache aplikasi',
                subtitle: 'Ukuran saat ini: ${settings.cacheSize}',
                onTap: settings.isClearingCache
                    ? null
                    : () => _confirm(context, ref, cache: true),
                trailing: settings.isClearingCache
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: () => _confirm(context, ref, cache: true),
                        child: const AppText('Hapus'),
                      ),
              ),
              const SettingsCardDivider(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: AppText(
                  'Bersihkan file sementara untuk menghemat ruang. Koleksi lagu dan playlist Anda tetap tersimpan.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
          SettingsCardGroup(
            title: 'Riwayat pencarian',
            children: [
              SettingsCardTile(
                icon: Icons.history,
                title: 'Riwayat kata kunci',
                subtitle: 'Bersihkan pencarian lagu sebelumnya.',
                onTap: () => _confirm(context, ref, cache: false),
                trailing: TextButton(
                  onPressed: () => _confirm(context, ref, cache: false),
                  child: const AppText('Bersihkan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
