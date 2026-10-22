import 'dart:io';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/repositories/storage_repository.dart';
import 'library_provider.dart';

enum AudioQuality {
  high('Tinggi (192-256 kbps)', 'Kualitas audio terbaik, cocok untuk Wi-Fi'),
  normal(
    'Standar (128 kbps)',
    'Seimbang antara kualitas dan kuota (Rekomendasi)',
  ),
  low('Hemat Kuota (64 kbps)', 'Irit kuota data & loading tercepat');

  final String label;
  final String description;
  const AudioQuality(this.label, this.description);

  static AudioQuality fromString(String val) {
    switch (val) {
      case 'high':
        return AudioQuality.high;
      case 'low':
        return AudioQuality.low;
      default:
        return AudioQuality.normal;
    }
  }

  String get key {
    switch (this) {
      case AudioQuality.high:
        return 'high';
      case AudioQuality.low:
        return 'low';
      case AudioQuality.normal:
        return 'normal';
    }
  }
}

enum LyricsFontSize {
  small('Kecil', 15.0, 20.0),
  medium('Sedang', 18.0, 24.0),
  large('Besar', 22.0, 28.0);

  final String label;
  final double baseSize;
  final double activeSize;
  const LyricsFontSize(this.label, this.baseSize, this.activeSize);

  static LyricsFontSize fromString(String val) {
    switch (val) {
      case 'small':
        return LyricsFontSize.small;
      case 'large':
        return LyricsFontSize.large;
      default:
        return LyricsFontSize.medium;
    }
  }

  String get key {
    switch (this) {
      case LyricsFontSize.small:
        return 'small';
      case LyricsFontSize.large:
        return 'large';
      case LyricsFontSize.medium:
        return 'medium';
    }
  }
}

enum ContentLanguage {
  system('Ikuti Sistem', 'Gunakan bahasa perangkat', 'system'),
  indonesian('Bahasa Indonesia', 'Bahasa antarmuka aplikasi', 'id'),
  english('English', 'App interface language', 'en'),
  japanese('日本語', 'アプリの表示言語', 'ja'),
  korean('한국어', '앱 표시 언어', 'ko');

  final String label;
  final String description;
  final String code;

  const ContentLanguage(this.label, this.description, this.code);

  static ContentLanguage fromCode(String code) {
    return ContentLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => ContentLanguage.system,
    );
  }
}

class SettingsState {
  final AudioQuality audioQuality;
  final LyricsFontSize lyricsFontSize;
  final ContentLanguage contentLanguage;
  final bool dynamicThemeEnabled;
  final bool autoScrollLyrics;
  final String cacheSize;
  final bool isClearingCache;

  const SettingsState({
    this.audioQuality = AudioQuality.normal,
    this.lyricsFontSize = LyricsFontSize.medium,
    this.contentLanguage = ContentLanguage.system,
    this.dynamicThemeEnabled = true,
    this.autoScrollLyrics = true,
    this.cacheSize = '0 B',
    this.isClearingCache = false,
  });

  SettingsState copyWith({
    AudioQuality? audioQuality,
    LyricsFontSize? lyricsFontSize,
    ContentLanguage? contentLanguage,
    bool? dynamicThemeEnabled,
    bool? autoScrollLyrics,
    String? cacheSize,
    bool? isClearingCache,
  }) {
    return SettingsState(
      audioQuality: audioQuality ?? this.audioQuality,
      lyricsFontSize: lyricsFontSize ?? this.lyricsFontSize,
      contentLanguage: contentLanguage ?? this.contentLanguage,
      dynamicThemeEnabled: dynamicThemeEnabled ?? this.dynamicThemeEnabled,
      autoScrollLyrics: autoScrollLyrics ?? this.autoScrollLyrics,
      cacheSize: cacheSize ?? this.cacheSize,
      isClearingCache: isClearingCache ?? this.isClearingCache,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    final storage = ref.watch(storageRepoProvider);
    return SettingsNotifier(storage);
  },
);

class SettingsNotifier extends StateNotifier<SettingsState> {
  final StorageRepository _storage;

  SettingsNotifier(this._storage) : super(const SettingsState()) {
    _loadSettings();
    loadCacheSize();
  }

  void _loadSettings() {
    final qualityStr = _storage.getAudioQuality();
    final fontStr = _storage.getLyricsFontSize();
    final langStr = _storage.getContentLanguage();
    final dynamicTheme = _storage.getDynamicThemeEnabled();
    final autoScroll = _storage.getAutoScrollLyrics();

    state = state.copyWith(
      audioQuality: AudioQuality.fromString(qualityStr),
      lyricsFontSize: LyricsFontSize.fromString(fontStr),
      contentLanguage: ContentLanguage.fromCode(langStr),
      dynamicThemeEnabled: dynamicTheme,
      autoScrollLyrics: autoScroll,
    );
  }

  Future<void> setAudioQuality(AudioQuality quality) async {
    state = state.copyWith(audioQuality: quality);
    await _storage.setAudioQuality(quality.key);
  }

  Future<void> setLyricsFontSize(LyricsFontSize size) async {
    state = state.copyWith(lyricsFontSize: size);
    await _storage.setLyricsFontSize(size.key);
  }

  Future<void> setContentLanguage(ContentLanguage language) async {
    state = state.copyWith(contentLanguage: language);
    await _storage.setContentLanguage(language.code);
  }

  Future<void> setDynamicThemeEnabled(bool enabled) async {
    state = state.copyWith(dynamicThemeEnabled: enabled);
    await _storage.setDynamicThemeEnabled(enabled);
  }

  Future<void> setAutoScrollLyrics(bool enabled) async {
    state = state.copyWith(autoScrollLyrics: enabled);
    await _storage.setAutoScrollLyrics(enabled);
  }

  Future<void> loadCacheSize() async {
    try {
      int totalBytes = 0;
      final tempDir = await getTemporaryDirectory();
      totalBytes += await _getDirectorySize(
        Directory('${tempDir.path}/${DefaultCacheManager.key}'),
      );

      if (!mounted) return;
      state = state.copyWith(cacheSize: _formatBytes(totalBytes));
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(cacheSize: '0 B');
    }
  }

  Future<int> _getDirectorySize(Directory dir) async {
    int total = 0;
    try {
      if (await dir.exists()) {
        await for (final file in dir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (file is File) {
            total += await file.length();
          }
        }
      }
    } catch (_) {}
    return total;
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  Future<void> clearCache() async {
    if (state.isClearingCache) return;
    state = state.copyWith(isClearingCache: true);
    try {
      await DefaultCacheManager().emptyCache();
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      await _storage.clearNetworkCache();
      await loadCacheSize();
    } finally {
      if (mounted) state = state.copyWith(isClearingCache: false);
    }
  }

  Future<void> clearSearchHistory() async {
    await _storage.clearSearchHistory();
  }
}
