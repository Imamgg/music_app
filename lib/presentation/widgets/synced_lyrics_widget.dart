import 'package:auno/core/localization/app_strings.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../providers/audio_player_provider.dart';
import '../providers/lyrics_provider.dart';
import '../providers/settings_provider.dart';

class SyncedLyricsWidget extends ConsumerStatefulWidget {
  const SyncedLyricsWidget({super.key, this.onExpand});
  final VoidCallback? onExpand;
  @override
  ConsumerState<SyncedLyricsWidget> createState() => _SyncedLyricsWidgetState();
}

class _SyncedLyricsWidgetState extends ConsumerState<SyncedLyricsWidget> {
  final _scrollController = ScrollController();
  final Map<int, GlobalKey> _lineKeys = {};
  Object? _lastLines;
  int _lastActiveIndex = -1;
  bool _manualScroll = false;
  bool _autoScrollWasEnabled = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleScroll(int index) {
    final lines = _lastLines;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _manualScroll || !identical(lines, _lastLines)) return;
      final target = _lineKeys[index]?.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        alignment: .38,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final lyrics = ref.watch(lyricsProvider);
    final settings = ref.watch(settingsProvider);
    final synced = lyrics.hasSyncedLyrics && lyrics.lines.isNotEmpty;
    final plain = lyrics.plainLyrics?.trim() ?? '';
    if (!identical(_lastLines, lyrics.lines)) {
      _lastLines = lyrics.lines;
      _lineKeys.clear();
      _lastActiveIndex = -1;
      _manualScroll = false;
      final lines = lyrics.lines;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            identical(lines, _lastLines) &&
            lyrics.activeIndex < 0 &&
            _scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }
    if (settings.autoScrollLyrics && !_autoScrollWasEnabled) {
      _lastActiveIndex = -1;
    }
    _autoScrollWasEnabled = settings.autoScrollLyrics;
    if (settings.autoScrollLyrics &&
        !_manualScroll &&
        lyrics.activeIndex != _lastActiveIndex) {
      _lastActiveIndex = lyrics.activeIndex;
      _scheduleScroll(lyrics.activeIndex);
    }
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, bounds) {
        final compact = bounds.maxHeight < 200;
        Widget content;
        if (lyrics.isLoading || (!synced && plain.isEmpty)) {
          content = Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lyrics_outlined,
                    size: compact ? 28 : 40,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  AppText(
                    lyrics.isLoading
                        ? 'Menyiapkan lirik…'
                        : 'Lirik belum tersedia untuk lagu ini',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, height: 1.5),
                  ),
                  if (!lyrics.isLoading)
                    TextButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const AppText('Coba lagi'),
                      onPressed: () => ref
                          .read(lyricsProvider.notifier)
                          .loadLyricsForSong(
                            ref.read(audioPlayerProvider).currentSong,
                          ),
                    ),
                ],
              ),
            ),
          );
        } else if (!synced) {
          content = SingleChildScrollView(
            key: ValueKey(plain),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            child: Text(
              plain,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: settings.lyricsFontSize.baseSize,
                height: 1.8,
                color: Colors.white.withValues(alpha: .85),
              ),
            ),
          );
        } else {
          content = NotificationListener<ScrollStartNotification>(
            onNotification: (event) {
              if (event.dragDetails != null && !_manualScroll) {
                HapticFeedback.lightImpact();
                setState(() => _manualScroll = true);
              }
              return false;
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                12,
                compact ? 8 : 24,
                12,
                bounds.maxHeight * .45,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(lyrics.lines.length, (index) {
                  final line = lyrics.lines[index];
                  final active = index == lyrics.activeIndex;
                  final text = line.text.trim().isEmpty
                      ? context.tr('Instrumental')
                      : line.text;
                  return Semantics(
                    button: true,
                    selected: active,
                    child: Padding(
                      key: _lineKeys.putIfAbsent(index, () => GlobalKey()),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            setState(() => _manualScroll = false);
                            try {
                              await ref
                                  .read(audioPlayerProvider.notifier)
                                  .seek(line.timestamp);
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: AppText(
                                      'Gagal berpindah ke baris lirik.',
                                    ),
                                  ),
                                );
                              }
                            }
                            if (mounted) _scheduleScroll(index);
                          },
                          child: AnimatedContainer(
                            duration: reducedMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 220),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: active
                                  ? AppColors.primary.withValues(alpha: .12)
                                  : Colors.transparent,
                            ),
                            child: Text(
                              text,
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: settings.lyricsFontSize.baseSize,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                                color: active
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: .58),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          );
        }
        return Column(
          children: [
            if (!compact)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 8, 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lyrics_outlined,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppText(
                        synced
                            ? 'Ketuk baris untuk melompat'
                            : plain.isNotEmpty
                            ? 'Lirik tanpa sinkronisasi waktu'
                            : 'Lirik Lagu',
                        maxLines: 2,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (widget.onExpand != null)
                      IconButton(
                        tooltip: context.tr('Lirik layar penuh'),
                        onPressed: widget.onExpand,
                        icon: const Icon(Icons.open_in_full, size: 20),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: content),
                  if (compact && widget.onExpand != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        tooltip: context.tr('Lirik layar penuh'),
                        onPressed: widget.onExpand,
                        icon: const Icon(Icons.open_in_full, size: 20),
                      ),
                    ),
                  if (synced && _manualScroll && settings.autoScrollLyrics)
                    Positioned(
                      bottom: 10,
                      left: 12,
                      right: 12,
                      child: Center(
                        child: FilledButton.tonalIcon(
                          onPressed: () {
                            setState(() {
                              _manualScroll = false;
                              _lastActiveIndex = -1;
                            });
                            _scheduleScroll(lyrics.activeIndex);
                          },
                          icon: const Icon(Icons.my_location, size: 18),
                          label: const AppText('Kembali ke lirik aktif'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
