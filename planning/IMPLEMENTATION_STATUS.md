# Implementation Status

**Current phase:** Phase 0 — Foundation (pre-development technical validation)

**Last updated:** 2026-11-26

| Area | Status | Notes |
| --- | --- | --- |
| Repository & documentation | ✅ Complete | PRD reconciled (canonical edition); Q-017 and Q-018 resolved; source-text gaps tracked in Q-019 |
| Technical feasibility review | 📝 Drafted, awaiting review | [TECHNICAL_FEASIBILITY_REVIEW.md](../docs/architecture/TECHNICAL_FEASIBILITY_REVIEW.md). Its TD-03, TD-04 and TD-05 recommendations were approved on 2026-11-24 through [ADR-0001](../docs/decisions/ADR-0001-flame-riverpod-manual-bridge.md), [ADR-0002](../docs/decisions/ADR-0002-pub-workspace-and-domain-boundary.md) and [ADR-0003](../docs/decisions/ADR-0003-handwritten-riverpod-providers.md); its other recommendations are not approved. S-01 Android device validation is still outstanding |
| Product decisions | ✅ Updated | Q-009 (piece generation), Q-010 (placement), Q-011 (tray) resolved 2026-11-23; Q-001 (target audience: core 16–35, overall 13+) resolved 2026-11-24; Q-010 and Q-011 revised twice on 2026-11-25, first to free placement and memory reveal, then to the **rectangular picture-swap puzzle** (PRD GP-29 to GP-36; hints planned for v1). **Q-022 resolved 2026-11-25** (equal-sized tiles on a uniform 4×4 grid; mixed-size partition superseded for this gameplay; Q-009 revised) and **Q-023 resolved 2026-11-25** (correct tiles remain movable; no locking); see [OPEN_QUESTIONS](OPEN_QUESTIONS.md) |
| Flutter project | 🔄 Created (feature branches) | Pub workspace per ADR-0002: `app/` (Flutter, Android) and `packages/puzzle_domain/` (pure Dart). Current gameplay on `feature/m32-connected-tile-groups` (M3.2, based on the M3.1 branch `feature/gameplay-picture-swap`); earlier builds on `feature/m1-1-core-puzzle-gameplay` and `feature/gameplay-free-placement-reveal` (superseded); none merged. Application ID `com.example.jigsaw_cards` is a temporary placeholder (owner decision) |
| Puzzle domain | 🔄 In progress | Picture-swap model with connected tile groups (M3.2: groups by relative alignment, group moves keeping the board full; `TileGroups` extension, `PicturePuzzle` unchanged): equal tiles cut from a source size, seeded Fisher–Yates shuffle (never solved, ≥75% misplaced; provisional), swap, occupancy validation, correctness counts, completion, minimum swaps. Matches Q-022 and Q-023. The partition generator, superseded for this gameplay by Q-022, is kept but not used. 35 unit tests. Serialisation/restore not started |
| Flame rendering | 🔄 Playable | Framed board keeping the artwork aspect; tiles drawn from cached slices; press, lift and target feedback; eased exchange and cancel animations; correct-tile glow, with correct tiles drawn edge to edge; connected groups lifted, dragged and drawn as one seamless piece (M3.2); completion shine; input blocked while settling; manual bridge per ADR-0001 (`syncPuzzle` in, intents out); puzzle introduction (card entrance and reveal, GP-37) via a reusable `IntroTimeline` + `IntroDirector` with a replaceable code-drawn card back |
| Riverpod state | 🔄 Playable | Hand-written `PuzzleController` Notifier (ADR-0003): shuffled puzzle, swaps and group moves (`moveTile`), completion state ready for future rewards; a single `artworkProvider` feeds both domain slicing and rendering |
| Persistence | ⛔ Not started | Technology not selected |
| Audio | ⛔ Not started | |
| Rive animation | ⛔ Not validated | |
| Art assets | ⛔ Not started | Code-drawn **placeholder** storybook scene only; no downloaded or generated artwork |
| CI | 🔄 Partial | `.github/workflows/android-apk.yml` builds and uploads a **debug** APK for product-owner testing (not a release pipeline). Format, analyze and test checks on PRs (TD-08) are not configured |
| Architecture decisions | ✅ TD-03, TD-04, TD-05 confirmed 2026-11-24 | [ADR-0001](../docs/decisions/ADR-0001-flame-riverpod-manual-bridge.md), [ADR-0002](../docs/decisions/ADR-0002-pub-workspace-and-domain-boundary.md), [ADR-0003](../docs/decisions/ADR-0003-handwritten-riverpod-providers.md). S-01 Android device validation (§8.1 timings, `paused`/`resumed`) **still outstanding**; S-01 not complete. TD-01, TD-02, TD-06 to TD-08 Pending |

