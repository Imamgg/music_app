import 'library_provider.dart';
import 'media_notification_handler.dart';
import 'offline_provider.dart';
import 'equalizer_provider.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import '../../data/models/song_model.dart';
import 'settings_provider.dart';
import '../../data/repositories/youtube_audio_repository.dart';

enum PlaybackRepeatMode { off, all, one }

class AudioPlayerState {
  final SongModel? currentSong;
  final bool isPlaying;
  final bool isBuffering;
  final bool isLoadingStream;
  final Duration position;
  final Duration duration;
  final List<SongModel> queue;
  final int currentIndex;
  final bool isShuffle;
  final PlaybackRepeatMode repeatMode;
  final String? errorMessage;

  const AudioPlayerState({
    this.currentSong,
    this.isPlaying = false,
    this.isBuffering = false,
    this.isLoadingStream = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.queue = const [],
    this.currentIndex = -1,
    this.isShuffle = false,
    this.repeatMode = PlaybackRepeatMode.off,
    this.errorMessage,
  });

  bool get hasCurrentSong => currentSong != null;
  bool get hasNext =>
      queue.isNotEmpty &&
      (currentIndex < queue.length - 1 || repeatMode == PlaybackRepeatMode.all);
  bool get hasPrevious => queue.isNotEmpty && currentIndex > 0;

  AudioPlayerState copyWith({
    SongModel? currentSong,
    bool clearCurrentSong = false,
    bool? isPlaying,
    bool? isBuffering,
    bool? isLoadingStream,
    Duration? position,
    Duration? duration,
    List<SongModel>? queue,
    int? currentIndex,
    bool? isShuffle,
    PlaybackRepeatMode? repeatMode,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AudioPlayerState(
      currentSong: clearCurrentSong ? null : (currentSong ?? this.currentSong),
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      isLoadingStream: isLoadingStream ?? this.isLoadingStream,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isShuffle: isShuffle ?? this.isShuffle,
      repeatMode: repeatMode ?? this.repeatMode,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final youtubeAudioRepoProvider = Provider<YoutubeAudioRepository>((ref) {
  final repo = YoutubeAudioRepository();
  ref.listen(settingsProvider.select((s) => s.audioQuality), (_, quality) {
    repo.quality = quality.key;
  }, fireImmediately: true);
  ref.onDispose(() => repo.dispose());
  return repo;
});

final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
      final ytRepo = ref.watch(youtubeAudioRepoProvider);
      final notifier = AudioPlayerNotifier(
        ytRepo,
        onAudioSessionChanged: ref.read(equalizerProvider).attachSession,
        localAudioPath: ref.read(offlineProvider).localPath,
      );
      final handler = mediaNotificationHandler;
      if (handler != null) {
        handler.onPlay = notifier.play;
        handler.onPause = notifier.pause;
        handler.onNext = notifier.playNext;
        handler.onPrevious = notifier.playPrevious;
        handler.onSeek = notifier.seek;
        handler.onShuffle = notifier.toggleShuffle;
        handler.onLike = () async {
          final song = notifier.snapshot.currentSong;
          if (song != null) {
            await ref.read(libraryProvider.notifier).toggleLike(song);
          }
        };
        final remove = notifier.addListener(
          (state) => handler.publish(
            state,
            ref.read(libraryProvider).isLiked(state.currentSong?.id ?? ''),
          ),
        );
        ref.listen(
          libraryProvider,
          (_, library) => handler.publish(
            notifier.snapshot,
            library.isLiked(notifier.snapshot.currentSong?.id ?? ''),
          ),
        );
        ref.onDispose(() {
          remove();
          handler.detach();
        });
      }
      return notifier;
    });

class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  AudioPlayerState get snapshot => state;
  final Future<String?> Function(String)? localAudioPath;
  final AudioPlayer _player;
  final YoutubeAudioRepository _ytRepo;

  StreamSubscription<int?>? _audioSessionSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlaybackEvent>? _playbackEventSub;

  List<SongModel> _originalQueue = [];
  bool _hasPrefetchedNext = false;
  int _loadGeneration = 0;
  bool _wantsPlayback = false;
  bool _sourceReady = false;
  bool _completedHandled = false;

  bool _isCurrentLoad(int generation) =>
      mounted && generation == _loadGeneration;

  AudioPlayerNotifier(
    this._ytRepo, {
    AudioPlayer? player,
    this.localAudioPath,
    Future<void> Function(int?)? onAudioSessionChanged,
  }) : _player =
           player ??
           AudioPlayer(
             audioLoadConfiguration: const AudioLoadConfiguration(
               androidLoadControl: AndroidLoadControl(
                 bufferForPlaybackDuration: Duration(milliseconds: 750),
               ),
             ),
           ),
       super(const AudioPlayerState()) {
    _initAudioStreams();
    if (onAudioSessionChanged != null &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      _audioSessionSub = _player.androidAudioSessionIdStream.listen(
        onAudioSessionChanged,
      );
    }
  }

  void _initAudioStreams() {
    _playerStateSub = _player.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;

      final isBuffering =
          processingState == ProcessingState.buffering ||
          processingState == ProcessingState.loading;

      state = state.copyWith(
        isPlaying: state.isLoadingStream ? _wantsPlayback : isPlaying,
        isBuffering: isBuffering,
      );

      // Otomatis putar lagu berikutnya saat selesai
      if (processingState != ProcessingState.completed) {
        _completedHandled = false;
      }
      if (!state.isLoadingStream &&
          !_completedHandled &&
          processingState == ProcessingState.completed) {
        _completedHandled = true;
        _onTrackCompleted();
      }
    });

