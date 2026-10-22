import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../core/constants/app_colors.dart';
import 'audio_player_provider.dart';

final dominantColorProvider = FutureProvider<Color>((ref) async {
  final currentSong = ref.watch(audioPlayerProvider.select((s) => s.currentSong));
  if (currentSong == null) return AppColors.surface;

  final imageUrl = currentSong.highResCoverUrl.isNotEmpty
      ? currentSong.highResCoverUrl
      : currentSong.coverUrl;

  if (imageUrl.isEmpty) return AppColors.surface;

  try {
    final imageProvider = NetworkImage(imageUrl);
    final palette = await PaletteGenerator.fromImageProvider(
      imageProvider,
      maximumColorCount: 16,
      timeout: const Duration(seconds: 4),
    );

    return palette.darkMutedColor?.color ??
        palette.darkVibrantColor?.color ??
        palette.dominantColor?.color ??
        AppColors.surface;
  } catch (_) {
    return AppColors.surface;
  }
});
