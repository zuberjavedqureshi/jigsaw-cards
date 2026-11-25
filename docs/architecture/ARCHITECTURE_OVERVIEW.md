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
- **[Confirmed]** Hand-written Riverpod `Notifier` providers; no code generation or `build_runner` at the current scale (TD-05, [ADR-0003](../decisions/ADR-0003-handwritten-riverpod-providers.md)).

Details: [GAME_STATE.md](GAME_STATE.md).

### 2.3 Puzzle domain (pure Dart)

- **[Confirmed]** Independent pure-Dart module, with no dependency on Flutter or Flame.
- **[Confirmed]** Packaged as `packages/puzzle_domain/` in a Dart pub workspace. The package structure alone does not enforce the boundary, so it is enforced by `depend_on_referenced_packages: error`, a static dependency/import/export guard run in CI, and plain-Dart analysis and tests (TD-04, [ADR-0002](../decisions/ADR-0002-pub-workspace-and-domain-boundary.md)).
- **[Confirmed]** Supports the hybrid puzzle system: rectangular pieces now, irregular jigsaw later (not yet implemented).
- **[Proposed]** Exposes immutable state and pure operations (e.g. "attempt placement" → result + new state), which makes it deterministic and unit-testable.

Details: [PUZZLE_ENGINE.md](PUZZLE_ENGINE.md).

### 2.4 Flame rendering layer

- **[Confirmed]** Flame as the game engine; flame_audio for audio.
- **[Confirmed]** Flame communicates with the application layer through a manual bridge: intent callbacks out and a small view interface in, with explicit initial-state sync. Flame game and component classes do not use Riverpod, and `flame_riverpod` is not used (TD-03, [ADR-0001](../decisions/ADR-0001-flame-riverpod-manual-bridge.md)).
- **[Proposed]** Flame components translate pointer input into domain commands, and render the domain state. All positions are derived from the board layout computed from screen size — no hardcoded screen coordinates.
- **[Confirmed, subject to validation]** Rive for character animation.

### 2.5 Local persistence

- **[Confirmed]** Local-first.
- **[Open]** Database/storage choice (candidates to evaluate during validation; no selection yet). See [TECHNICAL_DECISIONS.md](TECHNICAL_DECISIONS.md).
- **[Proposed]** Persistence accessed through repository interfaces so that the storage engine (and later a backend) can change without touching the domain or UI.
- **[Proposed]** Persisted data is versioned to allow migrations.

### 2.6 Future backend integration

- **[Confirmed]** Firebase is used *when justified* (e.g. cloud save, remote config, analytics, crash reporting). No backend is required for the prototype.
- **[Proposed]** Backend services plug in behind the same repository/service interfaces as local persistence.

## 3. Data Flow — Swapping Two Tiles (implemented on a feature branch)

1. The player presses a tile and drags it. Flame handles the gesture, the selection feedback and the target highlight, finding the cell under the finger from the board grid.
2. On release over another tile, Flame sends the two cells to the application state (bridge intent). A release anywhere else is cancelled in Flame, and the tile glides back.
3. The puzzle domain exchanges the two tiles and returns the new immutable puzzle. Incorrect swaps are accepted.
4. The application layer syncs the new puzzle to Flame, which animates both tiles into their new cells, highlights tiles that are now correct, and blocks input until the board has settled.
5. Application state will trigger auto-save (not implemented); on completion it triggers the completion state, and later reveal and reward.

*History:* earlier versions of this flow covered tray placement with rejection, then free placement with snapping (both superseded 2026-11-25).

## 4. Project Layout (confirmed, not yet created)

```
pubspec.yaml            Dart pub workspace root
app/                    Flutter application
packages/
  puzzle_domain/        Pure Dart puzzle engine
```

**[Confirmed]** by TD-04 / [ADR-0002](../decisions/ADR-0002-pub-workspace-and-domain-boundary.md) on 2026-11-24, including the boundary enforcement described in §2.3. The production project has not been created yet; the S-01 spike layout is the reference.

## 5. Non-Goals for the Prototype

- No rotation, irregular shapes, grouping, zoom/pan, or variable board sizes.
- No backend.
- No speculative abstraction layers beyond what the prototype needs.
