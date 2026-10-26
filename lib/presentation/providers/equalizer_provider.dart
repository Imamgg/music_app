import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/storage_repository.dart';
import 'library_provider.dart';

final equalizerProvider = ChangeNotifierProvider<EqualizerController>(
  (ref) => EqualizerController(ref.watch(storageRepoProvider)),
);

class EqualizerController extends ChangeNotifier {
  EqualizerController(this.storage) {
    final saved = storage.getAudioEffects();
    enabled = saved['enabled'] == true;
    preset =
        ['Normal', 'Bass Boost', 'Vokal', 'Manual'].contains(saved['preset'])
        ? saved['preset'] as String
        : 'Normal';
    bass = (saved['bass'] as num? ?? 0).toDouble().clamp(0, 1000);
    final values = saved['manual'];
    if (values is Map) {
      for (final entry in values.entries) {
        if (entry.value is num) {
          manual[entry.key.toString()] = (entry.value as num).toDouble();
        }
      }
    }
  }
  final StorageRepository storage;
  static const channel = MethodChannel('auno/audio_effects');
  bool enabled = false, bassSupported = false, failed = false;
  String preset = 'Normal';
  double bass = 0, min = -15, max = 15;
  List<double> frequencies = [];
  final Map<String, double> manual = {};
  int? _session;
  int _generation = 0;
  bool _disposed = false;
  Timer? _timer;
  Future<void> _pending = Future.value();
  bool get android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get ready => frequencies.isNotEmpty || bassSupported;
  String get status => !android
      ? 'Equalizer tersedia di Android.'
      : failed
      ? 'Efek audio tidak tersedia pada perangkat ini.'
      : !ready && _session != null
      ? 'Efek audio tidak tersedia pada perangkat ini.'
      : 'Putar lagu untuk mengaktifkan equalizer.';
  double gain(double hz) {
    final value = switch (preset) {
      'Bass Boost' =>
        hz < 150
            ? 5.0
            : hz < 500
            ? 2.0
            : 0.0,
      'Vokal' => hz >= 500 && hz <= 4000 ? 3.0 : 0.0,
      'Manual' => manual[hz.toString()] ?? 0.0,
      _ => 0.0,
    };
    return value.clamp(min, max);
  }

  Future<void> attachSession(int? session) async {
    if (!android || _disposed) return;
    final generation = ++_generation;
    _session = session;
    try {
      final result = await channel.invokeMapMethod<String, dynamic>('attach', {
        'session': session,
      });
      if (_disposed || generation != _generation) return;
      frequencies = (result?['frequencies'] as List? ?? [])
          .map((e) => (e as num).toDouble())
          .toList();
      min = (result?['min'] as num? ?? -15).toDouble();
      max = (result?['max'] as num? ?? 15).toDouble();
      bassSupported = result?['bassSupported'] == true;
      failed = false;
      notifyListeners();
      _schedule();
    } catch (_) {
      if (_disposed || generation != _generation) return;
      failed = true;
      frequencies = [];
      bassSupported = false;
      notifyListeners();
    }
  }

  void setEnabled(bool value) {
    enabled = value;
    _changed();
  }

  void setPreset(String value) {
    preset = value;
    _changed();
  }

  void setBass(double value) {
    bass = value.clamp(0, 1000);
    _changed();
  }

  void setGain(double hz, double value) {
    if (preset != 'Manual') {
      for (final frequency in frequencies) {
        manual[frequency.toString()] = gain(frequency);
      }
    }
    preset = 'Manual';
    manual[hz.toString()] = value.clamp(min, max);
    _changed();
  }

  void reset() {
    preset = 'Normal';
    bass = 0;
    manual.clear();
    _changed();
  }

  void _changed() {
    notifyListeners();
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 60), () {
      final saved = <String, dynamic>{
        'enabled': enabled,
        'preset': preset,
        'bass': bass,
        'manual': Map<String, double>.from(manual),
      };
      final args = {
        'session': _session,
        'enabled': enabled,
        'bass': bass,
        'gains': frequencies.map(gain).toList(),
      };
      final generation = _generation;
      _pending = _pending
          .then((_) async {
            await storage.saveAudioEffects(saved);
            if (_disposed || generation != _generation || !ready || !android) {
              return;
            }
            try {
              await channel.invokeMethod<bool>('apply', args);
            } catch (_) {
              if (!_disposed) {
                failed = true;
                notifyListeners();
              }
            }
          })
          .catchError((Object _) {});
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
