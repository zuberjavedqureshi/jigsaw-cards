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
- [ ] S-03 Drag, snap and lock feel; snapping tolerance and animation tuning on devices (Q-010 and Q-011 revised 2026-11-25) → GP-05, GP-15, GP-20 to GP-28
- [ ] S-04 Rectangular partition generation under the approved Q-009 constraints (pure Dart) → TD-02
- [ ] S-05 Audio latency and lifecycle (`flame_audio`)
- [ ] S-06 Persistence: atomic write-and-replace JSON store; background-kill, force-stop and staged-termination tests; recovery-policy alternatives; reward consistency → TD-01, Q-014
- [ ] S-07 Screen sizes and API 36 large-screen orientation behaviour → Q-013 input
- [ ] Write ADRs for TD-01 to TD-08 (TD-03, TD-04, TD-05 done: ADR-0001 to ADR-0003)
- [ ] Set up CI (format, analyze, test, domain boundary guard per ADR-0002) when code starts (TD-08)

## Phase 2 — Puzzle Domain
- [ ] Grid and cell model
- [ ] Piece definition and location model
- [ ] Configuration loading and tiling validation
- [ ] Rectangular partition generation: constraints per PRD PS-19 to PS-24 (Q-009); algorithm per TD-02
- [ ] Occupancy
- [ ] Placement validation
- [ ] Completion detection
- [ ] Serialisation / restore

## Phase 3 — Prototype
- [x] Board workspace layout adapting to phone aspect ratios (GP-27, GP-28): first implementation on a feature branch, not device-validated
- [x] Scattered face-down start, 4-second preview, tap to reveal (GP-20 to GP-23): first implementation on a feature branch
- [x] Free placement, flip, selection, snap and lock animations (GP-24 to GP-26): first implementation on a feature branch
- [ ] Physical-device validation of the free-placement gameplay
- [ ] Reference preview
- [ ] Completion → reveal → coin reward
- [ ] Sound effects
- [ ] Auto-save and restore, including the persisted layout (PS-23, Q-009): outstanding

## Icebox (future — requires approval)
- Irregular jigsaw pieces
- Rotation
- Connected-piece grouping
- Zoom and pan
- Board sizes and difficulty levels
- Firebase services
