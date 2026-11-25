# Gameplay

**Hybrid puzzle system [Confirmed]:** Jigsaw Cards will support two separate puzzle styles:

| Style | Status | Characteristics |
| --- | --- | --- |
| Rectangular tile | Initial development and first prototype | Mixed-sized rectangular pieces, logical grid occupancy, rectangular partition generation |
| Traditional irregular jigsaw | Future expansion, not approved for implementation | Interlocking geometry, tabs and blanks, rotation, connected-piece grouping |

The styles are not necessarily combined within one puzzle. Both share puzzle session management, level configuration, common interaction contracts where practical, progress and completion reporting, and reward integration (PRD PS-13 to PS-17).

This document describes player-facing gameplay. Requirement IDs (GP-xx, FP-xx, CC-xx) refer to the [PRD](PRD.md). Technical behaviour is specified in [PUZZLE_ENGINE.md](../architecture/PUZZLE_ENGINE.md).

## 1. Initial Prototype — Confirmed Behaviour

### Picture-swap puzzle (approved 2026-11-25; PRD GP-29 to GP-36)

The product owner chose this gameplay from a reference gameplay recording. It replaces the earlier tray and memory/free-placement designs (history below).

### Board (GP-01, GP-29, GP-35)

- A fixed **rectangular grid**: **4 × 4** for the prototype.
- Every cell always holds exactly **one tile**. There are no empty cells, no overlapping and no free-floating pieces, and tiles never leave the board.
- The board keeps the illustration's aspect ratio and fits phone screens within the safe area, with comfortable touch targets.

### Tiles (GP-30)

- The illustration is cut into **equal-size tiles** on the grid, without stretching. Each tile always shows its own fragment, wherever it currently is.
- Every tile is **face-up from the start**. There is no face-down state, preview or reveal.
- No rotation.
- *Open (Q-022):* how this relates to the confirmed mixed-size partition (PS-08, PS-19 to PS-21). The prototype uses equal tiles.

### Start (GP-31)

- The tiles begin **shuffled** (seeded and deterministic). The arrangement is never already solved, and every arrangement can be solved by swapping.

### Drag-and-swap (GP-32, GP-33)

1. The player presses a tile, which shows clear selection feedback.
2. The player drags it over another tile, which is clearly highlighted as the target.
3. On release, the **two tiles exchange cells** with a smooth animation.
4. Incorrect swaps are allowed and never rejected. Swaps are unlimited, with no penalty.
5. Releasing outside another tile (or back on its own cell) **cancels**: the tile returns to its own cell.
6. The interaction is direct drag-and-drop; there is no tap-then-tap selection.

> Whether a tile locks once it is in its correct cell is open (Q-023). The prototype keeps every tile swappable.

### Hints (GP-36)

- **Intentionally excluded from the initial prototype; planned for v1.** The hint design is not specified yet.

### Superseded (history)

- **Q-011, 2026-11-23:** pieces started in a two-row, horizontally scrolling tray below the board (GP-03, GP-04, GP-16 to GP-19). **Revised 2026-11-25:** pieces started face-down and scattered across the board (GP-20, GP-27, GP-28). **Revised again 2026-11-25:** fixed, fully filled grid (above).
- **Q-010, 2026-11-23:** strict placement. Only the correct position accepted a piece, incorrect drops animated back (GP-06, GP-14), and correct pieces locked (GP-15). **Revised 2026-11-25:** free placement, with a 4-second memory preview and tap to reveal (GP-21 to GP-26). **Revised again 2026-11-25:** drag-and-swap (above).
- Magnetic snapping (GP-05) and permanent locking (GP-15) belonged to those placement rules and do not apply to the picture-swap puzzle.

### Reference preview

- The player can optionally view the full reference image.
- The interaction (hold-to-peek, toggle button, thumbnail) is TBC.

### Completion

- The puzzle completes when **every tile is in its correct cell** (GP-34). A tile that lands in its correct cell gets brief visual feedback.
- The completion state shows the finished illustration with a New puzzle (later: Continue) action.
- Completion triggers, in order:
  1. Completion feedback (sound/visual).
  2. **Character/card reveal**: on a *designated* puzzle, the guaranteed card is awarded and its character comes to life (CC-04). A card already collected does not count as new collection progress (CC-06).
  3. **Coin reward animation**.
  4. Return to puzzle selection or continue (flow TBC).

- On a *non-designated* puzzle, step 2 is replaced by progression rewards (CC-05). The content of progression rewards, and how they are presented, is open (Q-020).

> **[Confirmed]** The first prototype puzzle is a designated card puzzle (CC-07), so that the full discovery and reward experience can be validated.

### Saving

- Unfinished puzzles are **saved automatically** (e.g. on each placement and when the app is backgrounded).
- Returning to a puzzle restores the tile arrangement. **Not yet implemented**; the persisted-layout requirement PS-23 is also outstanding.

### Audio

- Sound effects for pick-up, swap, correct tile, completion, card reveal and coins (exact list TBC).
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
