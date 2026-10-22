import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'audio_player_provider.dart';

enum SleepTimerMode { off, duration, endOfTrack }

class SleepTimerState {
  final SleepTimerMode mode;
  final int remainingSeconds;
  final int totalSeconds;

  const SleepTimerState({
    this.mode = SleepTimerMode.off,
    this.remainingSeconds = 0,
    this.totalSeconds = 0,
  });

  bool get isActive => mode != SleepTimerMode.off;

  String get formattedRemaining {
    if (!isActive) return 'Nonaktif';
    if (mode == SleepTimerMode.endOfTrack) return 'Di akhir lagu ini';
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  SleepTimerState copyWith({
    SleepTimerMode? mode,
    int? remainingSeconds,
    int? totalSeconds,
  }) {
    return SleepTimerState(
      mode: mode ?? this.mode,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
    );
  }
}

final sleepTimerProvider =
    StateNotifierProvider<SleepTimerNotifier, SleepTimerState>((ref) {
      final playerNotifier = ref.watch(audioPlayerProvider.notifier);
      final notifier = SleepTimerNotifier(playerNotifier);
      return notifier;
    });

class SleepTimerNotifier extends StateNotifier<SleepTimerState>
    with WidgetsBindingObserver {
  final AudioPlayerNotifier _playerNotifier;
  Timer? _timer;
  DateTime? _deadline;
  final DateTime Function() _now;

  SleepTimerNotifier(this._playerNotifier, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(const SleepTimerState()) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) checkDeadline();
  }

  void checkDeadline() {
    if (!mounted || _deadline == null) return;
    final milliseconds = _deadline!.difference(_now()).inMilliseconds;
    if (milliseconds <= 0) {
      _triggerStop();
    } else {
      state = state.copyWith(remainingSeconds: (milliseconds / 1000).ceil());
    }
  }

  void setTimer(Duration duration) {
    cancelTimer();
    if (duration <= Duration.zero) {
      _triggerStop();
      return;
    }
    _deadline = _now().add(duration);
    final seconds = duration.inSeconds;
    state = SleepTimerState(
      mode: SleepTimerMode.duration,
      remainingSeconds: seconds,
      totalSeconds: seconds,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => checkDeadline());
  }

  void setEndOfTrack() {
    cancelTimer();
    state = const SleepTimerState(
      mode: SleepTimerMode.endOfTrack,
      remainingSeconds: 0,
      totalSeconds: 0,
    );
    _playerNotifier.onTrackEnded = () {
      _triggerStop();
    };
  }

  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
    _deadline = null;
    _playerNotifier.onTrackEnded = null;
    state = const SleepTimerState(mode: SleepTimerMode.off);
  }

  void _triggerStop() {
    cancelTimer();
    _playerNotifier.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _playerNotifier.onTrackEnded = null;
    super.dispose();
  }
}
