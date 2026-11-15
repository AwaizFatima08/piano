import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'admob_ad_service.dart';

/// Ad seam (adapted from File Manager). Rainbow Keys is a toddler app, so the
/// only placement is a banner on the Grown-ups screen, which sits behind the
/// parent gate. Never on the play screen, never full-screen ads. See docs/admob.md.
enum AdPlacement {
  grownupsBanner('grownups_banner');

  const AdPlacement(this.id);
  final String id;
}

/// Height of the placeholder banner (AdMob's standard 320x50).
const double bannerHeight = 50;

abstract class AdService {
  /// Chooses the implementation from `--dart-define=RK_ADS=off|placeholder|admob`.
  /// Default: AdMob in release builds (it stays ad-free unless the real unit id
  /// was passed, see scripts/build_release.sh), placeholders in debug/profile.
  /// `admob` in a debug build uses Google's test unit.
  factory AdService.fromEnvironment() {
    const mode = String.fromEnvironment('RK_ADS');
    return switch (mode) {
      'off' => const NoAdService(),
      'admob' => AdMobAdService(),
      'placeholder' => const PlaceholderAdService(),
      _ => kReleaseMode ? AdMobAdService() : const PlaceholderAdService(),
    };
  }

  /// Consent (where required) and SDK start-up. Safe to call more than once;
  /// never throws. Ads stay off until it has finished.
  Future<void> init();

  bool get enabled;

  /// True where the law requires a way to change ad consent (EEA, UK, CH).
  Future<bool> get privacyOptionsRequired;

  Future<void> showPrivacyOptions();

  /// A banner for [placement], or null when there is nothing to show.
  Widget? banner(AdPlacement placement);
}

class NoAdService implements AdService {
  const NoAdService();

  @override
  Future<void> init() async {}

  @override
  bool get enabled => false;

  @override
  Future<bool> get privacyOptionsRequired async => false;

  @override
  Future<void> showPrivacyOptions() async {}

  @override
  Widget? banner(AdPlacement placement) => null;
}

/// A visible stand-in used while developing, so the placement can be checked
/// on a device before any ad network is involved.
class PlaceholderAdService implements AdService {
  const PlaceholderAdService();

  @override
  Future<void> init() async {}

  @override
  bool get enabled => true;

  @override
  Future<bool> get privacyOptionsRequired async => false;

  @override
  Future<void> showPrivacyOptions() async {}

  @override
  Widget? banner(AdPlacement placement) => Container(
    key: Key('ad-banner-${placement.id}'),
    height: bannerHeight,
    width: 320,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: Colors.white10, border: Border.all(color: Colors.white24)),
    child: Text('Ad slot · ${placement.id} · 320×50', style: const TextStyle(color: Colors.white54, fontSize: 12)),
  );
}

/// A banner area. Collapses to nothing when ads are off or no ad has loaded,
/// so the screen never shows an empty bar.
class AdBannerSlot extends StatelessWidget {
  const AdBannerSlot({super.key, required this.ads, required this.placement});
  final AdService ads;
  final AdPlacement placement;

  @override
  Widget build(BuildContext context) {
    final b = ads.banner(placement);
    if (b == null) return const SizedBox.shrink();
    return SizedBox(width: double.infinity, child: Center(child: b));
  }
}
