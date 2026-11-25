# Implementation Status

**Current phase:** Phase 0 — Foundation (pre-development technical validation)

**Last updated:** 2026-11-25

| Area | Status | Notes |
| --- | --- | --- |
| Repository & documentation | ✅ Complete | PRD reconciled (canonical edition); Q-017 and Q-018 resolved; source-text gaps tracked in Q-019 |
| Technical feasibility review | 📝 Drafted, awaiting review | [TECHNICAL_FEASIBILITY_REVIEW.md](../docs/architecture/TECHNICAL_FEASIBILITY_REVIEW.md). Its TD-03, TD-04 and TD-05 recommendations were approved on 2026-11-24 through [ADR-0001](../docs/decisions/ADR-0001-flame-riverpod-manual-bridge.md), [ADR-0002](../docs/decisions/ADR-0002-pub-workspace-and-domain-boundary.md) and [ADR-0003](../docs/decisions/ADR-0003-handwritten-riverpod-providers.md); its other recommendations are not approved. S-01 Android device validation is still outstanding |
| Product decisions | ✅ Updated | Q-009 (piece generation), Q-010 (placement), Q-011 (tray) resolved 2026-11-23; Q-001 (target audience: core 16–35, overall 13+) resolved 2026-11-24; Q-010 and Q-011 revised twice on 2026-11-25, first to free placement and memory reveal, then to the **rectangular picture-swap puzzle** (PRD GP-29 to GP-36; hints planned for v1). New open questions Q-022 (equal tiles vs mixed-size partition) and Q-023 (lock correct tiles?); see [OPEN_QUESTIONS](OPEN_QUESTIONS.md) |
| Flutter project | 🔄 Created (feature branches) | Pub workspace per ADR-0002: `app/` (Flutter, Android) and `packages/puzzle_domain/` (pure Dart). Current gameplay on `feature/gameplay-picture-swap`; earlier builds on `feature/m1-1-core-puzzle-gameplay` and `feature/gameplay-free-placement-reveal` (superseded); none merged. Application ID `com.example.jigsaw_cards` is a temporary placeholder (owner decision) |
| Puzzle domain | 🔄 In progress | Picture-swap model: equal tiles cut from a source size, seeded Fisher–Yates shuffle (never solved, ≥75% misplaced; provisional), swap, occupancy validation, correctness counts, completion, minimum swaps. The partition generator (TD-02 Pending) is kept but not used (Q-022). 35 unit tests. Serialisation/restore not started |
| Flame rendering | 🔄 Playable | Framed board keeping the artwork aspect; tiles drawn from cached slices; press, lift and target feedback; eased exchange and cancel animations; correct-tile glow, with correct tiles drawn edge to edge; completion shine; input blocked while settling; manual bridge per ADR-0001 (`syncPuzzle` in, intents out) |
| Riverpod state | 🔄 Playable | Hand-written `PuzzleController` Notifier (ADR-0003): shuffled puzzle, swaps, completion state ready for future rewards; a single `artworkProvider` feeds both domain slicing and rendering |
| Persistence | ⛔ Not started | Technology not selected |
| Audio | ⛔ Not started | |
| Rive animation | ⛔ Not validated | |
| Art assets | ⛔ Not started | Code-drawn **placeholder** storybook scene only; no downloaded or generated artwork |
| CI | 🔄 Partial | `.github/workflows/android-apk.yml` builds and uploads a **debug** APK for product-owner testing (not a release pipeline). Format, analyze and test checks on PRs (TD-08) are not configured |
| Architecture decisions | ✅ TD-03, TD-04, TD-05 confirmed 2026-11-24 | [ADR-0001](../docs/decisions/ADR-0001-flame-riverpod-manual-bridge.md), [ADR-0002](../docs/decisions/ADR-0002-pub-workspace-and-domain-boundary.md), [ADR-0003](../docs/decisions/ADR-0003-handwritten-riverpod-providers.md). S-01 Android device validation (§8.1 timings, `paused`/`resumed`) **still outstanding**; S-01 not complete. TD-01, TD-02, TD-06 to TD-08 Pending |

## Picture-swap gameplay (2026-11-25, branch `feature/gameplay-picture-swap`, not merged)

Supersedes the memory/free-placement build and the tray build below (Q-010 and Q-011 revised again on 2026-11-25).

**Implemented:**
- A shuffled 4×4 grid of equal picture tiles, all face-up, keeping the artwork's square aspect.
- Pressing a tile highlights it. Dragging lifts it and outlines the target tile above it. Releasing over another tile exchanges the two with an eased animation; releasing elsewhere (or on its own cell) glides the tile back.
- Wrong swaps are accepted, with no limit.
- A tile that lands in its correct cell glows briefly, and correct tiles lose their edge, so solved regions read as one picture.
- Input is blocked while tiles settle, and rendered positions are re-synced to the logical board after every animation.
- On completion: a shine across the picture, then a card with the finished illustration, the swap count and New puzzle.
- Bug fixed during development: Flame calls `onGameResize` on every widget rebuild, which had cancelled swap animations and frozen input. The game now relays out only on real size changes and re-aims tiles that are mid-flight.

