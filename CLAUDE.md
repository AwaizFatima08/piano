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
- Not done: AdMob app + banner unit, upload keystore, Play listing (Families programme, target age ≤5).