    _playbackEventSub = _player.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace st) {
        debugPrint('Playback error event: $e');
        state = state.copyWith(
          isPlaying: false,
          isBuffering: false,
          isLoadingStream: false,
          errorMessage: 'Kendala pemutaran: $e',
        );
      },
    );

    _positionSub = _player.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
      _checkAndPrefetchNext(pos);
    });

    _durationSub = _player.durationStream.listen((dur) {
      if (dur != null) {
        state = state.copyWith(duration: dur);
      }
    });
  }

  /// Prepare the next URL after playback settles; this does not buffer audio.
  Future<void> _prefetchOnline(SongModel song) async {
    if (await localAudioPath?.call(song.id) != null || !mounted) return;
    await _ytRepo.getAudioStream(song);
  }

  void _checkAndPrefetchNext(Duration pos) {
    if (_hasPrefetchedNext || state.duration.inSeconds <= 0) return;
    if (state.isLoadingStream || state.isBuffering || !state.isPlaying) return;
    if (pos >= const Duration(seconds: 5) && state.hasNext) {
      _hasPrefetchedNext = true;
      final nextIndex = (state.currentIndex + 1) % state.queue.length;
      if (nextIndex < state.queue.length) {
        final nextSong = state.queue[nextIndex];
        _prefetchOnline(nextSong);
      }
    }
  }

  VoidCallback? onTrackEnded;

  void _onTrackCompleted() {
    if (onTrackEnded != null) {
      final callback = onTrackEnded;
      onTrackEnded = null;
      callback!();
      return;
    }

    if (state.repeatMode == PlaybackRepeatMode.one) {
      _player.seek(Duration.zero);
      _player.play();
    } else if (state.hasNext) {
      playNext();
    } else if (state.repeatMode == PlaybackRepeatMode.all &&
        state.queue.isNotEmpty) {
      _playSongAtIndex(0);
    } else {
      state = state.copyWith(isPlaying: false);
    }
  }

  /// Memulai pemutaran lagu [song] dengan antrean opsional [queue]
  Future<void> playSong(SongModel song, {List<SongModel>? queue}) async {
    List<SongModel> activeQueue = List.of(queue ?? state.queue);
    if (!activeQueue.contains(song)) {
      activeQueue = [...activeQueue, song];
    }

    final targetIndex = activeQueue.indexWhere((s) => s.id == song.id);
    // Keep the selected recording metadata when revisiting it from the queue.
    if (targetIndex >= 0) activeQueue[targetIndex] = song;
    _originalQueue = List.from(activeQueue);

    if (state.currentSong?.id == song.id &&
        (_sourceReady || state.isLoadingStream)) {
      state = state.copyWith(queue: activeQueue, currentIndex: targetIndex);
      await play();
      return;
    }

    state = state.copyWith(
      currentSong: song,
      queue: activeQueue,
      currentIndex: targetIndex >= 0 ? targetIndex : 0,
      isLoadingStream: true,
      clearError: true,
      position: Duration.zero,
    );

    await _loadAndPlayStream(song);
  }

  Future<void> _loadAndPlayStream(
    SongModel song, {
    bool isRetry = false,
    int? generation,
  }) async {
    final startup = Stopwatch()..start();
    final request = generation ?? ++_loadGeneration;
    if (!_isCurrentLoad(request)) return;
    if (!isRetry) _wantsPlayback = true;
    _sourceReady = false;
    try {
      _hasPrefetchedNext = false;
      state = state.copyWith(
        isLoadingStream: true,
        isPlaying: _wantsPlayback,
        duration: Duration.zero,
        clearError: true,
      );
      await _player.stop();
      if (!_isCurrentLoad(request)) return;

      final lookupStarted = startup.elapsedMilliseconds;
      final local = await localAudioPath?.call(song.id);
      if (!_isCurrentLoad(request)) return;
      final streamResult = local != null
          ? AudioStreamResult(
              streamUrl: Uri.file(local).toString(),
              videoId: song.youtubeVideoId ?? song.id,
            )
          : await _ytRepo.getAudioStream(song, forceRefresh: isRetry);
      if (!_isCurrentLoad(request)) return;
      if (streamResult == null) {
        state = state.copyWith(
          isLoadingStream: false,
          isPlaying: false,
          isBuffering: false,
          errorMessage:
              'Gagal mengekstrak audio dari "${song.title}". Silakan coba lagu lain.',
        );
        return;
      }

      final cover = song.highResCoverUrl.isNotEmpty
          ? song.highResCoverUrl
          : song.coverUrl;
      final artUri =
          local == null && cover.isNotEmpty && cover.startsWith('http')
          ? Uri.tryParse(cover)
          : null;

      final audioSource = AudioSource.uri(
        Uri.parse(streamResult.streamUrl),
        headers: local != null
            ? null
            : const {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Accept': '*/*',
                'Referer': 'https://www.youtube.com/',
              },
        tag: MediaItem(
          id: song.id,
          album: song.album.isNotEmpty ? song.album : 'AUNO Music',
          title: song.title,
          artist: song.artist,
          artUri: artUri,
          duration: Duration(seconds: song.durationSeconds),
        ),
      );

      final lookupMs = startup.elapsedMilliseconds - lookupStarted;
      final prepareStarted = startup.elapsedMilliseconds;
      await _player.setAudioSource(audioSource);
      if (!_isCurrentLoad(request)) return;
      if (kDebugMode) {
        debugPrint(
          'Audio startup: lookup=${lookupMs}ms, prepare=${startup.elapsedMilliseconds - prepareStarted}ms, local=${local != null}, retry=$isRetry',
        );
      }
      _sourceReady = true;
      state = state.copyWith(
        isLoadingStream: false,
        isBuffering: false,
        isPlaying: _wantsPlayback,
      );
      // play() completes when playback ends, not when playback starts.
      if (_wantsPlayback) _startPlayback(request);
    } catch (e) {
      if (!_isCurrentLoad(request)) return;
      debugPrint('Error playing stream: $e');
      if (!isRetry) {
        // Otomatis invalidate cache dan coba sekali lagi dengan fresh stream extraction
        _ytRepo.invalidateCache(song.id);
        return _loadAndPlayStream(song, isRetry: true, generation: request);
      }
      state = state.copyWith(
        isLoadingStream: false,
        isPlaying: false,
        isBuffering: false,
        errorMessage: 'Terjadi kendala saat memutar lagu: $e',
      );
    }
  }

  void _startPlayback(int generation) {
    unawaited(
      _player.play().catchError((Object error) {
        if (!_isCurrentLoad(generation)) return;
        _wantsPlayback = false;
        _sourceReady = false;
        state = state.copyWith(
          isPlaying: false,
          isBuffering: false,
          isLoadingStream: false,
          errorMessage: 'Kendala pemutaran: $error',
        );
      }),
    );
  }

  Future<void> togglePlayPause() async {
    if (state.currentSong == null) return;
    if (state.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> pause() async {
    _wantsPlayback = false;
    state = state.copyWith(isPlaying: false);
    await _player.pause();
  }

  Future<void> play() async {
    final song = state.currentSong;
    if (song == null) return;
    _wantsPlayback = true;
    state = state.copyWith(isPlaying: true, clearError: true);
    if (state.isLoadingStream) return;
    if (!_sourceReady) {
      await _loadAndPlayStream(song);
      return;
    }
    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
      if (!mounted || !_wantsPlayback) return;
    }
    _startPlayback(_loadGeneration);
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> playNext() async {
    if (state.queue.isEmpty) return;

    int nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.queue.length) {
      if (state.repeatMode == PlaybackRepeatMode.all) {
        nextIndex = 0;
      } else {
        return;
      }
    }
    await _playSongAtIndex(nextIndex);
  }

  Future<void> playPrevious() async {
    if (state.queue.isEmpty) return;

    // Jika sudah berjalan > 3 detik, restart lagu saat ini
    if (state.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }

    int prevIndex = state.currentIndex - 1;
    if (prevIndex < 0) {
      if (state.repeatMode == PlaybackRepeatMode.all) {
        prevIndex = state.queue.length - 1;
      } else {
        prevIndex = 0;
      }
    }
    await _playSongAtIndex(prevIndex);
  }

  Future<void> _playSongAtIndex(int index) async {
    if (index < 0 || index >= state.queue.length) return;
    final song = state.queue[index];
    state = state.copyWith(
      currentSong: song,
      currentIndex: index,
      isLoadingStream: true,
      clearError: true,
      position: Duration.zero,
    );
    await _loadAndPlayStream(song);
  }

  void toggleShuffle() {
    final nextShuffle = !state.isShuffle;
    if (nextShuffle) {
      final current = state.currentSong;
      final shuffled = List<SongModel>.from(state.queue)..shuffle();
      if (current != null) {
        shuffled.remove(current);
        shuffled.insert(0, current);
      }
      state = state.copyWith(isShuffle: true, queue: shuffled, currentIndex: 0);
    } else {
      final current = state.currentSong;
      final restored = List<SongModel>.from(_originalQueue);
      final newIndex = current != null ? restored.indexOf(current) : 0;
      state = state.copyWith(
        isShuffle: false,
        queue: restored,
        currentIndex: newIndex >= 0 ? newIndex : 0,
      );
    }
  }

  void toggleRepeat() {
    final nextMode = switch (state.repeatMode) {
      PlaybackRepeatMode.off => PlaybackRepeatMode.all,
      PlaybackRepeatMode.all => PlaybackRepeatMode.one,
      PlaybackRepeatMode.one => PlaybackRepeatMode.off,
    };
    state = state.copyWith(repeatMode: nextMode);
  }

  void addToQueue(SongModel song) {
    state = state.copyWith(queue: [...state.queue, song]);
    _originalQueue = [..._originalQueue, song];
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= state.queue.length) return;
    final updated = List<SongModel>.from(state.queue)..removeAt(index);
    int newCurrent = state.currentIndex;
    if (index < state.currentIndex) {
      newCurrent--;
    }
    state = state.copyWith(queue: updated, currentIndex: newCurrent);
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.queue.length) return;
    final updated = List<SongModel>.from(state.queue);
    final item = updated.removeAt(oldIndex);
    if (newIndex > oldIndex) newIndex--;
    updated.insert(newIndex, item);

    int newCurrent = state.currentIndex;
    if (state.currentSong != null) {
      newCurrent = updated.indexOf(state.currentSong!);
    }

    state = state.copyWith(queue: updated, currentIndex: newCurrent);
  }

  @override
  void dispose() {
    _loadGeneration++;
    _audioSessionSub?.cancel();
    _playerStateSub?.cancel();
    _playbackEventSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
