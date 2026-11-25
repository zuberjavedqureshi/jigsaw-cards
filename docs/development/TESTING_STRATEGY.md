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

- Coverage invariant (required, PUZZLE_ENGINE §4): every arrangement fills every cell with exactly one tile, with no overlap or duplicates; an invalid arrangement is rejected.
- *(Superseded 2026-11-25 by Q-022 as a requirement: rectangular partition generation with 1×1 to 2×2 pieces and 8–12 pieces, PS-20, PS-21. The dormant generator in the domain package keeps its own tests.)* Seeded starting arrangements are reproducible for a given seed within one SDK version (PS-22 revised). A persisted arrangement restores identically (PS-23 revised; not implemented).
- Reward rules (application layer): designated puzzle awards its card once; already collected card does not add collection progress (CC-04, CC-06).
- Picture-swap board (GP-29 to GP-31): the solved grid is correct; tiles are equal, non-overlapping slices of the source; the shuffle is deterministic per seed, never solved and always solvable by swaps; there are no empty cells or duplicate occupancy; tile identity and target cells never change.
- Swaps (GP-32): exactly two cells change; incorrect swaps are accepted; correctly positioned tiles can still be swapped, including with each other (Q-023); invalid indices, the same cell, or swapping after completion are rejected without changing the board; repeated swaps keep every invariant.
- Correctness and completion (GP-34): correct-tile detection and counts; complete exactly when every tile is correct.
- *(Superseded 2026-11-25: strict placement, then the reveal sequence, free placement, scatter and hit-testing coverage.)*
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
