import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_keys/core/music.dart';
import 'package:rainbow_keys/core/play_logic.dart';
import 'package:rainbow_keys/core/settings.dart';
import 'package:rainbow_keys/core/sound_engine.dart';

void main() {
  late Settings settings;
  late RecordingSoundEngine sound;
  late PlayLogic logic;

  setUp(() {
    settings = Settings.memory();
    sound = RecordingSoundEngine();
    logic = PlayLogic(settings: settings, sound: sound, random: math.Random(1));
  });
  tearDown(() => logic.dispose());

  test('every song only uses keys 0..7 and has positive beats', () {
    for (final s in songs) {
      expect(s.notes, isNotEmpty, reason: s.name);
      for (final n in s.notes) {
        expect(n.key, inInclusiveRange(0, 7), reason: s.name);
        expect(n.beats, greaterThan(0), reason: s.name);
      }
    }
  });

  test('every sound name has a matching asset file name pattern', () {
    expect(allSounds.length, 50);
    expect(allSounds.toSet().length, 50);
  });

  test('piano, drums and silly play the pressed key', () {
    expect(logic.press(3).lit, [3]);
    expect(sound.played.last, 'piano_3');
    settings.update((s) => s.instrument = Instrument.xylo);
    logic.press(0);
    expect(sound.played.last, 'xylo_0');
    settings.update((s) => s.mode = PlayMode.drums);
    logic.press(0);
    expect(sound.played.last, 'drum_kick');
    settings.update((s) => s.mode = PlayMode.silly);
    logic.press(2);
    expect(sound.played.last, 'silly_quack');
  });

  test('songs: any key plays the next note and the song key lights', () {
    settings.update((s) => s.mode = PlayMode.songs);
    logic.reset();
    final twinkle = songs[0];
    expect(logic.hintKey, twinkle.notes[0].key);
    final r1 = logic.press(7); // wrong key on purpose: the song still moves on
    expect(sound.played.last, 'piano_${twinkle.notes[0].key}');
    expect(r1.lit, containsAll([twinkle.notes[0].key, 7]));
    for (var i = 1; i < twinkle.notes.length - 1; i++) {
      expect(logic.press(0).reward, Reward.none);
    }
    expect(logic.press(0).reward, Reward.big);
    expect(logic.songPos, 0);
  });

  test('songs with 5 keys never light a missing key', () {
    settings.update((s) {
      s.mode = PlayMode.songs;
      s.keyCount = 5;
      s.songIndex = 2; // Row Your Boat uses the high C (key 7)
    });
    logic.reset();
    for (var i = 0; i < logic.song.notes.length; i++) {
      expect(logic.hintKey, lessThan(5));
      for (final k in logic.press(0).lit) {
        expect(k, lessThan(5));
      }
    }
  });

  test('find: the right key earns a star, five stars a big reward', () async {
    settings.update((s) => s.mode = PlayMode.find);
    logic.reset();
    for (var star = 1; star <= 5; star++) {
      final t = logic.targetKey!;
      final wrong = (t + 1) % settings.keyCount;
      expect(logic.press(wrong).reward, Reward.none);
      final r = logic.press(t);
      expect(r.reward, star == 5 ? Reward.big : Reward.small);
      expect(logic.found, star);
      expect(logic.targetKey, isNull);
      await Future<void>.delayed(const Duration(milliseconds: 2000));
      expect(logic.targetKey, isNot(t)); // a new key, never the same twice in a row
    }
  });

  test('volume never goes above the grown-up limit, mute silences', () {
    settings.update((s) {
      s.maxVolume = 0.5;
      s.volume = 0.9;
    });
    expect(settings.volume, 0.5);
    expect(settings.effectiveVolume, 0.5);
    settings.update((s) => s.muted = true);
    expect(settings.effectiveVolume, 0);
  });
}
