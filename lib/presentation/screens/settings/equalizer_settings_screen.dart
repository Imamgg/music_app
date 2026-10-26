import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_strings.dart';
import '../../providers/equalizer_provider.dart';
import '../../widgets/glass_surface.dart';

class EqualizerSettingsScreen extends ConsumerWidget {
  const EqualizerSettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eq = ref.watch(equalizerProvider);
    return Scaffold(
      appBar: AppBar(title: const AppText('Equalizer')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GlassSurface(
            child: SwitchListTile(
              title: const AppText('Aktifkan equalizer'),
              subtitle: const AppText(
                'Pengaturan suara berlaku untuk semua lagu.',
              ),
              value: eq.enabled,
              onChanged: eq.ready ? eq.setEnabled : null,
            ),
          ),
          const SizedBox(height: 16),
          if (!eq.ready || eq.failed)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AppText(eq.status),
            ),
          GlassSurface(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText('Karakter suara'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Normal', 'Bass Boost', 'Vokal', 'Manual']
                      .map(
                        (preset) => ChoiceChip(
                          label: AppText(preset),
                          selected: eq.preset == preset,
                          onSelected: eq.ready && eq.enabled
                              ? (_) => eq.setPreset(preset)
                              : null,
                        ),
                      )
                      .toList(),
                ),
                for (final hz in eq.frequencies) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      Text(
                        hz >= 1000
                            ? '${(hz / 1000).toStringAsFixed(1)} kHz'
                            : '${hz.round()} Hz',
                      ),
                      Text(
                        '${eq.gain(hz) > 0 ? '+' : ''}${eq.gain(hz).toStringAsFixed(1)} dB',
                      ),
                    ],
                  ),
                  Slider(
                    value: eq.gain(hz),
                    min: eq.min,
                    max: eq.max,
                    onChanged: eq.enabled && eq.max > eq.min
                        ? (value) => eq.setGain(hz, value)
                        : null,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassSurface(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText('Bass booster'),
                if (eq.bassSupported) ...[
                  Text('${(eq.bass / 10).round()}%'),
                  Slider(
                    value: eq.bass,
                    min: 0,
                    max: 1000,
                    onChanged: eq.enabled ? eq.setBass : null,
                  ),
                ] else
                  const AppText(
                    'Bass booster tidak tersedia pada sesi audio ini.',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: eq.reset,
            icon: const Icon(Icons.restart_alt),
            label: const AppText('Reset suara'),
          ),
        ],
      ),
    );
  }
}
