# Rainbow Keys — notes for Claude Code

Flutter Android toddler piano (package `com.homilabs.rainbowkeys`, Dart package `rainbow_keys`). See README.md.

- Root: `/mnt/storage/projects/Tools/piano`. Backup: `bash scripts/backup.sh` → local copies in
  `/mnt/storage/project_backups/Tools/piano_backup/` + push to GitHub `AwaizFatima08/piano` (**PUBLIC** — never
  commit `.secrets/`, keystores or `key.properties`).
- Ads: AdMob homilabs.smc@gmail.com, child-directed, banner on Grown-ups screen only — see `docs/admob.md`.
- Website: slug `rainbowkeys` on tools.homilabs.org (privacy#rainbowkeys, terms#rainbowkeys). Source in `web/`,
  merged into `/mnt/storage/projects/homilabs_tools/site`.
- Emulator: AVD `rainbowkeys_api35` in `/mnt/storage/projects/android-avd`, always through `jobq`.
- Sounds come only from `tools/make_sounds.py`; keep it that way (no samples to license).
- Lights must stay fades, never fast strobes (photosensitive children).

## Status (15 Nov 2026)
- v1.0.0+1 built (debug) and tested on emulator `rainbowkeys_api35` (CPU-only, debug build lags; ANRs there are
  the emulator): all 5 modes, multi-touch hold, autoplay, find-it stars, 5-key layout, parent gate, grown-ups
  screen, child-directed Google **test** banner. Sound playback not heard (emulator runs with -no-audio).
- tools.homilabs.org: card + privacy#rainbowkeys + terms#rainbowkeys live (uploaded over SSH
  `ssh -p 65002 u809141334@145.79.26.208`, root `domains/tools.homilabs.org/public_html`; fetch live pages and run
  `web/add_rainbowkeys.py` on them, never overwrite with the local copy).
- AdMob app + banner created (ids in docs/admob.md and `.secrets/ad-units.env`). Upload key
  `.secrets/rainbowkeys-upload.jks` (password in `android/key.properties`, both gitignored; SHA-256 pinned in
  `scripts/build_release.sh`). **Losing it blocks Play updates** — the local backup copies `.secrets/`.
- Tested on Galaxy Tab S9 FE (Android 16): sound, all modes, gate, grown-ups, test banner. Android 16 ignores
  our landscape request on tablets (targetSdk 36), so the layout must also work in portrait.
- Play Console (Homilabs org account, app id 4971995499261122682): created and **sent for review 15 Nov 2026**
  — production 1.0.0 (1), 178 countries, Music & Audio, target ages 5 and under + 6–8 (Designed for Families),
  Teacher Approved review requested, content rating Everyone / PEGI 3. Answers recorded in `store/listing.md`.
- After approval: AdMob → Rainbow Keys → Add store (Google Play); switch the tools.homilabs.org card from
  "Coming soon" to the Play link.
