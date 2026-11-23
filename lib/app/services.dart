import '../ads/ads.dart';
import '../core/settings.dart';
import '../core/sound_engine.dart';

export '../core/settings.dart';

/// App-wide objects, handed down from main() to every screen.
class Services {
  const Services({required this.settings, required this.sound, required this.ads});

  final Settings settings;
  final SoundEngine sound;
  final AdService ads;
}

const kAppVersion = '1.0.1';
const kPrivacyUrl = 'https://tools.homilabs.org/privacy#rainbowkeys';
const kTermsUrl = 'https://tools.homilabs.org/terms#rainbowkeys';
