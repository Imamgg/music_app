import 'package:flutter/material.dart';

/// Keep the action visible and tappable even while a stream is preparing.
class PlaybackControlIcon extends StatelessWidget {
  const PlaybackControlIcon({
    super.key,
    required this.isPlaying,
    required this.isBusy,
    this.size = 28,
    this.color = Colors.white,
  });
  final bool isPlaying;
  final bool isBusy;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size + 8,
    height: size + 8,
    child: Stack(
      alignment: Alignment.center,
      children: [
        if (isBusy && isPlaying)
          Positioned.fill(
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: color.withValues(alpha: .55),
            ),
          ),
        Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: color,
          size: size,
        ),
      ],
    ),
  );
}
