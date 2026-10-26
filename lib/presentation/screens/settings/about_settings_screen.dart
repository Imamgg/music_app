import 'dart:math' as math;
import 'package:auno/core/localization/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/settings_card_widget.dart';

class AboutSettingsScreen extends StatelessWidget {
  const AboutSettingsScreen({super.key});

  static final _instagram = Uri.https('www.instagram.com', '/0ximam/');
  static final _github = Uri.https('github.com', '/Imamgg');

  Future<void> _openProfile(BuildContext context, Uri uri) async {
    // Let the installed social app handle HTTPS links, with browser fallback.
    for (final mode in [
      LaunchMode.externalApplication,
      LaunchMode.platformDefault,
    ]) {
      try {
        if (await launchUrl(uri, mode: mode)) return;
      } catch (_) {
        // Try the platform's default handler if the external handler fails.
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText('Profil belum dapat dibuka. Silakan coba lagi.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    appBar: AppBar(title: const AppText('Tentang AUNO')),
    body: ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 36),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GlassSurface(
            radius: 28,
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryLight, AppColors.primaryDark],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: .16),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.graphic_eq_rounded,
                    size: 34,
                    color: AppColors.background,
                  ),
                ),
                const SizedBox(width: 18),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AUNO',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Badge('v1.0.0', accent: true),
                          _Badge('MUSIC PLAYER'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GlassSurface(
            radius: 28,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF75DDCE).withValues(alpha: .14),
                    const Color(0xFF9E8FEC).withValues(alpha: .12),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(
                    height: 148,
                    child: ExcludeSemantics(
                      child: CustomPaint(painter: _AuroraRecordPainter()),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Badge('Dibuat oleh', accent: true),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Imamgg',
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -.9,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  AppText(
                                    'Pengembang AUNO',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: .7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 64,
                              height: 64,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: .08),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .25),
                                ),
                              ),
                              child: ClipOval(
                                child: Image.network(
                                  'https://github.com/Imamgg.png?size=160',
                                  cacheWidth: 160,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (_, child, progress) =>
                                      progress == null
                                      ? child
                                      : const _AvatarFallback(),
                                  errorBuilder: (_, _, _) =>
                                      const _AvatarFallback(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const AppText(
                          'Dibangun dengan perhatian pada setiap pengalaman mendengarkan.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 12),
          child: AppText(
            'Terhubung dengan pengembang',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: .5,
              color: Colors.white.withValues(alpha: .65),
            ),
          ),
        ),
        _ProfileLink(
          platform: 'Instagram',
          handle: '@0ximam',
          icon: Icons.camera_alt_outlined,
          onTap: () => _openProfile(context, _instagram),
        ),
        const SizedBox(height: 10),
        _ProfileLink(
          platform: 'GitHub',
          handle: 'Imamgg',
          icon: Icons.code_rounded,
          onTap: () => _openProfile(context, _github),
        ),
        const SizedBox(height: 24),
        const SettingsCardGroup(
          title: 'Pengalaman mendengarkan',
          children: [
            SettingsInfoTile(
              icon: Icons.auto_awesome_outlined,
              title: 'Liquid Aurora',
              description:
                  'Cahaya dan warna mengikuti musik, dipadukan dengan permukaan kaca yang lembut.',
            ),
            SettingsCardDivider(),
            SettingsInfoTile(
              icon: Icons.headphones_outlined,
              title: 'Musik menemani aktivitas Anda',
              description:
                  'Kontrol pemutaran melalui notifikasi dan layar kunci yang didukung perangkat.',
            ),
          ],
        ),
        SettingsCardGroup(
          title: 'Lisensi',
          children: [
            SettingsCardTile(
              icon: Icons.description_outlined,
              title: 'Lisensi sumber terbuka',
              subtitle: 'Lihat lisensi pustaka yang digunakan AUNO.',
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'AUNO',
                applicationVersion: '1.0.0',
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, {this.accent = false});
  final String label;
  final bool accent;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: (accent ? AppColors.primary : Colors.white).withValues(alpha: .09),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(
        color: (accent ? AppColors.primary : Colors.white).withValues(
          alpha: .18,
        ),
      ),
    ),
    child: AppText(
      label,
      style: TextStyle(
        color: accent ? AppColors.primaryLight : Colors.white70,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: .7,
      ),
    ),
  );
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: AppColors.surfaceLight,
    child: Center(
      child: Text(
        'I',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryLight,
        ),
      ),
    ),
  );
}

class _ProfileLink extends StatelessWidget {
  const _ProfileLink({
    required this.platform,
    required this.handle,
    required this.icon,
    required this.onTap,
  });
  final String platform, handle;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: GlassSurface(
      radius: 24,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primaryLight, size: 25),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        platform,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        handle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.arrow_outward_rounded,
                  size: 19,
                  color: Colors.white60,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// A lightweight, offline illustration echoing the app's aurora and music.
class _AuroraRecordPainter extends CustomPainter {
  const _AuroraRecordPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .63, size.height * .5);
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [AppColors.primary.withValues(alpha: .18), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: 115));
    canvas.drawCircle(center, 115, glow);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-.28);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 216, height: 80),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.primary.withValues(alpha: .28),
    );
    canvas.restore();
    canvas.drawCircle(
      center,
      48,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF36585F), Color(0xFF131B30)],
        ).createShader(Rect.fromCircle(center: center, radius: 48)),
    );
    for (var radius = 21.0; radius <= 44; radius += 6) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7
          ..color = Colors.white.withValues(alpha: .12),
      );
    }
    canvas.drawCircle(center, 15, Paint()..color = AppColors.primary);
    canvas.drawCircle(center, 3, Paint()..color = AppColors.background);
    final spark = Paint()
      ..color = Colors.white.withValues(alpha: .65)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (final point in [
      Offset(size.width * .19, 47),
      Offset(size.width * .85, 29),
      Offset(size.width * .3, 110),
    ]) {
      canvas.drawLine(
        point - const Offset(4, 0),
        point + const Offset(4, 0),
        spark,
      );
      canvas.drawLine(
        point - const Offset(0, 4),
        point + const Offset(0, 4),
        spark,
      );
    }
    final wave = Path();
    for (var x = 0.0; x <= size.width; x += 3) {
      final y = size.height - 13 + math.sin(x / 44) * 9;
      if (x == 0) {
        wave.moveTo(x, y);
      } else {
        wave.lineTo(x, y);
      }
    }
    canvas.drawPath(
      wave,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.primary.withValues(alpha: .16),
    );
  }

  @override
  bool shouldRepaint(covariant _AuroraRecordPainter oldDelegate) => false;
}