**Validated in this environment:**
- `dart format`, `flutter analyze` and `dart analyze --fatal-infos` (domain);
- 35 domain tests;
- 23 app widget and controller tests: rendering, press feedback, drag and target highlight, exchange and its animation, no double swaps, real resize mid-swap, cancel outside the board, drop on own cell, correct-tile glow, wrong swaps, completion and New puzzle, six screen sizes, and a touch swap at 320×568;
- domain boundary guard and its 32 self-tests;
- a clean `flutter build apk --debug` (161,622,378 bytes; apksigner, zipalign and `unzip -t` pass);
- a scripted solve of a scratch web build (screenshots and a recording).

**Not validated on a physical Android device**; no performance measurements.

**Provisional choices (not product or technical decisions):**
- shuffle at least 75% misplaced; seed from `--dart-define=PUZZLE_SEED` or launch time;
- swap 0.22 s, cancel 0.18 s, glow 0.6 s, completion shine 0.9 s;
- the target is the cell under the finger;
- correct tiles stay swappable (Q-023);
- equal tiles instead of mixed-size pieces (Q-022);
- square placeholder artwork; temporary application ID.

**Not implemented:** hints (planned for v1); persistence and auto-save, including the **persisted layout (PS-23, Q-009), which remains outstanding**; reference preview (GP-08, Q-008); card reveal; coins; sound; Rive; world map and progression. S-01 Android device validation remains outstanding and M1.1 is not complete.

## Free-placement memory gameplay — superseded (2026-11-25, branch `feature/gameplay-free-placement-reveal`, not merged)

Supersedes the tray-based first playable below (Q-010 and Q-011 revised 2026-11-25).

**Implemented:** 4×4 board of 8–12 mixed rectangular pieces. Pieces start face-down at seeded scattered positions across the board workspace (no tray). A short introduction, then every piece flips face-up for exactly 4 seconds (countdown bar), then flips face-down. Tapping a face-down piece reveals only that piece. Revealed pieces can be dragged anywhere on the board, overlap, and stay where dropped. Within the snap tolerance a piece snaps exactly, locks and sparkles. Locked pieces cannot move, and touches pass through them to pieces beneath. Completion overlay with "New puzzle".

**Validated in this environment:** `dart format`, `flutter analyze`, `dart analyze --fatal-infos` (domain), 350 domain tests, 23 app widget/controller tests (reveal sequence, flips, free placement, overlap and topmost selection, snap and lock, locked hit testing, board edges, completion, responsive layout at six sizes from 320×568 to 600×960), domain boundary guard and its 32 self-tests, a clean `flutter build apk --debug` (161,640,422 bytes), and a scripted play-through of a scratch web build (screenshots). **Not validated on a physical Android device or emulator**; no performance measurements.

**Provisional choices (not product or technical decisions):** generation algorithm (TD-02 Pending); scatter algorithm; seed from `--dart-define=PUZZLE_SEED` or launch time, shared by layout and scatter; workspace 4.6 × 8.0 cells (grid at the top, open area below); snap tolerance 0.3 cell (Chebyshev); intro 1.2 s; flip 0.34 s with 45 ms stagger; the 4 s preview starts once the flip-up has finished; a drag on a face-down piece does not move it (a small shake hints to tap); a revealed piece is raised to the top; placeholder artwork and card back; temporary application ID.

**Not implemented:** persistence and auto-save, including the **persisted layout (PS-23, Q-009), which remains outstanding**; reference preview (GP-08, Q-008 open); card reveal; coins; sound; Rive; rewards. S-01 Android device validation remains outstanding and M1.1 is not complete.

## First playable puzzle — superseded (2026-11-25, branch `feature/m1-1-core-puzzle-gameplay`, not merged)

**Implemented:** 4×4 board of 8–12 mixed rectangular pieces; two-row horizontally scrollable tray; vertical drag from the tray picks a piece up and enlarges it to board scale; strict placement (only the correct position is accepted); correct pieces snap and lock permanently; incorrect drops animate back to the tray; locked pieces cannot be moved; completion overlay with "New puzzle".

**Validated in this environment:** `dart format`, `flutter analyze`, `dart analyze --fatal-infos` (domain), 29 domain tests, 18 app widget/controller tests (including responsive layout at 320×568, 360×640, 412×915, 480×1000 and 600×960), domain boundary guard and its 32 self-tests, `flutter build apk --debug`, and a scripted play-through of a scratch web build (screenshots). **Not validated on a physical Android device or emulator**; no performance measurements.

**Provisional choices (not product or technical decisions):** generation algorithm (TD-02 Pending); seed from `--dart-define=PUZZLE_SEED` or launch time; tray order is a seeded shuffle; 72 dp tray tiles; half-cell snap threshold; board shows a grid with no ghost image; pieces are picked up with a vertical drag (horizontal swipes scroll the tray); placeholder artwork; temporary application ID.

**Not implemented:** layout persistence and auto-save (PS-23), reference preview (GP-08, Q-008 open), card reveal, coins, sound, Rive, rewards. S-01 Android device validation remains outstanding and M1.1 is not complete.
