import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../app/services.dart';
import '../../core/music.dart';
import '../../core/play_logic.dart';
import '../grownups/grownups_screen.dart';
import '../grownups/parent_gate.dart';
import 'fx.dart';
import 'keyboard.dart';

/// The one screen a toddler sees: mode buttons, volume, the light strip and
/// the keys. Grown-up settings hide behind a press-and-hold gear + parent gate.
class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key, required this.services});
  final Services services;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  late final Settings settings = widget.services.settings;
  late final PlayLogic logic = PlayLogic(settings: settings, sound: widget.services.sound);
  late final Fx fx = Fx(this);
  late final AnimationController pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))
    ..repeat();
  late final AnimationController yay = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900));
  final _stackKey = GlobalKey();
  final _keyboardKey = GlobalKey<KeyboardState>();
  final _focus = FocusNode();
  final _rng = math.Random();
  String _yayEmoji = '🎉';
  late (PlayMode, int, int) _shape = (settings.mode, settings.keyCount, settings.songIndex);

  static const _yayEmojis = ['🎉', '🌟', '🥳', '🏆', '🎈', '🌈'];
  static const _hwKeys = [
    LogicalKeyboardKey.keyA,
    LogicalKeyboardKey.keyS,
    LogicalKeyboardKey.keyD,
    LogicalKeyboardKey.keyF,
    LogicalKeyboardKey.keyG,
    LogicalKeyboardKey.keyH,
    LogicalKeyboardKey.keyJ,
    LogicalKeyboardKey.keyK,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    settings.addListener(_onSettings);
    logic.addListener(_rebuild);
    logic.onAutoNote = _light;
    _onSettings();
    logic.reset();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    settings.removeListener(_onSettings);
    logic.dispose();
    fx.dispose();
    pulse.dispose();
    yay.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) logic.stopAuto();
    if (state == AppLifecycleState.resumed) _applyAwake();
  }

  void _rebuild() => setState(() {});

  void _onSettings() {
    widget.services.sound.volume = settings.effectiveVolume;
    fx.level = settings.lights;
    _applyAwake();
    final shape = (settings.mode, settings.keyCount, settings.songIndex);
    if (shape != _shape) {
      _shape = shape;
      logic.reset();
    }
    if (mounted) setState(() {});
  }

  void _applyAwake() => WakelockPlus.toggle(enable: settings.keepAwake).catchError((_) {});

  // ---------- keys ----------

  List<KeyFace> get _faces => [
    for (var i = 0; i < settings.keyCount; i++) _face(i),
  ];

  KeyFace _face(int i) {
    final k = keyInfo[i];
    switch (settings.mode) {
      case PlayMode.drums:
        return KeyFace(color: k.color, emoji: drumPads[i].emoji, label: drumPads[i].word);
      case PlayMode.silly:
        return KeyFace(color: k.color, emoji: sillyPads[i].emoji, label: sillyPads[i].word);
      case PlayMode.piano || PlayMode.songs || PlayMode.find:
        return switch (settings.labels) {
          KeyLabels.animals => KeyFace(color: k.color, emoji: k.animal, label: null),
          KeyLabels.letters => KeyFace(color: k.color, emoji: k.animal, label: k.letter),
          KeyLabels.solfa => KeyFace(color: k.color, emoji: k.animal, label: k.solfa),
          KeyLabels.colours => KeyFace(color: k.color, emoji: null, label: null),
        };
    }
  }

  void _press(int key) => _light(logic.press(key));

  void _light(PressResult r) {
    for (final k in r.lit) {
      final (origin, across) = _keySpot(k);
      fx.hit(k, keyInfo[k].color, origin, across);
    }
    if (r.reward == Reward.small && r.lit.isNotEmpty) {
      fx.sparkle(_keySpot(r.lit.first).$1, keyInfo[r.lit.first].color);
    } else if (r.reward == Reward.big) {
      _celebrate();
    }
  }

  /// Centre of key [k]'s face in stack coordinates, and how far across it is (0..1).
  (Offset, double) _keySpot(int k) {
    final kb = _keyboardKey.currentContext?.findRenderObject() as RenderBox?;
    final st = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final state = _keyboardKey.currentState;
    if (kb == null || st == null || state == null) return (Offset.zero, 0.5);
    final rect = state.keyRect(k, kb.size);
    final local = Offset(rect.center.dx, rect.top + rect.height * 0.55);
    final pos = st.globalToLocal(kb.localToGlobal(local));
    return (pos, (kb.localToGlobal(local).dx - st.localToGlobal(Offset.zero).dx) / st.size.width);
  }

  void _celebrate() {
    final st = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (st != null) fx.confetti(st.size);
    _yayEmoji = _yayEmojis[_rng.nextInt(_yayEmojis.length)];
    yay.forward(from: 0);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    final i = _hwKeys.indexOf(e.logicalKey);
    final digit = int.tryParse(e.character ?? '');
    final key = i >= 0 ? i : (digit != null && digit >= 1 && digit <= 8 ? digit - 1 : -1);
    if (key < 0 || e is KeyRepeatEvent) return KeyEventResult.ignored;
    _keyboardKey.currentState?.holdKey(key, e is KeyDownEvent);
    return KeyEventResult.handled;
  }

  // ---------- grown-ups ----------

  Future<void> _openGrownups() async {
    logic.stopAuto();
    if (!await showParentGate(context) || !mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => GrownupsScreen(services: widget.services)));
    _focus.requestFocus();
  }

  void _setMode(PlayMode m) {
    if (m == settings.mode) return;
    settings.update((s) => s.mode = m);
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Stack(
          key: _stackKey,
          children: [
            const Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _SkyPainter()))),
            SafeArea(
              child: Column(
                children: [
                  _TopBar(
                    settings: settings,
                    onMode: _setMode,
                    onGearHeld: _openGrownups,
                  ),
                  _SubBar(settings: settings, logic: logic),
                  LayoutBuilder(
                    builder: (context, box) {
                      fx.setBulbCount(math.max(8, (box.maxWidth / 44).round()));
                      return SizedBox(
                        height: 30,
                        width: double.infinity,
                        child: CustomPaint(painter: BulbPainter(fx)),
                      );
                    },
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                      child: Keyboard(
                        key: _keyboardKey,
                        faces: _faces,
                        fx: fx,
                        pulse: pulse,
                        onPress: _press,
                        hintKey: logic.hintKey,
                        targetKey: logic.targetKey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: FxPainter(fx)))),
            Positioned.fill(child: IgnorePointer(child: _Yay(controller: yay, emoji: _yayEmoji))),
          ],
        ),
      ),
    );
  }
}

