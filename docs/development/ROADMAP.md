# Roadmap

> **Status: Proposed.** The approved PRD v1.0 defines its own development phases, but their text has not yet been supplied to the repository (PRD §16, Q-019). This roadmap will be reconciled with them.
>
> Dates are not set. Phases are sequential; a phase starts only when the previous phase's exit criteria are met.

## Phase 0 — Foundation *(current)*

- Repository, documentation and contribution workflow.
- Resolve blocking open questions (target audience, placement rule, piece layout method). Placement rule (Q-010), piece layout (Q-009) and tray (Q-011) were resolved 2026-11-23; target audience (Q-001) was resolved 2026-11-24.

**Exit:** documentation reviewed; blocking questions answered or explicitly deferred.

## Phase 1 — Technical Validation

Time-boxed spikes (on `spike/*` branches) to validate:

- Flutter + Flame + Riverpod integration in the hybrid architecture.
- Drag-and-snap feel and performance on target Android devices.
- Rive character animation inside the app (or decide an alternative).
- flame_audio latency for feedback sounds.
- Local persistence options → select one (ADR).
- Responsive board/tray layout across screen sizes.

**Exit:** ADRs for each validated decision; Flutter project structure approved.

## Phase 2 — Puzzle Domain

- Pure-Dart puzzle engine: configuration, grid, pieces, occupancy, placement, completion, serialisation.
- Full unit test coverage of domain rules.

**Exit:** engine passes all tests; no Flutter/Flame dependency.

## Phase 3 — Playable Prototype

- One 4×4 mixed-rectangle puzzle end to end: tray, drag, snap, reject, preview, completion, reveal, coin animation, sound effects, auto-save/restore.

**Exit:** prototype success criteria in the PRD are met.

## Phase 4 — MVP Vertical Slice

- First world (working name: Enchanted Forest) content, card collection, progression, mascot introduction, polish.
- Scope finalised after Phase 3.

## Later (requires approval)

- Remaining worlds (working names: Ocean Kingdom, Fantasy Kingdom, Cosmic Adventures).
- Future puzzle styles: irregular pieces, rotation, grouping, zoom/pan, board sizes and difficulty levels.
- Firebase services where justified.
