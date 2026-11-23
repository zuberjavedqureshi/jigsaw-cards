# Architecture Overview

> Status: **Proposed.** The high-level shape is confirmed; implementation details are proposals to be validated in Phase 1 (technical validation).

Every statement in this document is labelled:

- **[Confirmed]** — approved product/technical decision.
- **[Proposed]** — recommended implementation choice, subject to validation and an ADR.
- **[Open]** — undecided.

## 1. Architectural Style

**[Confirmed]** Hybrid Flutter + Flame architecture with an independent pure-Dart puzzle domain.

- Flutter owns the application: screens, navigation, menus, collection views, overlays.
- Flame owns the interactive puzzle scene: rendering pieces, drag gestures, snap animations, effects.
- The puzzle rules live in a pure-Dart module that knows nothing about Flutter or Flame.

## 2. Layers

```
┌──────────────────────────────────────────────────────────┐
│ Flutter application layer                                │
│  Screens, navigation, menus, collection, overlays        │
└───────────────┬──────────────────────────────────────────┘
                │ reads / invokes
┌───────────────▼──────────────────────────────────────────┐
│ Riverpod application state                               │
│  Providers / notifiers: session, progress, collection    │
└───────┬──────────────────────────────┬───────────────────┘
        │ uses                         │ uses
┌───────▼─────────────────┐   ┌────────▼──────────────────┐
│ Puzzle domain (pure Dart)│   │ Persistence (local-first) │
│  Config, grid, pieces,   │   │  Repositories behind      │
│  placement, completion   │   │  interfaces               │
└───────▲─────────────────┘   └────────┬──────────────────┘
        │ commands / state             │ (future)
┌───────┴─────────────────┐   ┌────────▼──────────────────┐
│ Flame rendering layer    │   │ Backend (Firebase, when   │
│  Piece components, drag, │   │ justified)                │
│  snap animation, effects │   └───────────────────────────┘
└─────────────────────────┘
```

### 2.1 Flutter application layer

- **[Confirmed]** Flutter, Dart, Android first, portrait.
- **[Proposed]** Flame's `GameWidget` is embedded inside a Flutter screen; Flutter overlays handle HUD, preview button, reveal and reward UI where Flutter widgets are a better fit.
- **[Open]** Routing package (Flutter's built-in navigation vs. a routing library) — decide only if needed (Rule 1: no unnecessary dependencies).

### 2.2 Riverpod application state

- **[Confirmed]** Riverpod for state management.
- **[Proposed]** Riverpod holds application-level state (current puzzle session, player progress, coins, collection) and calls into the puzzle domain. Flame components do not own game rules.
- **[Open]** Code generation (`riverpod_generator`) vs. hand-written providers.

Details: [GAME_STATE.md](GAME_STATE.md).

### 2.3 Puzzle domain (pure Dart)

- **[Confirmed]** Independent pure-Dart module, with no dependency on Flutter or Flame.
- **[Proposed]** Packaged as a separate Dart package inside the repository (e.g. `packages/puzzle_domain/`) so that the boundary is enforced by the dependency graph.
- **[Confirmed]** Supports the hybrid puzzle system: rectangular pieces now, irregular jigsaw later (not yet implemented).
- **[Proposed]** Exposes immutable state and pure operations (e.g. "attempt placement" → result + new state), which makes it deterministic and unit-testable.

Details: [PUZZLE_ENGINE.md](PUZZLE_ENGINE.md).

### 2.4 Flame rendering layer

- **[Confirmed]** Flame as the game engine; flame_audio for audio.
- **[Proposed]** Flame components translate pointer input into domain commands, and render the domain state. All positions are derived from the board/tray layout computed from screen size — no hardcoded screen coordinates.
- **[Confirmed, subject to validation]** Rive for character animation.

### 2.5 Local persistence

- **[Confirmed]** Local-first.
- **[Open]** Database/storage choice (candidates to evaluate during validation; no selection yet). See [TECHNICAL_DECISIONS.md](TECHNICAL_DECISIONS.md).
- **[Proposed]** Persistence accessed through repository interfaces so that the storage engine (and later a backend) can change without touching the domain or UI.
- **[Proposed]** Persisted data is versioned to allow migrations.

### 2.6 Future backend integration

- **[Confirmed]** Firebase is used *when justified* (e.g. cloud save, remote config, analytics, crash reporting). No backend is required for the prototype.
- **[Proposed]** Backend services plug in behind the same repository/service interfaces as local persistence.

## 3. Data Flow — Placing a Piece (proposed)

1. Player drags a piece (Flame handles the gesture and visual drag).
2. On release, Flame converts the drop position into a candidate grid position using the current layout.
3. The candidate is sent to the puzzle domain via the application state.
4. The domain validates the placement and returns accepted/rejected plus new state.
5. Flame animates the snap or the return to the previous position; flame_audio plays feedback.
6. Application state triggers auto-save; on completion it triggers reveal and reward.

## 4. Proposed Project Layout (not yet created)

```
app/                    Flutter application (created in Phase 1)
packages/
  puzzle_domain/        Pure Dart puzzle engine
```

This layout is a proposal and will be confirmed by an ADR before the Flutter project is created.

## 5. Non-Goals for the Prototype

- No rotation, irregular shapes, grouping, zoom/pan, or variable board sizes.
- No backend.
- No speculative abstraction layers beyond what the prototype needs.
