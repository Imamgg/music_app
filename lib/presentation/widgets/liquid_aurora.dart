import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_player_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_palette_provider.dart';

class LiquidAurora extends ConsumerStatefulWidget {
  const LiquidAurora({super.key});
  @override
  ConsumerState<LiquidAurora> createState() => _LiquidAuroraState();
}

class _LiquidAuroraState extends ConsumerState<LiquidAurora>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );
  Duration? _period;
  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playing = ref.watch(audioPlayerProvider.select((s) => s.isPlaying));
    final hasSong = ref.watch(
      audioPlayerProvider.select((s) => s.hasCurrentSong),
    );
    final enabled = ref.watch(
      settingsProvider.select((s) => s.dynamicThemeEnabled),
    );
    final reduced = MediaQuery.disableAnimationsOf(context);
    final colors =
        ref.watch(auroraPaletteProvider).valueOrNull ?? fallbackAuroraColors;
    final period = playing
        ? const Duration(seconds: 12)
        : const Duration(seconds: 240);
    if (reduced || !enabled || !hasSong) {
      _motion.stop();
      _period = null;
    } else if (_period != period) {
      _period = period;
      _motion.repeat(period: period);
    }
    return IgnorePointer(
      child: RepaintBoundary(
        child: TweenAnimationBuilder<List<Color>>(
          tween: _PaletteTween(end: colors),
          duration: reduced ? Duration.zero : const Duration(milliseconds: 900),
          builder: (context, palette, _) => CustomPaint(
            painter: AuroraPainter(_motion, palette),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _PaletteTween extends Tween<List<Color>> {
  _PaletteTween({required List<Color> end}) : super(begin: end, end: end);
  @override
  List<Color> lerp(double t) =>
      List.generate(4, (i) => Color.lerp(begin![i], end![i], t)!);
}

/// Four overlapping radial fields form a soft moving color mesh.
class AuroraPainter extends CustomPainter {
  AuroraPainter(this.motion, this.colors) : super(repaint: motion);
  final Animation<double> motion;
  final List<Color> colors;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = const Color(0xFF080C1C));
    final phase = motion.value * math.pi * 2;
    for (var i = 0; i < 4; i++) {
      final angle = phase + i * math.pi / 2;
      final center = Offset(
        size.width * (.5 + .38 * math.sin(angle)),
        size.height * (.5 + .38 * math.cos(angle + math.sin(phase) * .3)),
      );
      canvas.drawRect(
        rect,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  colors[i].withValues(alpha: .8),
                  colors[i].withValues(alpha: 0),
                ],
              ).createShader(
                Rect.fromCircle(center: center, radius: size.longestSide * .85),
              ),
      );
    }
    canvas.drawRect(rect, Paint()..color = Colors.black.withValues(alpha: .35));
  }

  @override
  bool shouldRepaint(AuroraPainter oldDelegate) => oldDelegate.colors != colors;
}
