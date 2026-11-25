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

- Tiling invariant (required; follows from the confirmed partition requirement PS-08, see PUZZLE_ENGINE §4): every layout covers the board fully, with no overlap and nothing out of bounds. A layout or configuration that violates it is rejected (rejection at load time is the proposed mechanism).
- Rectangular partition generation: every output satisfies the tiling invariant, uses only 1×1, 1×2, 2×1 and 2×2 pieces, and contains between 8 and 12 pieces, inclusive (PS-20, PS-21). Boundary cases: layouts with 7 or 13 pieces are never produced. Output is reproducible for a given seed within one SDK version (PS-22). A persisted layout restores identically (PS-23).
- Reward rules (application layer): designated puzzle awards its card once; already collected card does not add collection progress (CC-04, CC-06).
- Reveal sequence (GP-20 to GP-23): pieces start face-down; the preview shows all pieces and lasts exactly 4 seconds; afterwards all are face-down; a tap reveals only one piece, which stays revealed; no interaction outside memory mode.
- Free placement (GP-24 to GP-26): correct and incorrect positions are both accepted; incorrect pieces stay where dropped and can move again; overlap allowed; positions clamped to the workspace; current position stays separate from the target; within the snapping tolerance the piece snaps exactly and locks.
- Locking (GP-15): a locked piece cannot be moved, revealed again or selected; any such attempt is rejected and leaves state unchanged.
- Starting scatter (GP-20): deterministic per seed; in bounds; no piece at or next to its target; every piece substantially visible.
- Hit testing: the topmost selectable piece wins; locked pieces are passed through.
- *(Superseded 2026-11-25: strict placement, GP-14.)*
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
