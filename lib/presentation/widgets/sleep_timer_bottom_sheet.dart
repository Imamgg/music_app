import 'package:auno/core/localization/app_strings.dart';
import 'glass_surface.dart';
import 'settings_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../providers/sleep_timer_provider.dart';

class SleepTimerBottomSheet extends ConsumerWidget {
  const SleepTimerBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .85,
        ),
        child: const GlassSurface(
          radius: 28,
          child: SingleChildScrollView(child: SleepTimerBottomSheet()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(sleepTimerProvider);
    final timerNotifier = ref.read(sleepTimerProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: AppText(
                    'Pengatur Waktu Tidur',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (timerState.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer,
                          color: AppColors.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        AppText(
                          timerState.formattedRemaining,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            AppText(
              'Musik akan berhenti otomatis saat timer habis.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),

            // Active Timer Info & Cancel Option
            if (timerState.isActive) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_top, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppText(
                            'Timer Sedang Aktif',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          AppText(
                            'Sisa waktu: ${timerState.formattedRemaining}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        timerNotifier.cancelTimer();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: AppText('Waktu tidur dibatalkan'),
                          ),
                        );
                      },
                      child: const AppText(
                        'Batalkan',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Options List
            _buildOption(
              context,
              label: context.tr('15 Menit'),
              isSelected: timerState.totalSeconds == 15 * 60,
              onTap: () {
                timerNotifier.setTimer(const Duration(minutes: 15));
                Navigator.pop(context);
                _showToast(context, 'Timer diatur: 15 menit');
              },
            ),
            _buildOption(
              context,
              label: context.tr('30 Menit'),
              isSelected: timerState.totalSeconds == 30 * 60,
              onTap: () {
                timerNotifier.setTimer(const Duration(minutes: 30));
                Navigator.pop(context);
                _showToast(context, 'Timer diatur: 30 menit');
              },
            ),
            _buildOption(
              context,
              label: context.tr('45 Menit'),
              isSelected: timerState.totalSeconds == 45 * 60,
              onTap: () {
                timerNotifier.setTimer(const Duration(minutes: 45));
                Navigator.pop(context);
                _showToast(context, 'Timer diatur: 45 menit');
              },
            ),
            _buildOption(
              context,
              label: context.tr('1 Jam (60 Menit)'),
              isSelected: timerState.totalSeconds == 60 * 60,
              onTap: () {
                timerNotifier.setTimer(const Duration(hours: 1));
                Navigator.pop(context);
                _showToast(context, 'Timer diatur: 60 menit');
              },
            ),
            _buildOption(
              context,
              label: context.tr('Di akhir lagu saat ini'),
              isSelected: timerState.mode == SleepTimerMode.endOfTrack,
              onTap: () {
                timerNotifier.setEndOfTrack();
                Navigator.pop(context);
                _showToast(context, 'Musik akan berhenti di akhir lagu ini');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: AppText(message), duration: const Duration(seconds: 2)),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return SettingsChoiceTile(title: label, selected: isSelected, onTap: onTap);
  }
}
