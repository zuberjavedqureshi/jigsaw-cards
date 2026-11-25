# S-01 Hybrid Shell — throwaway spike

**Not production code.** This directory exists only to validate the hybrid
Flutter + Flame + Riverpod architecture (feasibility review S-01). Findings:
[docs/spikes/S-01-HYBRID-SHELL.md](../../docs/spikes/S-01-HYBRID-SHELL.md).

It mirrors the proposed TD-04 layout inside an isolated folder:

```
spikes/s01_hybrid_shell/
  pubspec.yaml              Dart pub workspace root (single pubspec.lock)
  app/                      Flutter app (Android + web), Flame scene, Riverpod state
  packages/puzzle_domain/   Pure-Dart placeholder package
  tool/check_domain_boundary.sh        boundary guard (--static-only [dir] for static checks only)
  tool/test_check_domain_boundary.sh   positive and negative tests for the guard
```

## Run

Requires Flutter 3.50.1 (Dart 3.14.0). From this directory:

```sh
flutter pub get                     # resolves the whole workspace
cd app
flutter test                        # widget + unit tests (both bridges)
flutter run --profile               # on an Android device; profile mode for timings
flutter run --profile --dart-define=S01_BRIDGE=flame_riverpod   # TD-03 option 2
cd ../packages/puzzle_domain && dart test
cd ../.. && ./tool/check_domain_boundary.sh
./tool/test_check_domain_boundary.sh
```

## Measuring frame timing (feasibility review §8.1)

In profile mode on a device: tap **Show overlay**, then **Measure → idle /
overlay / state**. Each scenario runs for 10 s and prints one line prefixed
`S01_PERF` (JSON: build/raster p50/p90/p99/max, total frames, missed frames)
to the device log (`flutter run` output or `adb logcat | grep S01_PERF`).
Record device model, Android version, RAM, refresh rate and conditions as the
protocol requires, and run each scenario at least 3 times.

## Physical-device validation runbook (closes S-01)

S-01 remains **in progress** until these steps are run on physical Android
devices: ideally one **low-end** and one **mid-range** phone, plus a
high-refresh (90/120 Hz) phone if available. Nothing here has been run on a
device yet. Record only what you observe; if a device profile is unavailable,
write that down rather than estimating.

### 1. Prerequisites

- Each phone: Developer options → **USB debugging** on; battery ≥ 50 %;
  battery saver off; other apps closed. Note whether it is charging.
- A computer with `adb` (Android SDK platform-tools).
- The two **profile** APKs, built from the same commit:
  `flutter build apk --profile` (manual bridge) and
  `flutter build apk --profile --dart-define=S01_BRIDGE=flame_riverpod`.
  Both use the application ID `com.example.jigsaw_cards_spike`, so installing
  one replaces the other. Test one variant at a time.

### 2. Record the device (once per phone)

```sh
adb shell getprop ro.product.manufacturer
adb shell getprop ro.product.model
adb shell getprop ro.build.version.release      # Android version
adb shell getprop ro.build.version.sdk          # API level
adb shell grep MemTotal /proc/meminfo           # RAM
adb shell dumpsys display | grep -iE 'refreshRate|fps' | head -5
```

The app also reports the refresh rate it used: the summary prints it from the
frame budget.

### 3. Install a variant and capture the log

```sh
adb install -r s01-manual-profile.apk           # or s01-flame-riverpod-profile.apk
adb logcat -c
adb logcat -v time -s flutter > s01-<device>-<bridge>.log   # keep running
```

The header's last line must show **`profile`** and the expected bridge
(`manual` or `flameRiverpod`).

### 4. Functional checklist (per device and bridge)

| # | Check | Steps | Expected |
| --- | --- | --- | --- |
| F1 | Initial state sync | Launch the app | Header: taps 0, colour 0, **Lifecycle: resumed**; game status line: `lifecycle seen by game: resumed`; orange orb; game clock advancing |
| F2 | Flutter → Flame | Tap **Change colour** | Orb turns blue; header colour 1 |
| F3 | Flame → Flutter | Tap the orb 3 times | Header taps 3, `domain cell 0,3` |
| F4 | Overlay | **Show overlay**; tap the orb; tap overlay **Colour**; **Close** | Overlay appears; game clock keeps advancing; orb tap counts (taps 4); orb colour changes; overlay closes and the game stays (same clock) |
| F5 | Background / resume | Home button, wait 10 s, reopen from Recents | Header pauses 1, resumes 1, Lifecycle resumed; game status `resumed`; taps and colour preserved. Note whether the game clock advanced while in the background (Flame pauses its engine when backgrounded) |
| F6 | Screen off / on | Power button off, wait 5 s, unlock | Pauses and resumes each increase by exactly 1; no crash |
| F7 | Background process kill | Home button, then `adb shell am kill com.example.jigsaw_cards_spike`, reopen | App cold-starts with fresh state (taps 0, colour 0) and F1 holds. **Expected:** S-01 has no persistence, so state is not restored. Pass means no crash and correct initial sync |
| F8 | Force-stop | `adb shell am force-stop com.example.jigsaw_cards_spike`, relaunch | As F7 |

Pauses and resumes must never increase by more than 1 per transition, which
would indicate a duplicate listener.

### 5. Frame timing (§8.1), per device and bridge

1. Cold start, or after a 5-minute warm-up. Record which.
2. Tap **Show overlay**, then **Measure: idle**. Don't touch the screen for
   about 11 s, until the result line appears in the overlay.
3. Repeat **idle** 2 more times (3 runs), then **overlay** ×3, then **state** ×3.
   The overlay scenario toggles the overlay itself and ends with it visible.
4. Stop `adb logcat` (Ctrl+C) and summarise:

```sh
cd spikes/s01_hybrid_shell/app
dart run tool/summarize_perf_log.dart path/to/s01-<device>-<bridge>.log
```

The summary lists every run (frames; missed frames; build and raster
p50/p90/p99/max) and the refresh rate. It flags non-profile runs as
**INVALID**, warns about any scenario with fewer than 3 runs, and names any
of the three expected scenarios (idle, overlay, state) that is missing
entirely. It never averages or fills in missing data.

Pass/fail thresholds in the feasibility review §8.1 are **proposed targets
that require approval**:
- mid-range 60 Hz: ≤ 1 % missed and p99 build and raster ≤ 16.7 ms;
- low-end 60 Hz: ≤ 5 % missed;
- 120 Hz: measure and report only.

### 6. What to send back

For each device: the step-2 output and conditions (charging, battery %,
cold or warm). For each device and bridge: the F1–F8 results (pass/fail plus
notes), the `.log` file and the summary output. Screenshots of F1 and F5 are
helpful.
