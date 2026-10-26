import 'package:flutter/material.dart';

/// Original artwork supplied for AUNO, shared by startup and About.
class AunoLogo extends StatelessWidget {
  const AunoLogo({super.key, this.size = 240});

  final double size;
  static const asset = 'assets/branding/auno_logo.png';

  @override
  Widget build(BuildContext context) => Image.asset(
    asset,
    width: size,
    height: size,
    fit: BoxFit.contain,
    semanticLabel: 'AUNO',
    filterQuality: FilterQuality.medium,
  );
}
