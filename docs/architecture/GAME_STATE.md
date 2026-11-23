# Game State

> Status: **Proposed.** Riverpod is confirmed; the provider structure below is a proposal to be validated.

## 1. State Categories

| Category | Examples | Owner (proposed) | Persisted |
| --- | --- | --- | --- |
| Static content | Worlds, collections, puzzle configs | Loaded from configuration assets | No (bundled) |
| Puzzle session | Current puzzle, piece locations | Puzzle domain state held by a Riverpod notifier | Yes (auto-save) |
| Player progress | Completed puzzles, unlocked worlds | Riverpod notifier | Yes |
| Collection | Owned cards | Riverpod notifier | Yes |
| Currency | Coin balance | Riverpod notifier | Yes |
| Settings | Sound on/off, etc. | Riverpod notifier | Yes |
| Transient UI / render | Drag position, animation progress | Flame components / widgets | No |

## 2. Principles

- **Single source of truth.** Game rules and puzzle state live in the puzzle domain; Riverpod holds and exposes that state; Flame renders it.
- **No business logic in rendering.** Flame components forward intents (e.g. "drop piece X at origin Y") and react to results.
- **Transient state stays local.** In-progress drag offsets and animations are not application state.
- **Persistence behind interfaces.** Notifiers talk to repository interfaces, not directly to a database.

## 3. Puzzle Session Lifecycle (proposed)

```
[Not started] → start(puzzleId) → [In progress] ─ placement ─┐
                                      ▲            │          │
                                      └── rejected ┘          │
                                         accepted & complete ─▼
                                                     [Completed]
                                                          │
                                          reveal → reward → progress update
```

- On each accepted placement and on app pause/background: save session.
- On resume: restore session if an unfinished one exists.
- On completion, exactly once: award coins; for a designated puzzle, award the guaranteed card unless it is already collected (CC-04, CC-06); for a non-designated puzzle, award progression rewards (CC-05, content open, Q-020); update progress; clear the saved session.
- Session management, completion reporting and reward integration are shared by all puzzle styles (PS-13, PS-16, PS-17).

## 4. Flame ↔ Riverpod Bridge

**[Open]** The exact mechanism for Flame components to read providers and send intents (e.g. passing a `ProviderContainer`/ref into the game, or using an integration package such as `flame_riverpod`). To be evaluated in Phase 1 against Rule 1 (no unnecessary dependencies) and recorded in an ADR.

## 5. Idempotency and Safety

- Completion rewards must not be granted twice (e.g. after an app restart mid-reveal).
- Saved state includes a schema version for migration.
