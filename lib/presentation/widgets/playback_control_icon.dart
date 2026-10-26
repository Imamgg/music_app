import 'package:flutter/material.dart';

/// Keep the action visible and tappable even while a stream is preparing.
class PlaybackControlIcon extends StatelessWidget {
  const PlaybackControlIcon({
    super.key,
    required this.isPlaying,
    this.size = 28,
    this.color = Colors.white,
  });
  final bool isPlaying;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size + 8,
    height: size + 8,
    child: Icon(
      isPlaying ? Icons.pause : Icons.play_arrow,
      color: color,
      size: size,
    ),
  );
}
