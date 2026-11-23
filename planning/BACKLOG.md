# Backlog

Prioritised list of upcoming work. Items move to GitHub issues when scheduled. Nothing here is approved for implementation until its phase begins.

## Phase 0 — Foundation
- [x] Create repository and documentation structure
- [ ] Set repository description on GitHub (owner action)
- [ ] Review PRD and architecture documents
- [ ] Resolve blocking open questions: Q-001 (Q-009, Q-010 and Q-011 resolved 2026-11-23)

## Phase 1 — Technical Validation (spikes)
Prioritised per the [feasibility review §8](../docs/architecture/TECHNICAL_FEASIBILITY_REVIEW.md#8-proposed-technical-spikes-prioritised); each needs approval before starting.
- [ ] S-01 Hybrid shell: Flutter + `GameWidget` + Riverpod + overlay + lifecycle → TD-03, TD-04, TD-05
- [ ] S-02 Rive reveal: frame timing, APK size, minSdk → Q-015
- [ ] S-03 Drag, snap and lock; two-row scrollable tray (approved Q-010, Q-011) → GP-03 to GP-06, GP-14 to GP-19
- [ ] S-04 Rectangular partition generation under the approved Q-009 constraints (pure Dart) → TD-02
- [ ] S-05 Audio latency and lifecycle (`flame_audio`)
- [ ] S-06 Persistence: atomic write-and-replace JSON store; background-kill, force-stop and staged-termination tests; recovery-policy alternatives; reward consistency → TD-01, Q-014
- [ ] S-07 Screen sizes and API 36 large-screen orientation behaviour → Q-013 input
- [ ] Write ADRs for TD-01 to TD-08
- [ ] Set up CI (format, analyze, test) when code starts (TD-08)

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
- [ ] Board and two-row scrollable tray layout, adapting to phone screen sizes (GP-16 to GP-19)
- [ ] Drag, snap, reject animations
- [ ] Reference preview
- [ ] Completion → reveal → coin reward
- [ ] Sound effects
- [ ] Auto-save and restore

## Icebox (future — requires approval)
- Irregular jigsaw pieces
- Rotation
- Connected-piece grouping
- Zoom and pan
- Board sizes and difficulty levels
- Firebase services