## M3.2 Connected Tile Groups (core gameplay feature; implemented and approved on the product owner's Android device 2026-11-26; branch `feature/m32-connected-tile-groups`, based on `2cd20f2`, not merged)

Approved scope (PRD GP-41 to GP-44, VI-08): the M3.1 picture-swap gameplay, unchanged, plus one mechanic. Neighbouring tiles that line up as in the original picture join into a group, anywhere on the board, and a group moves as one unit.

**Implemented:**
- **Domain:** a `TileGroups` extension on `PicturePuzzle` (`packages/puzzle_domain/lib/src/tile_groups.dart`). `PicturePuzzle` and `swap()` are unchanged.
  - `connectedGroups`, `groupAt` and `unitAt`: two board neighbours join when both are shifted from their correct cells by the same offset, transitively.
  - `moveGroup(from, to)`: the unit moves rigidly by `to − from`; displaced tiles slide back against the drag direction into the vacated cells, so the board stays full. A single tile delegates to `swap()`. A unit that would leave the board is refused.
  - Groups are derived after every move, never stored.
- **State and bridge:** `PuzzleController.moveTile(from, to)`, with the existing `swap()` kept. The screen sends the existing `onSwapRequested` intent to `moveTile`, and the bridge contract is unchanged.
- **Flame:**
  - Pressing or dragging any member lifts the whole group, which is drawn seamless and slightly enlarged with one shared shadow (`GroupLiftShadow`).
  - The target marker outlines all destination cells, and displaced tiles are highlighted. A refused drop glides the whole group back.
  - Resting groups are drawn without inner edges (`TileComponent.joinedSides`).
  - The intro, celebration, exit and single-tile rendering are unchanged.

**Validated:**
- In this environment: 58 domain tests (23 new for groups) and 96 app tests (10 new interaction tests; all 86 M3.1 tests unchanged); formatting, both analyzers and the boundary guard and its self-tests clean. The new domain tests cover:
  - detection, including L-shapes, merges and groups away from their final cells;
  - group movement, group-to-group exchange, overlapping moves and a group with a notch;
  - single tiles behaving exactly like `swap()`;
  - 300 randomised move sequences and a solvability check on 500 boards.
- In a browser preview: pairs joining away from their final cells, lifting by either member, an L-shaped group moving, and two groups merging.
- On device: the product owner tested the debug APK (SHA-256 `c7a52fc7…1e1ab7`) on their Android phone and approved it on 2026-11-26.
- No performance measurements yet.

**Rejected (history):** the M3.2 "Direction B" prototype, with free-moving groups on a scattered workbench, continuous positions and snapping (`experiment/m32-connected-groups`, uncommitted), was rejected by the product owner. A first correction that grouped only tiles in their final cells was replaced by relative alignment after comparison with the reference recording.

## M3.1 "Bright & Celebrate" (approved 2026-11-26; implemented and approved on the product owner's Android device 2026-11-26; branch `feature/gameplay-picture-swap`, not merged)

