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
