import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../core/settings.dart';

/// Light show state: key glows, the bulb strip, the soft background glow and
/// particles (stars, hearts, notes, confetti).
///
/// Flashes are fades, never hard on/off strobes, and the background glow is
/// faint even in Party mode, to stay gentle on young eyes. The ticker only
/// runs while something is moving.
class Fx extends ChangeNotifier {
  Fx(TickerProvider vsync) {
    _ticker = vsync.createTicker(_tick);
    _chaseTimer = Timer.periodic(const Duration(milliseconds: 480), (_) {
      if (level == LightsLevel.calm) return;
      chase++;
      notifyListeners();
    });
  }

  late final Ticker _ticker;
  late final Timer _chaseTimer;
  final _rng = math.Random();

  LightsLevel level = LightsLevel.party;

  final keyGlow = List<double>.filled(8, 0);
  final keyBounce = List<double>.filled(8, 0);

  int _bulbs = 0;
  List<double> bulbGlow = [];
  List<Color> bulbColor = [];
  int chase = 0;

  Color bgColor = const Color(0x00000000);
  double bgGlow = 0;
  Offset bgCenter = Offset.zero;

  final particles = <Particle>[];
  final _ripples = <_Ripple>[];
  double _now = 0;
  Duration _last = Duration.zero;

  int get bulbCount => _bulbs;

  void setBulbCount(int n) {
    if (n == _bulbs) return;
    _bulbs = n;
    bulbGlow = List.filled(n, 0);
    bulbColor = List.filled(n, const Color(0xFFFFFFFF));
  }

