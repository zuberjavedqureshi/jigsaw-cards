# Gameplay

This document describes player-facing gameplay. Technical behaviour is specified in [PUZZLE_ENGINE.md](../architecture/PUZZLE_ENGINE.md).

## 1. Initial Prototype — Confirmed Behaviour

### Board

- A single **4×4 logical board** (16 cells).
- The board shows where the image will be assembled. Whether empty cells show a faint outline or ghost image is a presentation detail (TBC).

### Pieces

- The image is divided into **mixed-sized rectangular pieces**. A piece covers one or more whole grid cells (for example 1×1, 1×2, 2×1, 2×2).
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
  2. **Character/card reveal** — the puzzle's character comes to life.
  3. **Coin reward animation**.
  4. Return to puzzle selection or continue (flow TBC).

### Saving

- Unfinished puzzles are **saved automatically** (e.g. on each placement and when the app is backgrounded).
- Returning to a puzzle restores all piece positions.

### Audio

- Sound effects for pick-up, snap, rejection, completion, reveal and coins (exact list TBC).
- Background music is not specified for the prototype (TBC).

## 2. Future Puzzle Styles (not approved for implementation)

| Feature | Notes |
| --- | --- |
| Traditional irregular jigsaw pieces | Tab/blank piece shapes |
| Rotation | Pieces may need rotating before placement |
| Connected-piece grouping | Joined pieces move together |
| Zoom and pan | For larger boards |
| Board sizes and difficulty levels | Beyond 4×4 |

These must not be implemented until approved, but the architecture should not make them impossible.
