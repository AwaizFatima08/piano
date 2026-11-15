# AdMob — Rainbow Keys

AdMob account: **homilabs.smc@gmail.com** (publisher `pub-2087846699268567`), same as the other HomiLabs apps.

| What | ID |
|---|---|
| App (Android) | not created yet |
| Banner `rainbowkeys_grownups_banner` | not created yet |

Until they exist, debug builds use Google's test ids and a plain release build is ad-free.
Put the real ids in `.secrets/ad-units.env` (copy the `.example`); `scripts/build_release.sh` refuses test ids.

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
1. Create the AdMob app + banner unit (needs Homi's OK), fill `.secrets/ad-units.env`.
2. After the Play listing is live: AdMob → app → **Add store**.
