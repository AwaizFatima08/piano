import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'music.dart';

enum KeyLabels { animals, letters, solfa, colours }

/// How much the lights move. Calm keeps only a soft glow on the pressed key.
enum LightsLevel { party, gentle, calm }

/// Everything the grown-ups (and the mode buttons) can change, saved on the
/// device with shared_preferences. Nothing is sent anywhere.
class Settings extends ChangeNotifier {
  Settings._(this._prefs);

  /// In-memory settings for tests.
  Settings.memory() : _prefs = null;

  final SharedPreferences? _prefs;

  PlayMode mode = PlayMode.piano;
  Instrument instrument = Instrument.piano;
  int songIndex = 0;
  int keyCount = 8;
  KeyLabels labels = KeyLabels.animals;
  LightsLevel lights = LightsLevel.party;
  bool hideModes = false;
  bool keepAwake = false;
  bool muted = false;

  /// 0..1, the toddler-facing slider. Never above [maxVolume].
  double volume = 0.7;

  /// 0.2..1, the loudest the slider can go (grown-ups only).
  double maxVolume = 0.85;

  double get effectiveVolume => muted ? 0 : volume.clamp(0, maxVolume);

  static Future<Settings> load() async {
    final p = await SharedPreferences.getInstance();
    final s = Settings._(p);
    T pick<T extends Enum>(List<T> values, String key, T fallback) =>
        values.where((v) => v.name == p.getString(key)).firstOrNull ?? fallback;
    s
      ..mode = pick(PlayMode.values, 'mode', s.mode)
      ..instrument = pick(Instrument.values, 'instrument', s.instrument)
      ..labels = pick(KeyLabels.values, 'labels', s.labels)
      ..lights = pick(LightsLevel.values, 'lights', s.lights)
      ..songIndex = (p.getInt('song') ?? 0).clamp(0, songs.length - 1)
      ..keyCount = p.getInt('keys') == 5 ? 5 : 8
      ..hideModes = p.getBool('hideModes') ?? false
      ..keepAwake = p.getBool('keepAwake') ?? false
      ..muted = p.getBool('muted') ?? false
      ..maxVolume = (p.getDouble('maxVolume') ?? s.maxVolume).clamp(0.2, 1.0)
      ..volume = (p.getDouble('volume') ?? s.volume).clamp(0.0, 1.0);
    return s;
  }

  /// Change one or more fields, then save and notify.
  void update(void Function(Settings s) change) {
    change(this);
    volume = volume.clamp(0, maxVolume);
    notifyListeners();
    _save();
  }

  void _save() {
    final p = _prefs;
    if (p == null) return;
    p.setString('mode', mode.name);
    p.setString('instrument', instrument.name);
    p.setString('labels', labels.name);
    p.setString('lights', lights.name);
    p.setInt('song', songIndex);
    p.setInt('keys', keyCount);
    p.setBool('hideModes', hideModes);
    p.setBool('keepAwake', keepAwake);
    p.setBool('muted', muted);
    p.setDouble('maxVolume', maxVolume);
    p.setDouble('volume', volume);
  }
}
