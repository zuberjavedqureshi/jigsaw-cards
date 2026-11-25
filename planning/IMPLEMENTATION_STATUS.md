# Implementation Status

**Current phase:** Phase 0 — Foundation (pre-development technical validation)

**Last updated:** 2026-11-25

| Area | Status | Notes |
| --- | --- | --- |
| Repository & documentation | ✅ Complete | PRD reconciled (canonical edition); Q-017 and Q-018 resolved; source-text gaps tracked in Q-019 |
| Technical feasibility review | 📝 Drafted, awaiting review | [TECHNICAL_FEASIBILITY_REVIEW.md](../docs/architecture/TECHNICAL_FEASIBILITY_REVIEW.md). Its TD-03, TD-04 and TD-05 recommendations were approved on 2026-11-24 through [ADR-0001](../docs/decisions/ADR-0001-flame-riverpod-manual-bridge.md), [ADR-0002](../docs/decisions/ADR-0002-pub-workspace-and-domain-boundary.md) and [ADR-0003](../docs/decisions/ADR-0003-handwritten-riverpod-providers.md); its other recommendations are not approved. S-01 Android device validation is still outstanding |
| Product decisions | ✅ Updated | Q-009 (piece generation), Q-010 (placement), Q-011 (tray) resolved 2026-11-23; Q-001 (target audience: core 16–35, overall 13+) resolved 2026-11-24; see [OPEN_QUESTIONS](OPEN_QUESTIONS.md) |
| Flutter project | 🔄 Created (feature branch) | Pub workspace per ADR-0002: `app/` (Flutter, Android) and `packages/puzzle_domain/` (pure Dart), on `feature/m1-1-core-puzzle-gameplay`, not merged. Application ID `com.example.jigsaw_cards` is a temporary placeholder (owner decision) |
| Puzzle domain | 🔄 In progress | Grid, pieces, layout validation (gaps, overlaps, bounds, sizes, 8–12 count), seeded generation behind `LayoutGenerator` (**provisional**; TD-02 Pending), placement, locking, completion. 29 unit tests. Serialisation/restore not started |
| Flame rendering | 🔄 First playable | Board, locked pieces, floating piece (enlarges to board scale on pick-up), snap-and-lock and return-to-tray effects; manual bridge per ADR-0001 |
| Riverpod state | 🔄 First playable | Hand-written `PuzzleController` Notifier (ADR-0003); completion state ready for future rewards |
| Persistence | ⛔ Not started | Technology not selected |
| Audio | ⛔ Not started | |
| Rive animation | ⛔ Not validated | |
| Art assets | ⛔ Not started | Code-drawn **placeholder** storybook scene only; no downloaded or generated artwork |
| CI | ⛔ Not configured | |
| Architecture decisions | ✅ TD-03, TD-04, TD-05 confirmed 2026-11-24 | [ADR-0001](../docs/decisions/ADR-0001-flame-riverpod-manual-bridge.md), [ADR-0002](../docs/decisions/ADR-0002-pub-workspace-and-domain-boundary.md), [ADR-0003](../docs/decisions/ADR-0003-handwritten-riverpod-providers.md). S-01 Android device validation (§8.1 timings, `paused`/`resumed`) **still outstanding**; S-01 not complete. TD-01, TD-02, TD-06 to TD-08 Pending |

## First playable puzzle (2026-11-25, branch `feature/m1-1-core-puzzle-gameplay`, not merged)

**Implemented:** 4×4 board of 8–12 mixed rectangular pieces; two-row horizontally scrollable tray; vertical drag from the tray picks a piece up and enlarges it to board scale; strict placement (only the correct position is accepted); correct pieces snap and lock permanently; incorrect drops animate back to the tray; locked pieces cannot be moved; completion overlay with "New puzzle".

**Validated in this environment:** `dart format`, `flutter analyze`, `dart analyze --fatal-infos` (domain), 29 domain tests, 18 app widget/controller tests (including responsive layout at 320×568, 360×640, 412×915, 480×1000 and 600×960), domain boundary guard and its 32 self-tests, `flutter build apk --debug`, and a scripted play-through of a scratch web build (screenshots). **Not validated on a physical Android device or emulator**; no performance measurements.

**Provisional choices (not product or technical decisions):** generation algorithm (TD-02 Pending); seed from `--dart-define=PUZZLE_SEED` or launch time; tray order is a seeded shuffle; 72 dp tray tiles; half-cell snap threshold; board shows a grid with no ghost image; pieces are picked up with a vertical drag (horizontal swipes scroll the tray); placeholder artwork; temporary application ID.

**Not implemented:** layout persistence and auto-save (PS-23), reference preview (GP-08, Q-008 open), card reveal, coins, sound, Rive, rewards. S-01 Android device validation remains outstanding and M1.1 is not complete.
