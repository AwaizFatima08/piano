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
/// real traffic. Oppo Reno14 F (CPH2743), added 2026-11-09; Galaxy Tab S9 FE
/// (SM-X510), added 2026-11-15.
const testDeviceIds = ['E41E9C57CF74F7488344578B3BD4DB0F', '84F0E2335747328B9CBDB93C0D43F4FB'];

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

  Future<bool>? _attempt;
  bool _consentFailed = false;
  bool _sdkStarted = false;
  bool _canRequest = false;

  /// Completes with whether ads may be requested. If the last start-up could not
  /// reach Google's consent service (offline, or the phone was dozing at launch),
  /// this tries again, so the Grown-ups banner can still appear later.
  Future<bool> get ready {
    if (_consentFailed && !_canRequest) _attempt = null;
    return _attempt ??= _start();
  }

  @override
  bool get enabled => _canRequest;

  @override
  Future<void> init() => ready;

  Future<bool> _start() async {
    _consentFailed = false;
    try {
      if (!AdUnits.anyConfigured) return false; // release build without real ids: stay ad-free
      final done = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(tagForUnderAgeOfConsent: true),
        () async {
          await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
          if (!done.isCompleted) done.complete();
        },
        (error) {
          debugPrint('[ads] consent update failed: ${error.message}');
          _consentFailed = true;
          if (!done.isCompleted) done.complete();
        },
      );
      await done.future.timeout(const Duration(seconds: 20), onTimeout: () {});
      _canRequest = await ConsentInformation.instance.canRequestAds();
      debugPrint('[ads] consent done, canRequestAds=$_canRequest');
      if (!_canRequest || _sdkStarted) return _canRequest;
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          maxAdContentRating: MaxAdContentRating.g,
          ageRestrictedTreatment: AgeRestrictedTreatment.child,
          testDeviceIds: testDeviceIds,
        ),
      );
      final status = await MobileAds.instance.initialize();
      _sdkStarted = true;
      debugPrint('[ads] SDK started: ${status.adapterStatuses.length} adapters');
    } on Object catch (e) {
      debugPrint('[ads] init failed: $e');
      _canRequest = false;
      _consentFailed = true;
    }
    return _canRequest;
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
    if (id == null) return null;
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
          debugPrint('[ads] banner loaded');
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
