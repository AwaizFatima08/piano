import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads.dart';

/// AdMob unit ids. Debug and profile builds use Google's public test units, so
/// testing on a device can never create invalid traffic on the real account.
/// Release builds read the real id from `--dart-define` (scripts/build_release.sh
/// reads them from `.secrets/ad-units.env`); without them a release shows no ads
/// at all, so test ads can never ship.
class AdUnits {
  const AdUnits._();

  static const testBanner = 'ca-app-pub-3940256099942544/6300978111';

  static const _banner = String.fromEnvironment('AD_BANNER_ID');

  static String? get banner => kReleaseMode ? (_banner.isEmpty ? null : _banner) : testBanner;
  static bool get anyConfigured => banner != null;
}

/// HomiLabs test phones (hashed device ids from the SDK's logcat hint). They get
/// labelled test ads even in release builds, so our own testing never counts as
/// real traffic. Oppo Reno14 F (CPH2743), added 2026-11-09.
const testDeviceIds = ['E41E9C57CF74F7488344578B3BD4DB0F'];

/// AdMob behind [AdService], set up for an app whose audience is young children
/// (Google Play Families policy):
/// - every request gets child age treatment (and the consent request is tagged under
///   the age of consent), so
///   Google serves only non-personalised, family-safe ads;
/// - content rated G only;
/// - the Advertising ID permission is removed in AndroidManifest.xml.
/// Google's User Messaging Platform still runs for EEA, UK and Switzerland.
class AdMobAdService implements AdService {
  AdMobAdService();

  final Completer<bool> _ready = Completer<bool>();
  bool _started = false;
  bool _canRequest = false;

  /// Completes with whether ads may be requested, once [init] has finished.
  Future<bool> get ready => _ready.future;

  @override
  bool get enabled => _canRequest;

  @override
  Future<void> init() async {
    if (_started) return;
    _started = true;
    try {
      if (!AdUnits.anyConfigured) return; // release build without real ids: stay ad-free
      final done = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(tagForUnderAgeOfConsent: true),
        () async {
          await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
          if (!done.isCompleted) done.complete();
        },
        (error) {
          debugPrint('[ads] consent update failed: ${error.message}');
          if (!done.isCompleted) done.complete();
        },
      );
      await done.future.timeout(const Duration(seconds: 20), onTimeout: () {});
      _canRequest = await ConsentInformation.instance.canRequestAds();
      if (!_canRequest) return;
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          maxAdContentRating: MaxAdContentRating.g,
          ageRestrictedTreatment: AgeRestrictedTreatment.child,
          testDeviceIds: testDeviceIds,
        ),
      );
      await MobileAds.instance.initialize();
    } on Object catch (e) {
      debugPrint('[ads] init failed: $e');
      _canRequest = false;
    } finally {
      if (!_ready.isCompleted) _ready.complete(_canRequest);
    }
  }

  @override
  Future<bool> get privacyOptionsRequired async {
    try {
      return await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> showPrivacyOptions() async {
    try {
      await ConsentForm.showPrivacyOptionsForm((_) {});
    } on Object catch (e) {
      debugPrint('[ads] privacy options failed: $e');
    }
  }

  @override
  Widget? banner(AdPlacement placement) {
    final id = AdUnits.banner;
    if (id == null || (_ready.isCompleted && !_canRequest)) return null;
    return _BannerSlot(service: this, adUnitId: id);
  }
}

/// Loads an anchored adaptive banner once consent and start-up are done; takes
/// no space until an ad has actually loaded.
class _BannerSlot extends StatefulWidget {
  const _BannerSlot({required this.service, required this.adUnitId});

  final AdMobAdService service;
  final String adUnitId;

  @override
  State<_BannerSlot> createState() => _BannerSlotState();
}

class _BannerSlotState extends State<_BannerSlot> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    unawaited(_load(MediaQuery.sizeOf(context).width.truncate()));
  }

  Future<void> _load(int width) async {
    if (!await widget.service.ready || !mounted) return;
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || size == null) return;
    final ad = BannerAd(
      adUnitId: widget.adUnitId,
      size: size,
      request: const AdRequest(nonPersonalizedAds: true),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (a, e) {
          debugPrint('[ads] banner failed: ${e.message}');
          a.dispose();
          if (identical(_ad, a)) _ad = null;
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