/// Night-sky background with a few fixed stars.
class _SkyPainter extends CustomPainter {
  const _SkyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A1460), Color(0xFF1A0B3D), Color(0xFF12062E)],
        ).createShader(rect),
    );
    final rng = math.Random(3);
    for (var i = 0; i < 70; i++) {
      final p = Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height);
      canvas.drawCircle(p, 0.6 + rng.nextDouble() * 1.6, Paint()..color = Colors.white.withValues(alpha: 0.15 + rng.nextDouble() * 0.45));
    }
  }

  @override
  bool shouldRepaint(_SkyPainter old) => false;
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.settings, required this.onMode, required this.onGearHeld});
  final Settings settings;
  final ValueChanged<PlayMode> onMode;
  final VoidCallback onGearHeld;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 0),
      child: Row(
        children: [
          if (!settings.hideModes)
            for (final m in PlayMode.values)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _RoundButton(
                  key: Key('mode-${m.name}'),
                  emoji: m.emoji,
                  label: m.label,
                  active: m == settings.mode,
                  color: keyInfo[m.index * 2 % keyInfo.length].color,
                  onTap: () => onMode(m),
                ),
              )
          else
            const Text('🌈 Rainbow Keys', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const Spacer(),
          _VolumeControl(settings: settings),
          _GearButton(onHeld: onGearHeld),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    super.key,
    required this.emoji,
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic, // no overshoot: an overshooting curve gives the shadow a negative blur
          width: active ? 56 : 48,
          height: active ? 56 : 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? color : Colors.white.withValues(alpha: 0.1),
            border: Border.all(color: Colors.white.withValues(alpha: active ? 0.95 : 0.25), width: active ? 3 : 2),
            boxShadow: [if (active) BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 18, spreadRadius: 1)],
          ),
          child: Text(emoji, style: TextStyle(fontSize: active ? 28 : 24)),
        ),
      ),
    );
  }
}

class _VolumeControl extends StatelessWidget {
  const _VolumeControl({required this.settings});
  final Settings settings;

  @override
  Widget build(BuildContext context) {
    final v = settings.volume.clamp(0.0, settings.maxVolume);
    final icon = settings.muted || v == 0
        ? '🔇'
        : v < 0.4
        ? '🔈'
        : '🔊';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: settings.muted ? 'Sound off' : 'Sound on',
          child: GestureDetector(
            key: const Key('mute'),
            onTap: () => settings.update((s) => s.muted = !s.muted),
            child: Padding(padding: const EdgeInsets.all(6), child: Text(icon, style: const TextStyle(fontSize: 26))),
          ),
        ),
        SizedBox(
          width: 150,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 12,
              activeTrackColor: const Color(0xFFFFE45C),
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 13),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: Slider(
              key: const Key('volume'),
              value: v,
              max: settings.maxVolume,
              semanticFormatterCallback: (x) => '${(x * 100).round()} percent',
              onChanged: (x) => settings.update((s) {
                s.volume = x;
                s.muted = false;
              }),
            ),
          ),
        ),
      ],
    );
  }
}

