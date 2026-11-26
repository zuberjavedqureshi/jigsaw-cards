# Backlog

Prioritised list of upcoming work. Items move to GitHub issues when scheduled. Nothing here is approved for implementation until its phase begins.

## Phase 0 — Foundation
- [x] Create repository and documentation structure
- [ ] Set repository description on GitHub (owner action)
- [ ] Review PRD and architecture documents
- [x] Resolve blocking open questions: Q-001 resolved 2026-11-24 (Q-009, Q-010 and Q-011 resolved 2026-11-23)

## Phase 1 — Technical Validation (spikes)
Prioritised per the [feasibility review §8](../docs/architecture/TECHNICAL_FEASIBILITY_REVIEW.md#8-proposed-technical-spikes-prioritised); each needs approval before starting.
- [ ] S-01 Hybrid shell: Flutter + `GameWidget` + Riverpod + overlay + lifecycle → TD-03, TD-04, TD-05 confirmed 2026-11-24 (ADR-0001 to ADR-0003); **Android device validation outstanding** (§8.1 timings, `paused`/`resumed`)
- [ ] S-02 Rive reveal: frame timing, APK size, minSdk → Q-015
- [ ] S-03 Drag-and-swap feel and animation tuning on devices (Q-010 and Q-011 revised again 2026-11-25) → GP-29 to GP-35
- [ ] ~~S-04 Rectangular partition generation under the approved Q-009 constraints (pure Dart) → TD-02~~ Superseded 2026-11-25 for the picture-swap gameplay (Q-022); a provisional generator already exists but is unused
- [ ] S-05 Audio latency and lifecycle (`flame_audio`)
- [ ] S-06 Persistence: atomic write-and-replace JSON store; background-kill, force-stop and staged-termination tests; recovery-policy alternatives; reward consistency → TD-01, Q-014
- [ ] S-07 Screen sizes and API 36 large-screen orientation behaviour → Q-013 input
- [ ] Write ADRs for TD-01 to TD-08 (TD-03, TD-04, TD-05 done: ADR-0001 to ADR-0003)
- [ ] Set up CI (format, analyze, test, domain boundary guard per ADR-0002) when code starts (TD-08)

## Phase 2 — Puzzle Domain
- [ ] Grid and cell model
- [ ] Piece definition and location model
- [ ] Configuration loading and tiling validation
- [ ] ~~Rectangular partition generation: constraints per PRD PS-19 to PS-24 (Q-009); algorithm per TD-02~~ Superseded 2026-11-25 (Q-022): uniform 4×4 grid of equal tiles with a seeded shuffle, implemented on a feature branch
- [ ] Occupancy
- [ ] Placement validation
- [ ] Completion detection
- [ ] Serialisation / restore

## Phase 3 — Prototype
- [x] Picture-swap board: shuffled 4 × 4 grid of equal tiles that keeps the artwork's aspect ratio (GP-29 to GP-31, GP-35). First implementation on a feature branch, not device-validated
- [x] Drag-and-swap with press, target and exchange animations, cancel on release outside, correct-tile feedback and completion state (GP-32 to GP-34). First implementation on a feature branch
- [x] Puzzle introduction: card entrance and reveal (GP-37), commit `37c5af4`; approved by the product owner on their Android phone 2026-11-26
- [x] Functional device check of the picture-swap gameplay by the product owner (2026-11-25/26); performance and low-end device validation (S-01) still outstanding
- [x] **M3.1 Bright & Celebrate** (approved 2026-11-26; implemented and approved on device 2026-11-26): Sunlit Storybook palette with the patterned violet gameplay background (VI-06); bright code-drawn daytime placeholder picture (VI-07); board spacing (GP-38); short completion celebration without rewards (GP-39); next-puzzle transition (GP-40)
- [x] Q-022 resolved 2026-11-25: equal-sized tiles on a uniform 4×4 grid. Q-023 resolved 2026-11-25: correct tiles remain movable. The implementation already matches both
- *(Superseded 2026-11-25: scattered face-down start, 4-second preview, tap to reveal, free placement)*
- [ ] Reference preview
- [ ] Completion → reveal → coin reward
- [ ] Sound effects
- [ ] Auto-save and restore, including the persisted layout (PS-23, Q-009): outstanding

## v1 (planned, not in the initial prototype)
- [ ] Hints (GP-36): design not yet specified

## Icebox (future — requires approval)
- Irregular jigsaw pieces
- Rotation
- Connected-piece grouping
- Zoom and pan
- Board sizes and difficulty levels
- Firebase services