Approved scope (PRD VI-06, VI-07, GP-38 to GP-40): the Sunlit Storybook palette across the whole UI; a bright code-drawn daytime placeholder picture; the board spacing rules (20–32 dp to the frame's outer edge, safe areas, responsive, no reserved bottom bar); a short completion celebration with no rewards shown; and a Next puzzle transition that reshuffles the same picture and reruns the introduction, with no duplicate taps or overlapping sequences. Puzzle mechanics, shuffle rules and the introduction are unchanged. Out of scope: merging into `main`, world progression, real rewards, and the application ID.

**Implemented:**
- **Design tokens:** a `Sunlit` palette and theme; filled buttons in deep teal with white text, per the contrast rule; the header and completion card restyled.
- **Gameplay background (VI-06, refined after device review):** a flat violet base (`#7543EE`) with a code-drawn diamond lattice (`#6531DE`, about 122 × 133 dp diamonds, 3.4 dp lines) and four-petal motifs (`#6633DD`) at the diamond centres, covering the whole screen; cream header text. This replaces the first implementation's sky-to-cream gradient with clouds.
- **Board:** a `BoardStyle` object injected into the Flame game, with a honey-wood frame, a pale bed, a turquoise target outline, a sunflower selection outline and a leaf correct glow; the intro rendering is unchanged.
- **Spacing (GP-38):** `BoardLayout` measures 20–32 dp to the frame's outer edge (6% of the width), at least 16 dp above and 24 dp below, and caps the frame at 560 dp; margins grow beyond 32 dp only when the board is capped or limited by height.
- **Placeholder picture (VI-07):** a bright code-drawn daytime scene ("Sunny Castle") with a distinct detail in every tile region.
- **Celebration (GP-39):** a step-based `CelebrationTimeline` with a `CelebrationDirector` (shine 0–0.7 s, sparkle burst 0.3–1.1 s); it starts at most once and keeps input disabled; there is no reward UI.
- **Next puzzle (GP-40):** the card hides, an `ExitTimeline` with an `ExitDirector` clears the board in about 0.6 s, then a new puzzle starts with the same picture and a seed from the injectable `PuzzleSeedSource` (no seed arithmetic; a repeated arrangement is skipped), and the introduction runs again. Repeated taps are ignored.

**Validated:**
- In this environment: 86 app tests (45 new for M3.1: palette, background and contrast; board spacing at 8 sizes with insets; artwork brightness and tile distinctness; celebration; next puzzle) and 35 domain tests; formatting, both analyzers and the boundary guard clean; the puzzle domain and the introduction are unchanged; checked visually in scratch web builds at 412×915 and 320×568.
- On device: the product owner tested the final M3.1 debug APK on their Android phone and approved it on 2026-11-26.
- No performance measurements yet, and S-01 low-end device validation is still outstanding.

## Puzzle introduction (2026-11-26, commit `37c5af4`, branch `feature/gameplay-picture-swap`, not merged)

**Implemented (GP-37):** tiles start as card backs, fly in from below one by one, tilted, into their actual shuffled cells, then flip to their picture in a fixed scattered order, after which input is enabled.
- **Structure:** a pure-Dart `IntroTimeline` (phases `idle → entering → revealing → ready`, keyed by board cell) and a Flame `IntroDirector` posing tiles through an `IntroStage` interface; the card back (`CardBackDesign`) is a replaceable, code-drawn placeholder.
- **Behaviour:** input is gated until the reveal finishes; resizes and rebuilds do not restart the sequence; the time step is capped so pauses cannot skip it; a new puzzle runs it again.

**Validated:**
- 18 new tests (8 timeline unit tests and 10 widget tests covering backs at start, shuffled target cells, reveal only after arrival, reveal order, correct fragments, input gating in both phases, enablement afterwards, rerun for a new puzzle, resize and rebuild, and pause/resume); 41 app tests and 35 domain tests in total; analyzer and boundary guard clean.
- GitHub Actions debug APK run #5 (161,648,194 bytes).
- Product owner functional check on their own Android phone (2026-11-26): entrance and reveal approved.
- No performance measurements yet.

**Provisional tuning:** entrance stagger 85 ms, flight 400 ms, reveal delay 40 ms, flip 220 ms, reveal stagger 50 ms (about 2.6 s in total).

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

**Device check:** the product owner reported the picture-swap gameplay working on their own Android phone (functional check, 2026-11-25/26). No performance measurements, and S-01 low-end and mid-range device validation remains outstanding.

**Provisional choices (not product or technical decisions):**
- shuffle at least 75% misplaced; seed from `--dart-define=PUZZLE_SEED` or launch time;
- swap 0.22 s, cancel 0.18 s, glow 0.6 s, completion shine 0.9 s;
- the target is the cell under the finger;
- square placeholder artwork; temporary application ID.

**Product decisions reflected (resolved 2026-11-25):** equal-sized tiles on a uniform 4×4 grid (Q-022); correctly positioned tiles remain movable, with correct-position feedback visual only (Q-023). The code already matched both; no application change was needed.

**Not implemented:** hints (planned for v1); persistence and auto-save, including the **persisted arrangement (PS-23 as revised by Q-022), which remains outstanding**; reference preview (GP-08, Q-008); card reveal; coins; sound; Rive; world map and progression. S-01 Android device validation remains outstanding and M1.1 is not complete.

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
