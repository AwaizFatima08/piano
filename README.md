# Rainbow Keys — toddler piano (HomiLabs)

A bright, flashing piano for toddlers. Flutter, Android (landscape). No login, no accounts, no data leaves
the phone. Package `com.homilabs.rainbowkeys`.

## What it does
- **5 modes** (round buttons, top left):
  - 🎹 **Piano** — 8 rainbow keys (C4–C5) with an animal on each; instruments: piano, xylophone, music box, space.
  - 🥁 **Drums** — boom, clap, tap, tss, crash, toms, bell.
  - 😜 **Silly** — boing, pop, quack, zap, bubbles, whistles, tickle.
  - 🎵 **Songs** — any key plays the next note of a nursery tune (Twinkle Star, Little Lamb, Row Your Boat,
    Old MacDonald, Hot Cross Buns, London Bridge); the song's own key lights up. "Play for me" plays it alone.
  - ⭐ **Find it** — one key shines; pressing it gives a star; five stars give a confetti party. No "wrong" sound.
- **Lights**: every key has its own bulb and glows; a strip of party bulbs chases and ripples out from the key
  you press; stars, hearts and notes fly up; a soft colour glow fills the screen. Lights fade rather than strobe.
- **Sound adjuster**: speaker button (mute) and a big volume slider; grown-ups set the loudest volume allowed.
- Many fingers at once; sliding across the keys plays each key. A keyboard (A–K or 1–8) also plays.
- **Grown-ups** (hold ⚙️ for one second, then answer a sum): loudest volume, 5 or 8 keys, labels
  (animals / C D E / Do Re Mi / colours only), lights (Party / Gentle / Calm), hide mode buttons, keep screen on,
  privacy policy, terms. The only ad (a banner) is on this screen.

## Sounds
All sounds are synthesized by `tools/make_sounds.py` (numpy) into `assets/sounds/*.wav` — no samples, nothing
to license or attribute. Re-run it after changing a sound. Playback: `flutter_soloud` (low latency, 24 voices).

## Ads (AdMob, account homilabs.smc@gmail.com)
See `docs/admob.md`. Child-directed: `AgeRestrictedTreatment.child`, under-age-of-consent UMP tag, G rating,
non-personalised requests, Advertising ID permission removed. Banner on the Grown-ups screen only.

## Commands
```bash
python3 tools/make_sounds.py                       # regenerate sounds
flutter analyze && flutter test
jobq run --name rainbowkeys-apk -- flutter build apk --debug
bash scripts/build_release.sh                       # real ads; needs .secrets/ad-units.env + upload key
bash scripts/backup.sh                              # local copy + GitHub push
```

## Code map
- `lib/core/music.dart` — keys, modes, instruments, pads, songs (pure data)
- `lib/core/play_logic.dart` — rules of each mode (tested in `test/play_logic_test.dart`)
- `lib/core/settings.dart` — saved settings; `lib/core/sound_engine.dart` — SoLoud playback
- `lib/features/play/` — play screen, keyboard (multi-touch), `fx.dart` (lights, particles)
- `lib/features/grownups/` — parent gate and settings screen
- `lib/ads/` — ad seam (`RK_ADS=off|placeholder|admob`)
- `web/` — card, privacy and terms sections for tools.homilabs.org (slug `rainbowkeys`)
