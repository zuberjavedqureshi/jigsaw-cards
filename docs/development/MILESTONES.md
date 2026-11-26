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

**M4 — MVP vertical slice.** Scope to be defined after M3.
