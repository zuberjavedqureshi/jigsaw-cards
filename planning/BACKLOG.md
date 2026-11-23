# Backlog

Prioritised list of upcoming work. Items move to GitHub issues when scheduled. Nothing here is approved for implementation until its phase begins.

## Phase 0 — Foundation
- [x] Create repository and documentation structure
- [ ] Set repository description on GitHub (owner action)
- [ ] Review PRD and architecture documents
- [ ] Resolve blocking open questions: Q-001, Q-009, Q-010

## Phase 1 — Technical Validation (spikes)
Prioritised per the [feasibility review §8](../docs/architecture/TECHNICAL_FEASIBILITY_REVIEW.md#8-proposed-technical-spikes-prioritised); each needs approval before starting.
- [ ] S-01 Hybrid shell: Flutter + `GameWidget` + Riverpod + overlay + lifecycle → TD-03, TD-04, TD-05
- [ ] S-02 Rive reveal: performance, APK size, minSdk → Q-015
- [ ] S-03 Drag, snap and tray layout → GP-03 to GP-06, Q-011 and Q-010 input
- [ ] S-04 Rectangular partition generation (pure Dart) → TD-02, Q-009 input
- [ ] S-05 Audio latency and lifecycle (`flame_audio`)
- [ ] S-06 Persistence: atomic JSON store, crash safety → TD-01, Q-014
- [ ] S-07 Screen sizes and orientation at API 36 → Q-013 input
- [ ] Write ADRs for TD-01 to TD-08
- [ ] Set up CI (format, analyze, test) when code starts (TD-08)

## Phase 2 — Puzzle Domain
- [ ] Grid and cell model
- [ ] Piece definition and location model
- [ ] Configuration loading and tiling validation
- [ ] Rectangular partition generation (algorithm per Q-009 / TD-02)
- [ ] Occupancy
- [ ] Placement validation
- [ ] Completion detection
- [ ] Serialisation / restore

## Phase 3 — Prototype
- [ ] Board and tray layout (responsive)
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
