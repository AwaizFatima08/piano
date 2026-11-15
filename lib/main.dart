import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ads/ads.dart';
import 'app/services.dart';
import 'core/sound_engine.dart';
import 'features/play/play_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // A piano wants to be wide; full screen so little fingers can't hit the system bars as easily.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final services = Services(
    settings: await Settings.load(),
    sound: SoLoudEngine(),
    ads: AdService.fromEnvironment(),
  );
  await services.sound.init();
  services.sound.volume = services.settings.effectiveVolume;
  unawaited(services.ads.init()); // consent + SDK in the background; the piano shows at once
  runApp(RainbowKeysApp(services: services));
}

class RainbowKeysApp extends StatelessWidget {
  const RainbowKeysApp({super.key, required this.services});
  final Services services;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rainbow Keys',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF9B5CFF),
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF1A0B3D),
      ),
      home: PlayScreen(services: services),
    );
  }
}
