# Testing Strategy

> Applies once implementation begins. No code exists yet.

## 1. Test Pyramid

| Level | Scope | Tooling (proposed) | Requirement |
| --- | --- | --- | --- |
| Unit | Puzzle domain (pure Dart) | `package:test` | **Mandatory** for all domain logic |
| Unit | Riverpod notifiers / app logic | `flutter_test` with provider overrides | Required for non-trivial logic |
| Widget | Flutter screens and overlays | `flutter_test` | Key screens and flows |
| Game component | Flame components | `flame_test` (if adopted) | Interaction-critical components |
| Integration | End-to-end puzzle flow on device/emulator | `integration_test` | Core loop before each milestone |
| Manual | Feel, animation, audio, device coverage | Checklist | Each milestone |

## 2. Puzzle Domain — Required Coverage

- Configuration validation: tiling invariant (full coverage, no overlap, in bounds); invalid configs rejected.
- Piece layout generation (if procedural): every output satisfies the invariant; deterministic with a seed.
- Placement: accepted at correct origin; rejected when out of bounds, overlapping, or (strict rule) wrong origin; rejected placement leaves state unchanged.
- Moving a piece from board to board / board to tray (if allowed).
- Occupancy consistent with piece locations after every operation.
- Completion: detected exactly when all pieces are correct; not before.
- Serialisation round-trip: save → restore yields identical state; schema version present.

## 3. Principles

- Domain tests do not depend on Flutter or Flame.
- Tests are deterministic — seed any randomness.
- A bug fix includes a test that reproduces the bug.
- No test is skipped or disabled to make CI pass.

## 4. Device Testing

Minimum Android version and target device list are TBC (TECHNICAL_DECISIONS TD-06). Drag/snap feel and animation performance must be checked on a low-end and a mid-range device.

## 5. Continuous Integration (proposed)

On each pull request: `dart format` check, `flutter analyze`, all unit and widget tests. To be configured once the Flutter project exists (TD-08).