/// Opens the grown-ups area only after a one-second hold, so a toddler's taps
/// don't. A quick tap shows how.
class _GearButton extends StatelessWidget {
  const _GearButton({required this.onHeld});
  final VoidCallback onHeld;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Grown-ups: press and hold for settings',
      child: RawGestureDetector(
        gestures: {
          LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            () => LongPressGestureRecognizer(duration: const Duration(seconds: 1)),
            (r) => r.onLongPress = onHeld,
          ),
          TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            TapGestureRecognizer.new,
            (r) => r.onTap = () => ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(
                content: Text('Grown-ups: press and hold ⚙️ for settings'),
                duration: Duration(seconds: 2),
              )),
          ),
        },
        child: const Padding(
          key: Key('gear'),
          padding: EdgeInsets.all(10),
          child: Opacity(opacity: 0.7, child: Text('⚙️', style: TextStyle(fontSize: 24))),
        ),
      ),
    );
  }
}

/// The second row: instruments, songs, or the find-it stars.
class _SubBar extends StatelessWidget {
  const _SubBar({required this.settings, required this.logic});
  final Settings settings;
  final PlayLogic logic;

  @override
  Widget build(BuildContext context) {
    final Widget? child = switch (settings.mode) {
      PlayMode.piano => _chips([
        for (final i in Instrument.values)
          _Chip(
            key: Key('inst-${i.name}'),
            text: '${i.emoji} ${i.label}',
            active: settings.instrument == i,
            onTap: () => settings.update((s) => s.instrument = i),
          ),
      ]),
      PlayMode.songs => Row(
        children: [
          Expanded(
            child: _chips([
              for (var k = 0; k < songs.length; k++)
                _Chip(
                  key: Key('song-$k'),
                  text: '${songs[k].emoji} ${songs[k].name}',
                  active: settings.songIndex == k,
                  onTap: () => settings.update((s) => s.songIndex = k),
                ),
            ]),
          ),
          _Chip(
            key: const Key('autoplay'),
            text: logic.autoPlaying ? '⏹ Stop' : '▶️ Play for me',
            active: logic.autoPlaying,
            onTap: logic.autoPlaying ? logic.stopAuto : logic.startAuto,
          ),
          const SizedBox(width: 12),
        ],
      ),
      PlayMode.find => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Find the shining key!  ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          for (var k = 0; k < 5; k++)
            AnimatedScale(
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              scale: k < logic.found % 5 ? 1.2 : 0.9,
              child: Opacity(
                opacity: k < logic.found % 5 ? 1 : 0.3,
                child: const Text('⭐', style: TextStyle(fontSize: 26)),
              ),
            ),
        ],
      ),
      PlayMode.drums || PlayMode.silly => null,
    };
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: child == null
          ? const SizedBox(width: double.infinity)
          : SizedBox(
              height: 50,
              child: Column(
                children: [
                  Expanded(child: child),
                  if (settings.mode == PlayMode.songs)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: logic.songProgress,
                          minHeight: 5,
                          color: const Color(0xFFFFE45C),
                          backgroundColor: Colors.white12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _chips(List<Widget> chips) => ListView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    children: chips,
  );
}

class _Chip extends StatelessWidget {
  const _Chip({super.key, required this.text, required this.active, required this.onTap});
  final String text;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: active ? const Color(0xFFFFE45C) : Colors.white.withValues(alpha: 0.1),
        shape: StadiumBorder(side: BorderSide(color: Colors.white.withValues(alpha: active ? 0 : 0.2))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: active ? const Color(0xFF2A1460) : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The big "Yay!" after a song or five stars.
class _Yay extends StatelessWidget {
  const _Yay({required this.controller, required this.emoji});
  final AnimationController controller;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        if (t == 0 || t == 1) return const SizedBox.shrink();
        final grow = Curves.elasticOut.transform((t / 0.45).clamp(0.0, 1.0));
        final fade = t < 0.8 ? 1.0 : 1 - (t - 0.8) / 0.2;
        return Center(
          child: Opacity(
            opacity: fade,
            child: Transform.scale(
              scale: 0.3 + 0.7 * grow,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 110)),
                  const Text(
                    'Yay!',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [Shadow(color: Color(0xFFFF5FD2), blurRadius: 24)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
