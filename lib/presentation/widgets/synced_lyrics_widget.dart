import 'package:auno/core/localization/app_strings.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../providers/audio_player_provider.dart';
import '../providers/lyrics_provider.dart';
import '../providers/settings_provider.dart';

class SyncedLyricsWidget extends ConsumerStatefulWidget {
  const SyncedLyricsWidget({super.key});

  @override
  ConsumerState<SyncedLyricsWidget> createState() => _SyncedLyricsWidgetState();
}

class _SyncedLyricsWidgetState extends ConsumerState<SyncedLyricsWidget> {
  final ScrollController _scrollController = ScrollController();
  int _lastActiveIndex = -1;
  final Map<int, GlobalKey> _lineKeys = {};
  Object? _lastLines;
  bool _autoScrollWasEnabled = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveIndex(int index) {
    if (!mounted || index < 0) return;
    final target = _lineKeys[index]?.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      alignment: .35,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lyricsState = ref.watch(lyricsProvider);
    final settings = ref.watch(settingsProvider);
    final baseFontSize = settings.lyricsFontSize.baseSize;
    final activeFontSize = settings.lyricsFontSize.activeSize;

    if (!identical(_lastLines, lyricsState.lines)) {
      _lastLines = lyricsState.lines;
      _lineKeys.clear();
      _lastActiveIndex = -1;
    }
    if (settings.autoScrollLyrics && !_autoScrollWasEnabled) {
      _lastActiveIndex = -1;
    }
    _autoScrollWasEnabled = settings.autoScrollLyrics;
    // Otomatis scroll saat baris aktif berganti (jika auto-scroll aktif)
    if (settings.autoScrollLyrics &&
        lyricsState.activeIndex != _lastActiveIndex) {
      _lastActiveIndex = lyricsState.activeIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToActiveIndex(_lastActiveIndex);
      });
    }

    if (lyricsState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (lyricsState.hasSyncedLyrics && lyricsState.lines.isNotEmpty) {
      return NotificationListener<ScrollStartNotification>(
        onNotification: (notification) {
          if (notification.dragDetails != null) HapticFeedback.lightImpact();
          return false;
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
          child: Column(
            children: List.generate(lyricsState.lines.length, (index) {
              final line = lyricsState.lines[index];
              final isActive = index == lyricsState.activeIndex;

              return GestureDetector(
                key: _lineKeys.putIfAbsent(index, () => GlobalKey()),
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(audioPlayerProvider.notifier).seek(line.timestamp);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: isActive ? activeFontSize : baseFontSize,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.65),
                      height: 1.4,
                      letterSpacing: -0.3,
                    ),
                    child: Text(line.text),
                  ),
                ),
              );
            }),
          ),
        ),
      );
    }

    if (lyricsState.plainLyrics != null &&
        lyricsState.plainLyrics!.trim().isNotEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Text(
          lyricsState.plainLyrics!,
          style: TextStyle(
            fontSize: baseFontSize,
            color: Colors.white70,
            height: 1.8,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lyrics_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          AppText(
            'Lirik belum tersedia untuk lagu ini',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
