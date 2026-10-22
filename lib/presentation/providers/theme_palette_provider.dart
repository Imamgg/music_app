import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';
import 'audio_player_provider.dart';
import 'settings_provider.dart';

const fallbackAuroraColors = [
  Color(0xFF57429D),
  Color(0xFF147D88),
  Color(0xFF844570),
  Color(0xFF273E82),
];
final auroraPaletteProvider = FutureProvider<List<Color>>((ref) async {
  final enabled = ref.watch(
    settingsProvider.select((s) => s.dynamicThemeEnabled),
  );
  final song = ref.watch(audioPlayerProvider.select((s) => s.currentSong));
  if (!enabled || song == null) return fallbackAuroraColors;
  final url = song.highResCoverUrl.isNotEmpty
      ? song.highResCoverUrl
      : song.coverUrl;
  if (url.isEmpty) return fallbackAuroraColors;
  try {
    final palette = await PaletteGenerator.fromImageProvider(
      ResizeImage(CachedNetworkImageProvider(url), width: 96, height: 96),
      maximumColorCount: 4,
      timeout: const Duration(seconds: 4),
    );
    final colors = palette.colors.take(4).toList();
    if (colors.isEmpty) return fallbackAuroraColors;
    return List.generate(4, (i) => colors[i % colors.length]);
  } catch (_) {
    return fallbackAuroraColors;
  }
});
final dominantColorProvider = Provider<AsyncValue<Color>>(
  (ref) => ref.watch(auroraPaletteProvider).whenData((colors) => colors.first),
);
