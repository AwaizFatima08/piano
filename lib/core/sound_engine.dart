import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'music.dart';

/// Plays the pre-made sounds in assets/sounds/. Behind an interface so tests
/// can record what was played instead of making noise.
abstract class SoundEngine {
  Future<void> init();

  /// [name] is a file name from [allSounds].
  void play(String name);

  /// 0..1 as shown on the slider; the engine applies a loudness curve.
  set volume(double v);
}

/// Low-latency, many-voices-at-once playback with SoLoud (toddlers press
/// several keys at a time). Sounds are loaded into memory once at start-up.
class SoLoudEngine implements SoundEngine {
  final _sources = <String, AudioSource>{};
  double _volume = 0.7;

  @override
  Future<void> init() async {
    try {
      final s = SoLoud.instance;
      if (!s.isInitialized) await s.init(bufferSize: 512, channels: Channels.mono, sampleRate: 32000);
      s.setMaxActiveVoiceCount(24);
      s.setGlobalVolume(_curve(_volume));
      for (final name in allSounds) {
        _sources[name] = await s.loadAsset('assets/sounds/$name.wav');
      }
    } on Object catch (e) {
      debugPrint('[sound] init failed: $e'); // the app still works, just silent
    }
  }

  @override
  void play(String name) {
    final src = _sources[name];
    if (src == null) return;
    try {
      SoLoud.instance.play(src);
    } on Object catch (e) {
      debugPrint('[sound] play $name failed: $e');
    }
  }

  @override
  set volume(double v) {
    _volume = v;
    if (SoLoud.instance.isInitialized) SoLoud.instance.setGlobalVolume(_curve(v));
  }

  /// Ears hear loudness roughly logarithmically; a power curve makes the
  /// slider feel even from quiet to loud.
  static double _curve(double v) => math.pow(v.clamp(0, 1), 1.8).toDouble();
}

/// Records sounds instead of playing them (tests).
class RecordingSoundEngine implements SoundEngine {
  final played = <String>[];
  double lastVolume = -1;

  @override
  Future<void> init() async {}

  @override
  void play(String name) => played.add(name);

  @override
  set volume(double v) => lastVolume = v;
}
