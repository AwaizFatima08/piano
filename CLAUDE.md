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
