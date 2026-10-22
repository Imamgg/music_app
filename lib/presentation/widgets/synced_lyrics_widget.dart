import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../providers/audio_player_provider.dart';
import '../providers/lyrics_provider.dart';

class SyncedLyricsWidget extends ConsumerStatefulWidget {
  const SyncedLyricsWidget({super.key});

  @override
  ConsumerState<SyncedLyricsWidget> createState() => _SyncedLyricsWidgetState();
}

class _SyncedLyricsWidgetState extends ConsumerState<SyncedLyricsWidget> {
  final ScrollController _scrollController = ScrollController();
  int _lastActiveIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveIndex(int index) {
    if (!_scrollController.hasClients || index < 0) return;
    const itemEstimateHeight = 64.0;
    final targetOffset = (index * itemEstimateHeight) - 150.0;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lyricsState = ref.watch(lyricsProvider);

    // Otomatis scroll saat baris aktif berganti
    if (lyricsState.activeIndex != _lastActiveIndex) {
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
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
        itemCount: lyricsState.lines.length,
        itemBuilder: (context, index) {
          final line = lyricsState.lines[index];
          final isActive = index == lyricsState.activeIndex;

          return GestureDetector(
            onTap: () {
              ref.read(audioPlayerProvider.notifier).seek(line.timestamp);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: isActive ? 24 : 18,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  color: isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.35),
                  height: 1.4,
                  letterSpacing: -0.3,
                ),
                child: Text(line.text),
              ),
            ),
          );
        },
      );
    }

    if (lyricsState.plainLyrics != null &&
        lyricsState.plainLyrics!.trim().isNotEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Text(
          lyricsState.plainLyrics!,
          style: const TextStyle(
            fontSize: 18,
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
          Icon(Icons.lyrics_outlined,
              size: 64, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
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
