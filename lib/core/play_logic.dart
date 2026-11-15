import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'music.dart';
import 'settings.dart';
import 'sound_engine.dart';

enum Reward { none, small, big }

/// What a key press did: which keys should light up, and whether to celebrate.
class PressResult {
  const PressResult(this.lit, [this.reward = Reward.none]);
  final List<int> lit;
  final Reward reward;
}

/// The rules of each mode. Plays the sounds; the screen only draws.
///
/// - piano / drums / silly: every key plays its own sound.
/// - songs: any key plays the next note of the song ("magic" playing), and the
///   song's real key lights up. [startAuto] plays the whole song by itself.
/// - find: one key glows; pressing it earns a star, five stars a party.
///   Wrong keys just play their note — there is no "wrong" sound.
class PlayLogic extends ChangeNotifier {
  PlayLogic({required this.settings, required this.sound, math.Random? random})
    : _rng = random ?? math.Random();

  final Settings settings;
  final SoundEngine sound;
  final math.Random _rng;

  int songPos = 0;
  int? targetKey;
  int _lastTarget = -1;
  int found = 0;
  bool autoPlaying = false;
  Timer? _auto;
  Timer? _later;

  /// Called for each note the song plays by itself, so the screen can light it.
  void Function(PressResult result)? onAutoNote;

  Song get song => songs[settings.songIndex];

  /// The key that plays the next song note (songs mode only).
  int? get hintKey => settings.mode == PlayMode.songs ? _songKey(songPos) : null;

  double get songProgress => songPos / song.notes.length;

  /// Songs use keys 0..7; with 5 keys the high notes land on the last key.
  int _songKey(int pos) => math.min(song.notes[pos].key, settings.keyCount - 1);

  /// Call after the mode, song or key count changed.
  void reset() {
    stopAuto();
    _later?.cancel();
    songPos = 0;
    found = 0;
    targetKey = null;
    if (settings.mode == PlayMode.find) _newTarget();
    notifyListeners();
  }

  PressResult press(int key) {
    switch (settings.mode) {
      case PlayMode.piano:
        sound.play(settings.instrument.sound(key));
        return PressResult([key]);
      case PlayMode.drums:
        sound.play(drumPads[key].sound);
        return PressResult([key]);
      case PlayMode.silly:
        sound.play(sillyPads[key].sound);
        return PressResult([key]);
      case PlayMode.songs:
        stopAuto();
        return _songStep(key);
      case PlayMode.find:
        return _find(key);
    }
  }

  PressResult _songStep(int? pressed) {
    final note = song.notes[songPos];
    sound.play(settings.instrument.sound(note.key));
    final shown = _songKey(songPos);
    songPos++;
    var reward = Reward.none;
    if (songPos >= song.notes.length) {
      songPos = 0;
      reward = Reward.big;
      _later?.cancel();
      _later = Timer(const Duration(milliseconds: 450), () => sound.play(fanfareSound));
    }
    notifyListeners();
    return PressResult({shown, ?pressed}.toList(), reward);
  }

  PressResult _find(int key) {
    sound.play(settings.instrument.sound(key));
    if (key != targetKey) return PressResult([key]);
    found++;
    targetKey = null;
    final big = found % 5 == 0;
    sound.play(big ? fanfareSound : cheerSound);
    _later?.cancel();
    _later = Timer(Duration(milliseconds: big ? 1900 : 800), () {
      _newTarget();
      notifyListeners();
    });
    notifyListeners();
    return PressResult([key], big ? Reward.big : Reward.small);
  }

  void _newTarget() {
    var t = _rng.nextInt(settings.keyCount);
    if (settings.keyCount > 1) {
      while (t == _lastTarget) {
        t = _rng.nextInt(settings.keyCount);
      }
    }
    _lastTarget = t;
    targetKey = t;
  }

  /// "Play for me": the song plays itself with the lights.
  void startAuto() {
    stopAuto();
    songPos = 0;
    autoPlaying = true;
    notifyListeners();
    _autoStep();
  }

  void _autoStep() {
    final wait = song.notes[songPos].beats * song.beatSeconds;
    final r = _songStep(null);
    onAutoNote?.call(r);
    if (songPos == 0) {
      autoPlaying = false;
      notifyListeners();
      return;
    }
    _auto = Timer(Duration(milliseconds: (wait * 1000).round()), _autoStep);
  }

  void stopAuto() {
    _auto?.cancel();
    _auto = null;
    if (autoPlaying) {
      autoPlaying = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _auto?.cancel();
    _later?.cancel();
    super.dispose();
  }
}
