# Real Screw Sort

A satisfying screw-removal physics puzzle built with Flutter. Unscrew panels and
watch them **bend, sag and tilt in real time** — plates are soft-body physics
simulations pinned to the board by screws. Remove the top screws first and the
plate's free edge droops at an angle before the whole panel drops.

> 200 levels · real physics · 7 screw mechanics · daily rewards · shop ·
> achievements · no licensed assets (fonts synthesized, SFX synthesized).

## Features

- **Real physics boards** — Position Based Dynamics soft bodies: unscrewing a
  top screw makes the plate sag and tilt around the remaining screws; heavy
  plates smash fragile ones below; plates stack and land on the board lip.
- **7 screw types**: basic, locked (key screw), frozen (clear surroundings),
  color (return to matching slot), hidden (revealed by falling cover plate),
  one-way (cannot be undone), heavy panels with cascading smashes.
- **200 levels**: 30 handcrafted + solver-validated procedurally generated
  levels (deterministic per level id). Every level is guaranteed solvable by a
  BFS solver, and par is the solver's optimal length.
- **Hint & undo** tools, stars (1-3 based on par), coins, daily reward
  calendar, achievements, 8 board themes, 5 screw skins.
- **Monetization-ready abstractions** — `AdsService`, `IapService`,
  `AnalyticsService` are interfaces with in-app demo implementations, so the
  game is fully playable without any SDK. Swap in real AdMob / Billing /
  Firebase behind the same interfaces.

## Play the web demo

The `main` branch auto-deploys to GitHub Pages:
<https://spider-man4u.github.io/Real-Screw-Sort/>

## Build locally

Requires a Flutter SDK (stable channel):

```sh
flutter pub get
flutter create --platforms=android,web .   # first time only
flutter run                                 # on a device/emulator
```

Run the test suite (engine, physics, level system — the physics tests verify
that unscrewing the top bends the plate at an angle):

```sh
flutter test
flutter analyze
```

## GitHub Actions

`.github/workflows/build.yml` on every push/PR:

1. `test` — `flutter analyze` + full test suite.
2. `android` — builds signed release APK + AAB. Set these repo secrets to sign
   with your own keystore; without them the APK is debug-signed (still
   installable):

   ```sh
   # create a keystore once (change the password!)
   keytool -genkeypair -v -keystore upload-keystore.jks \
     -alias upload -keyalg RSA -keysize 2048 -validity 10000
   base64 -w0 upload-keystore.jks   # paste into secret ANDROID_KEYSTORE_B64
   ```

   Secrets: `ANDROID_KEYSTORE_B64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`
   (key alias is `upload`).

3. `web` — builds and deploys the playable demo to GitHub Pages.
4. Pushing a `v*` tag attaches the APK/AAB to a GitHub Release.

## Swapping in real ad / IAP / analytics SDKs

- `lib/services/ads/ads_service.dart` — implement `AdsService` with AdMob;
  `RewardPlacement` maps to your rewarded placements, `showInterstitial`
  already obeys the "never after a failure" rule (it is only called from the
  victory flow).
- `lib/services/iap/iap_service.dart` — implement `IapService` with
  in_app_purchase / Billing; grant coins/boosts via `ProgressStore` exactly
  like `MockIapService` does.
- `lib/services/analytics/analytics_service.dart` — implement with Firebase
  Analytics.
- Wire the real instances in `lib/main.dart`; game code is untouched.

## Project layout

```
lib/
  app.dart                     composition root + routes
  main.dart                    entry point (mock services)
  core/theme/app_theme.dart    palette + Material 3 theme (Baloo2)
  core/storage/prefs.dart      typed SharedPreferences wrapper
  data/levels/                 handcrafted levels, generator, catalog
  data/progress/               coins/stars/achievements/daily rewards
  game/engine/                 rules engine + BFS solver (pure Dart)
  game/physics/                PBD soft bodies, collision, impacts
  game/rendering/              board painter, themes, screw skins
  game/game_controller.dart    wires board + physics + audio + rewards
  game/screens/                splash, home, level select, game, shop, ...
  services/                    ads / iap / analytics abstractions + mocks
  widgets/                     shared buttons, dialogs, coin bar
test/                          engine, physics and level-system tests
tools/                         asset synthesis + gradle signing patch
```

## Credits

- Font: Baloo 2 (OFL) - generated from source and committed as static weights.
- All sound effects are synthesized with the stdlib `wave` module
  (`tools/gen_audio.py`) - no licensed assets.
