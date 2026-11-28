# Milestones

| ID | Milestone | Phase | Status |
| --- | --- | --- | --- |
| M0 | Repository and documentation foundation | 0 | ✅ Done |
| M0.1 | Blocking open questions resolved | 0 | ✅ Done (Q-009, Q-010, Q-011 resolved 2026-11-23; Q-001 resolved 2026-11-24) |
| M1.1 | Flame + Riverpod integration spike | 1 | 🔄 In progress — Android device validation outstanding. **Done:** S-01 Hybrid Shell spike executed, tested and findings recorded ([PR #4](https://github.com/zuberjavedqureshi/jigsaw-cards/pull/4)); decisions recorded in ADR-0001 to ADR-0003. **Outstanding:** §8.1 frame-timing measurements and `paused`/`resumed` lifecycle checks on a physical low-end and mid-range Android device |
| M1.2 | Drag & snap feel spike | 1 | ⏳ Not started |
| M1.3 | Rive validation spike | 1 | ⏳ Not started |
| M1.4 | Persistence selection (ADR) | 1 | ⏳ Not started |
| M1.5 | Flutter project structure approved (ADR) | 1 | ✅ Approved 2026-11-24 ([ADR-0002](../decisions/ADR-0002-pub-workspace-and-domain-boundary.md)); production workspace created 2026-11-25 on branch `feature/m1-1-core-puzzle-gameplay` (not merged) |
| M2 | Puzzle domain complete with tests | 2 | 🔄 In progress — picture-swap model (equal tiles, seeded shuffle, swap, occupancy validation, correctness and completion) with tests, consistent with Q-022 (equal tiles) and Q-023 (no locking), both resolved 2026-11-25; the superseded partition generator is kept but not used. **Outstanding:** TD-02 (seed source), serialisation/restore (PS-23) |
| M3 | Playable 4×4 prototype | 3 | 🔄 In progress — picture-swap gameplay (shuffled 4×4 grid, drag-and-swap, correct-tile feedback, completion) with widget tests and a web-preview recording, on branch `feature/gameplay-picture-swap` (not merged). The tray build and the memory/free-placement build are superseded. **Outstanding:** physical Android device validation, reference preview, card reveal, coin reward, sound, auto-save/restore (including PS-23), final artwork; hints are planned for v1 |
| M3.1 | Bright & Celebrate | 3 | ✅ Done 2026-11-26: implemented and approved on the product owner's Android device (branch `feature/gameplay-picture-swap`, not merged to `main`). Patterned violet background and Sunlit palette across the UI, bright daytime placeholder picture, board spacing (GP-38), short completion celebration without rewards (GP-39), next-puzzle transition (GP-40) |
| M3.2 | Connected Tile Groups | 3 | ✅ Done 2026-11-26: implemented and approved on the product owner's Android device (branch `feature/m32-connected-tile-groups`, based on the M3.1 commit `2cd20f2`, not merged to `main`). Core gameplay feature (PRD GP-41 to GP-44, VI-08) |
| M3.3 | Positive Connection Feedback | 3 | ✅ Done 2026-11-26: implemented and approved on the product owner's Android device (branch `feature/m33-positive-feedback`, based on the M3.2 commit `06db9cb`, not merged to `main`). Praise for connections and completion (PRD GP-45, VI-09) |
| W4 | Sunny Meadows artwork (code-drawn) | 3 | 🧪 Experiment, not approved as the art direction (2026-11-28). Kept uncommitted in the W4 worktree as a comparison baseline; not registered |
| W4-R1 | Revised PRD and hybrid artwork strategy | 3 | ✅ Approved in principle by the product owner 2026-11-28, with final corrections applied (end of the main World Journey, WP-08; 40 MB ceiling for all 50 images, VI-11; Play Asset Delivery split out as Q-028); documents uncommitted pending authorisation. Covers PRD §1, TA-07, VI-01, VI-02, VI-04, VI-07 revised; VI-10 to VI-12 and WP-04 to WP-10 added; [ARTWORK_GUIDELINES](../product/ARTWORK_GUIDELINES.md), [raster proposal](../architecture/RASTER_ARTWORK_PROPOSAL.md) |
| W4-R2 | Four-image visual prototype | 3 | ⏳ Proposed, not started; needs at least one approved image source for the prototype (Q-024 stays open until after the prototype is evaluated). Specification: [W4-R2_VISUAL_PROTOTYPE.md](W4-R2_VISUAL_PROTOTYPE.md) |
| M4 | MVP vertical slice | 4 | ⏳ Not started |

## Milestone Definitions

**M0 — Foundation.** Repository created; product, architecture, development and planning documents in place; issue and PR templates configured.

**M0.1 — Blocking open questions resolved.** Objective: resolve and formally record all questions explicitly designated as blocking for Phase 0 (the original Phase 0 list in [BACKLOG](../../planning/BACKLOG.md) and [ROADMAP](ROADMAP.md)). Acceptance criteria:

- Q-001 — Target audience: resolved and recorded in [OPEN_QUESTIONS](../../planning/OPEN_QUESTIONS.md) and the [PRD](../product/PRD.md) (§3, TA-01 to TA-08).
- Q-009 — Puzzle piece generation: resolved and recorded (PRD PS-19 to PS-24).
- Q-010 — Piece placement rules: resolved and recorded (PRD GP-06, GP-14, GP-15).
- All three decisions are traceable to their corresponding PRD requirements.
- No unrelated open question needs to be resolved for M0.1 completion.

Completion condition: all three designated blocking questions are resolved and documented. Q-011 (tray) was resolved on 2026-11-23 but was not part of the original M0.1 blocking list. Completing M0.1 does **not** mean Phase 0 is complete: Phase 0 also requires the documentation review in its [exit criteria](ROADMAP.md#phase-0--foundation-current).

**M1.x — Technical validation.** Each spike produces a short written finding and, where a decision is made, an ADR. Spike code is not merged into production code without review.

**M2 — Puzzle domain.** Pure-Dart engine implementing PUZZLE_ENGINE.md with passing unit tests.

**M3 — Playable prototype.** All confirmed initial gameplay features working on an Android device.

**M3.1 — Bright & Celebrate** (approved 2026-11-26). Objective: make the prototype bright and pleasant end to end without changing the puzzle mechanics, shuffle rules or introduction. Scope: PRD VI-06, VI-07, GP-38, GP-39 and GP-40. Acceptance criteria are defined in the approved M3.1 implementation plan. Out of scope: merging into `main`, world progression and level selection, real rewards (coins, cards, character reveal), persistence, hints, sound, and the application ID. Completing M3.1 does not complete M3.

**M3.2 — Connected Tile Groups** (approved on device 2026-11-26). Objective: add connected groups to the approved M3.1 picture-swap gameplay without changing anything else. Scope: PRD GP-41 to GP-44 and VI-08. Groups form by relative picture alignment anywhere on the board and move, merge and render as one piece, while single tiles keep drag-and-swap and the board stays full. Acceptance: approval on the product owner's Android device (given 2026-11-26); all M3.1 tests unchanged and passing. An earlier free-placement prototype ("Direction B": scattered workbench, continuous positions) was evaluated and rejected; it is not part of M3.2.

**M3.3 — Positive Connection Feedback** (approved on device 2026-11-26). Objective: make successful connections feel rewarding without changing the gameplay. Scope: PRD GP-45 and VI-09. Nice! (pair), Great! (growth), Amazing! (merge), Fantastic! (first group reaching 10+ tiles per puzzle) and Perfect! (completion only), based on actual move results, paced, never blocking input, with no rewards, scoring, combos or sound. Acceptance: approval on the product owner's Android device (given 2026-11-26, after the Fantastic! threshold was raised to 10 and limited to once per puzzle); all M3.2 tests unchanged and passing.

**M4 — MVP vertical slice.** Scope to be defined after M3.
