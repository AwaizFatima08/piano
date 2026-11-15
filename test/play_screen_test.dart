import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_keys/ads/ads.dart';
import 'package:rainbow_keys/app/services.dart';
import 'package:rainbow_keys/core/music.dart';
import 'package:rainbow_keys/core/sound_engine.dart';
import 'package:rainbow_keys/main.dart';

void main() {
  testWidgets('tapping a key plays it; modes switch; gear needs a hold', (tester) async {
    tester.view.physicalSize = const Size(2400, 1080);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final sound = RecordingSoundEngine();
    final services = Services(settings: Settings.memory(), sound: sound, ads: const NoAdService());
    await tester.pumpWidget(RainbowKeysApp(services: services));

    final kb = find.byType(Listener).last;
    final box = tester.getRect(find.byKey(const Key('mode-piano')));
    expect(box.isEmpty, isFalse);

    await tester.tap(find.text('🐱'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(sound.played, ['piano_0']);
    expect(kb, findsOneWidget);

    await tester.tap(find.byKey(const Key('mode-drums')));
    await tester.pump();
    expect(services.settings.mode, PlayMode.drums);
    await tester.tap(find.text('🥁').last);
    await tester.pump(const Duration(milliseconds: 100));
    expect(sound.played.last, 'drum_kick');

    // a quick tap on the gear does not open the grown-ups area
    await tester.tap(find.byKey(const Key('gear')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('parent-gate')), findsNothing);
    await tester.pump(const Duration(seconds: 3));

    // a one-second hold shows the parent gate
    final g = await tester.startGesture(tester.getCenter(find.byKey(const Key('gear'))));
    await tester.pump(const Duration(milliseconds: 1100));
    await g.up();
    await tester.pump(const Duration(milliseconds: 400)); // no pumpAndSettle: the glow pulse loops forever
    expect(find.byKey(const Key('parent-gate')), findsOneWidget);
    await tester.tap(find.text('Back to playing'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('parent-gate')), findsNothing);
  });
}
