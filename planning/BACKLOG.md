# Backlog

Prioritised list of upcoming work. Items move to GitHub issues when scheduled. Nothing here is approved for implementation until its phase begins.

## Phase 0 — Foundation
- [x] Create repository and documentation structure
- [ ] Set repository description on GitHub (owner action)
- [ ] Review PRD and architecture documents
- [ ] Resolve blocking open questions: Q-001, Q-009, Q-010

## Phase 1 — Technical Validation (spikes)
- [ ] Spike: Flutter app embedding Flame `GameWidget` with Riverpod state
- [ ] Spike: drag-and-snap prototype on a 4×4 grid, measure feel on device
- [ ] Spike: Rive animation playback (in Flutter overlay and/or Flame)
- [ ] Spike: flame_audio feedback latency
- [ ] Evaluate local persistence options → ADR
- [ ] Decide project layout (`app/` + `packages/puzzle_domain/`) → ADR
- [ ] Decide Flame ↔ Riverpod bridge → ADR
- [ ] Set up CI (format, analyze, test)

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
