import 'package:audio_service/audio_service.dart';
import 'audio_player_provider.dart';

AunoMediaHandler? mediaNotificationHandler;

class AunoMediaHandler extends BaseAudioHandler {
  AudioPlayerState? _lastPublished;
  bool? _lastLiked;
  bool _forcePublish = false;
  bool _stopped = false;

  void detach() {
    onPlay = onPause = onNext = onPrevious = onLike = null;
    onSeek = null;
    onShuffle = null;
    _lastPublished = null;
    mediaItem.add(null);
    playbackState.add(
      PlaybackState(processingState: AudioProcessingState.idle),
    );
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode != AudioServiceShuffleMode.none;
    if (enabled != (_lastPublished?.isShuffle ?? false)) onShuffle?.call();
  }

  Future<void> Function()? onPlay, onPause, onNext, onPrevious, onLike;
  Future<void> Function(Duration)? onSeek;
  void Function()? onShuffle;
  @override
  Future<void> play() async {
    _stopped = false;
    await onPlay?.call();
  }

  @override
  Future<void> pause() async {
    await onPause?.call();
  }

  @override
  Future<void> stop() async {
    await onPause?.call();
    _stopped = true;
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    await onNext?.call();
  }

  @override
  Future<void> skipToPrevious() async {
    await onPrevious?.call();
  }

  @override
  Future<void> seek(Duration position) async {
    _forcePublish = true;
    final duration = mediaItem.value?.duration;
    final clamped = position < Duration.zero
        ? Duration.zero
        : duration != null && position > duration
        ? duration
        : position;
    await onSeek?.call(clamped);
  }

  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    if (name == 'shuffle') onShuffle?.call();
    if (name == 'like') await onLike?.call();
  }

  void publish(AudioPlayerState state, bool liked) {
    final song = state.currentSong;
    if (song == null) {
      if (mediaItem.value != null) {
        mediaItem.add(null);
        playbackState.add(
          PlaybackState(processingState: AudioProcessingState.idle),
        );
      }
      _lastPublished = null;
      return;
    }
    if (_stopped &&
        !state.isPlaying &&
        _lastPublished?.currentSong?.id == song.id) {
      return;
    }
    _stopped = false;
    final cover = song.highResCoverUrl.isNotEmpty
        ? song.highResCoverUrl
        : song.coverUrl;
    final uri = Uri.tryParse(cover);
    final item = MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: state.duration > Duration.zero
          ? state.duration
          : Duration(seconds: song.durationSeconds),
      artUri:
          uri != null &&
              (uri.scheme == 'https' ||
                  uri.scheme == 'http' ||
                  uri.scheme == 'file')
          ? uri
          : null,
    );
    // MediaItem equality only compares IDs, so compare mutable metadata explicitly.
    final oldItem = mediaItem.value;
    final metadataChanged =
        oldItem?.id != item.id ||
        oldItem?.title != item.title ||
        oldItem?.artist != item.artist ||
        oldItem?.album != item.album ||
        oldItem?.artUri != item.artUri ||
        oldItem?.duration != item.duration;
    if (metadataChanged) mediaItem.add(item);
    final previous = _lastPublished;
    final oldState = playbackState.value;
    final projected =
        oldState.updatePosition +
        (oldState.playing &&
                oldState.processingState == AudioProcessingState.ready
            ? DateTime.now().difference(oldState.updateTime)
            : Duration.zero);
    if (!_forcePublish &&
        !metadataChanged &&
        previous != null &&
        previous.isPlaying == state.isPlaying &&
        previous.isBuffering == state.isBuffering &&
        previous.isLoadingStream == state.isLoadingStream &&
        previous.isShuffle == state.isShuffle &&
        previous.repeatMode == state.repeatMode &&
        previous.errorMessage == state.errorMessage &&
        previous.currentIndex == state.currentIndex &&
        _lastLiked == liked &&
        (state.position - projected).inMilliseconds.abs() < 900) {
      return;
    }
    _forcePublish = false;
    _lastPublished = state;
    _lastLiked = liked;
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.custom(
            androidIcon: state.isShuffle
                ? 'drawable/auno_shuffle_on'
                : 'drawable/auno_shuffle',
            label: state.isShuffle ? 'Nonaktifkan acak' : 'Acak',
            name: 'shuffle',
          ),
          MediaControl.skipToPrevious,
          state.isPlaying ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.custom(
            androidIcon: liked
                ? 'drawable/auno_favorite'
                : 'drawable/auno_favorite_border',
            label: liked ? 'Hapus dari favorit' : 'Sukai',
            name: 'like',
          ),
        ],
        androidCompactActionIndices: const [1, 2, 3],
        systemActions: const {MediaAction.seek},
        processingState: state.errorMessage != null
            ? AudioProcessingState.error
            : state.isLoadingStream
            ? AudioProcessingState.loading
            : state.isBuffering
            ? AudioProcessingState.buffering
            : AudioProcessingState.ready,
        errorCode: state.errorMessage != null ? 1 : null,
        errorMessage: state.errorMessage,
        repeatMode: switch (state.repeatMode) {
          PlaybackRepeatMode.off => AudioServiceRepeatMode.none,
          PlaybackRepeatMode.one => AudioServiceRepeatMode.one,
          PlaybackRepeatMode.all => AudioServiceRepeatMode.all,
        },
        playing: state.isPlaying,
        updatePosition: state.position,
        bufferedPosition: state.position,
        shuffleMode: state.isShuffle
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
      ),
    );
  }
}
