# S-01 Hybrid Shell — Spike Findings

| Field | Value |
| --- | --- |
| Spike | S-01 Hybrid Shell ([feasibility review §8](../architecture/TECHNICAL_FEASIBILITY_REVIEW.md#8-proposed-technical-spikes-prioritised)) |
| Approval | Approved by the product owner, time-box 1–2 days |
| Date | 2026-11-23 |
| Branch | `spike/s01-hybrid-shell` (throwaway; not for merge as production code) |
| Code | [`spikes/s01_hybrid_shell/`](../../spikes/s01_hybrid_shell/) |
| Status | **Complete, with one gap:** no Android device or emulator was available, so Android runtime behaviour and Android performance were **not measured** (§10) |

**How to read this document.** Every finding is labelled:

| Label | Meaning |
| --- | --- |
| **[Measured]** | Produced by a command or test run in this spike; the result is quoted |
| **[Observed]** | Seen in code, logs or screenshots; not a numeric measurement |
| **[Recommendation]** | A proposal. It approves nothing: TD-03, TD-04 and TD-05 remain **Pending** until an ADR is approved |

---

## 1. Objective and Scope

Validate that Flutter, Flame and Riverpod work together in the proposed hybrid architecture before production development starts, and gather evidence for TD-03 (bridge), TD-04 (repository layout) and TD-05 (code generation).

**In scope:**
- A portrait Flutter shell with a header, a Flame `GameWidget`, a Flutter overlay and controls.
- A minimal Flame scene: background, an animated placeholder orb, and running status.
- Two-way communication through Riverpod.
- Lifecycle handling.
- A pure-Dart placeholder `puzzle_domain` package.
- Frame-timing tooling that implements the §8.1 protocol.

**Out of scope, and not built:** puzzle board, partition generation, dragging, snapping, tray, persistence, Firebase, Rive, audio, production navigation. S-02 to S-07 were not started.

---

## 2. Environment and Versions

| Item | Version / value | Source |
| --- | --- | --- |
| Flutter | 3.50.1 stable (framework `ae9b586f34`, engine `4d35714800`) | `flutter --version` |
| Dart | 3.14.0 | `flutter --version` |
| `flame` | 1.38.2 | `pubspec.lock` |
| `flutter_riverpod` / `riverpod` | 3.5.0 / 3.5.0 | `pubspec.lock` |
| `flame_riverpod` (TD-03 comparison only) | 5.5.5 | `pubspec.lock` |
| `material_ui` | 1.11.1 | `pubspec.lock` (§11, P-01) |
| Android Gradle Plugin / Kotlin / Gradle | 9.3.1 / 2.4.20 / 9.5.0 | Flutter 3.50.1 template |
| Android SDK | platform 36, build-tools 36.0.0 | `sdkmanager` |
| APK SDK levels | `minSdkVersion 24`, `targetSdkVersion 36` | `aapt2 dump badging` |
| Java | OpenJDK 21.0.13 | `flutter doctor -v` |
| Host | Linux container, 4 vCPU (Intel Xeon), 15 GB RAM, **no `/dev/kvm`** | `nproc`, `free`, `ls /dev/kvm` |
| Browser used for manual verification | Chrome for Testing 153 (headless, via Playwright) | `flutter doctor` |

The SDK values are Flutter's project defaults. They are **not** product decisions (Q-013, TD-06).

---

## 3. Implemented Architecture

```
spikes/s01_hybrid_shell/
  pubspec.yaml                  pub workspace root → single pubspec.lock
  app/                          Flutter app (Android + web)
    lib/main.dart               ProviderScope, portrait lock
    lib/state/shell_state.dart  ShellState + hand-written Notifier (Riverpod)
    lib/game/game_bridge.dart   Manual bridge contract (TD-03 option 1)
    lib/game/shell_game.dart    Flame game for the manual bridge (no Riverpod import)
    lib/game/riverpod_shell_game.dart  Same scene via flame_riverpod (option 2)
    lib/game/components.dart    Shared Flame components (backdrop, orb, status)
    lib/ui/shell_screen.dart    Header, GameWidget, overlay, controls, lifecycle
    lib/perf/                   FrameTiming collection and §8.1 statistics
  packages/puzzle_domain/       Pure Dart: GridSize, GridCell (+ tests)
  tool/check_domain_boundary.sh Boundary guard
  tool/test_check_domain_boundary.sh  Positive and negative tests for the guard
```

- **Flutter** owns the application UI: the header, the controls and the overlay, which is a widget in a `Stack` above the `GameWidget`.
- **Riverpod** owns the application state, in one hand-written `Notifier`.
- **Flame** renders the scene and emits intents. In the manual variant, the Flame game has no import of Riverpod.
- **`puzzle_domain`** is called from the application state: the tap count is mapped to a 4×4 grid cell. It is never called from Flame.
- The bridge is selected at build time: `--dart-define=S01_BRIDGE=flame_riverpod`, with `manual` as the default.

---

## 4. Communication Flows

**Flutter → Riverpod → Flame**

1. **Change colour** calls `ShellController.cycleColor()`, which updates the state.
2. The game is updated in one of two ways:
   - **Manual bridge:** `ShellScreen` uses `ref.listen(select(colorIndex))` and calls `ShellGameView.showColor()`.
   - **flame_riverpod:** the orb component's `ref.listen` sets its colour.
3. The orb changes colour.

**Flame → Riverpod → Flutter**

1. Tapping the orb fires the orb's `onTapUp`. It then reaches the state in one of two ways:
   - **Manual bridge:** the orb calls `ShellGameIntents.onOrbTapped`, which is `ShellController.recordGameTap`.
   - **flame_riverpod:** the orb calls `ref.read(...notifier).recordGameTap()`.
2. The state updates, and the header shows the tap count and the domain grid cell.

| Check | Result |
| --- | --- |
| Flutter → Flame, both bridges | **[Measured]** Widget test passes. **[Observed]** In the browser, orange → blue after **Change colour** |
| Flame → Flutter, both bridges | **[Measured]** Widget test passes (2 taps → count 2, domain cell 0,2). **[Observed]** In the browser, 3 of 3 orb taps counted |
| Domain package used by the app layer | **[Measured]** The tap count maps to a grid cell through `GridSize.cellAt` (asserted in the test) |

---

## 5. Overlay and Lifecycle Findings

### Overlay

| Check | Result |
| --- | --- |
| Show / hide | **[Measured]** Widget tests pass for both bridges. **[Observed]** Browser screenshots confirm |
| Game stays mounted | **[Measured]** Same game instance and a single `GameWidget` before, during and after the overlay; the game clock keeps advancing |
| Game usable beneath the overlay | **[Measured]** An orb tap counts while the overlay is visible. **[Observed]** The same in the browser |
| Overlay controls use Riverpod | **[Measured]** The overlay's **Colour** button changes the orb |

**[Observed]** The overlay is a Flutter `Stack` child above the `GameWidget`, driven by Riverpod state, rather than Flame's `overlays` API. Either works. The Riverpod-driven version keeps overlay visibility in application state, where a future reveal or reward flow would trigger it.

### Lifecycle

| Check | Result |
| --- | --- |
| Pause/resume received, no duplicates | **[Measured]** Widget test, both bridges: the transitions inactive → hidden → paused produce exactly **1** pause, and the reverse produces exactly **1** resume, after 6 forced rebuilds; listener count = 1 |
| Lifecycle shown in the app and the game | **[Measured]** The header and the Flame status both show `paused`, then `resumed` |
| Web (browser) | **[Observed]** Hiding and showing the browser tab is reported as `resumed` (resumes 1). Flutter web did **not** report `paused` |
| Android device | **Not verified.** There was no device or emulator (§10) |

**Findings:**
- **[Observed]** `AppLifecycleListener` only reports *changes*, so the initial state must be seeded. The spike reads `WidgetsBinding.instance.lifecycleState` in `Notifier.build`.
- **[Observed]** Neither bridge pushes *initial* values into the game: `WidgetRef.listen` has no fire-immediately option, and the `flame_riverpod` `ref.listen` only fires on change. Both variants need an explicit initial sync, through constructor parameters for the manual bridge or a `ref.read` in `onMount` for `flame_riverpod`.
- **[Observed]** Flame's `GameWidget` separately observes the app lifecycle in order to pause the engine while backgrounded. That is Flame's own observer; the application registers exactly one listener of its own. The lifecycle *policy* for production (what to save and pause, and when) belongs in the application layer, and its interaction with Flame's automatic pause should be confirmed on a device.

---

## 6. Pure-Dart Package Boundary

| Check | Result |
| --- | --- |
| `puzzle_domain` has no Flutter or Flame dependency | **[Measured]** The `pubspec.yaml` has no runtime dependencies |
| Tests run on the plain Dart VM | **[Measured]** `dart test`: 5/5 pass |
| **Negative test:** add `import 'package:flutter/...'` and `import 'package:flame/...'` | **[Measured]** With the default lints, `dart analyze` reports only 2 **info**-level hints and **exits 0**. `dart test` fails, but only incidentally, because Flame and Flutter need `dart:ui` |
| With the hardened `analysis_options.yaml` (`depend_on_referenced_packages: error`) | **[Measured]** `dart analyze` reports 2 **errors** and exits 3 |
| **Negative test:** add `flutter` to `puzzle_domain`'s own `pubspec.yaml` | **[Measured]** `tool/check_domain_boundary.sh` fails (exit 1) |
| Clean state | **[Measured]** The boundary script passes |
| Guard self-tests (`tool/test_check_domain_boundary.sh`, added after review) | **[Measured]** **28/28 pass**: 22 prohibited cases rejected with the expected message, and 6 allowed cases accepted (see below) |

**Key finding [Observed]:** in a pub workspace, every package shares one `package_config.json`. Any package can therefore *resolve* imports of packages that only a sibling depends on. **The package structure alone does not enforce the domain boundary.** Enforcement needs three things:
1. `depend_on_referenced_packages` promoted to an error in the domain package.
2. A check that the domain `pubspec.yaml` declares no Flutter or Flame dependency.
3. `dart test` on the plain VM.

All three are combined in `tool/check_domain_boundary.sh`.

**Guard coverage (hardened after review).** The static checks run before the analyzer. `--static-only [dir]` runs them against any package directory, which is how the self-tests exercise temporary copies.

| Area | Rejected (each has a negative test) | Accepted (each has a no-false-positive test) |
| --- | --- | --- |
| Dart directives | `import` and `export` of `package:flutter*/`, `package:flame*/`, `package:sky_engine/`, `dart:ui` and `dart:ui_web`, with single or double quotes. Also: `as`/`show` clauses, directives split across lines, conditional URIs (`if (dart.library.ui) '...'`), and directives in `test/` | Line, doc and block comments that mention these URIs; directive-like text inside single-line or multi-line string literals; identifiers such as `importance` or `exportedCells`; look-alike names (`flutterish`, `flameproof`); `dart:math` |
| `pubspec.yaml` | `flutter`, `flutter_*`, `flame`, `flame_*` or `sky_engine` under `dependencies`, `dev_dependencies` or `dependency_overrides` (quoted keys and inline maps included); any `sdk: flutter` dependency; a `flutter` constraint under `environment`; a top-level `flutter:` section | YAML comments mentioning Flutter/Flame; the package `description` text; a look-alike dependency name |

**[Observed] Limits of the static check.** It is text-based, not a Dart parser:
- Comments and multi-line strings are removed before scanning.
- Dart only allows directives before any declaration, so a string containing `//` or `/*` cannot appear ahead of one.
- Nested block comments and raw-string edge cases are not modelled.

The analyzer rule (`depend_on_referenced_packages: error`) and `dart test` on the plain VM remain as independent layers behind it.

---

## 7. TD-03 — Flame ↔ Riverpod Bridge

Both options were implemented for the same scene and pass the same 8 widget tests.

| Criterion | Manual bridge (callbacks + small view interface) | `flame_riverpod` 5.5.5 |
| --- | --- | --- |
| Glue code (non-blank, non-comment lines) | **[Measured]** About 27 in total: a 9-line contract, a 10-line `ref.listen` block in the screen, and two small view methods in the game class | **[Measured]** 46 lines in the game file, plus the `GlobalKey` wiring in the screen |
| Implementation complexity | **[Observed]** Plain Dart: callbacks out, method calls in | **[Observed]** Needs `RiverpodGameMixin`, `RiverpodComponentMixin`, `RiverpodAwareGameWidget` and a `GlobalKey`; listeners are registered via `addToGameWidgetBuild` |
| Lifecycle and subscriptions | **[Observed]** Subscriptions are `ref.listen` calls in the host widget's `build`, owned and closed by Riverpod with the widget; no manual disposal | **[Observed]** Subscriptions are recreated on each `GameWidget` rebuild. Mounting or removing a component forces a `setState` rebuild of the `GameWidget` (`rebuildGameWidget`). `ComponentRef` throws if used when not mounted |
| Testability | **[Measured]** The game runs in a plain `GameWidget` with a plain callback and **no `ProviderScope`** (`manual_bridge_test.dart`) | **[Observed]** Requires a `ProviderScope`, `RiverpodAwareGameWidget` and a `GlobalKey`; it cannot run without them |
| Coupling | **[Observed]** Flame code has no Riverpod import; the game depends on a 2-member contract | **[Observed]** Flame components import and reference providers directly |
| Maintenance | **[Observed]** Uses only public APIs | **[Observed]** Imports Riverpod's **private** `package:riverpod/src/framework.dart` (with an `ignore` comment), so Riverpod upgrades can break it. It is first-party (Flame team) and version-aligned today: 34 likes on pub.dev, about 1.9k downloads/30 days, on 2026-11-23 |
| Extra dependency | None | 1 direct package |

**[Recommendation]** Adopt the **manual bridge** for production. It's simpler, keeps Flame free of Riverpod, can be tested without a `ProviderScope` and uses only public APIs. Revisit `flame_riverpod` only if many components need to watch many providers. Needs an ADR; **TD-03 remains Pending**.

---

## 8. TD-04 — Repository Layout (pub workspace)

| Check | Result |
| --- | --- |
| Workspace root `pubspec.yaml` with `workspace: [app, packages/puzzle_domain]`; members use `resolution: workspace` | **[Measured]** `flutter pub get` resolves the whole workspace from the root. It writes one `pubspec.lock` and removes per-package locks and package configs |
| Flutter tooling | **[Measured]** `flutter analyze`, `flutter test`, `flutter build apk --profile` and `flutter build web` all work from `app/` |
| Dart tooling for the domain package | **[Measured]** `dart analyze` and `dart test` work from `packages/puzzle_domain/` |
| Cross-package dependency | **[Measured]** `app` depends on `puzzle_domain: ^0.0.1` and resolves to the local package; no `path:` needed |
| Boundary enforcement | **[Observed]** Not provided by the workspace alone (§6) |

**[Recommendation]** Adopt the pub workspace with `app/` and `packages/puzzle_domain/`, **together with** the boundary guard from §6 and a CI step that runs it (TD-08). Needs an ADR; **TD-04 remains Pending**.

---

## 9. TD-05 — Riverpod Code Generation

Tested in a throwaway copy outside the repository. The same `ShellController` was written with `@riverpod`, using `riverpod_annotation` 4.x, `riverpod_generator` 4.0.10 and `build_runner`.

| Criterion | Hand-written (spike) | Code generation (experiment) |
| --- | --- | --- |
| Provider declaration | **[Measured]** 3 lines (`NotifierProvider<…>(ShellController.new)`) | **[Measured]** `part` directive plus annotation; generates **62 lines** of `.g.dart` |
| Build step | None | **[Measured]** `build_runner` first run **42 s** (37 s build); no-change rerun **1.2 s** |
| Dependencies | **[Measured]** 75 locked packages | **[Measured]** **93** locked packages (+18) |
| Result | **[Measured]** 12/12 tests pass | **[Measured]** 11/11 tests pass in the copy (the copy predates the 12th test); analyzer clean |
| Readability | **[Observed]** Explicit; the provider type is visible | **[Observed]** Slightly less boilerplate; the provider is defined in generated code |

**[Recommendation]** **No code generation** at the current project size. It saves about 3 lines per provider, but costs a build step, 18 extra packages and a second source of truth. Revisit if provider families or the number of providers grow significantly. Needs an ADR; **TD-05 remains Pending**.

---

## 10. Performance Results and Limitations

**No Android performance measurement was possible.**
- The container has **no `/dev/kvm`**, so an Android emulator cannot run.
- **No physical device** is attached.

The §8.1 protocol requires a real Android device in profile mode, so **no Android frame-timing results are reported**.

**What was delivered instead:**
- **[Measured]** A profile-mode measurement tool built into the spike app. It collects `FrameTiming` data and computes build/raster p50, p90, p99 and max, total frames, and missed frames against `1000 / refreshRate` ms. The statistics maths has 3 unit tests. See [`spikes/s01_hybrid_shell/README.md`](../../spikes/s01_hybrid_shell/README.md) for how to run it on a device.
- **[Measured — tooling check only, not an S-01 result]** One run of each scenario in a **web profile build in headless Chromium**. That is software rendering on a desktop Xeon container, so it is not representative of Android. 60 Hz budget, 10 s per scenario, 1 run each:

| Scenario | Frames | Missed | Build p50 / p90 / p99 / max (ms) | Raster p50 / p90 / p99 / max (ms) |
| --- | --- | --- | --- | --- |
| Idle Flame scene | 620 | 1 (0.16%) | 1.0 / 1.4 / 1.9 / 3.6 | 4.6 / 5.4 / 6.0 / 25.6 |
| Overlay show/hide (every 500 ms) | 619 | 0 (0%) | 1.0 / 1.4 / 8.7 / 13.6 | 4.3 / 5.0 / 5.8 / 11.3 |
| Riverpod → Flame update (every 250 ms) | 618 | 0 (0%) | 0.8 / 1.3 / 6.5 / 11.1 | 4.0 / 4.5 / 5.5 / 11.8 |

These numbers show only that the tool works end to end. They must **not** be used to judge Android performance or the §8.1 targets.

**Still required to close the performance part of S-01:**
- Run the three scenarios 3 times each.
- Use a physical low-end device and a mid-range Android device, in profile mode.
- Record the device model, Android version, RAM, refresh rate and conditions, per §8.1.

---

## 11. Problems Encountered and Solutions

| # | Problem | Resolution |
| --- | --- | --- |
| P-01 | Flutter 3.50.1 templates import `package:material_ui`, and `package:flutter/material.dart` carries a `@Deprecated` annotation | **[Observed]** Used the first-party `material_ui` package, as the template does. Timeline per the official [migration guide](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui) (§11.1). **[Recommendation]** Production should use `material_ui` from the start |
| P-02 | `dl.google.com` (Android SDK, Google Maven artifacts) was blocked by the cloud environment's network policy | A personal `jigsaw-cards` cloud environment, approved by the owner, now allows `dl.google.com` |
| P-03 | The first Android build failed: Maven Central returned **HTTP 429 Too Many Requests** | Transient rate limiting; the retry succeeded with no changes |
| P-04 | CanvasKit was loaded from `www.gstatic.com`, which is not reachable from the sandbox | Built web with `--no-web-resources-cdn` (web verification only) |
| P-05 | Widget tests: `Paint.color` equality failed despite identical values | Components expose an integer palette index for assertions |
| P-06 | Widget tests: a pending-timer failure after taps | Flame's tap recogniser starts a long-press timer; tests advance the clock past it |
| P-07 | The overlay covered the orb at 360 dp width; Material buttons overflowed a `Row` | Compact two-row `Wrap` overlay; orb placed at 32% of the game height. Layout issue only |
| P-08 | Browser verification counted only some taps | Diagnosed with temporary logging (since removed): the scripted click coordinates missed the orb, because the header height differs between test and web. Hit-testing was correct. Fixed the coordinates; 3 of 3 taps then counted |
| P-09 | Two profile APKs with identical uncompressed contents reported different sizes (60.4 MB vs 72.2 MB) | **[Observed]** Most likely incremental-packaging free space. Not investigated: size belongs to S-02 (release AAB) |


### 11.1 Material migration timeline (verified)

Source: Flutter's official breaking-change page, [Migrate to standalone `material_ui` and `cupertino_ui` packages](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui), listed under "Released in Flutter 3.50" in the [breaking-changes index](https://docs.flutter.dev/release/breaking-changes). Read from its source in the official [`flutter/website`](https://github.com/flutter/website/blob/main/sites/docs/src/content/release/breaking-changes/material-ui-and-cupertino-ui.md) repository on 2026-11-23, because `docs.flutter.dev` is blocked by this environment's network policy.

| Milestone | Flutter version (per the official page) |
| --- | --- |
| Contributions to the in-framework Material and Cupertino libraries frozen | 3.44 |
| Standalone `material_ui` and `cupertino_ui` 1.0 published on pub.dev; opt-in | 3.47 |
| `package:flutter/material.dart` and `package:flutter/cupertino.dart` **formally deprecated** | 3.50 (stable); landed in 3.49.0-1.0.pre-295 |

The official page gives `dart fix --apply --code=migrate_design_widgets` as the automated migration, and documents a `MaterialUiCompatibilityBridge` for dependencies that still use the in-framework library.

**Correction:** an earlier version of this document said `package:flutter/material.dart` was "deprecated since 3.47". That conflated the package's introduction (3.47) with the formal deprecation (3.50). The figure came from the `@Deprecated` message in the SDK source, which reads "deprecated after v3.47.0-0.0.pre" and does not match the official timeline. This document follows the official page.

---

## 12. Known Limitations

1. **Not measured on Android:** runtime behaviour, lifecycle on a real device (including whether `paused` arrives as expected) and all Android performance (§10).
2. Manual verification used **Flutter web in headless Chromium**. Web has different lifecycle semantics (no `paused`) and different input and rendering paths.
3. Large-screen and orientation behaviour (S-07) was not examined; the portrait lock is set, but only phone-sized layouts were exercised.
4. The overlay is a simple `Stack` child, without animation or focus and accessibility handling.
5. The bridge is selected at build time; switching bridges at runtime was not explored, as it isn't needed.
6. The profile APK size is not meaningful for size decisions (S-02).

---

## 13. Recommended Production Architecture (subject to ADRs)

**[Recommendation]**

- **Repository:** a Dart pub workspace with `app/` (Flutter) and `packages/puzzle_domain/` (pure Dart). Include `tool/check_domain_boundary.sh`, or an equivalent, in CI.
- **State:** hand-written Riverpod `Notifier`s, with no code generation. Seed initial lifecycle values explicitly.
- **Bridge:** a manual contract, with intents out and a small view interface in. `ref.listen` in the hosting widget's `build`, plus an explicit initial sync. Flame code imports neither Riverpod nor the domain's persistence.
- **Overlays:** Flutter widgets above the `GameWidget`, driven by Riverpod state.
- **Lifecycle:** one `AppLifecycleListener` in the application layer. Rely on Flame's automatic engine pause, and confirm it on a device.
- **UI library:** `material_ui`, since `package:flutter/material.dart` is formally deprecated as of Flutter 3.50 (§11.1).
- **Measurement:** keep the `FrameTiming` tool for S-03 and the later spikes.

---

## 14. Go / No-Go Recommendation

**[Recommendation] Conditional GO.**

- **Go:** the hybrid architecture works. Two-way Flutter ↔ Riverpod ↔ Flame communication, the overlay, lifecycle handling and the pure-Dart boundary are all demonstrated and tested, the Android profile build succeeds, and no blocking integration issue was found. S-03 (drag, snap and tray) and S-04 (partition generation) can proceed on this foundation.
- **Condition:** before relying on performance or lifecycle assumptions in production:
  - Run the §8.1 measurements on a physical low-end and mid-range Android device.
  - Confirm `paused` and `resumed` on Android.

  This needs either a physical device or a host that supports an Android emulator.
- **Decisions:** TD-03, TD-04 and TD-05 remain **Pending** until ADRs are approved.
