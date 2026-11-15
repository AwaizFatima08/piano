import 'package:flutter/painting.dart';

/// Everything the keys can be: colours, faces, sounds and songs. Pure data, no
/// Flutter widgets, so it is easy to test.

/// One coloured key. Index 0..7 = C4..C5 (the C major scale).
class KeyInfo {
  const KeyInfo(this.color, this.letter, this.solfa, this.animal);
  final Color color;
  final String letter;
  final String solfa;
  final String animal;
}

const keyInfo = <KeyInfo>[
  KeyInfo(Color(0xFFFF4F6D), 'C', 'Do', '🐱'),
  KeyInfo(Color(0xFFFF8A3D), 'D', 'Re', '🐶'),
  KeyInfo(Color(0xFFFFD23F), 'E', 'Mi', '🐥'),
  KeyInfo(Color(0xFF4CD964), 'F', 'Fa', '🐸'),
  KeyInfo(Color(0xFF2ED1C4), 'G', 'So', '🐳'),
  KeyInfo(Color(0xFF3D8BFF), 'A', 'La', '🐧'),
  KeyInfo(Color(0xFF9B5CFF), 'B', 'Ti', '🦄'),
  KeyInfo(Color(0xFFFF5CC8), 'C', 'Do', '🐷'),
];

enum PlayMode {
  piano('🎹', 'Piano'),
  drums('🥁', 'Drums'),
  silly('😜', 'Silly'),
  songs('🎵', 'Songs'),
  find('⭐', 'Find it');

  const PlayMode(this.emoji, this.label);
  final String emoji;
  final String label;
}

enum Instrument {
  piano('piano', '🎹', 'Piano'),
  xylo('xylo', '🌈', 'Xylophone'),
  box('box', '🎁', 'Music box'),
  space('space', '🚀', 'Space');

  const Instrument(this.file, this.emoji, this.label);
  final String file;
  final String emoji;
  final String label;

  String sound(int key) => '${file}_$key';
}

/// A key face for the drum and silly modes.
class Pad {
  const Pad(this.sound, this.emoji, this.word);
  final String sound;
  final String emoji;
  final String word;
}

/// Ordered so the 5-key layout gets the best five.
const drumPads = <Pad>[
  Pad('drum_kick', '🥁', 'Boom'),
  Pad('drum_clap', '👏', 'Clap'),
  Pad('drum_snare', '⚡', 'Tap'),
  Pad('drum_hat', '✨', 'Tss'),
  Pad('drum_crash', '💥', 'Crash'),
  Pad('drum_tomlow', '🐘', 'Dum'),
  Pad('drum_tomhigh', '🐭', 'Tik'),
  Pad('drum_bell', '🔔', 'Ding'),
];

const sillyPads = <Pad>[
  Pad('silly_boing', '🐙', 'Boing'),
  Pad('silly_pop', '🎈', 'Pop'),
  Pad('silly_quack', '🦆', 'Quack'),
  Pad('silly_zap', '🚀', 'Zap'),
  Pad('silly_bubbles', '🐠', 'Blub'),
  Pad('silly_up', '🐦', 'Wheee'),
  Pad('silly_down', '🍌', 'Whooo'),
  Pad('silly_trill', '🐒', 'Tickle'),
];

const cheerSound = 'cheer';
const fanfareSound = 'fanfare';

/// Every sound file in assets/sounds/ (without .wav).
List<String> get allSounds => [
  for (final i in Instrument.values)
    for (var k = 0; k < keyInfo.length; k++) i.sound(k),
  for (final p in drumPads) p.sound,
  for (final p in sillyPads) p.sound,
  cheerSound,
  fanfareSound,
];

class SongNote {
  const SongNote(this.key, this.beats);
  final int key;
  final double beats;
}

class Song {
  Song(this.emoji, this.name, this.beatSeconds, String score) : notes = parseScore(score);
  final String emoji;
  final String name;
  final double beatSeconds;
  final List<SongNote> notes;
}

/// "4:1.5 5:.5 4" → key 4 for 1.5 beats, key 5 for half a beat, key 4 for one beat.
List<SongNote> parseScore(String score) => [
  for (final t in score.trim().split(RegExp(r'\s+')))
    if (t.contains(':'))
      SongNote(int.parse(t.split(':')[0]), double.parse(t.split(':')[1]))
    else
      SongNote(int.parse(t), 1),
];

/// Traditional nursery tunes (public domain), in C major on keys 0..7.
final songs = <Song>[
  Song('⭐', 'Twinkle Star', 0.45,
      '0 0 4 4 5 5 4:2 3 3 2 2 1 1 0:2 4 4 3 3 2 2 1:2 4 4 3 3 2 2 1:2 0 0 4 4 5 5 4:2 3 3 2 2 1 1 0:2'),
  Song('🐑', 'Little Lamb', 0.4, '2:1.5 1:.5 0 1 2 2 2:2 1 1 1:2 2 4 4:2 2:1.5 1:.5 0 1 2 2 2 2 1 1 2 1 0:4'),
  Song('🚣', 'Row Your Boat', 0.42,
      '0:1.5 0:1.5 0 1:.5 2:1.5 2 1:.5 2 3:.5 4:3 7:.5 7:.5 7:.5 4:.5 4:.5 4:.5 2:.5 2:.5 2:.5 0:.5 0:.5 0:.5 4 3:.5 2 1:.5 0:3'),
  Song('🐮', 'Old MacDonald', 0.4, '3 3 3 0 1 1 0:2 5 5 4 4 3:3 0 3 3 3 0 1 1 0:2 5 5 4 4 3:4'),
  Song('🥖', 'Hot Cross Buns', 0.45, '2 1 0:2 2 1 0:2 0:.5 0:.5 0:.5 0:.5 1:.5 1:.5 1:.5 1:.5 2 1 0:2'),
  Song('🌉', 'London Bridge', 0.4, '4:1.5 5:.5 4 3 2 3 4:2 1 2 3:2 2 3 4:2 4:1.5 5:.5 4 3 2 3 4:2 1 4 2 0:2'),
];