  /// A key was played. [origin] is where particles start (screen coordinates),
  /// [across] the key's position from 0 (left) to 1 (right).
  void hit(int key, Color color, Offset origin, double across) {
    keyGlow[key] = 1;
    keyBounce[key] = 1;
    if (_bulbs > 0) {
      final c = (across * (_bulbs - 1)).round();
      final reach = switch (level) {
        LightsLevel.party => _bulbs,
        LightsLevel.gentle => 2,
        LightsLevel.calm => 0,
      };
      for (var j = 0; j < _bulbs; j++) {
        final d = (j - c).abs();
        if (d <= reach) _ripples.add(_Ripple(_now + d * 0.04, j, color));
      }
    }
    if (level != LightsLevel.calm) {
      bgColor = color;
      bgCenter = origin;
      bgGlow = level == LightsLevel.party ? 0.32 : 0.12;
    }
    final n = switch (level) {
      LightsLevel.party => 12,
      LightsLevel.gentle => 5,
      LightsLevel.calm => 0,
    };
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + (_rng.nextDouble() - 0.5) * 1.6;
      final speed = 260 + _rng.nextDouble() * 320;
      particles.add(Particle(
        pos: origin,
        vel: Offset(math.cos(a), math.sin(a)) * speed,
        life: 0.9 + _rng.nextDouble() * 0.5,
        size: 10 + _rng.nextDouble() * 12,
        color: _rng.nextBool() ? color : _sparkleColors[_rng.nextInt(_sparkleColors.length)],
        shape: ParticleShape.values[_rng.nextInt(4)],
        spin: (_rng.nextDouble() - 0.5) * 6,
      ));
    }
    _start();
  }

  /// A ring of stars, for finding the shining key.
  void sparkle(Offset center, Color color) {
    final n = level == LightsLevel.calm ? 6 : 16;
    for (var i = 0; i < n; i++) {
      final a = i / n * 2 * math.pi;
      particles.add(Particle(
        pos: center,
        vel: Offset(math.cos(a), math.sin(a)) * 220,
        life: 1.0,
        size: 16,
        color: i.isEven ? color : const Color(0xFFFFE45C),
        shape: ParticleShape.star,
        spin: 2,
        gravity: 0,
      ));
    }
    _start();
  }

  /// Confetti falling over the whole screen.
  void confetti(Size size) {
    final n = switch (level) {
      LightsLevel.party => 120,
      LightsLevel.gentle => 50,
      LightsLevel.calm => 24,
    };
    for (var i = 0; i < n; i++) {
      particles.add(Particle(
        pos: Offset(_rng.nextDouble() * size.width, -20 - _rng.nextDouble() * size.height * 0.5),
        vel: Offset((_rng.nextDouble() - 0.5) * 80, 140 + _rng.nextDouble() * 160),
        life: 3.2,
        size: 8 + _rng.nextDouble() * 8,
        color: _sparkleColors[_rng.nextInt(_sparkleColors.length)],
        shape: _rng.nextInt(3) == 0 ? ParticleShape.star : ParticleShape.square,
        spin: (_rng.nextDouble() - 0.5) * 8,
        gravity: 30,
        sway: 1,
      ));
    }
    _start();
  }

  void _start() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero ? 1 / 60 : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    _now += dt;

    var busy = false;
    for (var i = 0; i < 8; i++) {
      keyGlow[i] = math.max(0, keyGlow[i] - dt * 2.0);
      keyBounce[i] = math.max(0, keyBounce[i] - dt * 2.8);
      busy |= keyGlow[i] > 0 || keyBounce[i] > 0;
    }
    for (var j = 0; j < _bulbs; j++) {
      bulbGlow[j] = math.max(0, bulbGlow[j] - dt * 1.7);
      busy |= bulbGlow[j] > 0;
    }
    _ripples.removeWhere((r) {
      if (r.due > _now || r.bulb >= _bulbs) return r.bulb >= _bulbs;
      bulbGlow[r.bulb] = 1;
      bulbColor[r.bulb] = r.color;
      return true;
    });
    busy |= _ripples.isNotEmpty;
    bgGlow = math.max(0, bgGlow - dt * 0.55);
    busy |= bgGlow > 0;

    for (final p in particles) {
      p.age += dt;
      p.vel = Offset(p.vel.dx + (p.sway > 0 ? math.sin(p.age * 3 + p.size) * 40 * dt : 0), p.vel.dy + p.gravity * 10 * dt);
      p.pos += p.vel * dt;
      p.rot += p.spin * dt;
    }
    particles.removeWhere((p) => p.age >= p.life);
    busy |= particles.isNotEmpty;

    notifyListeners();
    if (!busy) _ticker.stop();
  }

  @override
  void dispose() {
    _chaseTimer.cancel();
    _ticker.dispose();
    super.dispose();
  }
}

const _sparkleColors = [
  Color(0xFFFFE45C),
  Color(0xFFFFFFFF),
  Color(0xFFFF5FD2),
  Color(0xFF4FD8FF),
  Color(0xFF7CFF6B),
  Color(0xFFFF8A3D),
];

class _Ripple {
  _Ripple(this.due, this.bulb, this.color);
  final double due;
  final int bulb;
  final Color color;
}

enum ParticleShape { star, circle, heart, note, square }

class Particle {
  Particle({
    required this.pos,
    required this.vel,
    required this.life,
    required this.size,
    required this.color,
    required this.shape,
    this.spin = 0,
    this.gravity = 60,
    this.sway = 0,
  });

  Offset pos;
  Offset vel;
  final double life;
  final double size;
  final Color color;
  final ParticleShape shape;
  final double spin;
  final double gravity;
  final double sway;
  double age = 0;
  double rot = 0;
}

/// Background glow + particles, drawn above the keys (ignores touches).
class FxPainter extends CustomPainter {
  FxPainter(this.fx) : super(repaint: fx);
  final Fx fx;

