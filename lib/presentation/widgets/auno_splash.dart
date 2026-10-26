import 'package:flutter/material.dart';
import 'auno_logo.dart';

/// Mount the application immediately so its data loads during the reveal.
/// This overlay runs once per app session, never on route or locale changes.
class AunoSplash extends StatefulWidget {
  const AunoSplash({super.key, required this.child});
  final Widget child;

  @override
  State<AunoSplash> createState() => _AunoSplashState();
}

class _AunoSplashState extends State<AunoSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 850),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _finished = true);
        }
      });
  bool _started = false;
  bool _finished = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _finished = true;
      _controller.stop();
      return;
    }
    if (_started || _finished) return;
    _started = true;
    // Decode the local artwork before beginning the brief reveal.
    precacheImage(const AssetImage(AunoLogo.asset), context).then((_) {
      if (!mounted || _finished) return;
      // Finish the first layout/raster submission before ticking the reveal.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_finished) _controller.forward();
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).shortestSide.clamp(0.0, 300.0) * .8;
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          excluding: !_finished,
          child: ExcludeFocus(
            excluding: !_finished,
            child: IgnorePointer(
              ignoring: !_finished,
              child: RepaintBoundary(child: widget.child),
            ),
          ),
        ),
        if (!_finished)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              // Rasterize the artwork/mask as one stable layer; only its
              // transform and opacity change during the animation.
              child: RepaintBoundary(
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) => const RadialGradient(
                    colors: [Colors.white, Colors.white, Colors.transparent],
                    stops: [0, .72, 1],
                  ).createShader(bounds),
                  child: AunoLogo(size: size),
                ),
              ),
              builder: (context, logo) {
                final progress = _controller.value;
                final enter = const Interval(
                  0,
                  .35,
                  curve: Curves.easeOutCubic,
                ).transform(progress);
                final exit = const Interval(
                  .45,
                  1,
                  curve: Curves.easeInOutCubic,
                ).transform(progress);
                return Opacity(
                  opacity: 1 - exit,
                  child: ColoredBox(
                    key: const ValueKey('auno-splash'),
                    color: const Color(0xFF020410),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ExcludeSemantics(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: _SplashGlow(progress: enter),
                            ),
                          ),
                        ),
                        Center(
                          child: Transform.translate(
                            offset: Offset(0, -6 * exit),
                            child: Transform.scale(
                              scale: .98 + .02 * enter + .01 * exit,
                              child: Opacity(opacity: enter, child: logo),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Soft ambient light without a blur filter or a continuously running ticker.
class _SplashGlow extends CustomPainter {
  const _SplashGlow({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide * .55;
    for (final (offset, color) in [
      (Offset(-45 + 25 * progress, -15), const Color(0xFF7950FF)),
      (Offset(45 - 15 * progress, 25), const Color(0xFF36E4E2)),
    ]) {
      final center = size.center(offset);
      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: .10 * progress),
            color.withValues(alpha: 0),
          ],
        ).createShader(rect);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_SplashGlow oldDelegate) =>
      progress != oldDelegate.progress;
}
