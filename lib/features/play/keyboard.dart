import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'fx.dart';

/// What one key shows.
class KeyFace {
  const KeyFace({required this.color, required this.emoji, required this.label});
  final Color color;
  final String? emoji;
  final String? label;
}

/// The row of big candy keys. Many fingers at once, and sliding a finger
/// across the keys plays each one it reaches (a glissando).
class Keyboard extends StatefulWidget {
  const Keyboard({
    super.key,
    required this.faces,
    required this.fx,
    required this.pulse,
    required this.onPress,
    this.hintKey,
    this.targetKey,
  });

  final List<KeyFace> faces;
  final Fx fx;

  /// 0..1 repeating, for the glowing hint/target key.
  final Animation<double> pulse;
  final ValueChanged<int> onPress;
  final int? hintKey;
  final int? targetKey;

  @override
  State<Keyboard> createState() => KeyboardState();
}

class KeyboardState extends State<Keyboard> {
  final _pointers = <int, int>{};
  final _held = List<int>.filled(8, 0);

  static const gap = 10.0;

  int _keyAt(Offset local, double width) {
    final n = widget.faces.length;
    return (local.dx / width * n).floor().clamp(0, n - 1);
  }

  void _down(int pointer, int key) {
    _pointers[pointer] = key;
    setState(() => _held[key]++);
    widget.onPress(key);
  }

  void _up(int pointer) {
    final key = _pointers.remove(pointer);
    if (key != null) setState(() => _held[key] = math.max(0, _held[key] - 1));
  }

  /// Hardware keyboard: hold [key] down / let it go.
  void holdKey(int key, bool down) {
    if (key >= widget.faces.length) return;
    if (down) {
      _down(-1000 - key, key);
    } else {
      _up(-1000 - key);
    }
  }

  /// Where key [i] sits inside this widget (for particles and the glow).
  Rect keyRect(int i, Size size) {
    final w = size.width / widget.faces.length;
    return Rect.fromLTWH(w * i + gap / 2, 0, w - gap, size.height);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) => _down(e.pointer, _keyAt(e.localPosition, box.maxWidth)),
        onPointerMove: (e) {
          final prev = _pointers[e.pointer];
          if (prev == null) return;
          final now = _keyAt(e.localPosition, box.maxWidth);
          if (now == prev) return;
          _up(e.pointer);
          _down(e.pointer, now);
        },
        onPointerUp: (e) => _up(e.pointer),
        onPointerCancel: (e) => _up(e.pointer),
        child: AnimatedBuilder(
          animation: Listenable.merge([widget.fx, widget.pulse]),
          builder: (context, _) => Row(
            children: [
              for (var i = 0; i < widget.faces.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: gap / 2),
                    child: _CandyKey(
                      face: widget.faces[i],
                      down: _held[i] > 0,
                      glow: widget.fx.keyGlow[i],
                      bounce: widget.fx.keyBounce[i],
                      highlight: i == widget.targetKey
                          ? 1.0
                          : i == widget.hintKey
                          ? 0.45
                          : 0.0,
                      pointing: i == widget.targetKey,
                      pulse: widget.pulse.value,
                      fewKeys: widget.faces.length <= 5,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CandyKey extends StatelessWidget {
  const _CandyKey({
    required this.face,
    required this.down,
    required this.glow,
    required this.bounce,
    required this.highlight,
    required this.pointing,
    required this.pulse,
    required this.fewKeys,
  });

  final KeyFace face;
  final bool down;
  final double glow;
  final double bounce;
  final double highlight;
  final bool pointing;
  final double pulse;
  final bool fewKeys;

  @override
  Widget build(BuildContext context) {
    final c = face.color;
    final dark = Color.lerp(c, Colors.black, 0.38)!;
    final light = Color.lerp(c, Colors.white, 0.45)!;
    final wave = 0.5 + 0.5 * math.sin(pulse * 2 * math.pi);
    final lit = math.max(glow, down ? 0.8 : 0.0);
    final ring = highlight * (0.55 + 0.45 * wave);
    // Bounce: quick grow then settle.
    final b = bounce > 0 ? math.sin((1 - bounce) * math.pi) * bounce : 0.0;

    return LayoutBuilder(
      builder: (context, box) {
        final depth = math.min(12.0, box.maxHeight * 0.04);
        final press = down ? depth * 0.75 : 0.0;
        final emojiSize = math.min(box.maxWidth * (fewKeys ? 0.62 : 0.66), box.maxHeight * 0.3);
        // Portrait tablets (Android 16 ignores our landscape request on large
        // screens) give very tall keys: lift the animal towards the middle.
        final tall = box.maxHeight > box.maxWidth * 3;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // the darker "side" of the key that gives it depth
            Positioned.fill(
              top: depth,
              child: DecoratedBox(
                decoration: BoxDecoration(color: dark, borderRadius: BorderRadius.circular(26)),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: press,
              bottom: depth - press,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(light, Colors.white, lit * 0.5)!,
                      Color.lerp(c, Colors.white, lit * 0.25)!,
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: math.max(0.18, ring)),
                    width: 2 + ring * 4,
                  ),
                  boxShadow: [
                    if (lit > 0 || ring > 0)
                      BoxShadow(
                        color: c.withValues(alpha: 0.85 * math.max(lit, ring * 0.8)),
                        blurRadius: 18 + 28 * math.max(lit, ring),
                        spreadRadius: 2 + 6 * math.max(lit, ring),
                      ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(height: box.maxHeight * 0.06),
                    // the key's own light bulb
                    Container(
                      width: emojiSize * 0.32,
                      height: emojiSize * 0.32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.lerp(Colors.white.withValues(alpha: 0.35), Colors.white, math.max(lit, ring)),
                        boxShadow: [
                          if (lit > 0 || ring > 0)
                            BoxShadow(color: Colors.white.withValues(alpha: math.max(lit, ring)), blurRadius: 16, spreadRadius: 2),
                        ],
                      ),
                    ),
                    if (pointing)
                      Transform.translate(
                        offset: Offset(0, 6 * wave),
                        child: Text('👇', style: TextStyle(fontSize: emojiSize * 0.45)),
                      ),
                    Spacer(flex: tall ? 3 : 1),
                    if (face.emoji != null)
                      Transform.rotate(
                        angle: b * 0.25,
                        child: Transform.scale(
                          scale: 1 + 0.4 * b,
                          child: Text(face.emoji!, style: TextStyle(fontSize: emojiSize, height: 1.1)),
                        ),
                      ),
                    if (face.label != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: FittedBox(
                          child: Text(
                            face.label!,
                            style: TextStyle(
                              fontSize: math.min(28, emojiSize * 0.42),
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              shadows: [Shadow(color: dark, blurRadius: 0, offset: const Offset(0, 2))],
                            ),
                          ),
                        ),
                      ),
                    if (tall) const Spacer(flex: 2) else SizedBox(height: box.maxHeight * 0.07),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
