# Gameplay

**Hybrid puzzle system [Confirmed]:** Jigsaw Cards will support two separate puzzle styles:

| Style | Status | Characteristics |
| --- | --- | --- |
| Rectangular tile | Initial development and first prototype | Mixed-sized rectangular pieces, logical grid occupancy, rectangular partition generation |
| Traditional irregular jigsaw | Future expansion, not approved for implementation | Interlocking geometry, tabs and blanks, rotation, connected-piece grouping |

The styles are not necessarily combined within one puzzle. Both share puzzle session management, level configuration, common interaction contracts where practical, progress and completion reporting, and reward integration (PRD PS-13 to PS-17).

This document describes player-facing gameplay. Requirement IDs (GP-xx, FP-xx, CC-xx) refer to the [PRD](PRD.md). Technical behaviour is specified in [PUZZLE_ENGINE.md](../architecture/PUZZLE_ENGINE.md).

## 1. Initial Prototype — Confirmed Behaviour

### Board

- A single **4×4 logical board** (16 cells).
- The board shows where the image will be assembled. Whether empty cells show a faint outline or ghost image is a presentation detail (TBC).

### Pieces

- The image is divided into **mixed-sized rectangular pieces** by **rectangular partition generation** (PS-08). A piece covers one or more whole grid cells, for example 1×1, 1×2, 2×1 or 2×2. The allowed sizes are open (Q-009).
- Pieces together cover the whole board exactly, with no overlap.
- **No rotation** — every piece is always shown in its correct orientation.

### Tray

- At puzzle start, all pieces are arranged in a **tray below the board**.
- The tray layout must adapt to screen size (no hardcoded coordinates).
- Tray behaviour when pieces do not fit in one view (scrolling, paging, scaling) is TBC.

### Dragging and snapping

1. The player drags a piece from the tray (or from the board) onto the board.
2. When released close to a valid position, the piece **magnetically snaps** into place.
3. If the placement is **incorrect**, the piece **returns to its previous position** (tray or previous board location).
4. Feedback (sound, subtle animation) accompanies snap and rejection.

> Whether a correctly placed piece becomes locked, and the exact meaning of "incorrect" (only its correct cell vs. any free area), are defined in PUZZLE_ENGINE.md and partly open (OPEN_QUESTIONS Q-010).

### Reference preview

- The player can optionally view the full reference image.
- The interaction (hold-to-peek, toggle button, thumbnail) is TBC.

### Completion

- The puzzle completes when every piece is correctly placed.
- Completion triggers, in order:
  1. Completion feedback (sound/visual).
  2. **Character/card reveal**: on a *designated* puzzle, the guaranteed card is awarded and its character comes to life (CC-04). A card already collected does not count as new collection progress (CC-06).
  3. **Coin reward animation**.
  - On a *non-designated* puzzle, completion awards coins and progression rewards (CC-05). The content of progression rewards is open (Q-020).
  4. Return to puzzle selection or continue (flow TBC).

> **[Confirmed]** The first prototype puzzle is a designated card puzzle (CC-07), so that the full discovery and reward experience can be validated.

### Saving

- Unfinished puzzles are **saved automatically** (e.g. on each placement and when the app is backgrounded).
- Returning to a puzzle restores all piece positions.

### Audio

- Sound effects for pick-up, snap, rejection, completion, reveal and coins (exact list TBC).
- Background music is not specified for the prototype (TBC).

## 2. Future Puzzle Styles (not approved for implementation)

| Feature | Notes |
| --- | --- |
| Traditional irregular jigsaw pieces | Separate puzzle style with interlocking geometry, tabs and blanks |
| Rotation | Listed under irregular jigsaw expansion |
| Connected-piece grouping | Listed under irregular jigsaw expansion; joined pieces move together |
| Zoom and pan | For larger boards |
| Board sizes and difficulty levels | Beyond 4×4 |

These must not be implemented until approved, but the architecture should not make them impossible.