  @override
  void paint(Canvas canvas, Size size) {
    if (fx.bgGlow > 0) {
      final r = size.longestSide * 0.6;
      canvas.drawCircle(
        fx.bgCenter,
        r,
        Paint()
          ..shader = RadialGradient(colors: [
            fx.bgColor.withValues(alpha: fx.bgGlow),
            fx.bgColor.withValues(alpha: 0),
          ]).createShader(Rect.fromCircle(center: fx.bgCenter, radius: r)),
      );
    }
    for (final p in fx.particles) {
      final fade = (1 - p.age / p.life).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(p.pos.dx, p.pos.dy);
      canvas.rotate(p.rot);
      switch (p.shape) {
        case ParticleShape.star:
          canvas.drawPath(_star(p.size / 2), paint);
        case ParticleShape.circle:
          canvas.drawCircle(Offset.zero, p.size / 3, paint);
        case ParticleShape.heart:
          canvas.drawPath(_heart(p.size / 2), paint);
        case ParticleShape.note:
          _note(canvas, p.size, paint);
        case ParticleShape.square:
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
                const Radius.circular(2)),
            paint,
          );
      }
      canvas.restore();
    }
  }

  static Path _star(double r) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rad = i.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + i * math.pi / 5;
      final pt = Offset(math.cos(a) * rad, math.sin(a) * rad);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    return path..close();
  }

  static Path _heart(double r) => Path()
    ..moveTo(0, r * 0.9)
    ..cubicTo(-r * 1.4, -r * 0.1, -r * 0.6, -r * 1.2, 0, -r * 0.4)
    ..cubicTo(r * 0.6, -r * 1.2, r * 1.4, -r * 0.1, 0, r * 0.9)
    ..close();

  static void _note(Canvas canvas, double s, Paint paint) {
    canvas.drawOval(Rect.fromCenter(center: Offset(-s * 0.15, s * 0.3), width: s * 0.5, height: s * 0.38), paint);
    canvas.drawRect(Rect.fromLTWH(s * 0.06, -s * 0.5, s * 0.09, s * 0.8), paint);
    canvas.drawRect(Rect.fromLTWH(s * 0.06, -s * 0.5, s * 0.3, s * 0.1), paint);
  }

  @override
  bool shouldRepaint(FxPainter old) => false;
}

/// The marquee of party bulbs above the keys.
class BulbPainter extends CustomPainter {
  BulbPainter(this.fx) : super(repaint: fx);
  final Fx fx;

  static const rainbow = [
    Color(0xFFFF4F6D),
    Color(0xFFFF8A3D),
    Color(0xFFFFD23F),
    Color(0xFF4CD964),
    Color(0xFF2ED1C4),
    Color(0xFF3D8BFF),
    Color(0xFF9B5CFF),
    Color(0xFFFF5CC8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final n = fx.bulbCount;
    if (n == 0) return;
    final step = size.width / n;
    final r = math.min(step * 0.28, size.height * 0.36);
    final wire = Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final cy = size.height / 2;
    canvas.drawPath(
      Path()
        ..moveTo(0, cy - r)
        ..quadraticBezierTo(size.width / 2, cy + r * 0.2, size.width, cy - r),
      wire,
    );
    for (var j = 0; j < n; j++) {
      final c = Offset(step * (j + 0.5), cy);
      final chaseOn = fx.level != LightsLevel.calm && (j - fx.chase) % 4 == 0;
      final hit = fx.bulbGlow[j];
      final base = rainbow[j % rainbow.length];
      final color = Color.lerp(base, fx.bulbColor[j], hit)!;
      final on = math.max(hit, chaseOn ? 0.55 : 0.0);
      if (on > 0) {
        canvas.drawCircle(
          c,
          r * (1.6 + on),
          Paint()
            ..color = color.withValues(alpha: 0.35 * on)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.8),
        );
      }
      canvas.drawCircle(c, r, Paint()..color = Color.lerp(base.withValues(alpha: 0.35), color, on)!);
      canvas.drawCircle(c - Offset(r * 0.3, r * 0.3), r * 0.3,
          Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.25 + 0.6 * on));
    }
  }

  @override
  bool shouldRepaint(BulbPainter old) => false;
}
