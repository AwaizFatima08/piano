# AdMob — Rainbow Keys

AdMob account: **homilabs.smc@gmail.com** (publisher `pub-2087846699268567`), same as the other HomiLabs apps.

| What | ID |
|---|---|
| App (Android) "Rainbow Keys: Toddler Piano" | `ca-app-pub-2087846699268567~4983468905` |
| Banner `rainbowkeys_grownups_banner` | `ca-app-pub-2087846699268567/1248063019` |

Created 15 Nov 2026. Debug builds use Google's test ids; the real ids are in `.secrets/ad-units.env` (gitignored)
and reach only builds made with `scripts/build_release.sh`, which refuses test ids. Test devices (labelled test
ads even in release): Oppo Reno14 F, Galaxy Tab S9 FE — see `testDeviceIds` in `lib/ads/admob_ad_service.dart`.

## Rules for a toddler app (Google Play Families policy)
- Only one placement: a **banner on the Grown-ups screen**, behind the hold-the-gear + sum parent gate.
  No ads on the play screen, no interstitials, no rewarded ads.
- Every request: `AgeRestrictedTreatment.child`, max content rating **G**, `nonPersonalizedAds: true`.
  UMP consent request tagged under the age of consent.
- `com.google.android.gms.permission.AD_ID` is removed in the manifest; the release script checks it.
- In AdMob, when creating the app: mark it as **directed to children** (App settings → "Child-directed").
- Play Console: Target audience = ages 5 and under (and possibly 6–8); the app must join the Families
  programme; AdMob is a Families self-certified ad SDK.

## To do
1. After the Play listing is live: AdMob → app → **Add store**.
