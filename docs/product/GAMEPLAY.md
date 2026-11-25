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

- The image is divided into **mixed-sized rectangular pieces** by **rectangular partition generation** (PS-08).
- **[Confirmed]** Allowed piece dimensions: **1×1, 1×2, 2×1 and 2×2** (PS-20). Piece-count constraint: every generated prototype layout must contain between **8 and 12** pieces, inclusive (PS-21).
- **[Confirmed]** Layouts are produced by **seeded generation** (PS-22). The generated layout is **persisted**, so an unfinished puzzle keeps exactly the same arrangement (PS-23).
- Hand-authored layouts are not required for the prototype; they may come in a later phase (PS-24).
- Pieces together cover the whole board exactly, with no overlap. This is the tiling invariant that follows from rectangular partition generation (PS-08; PUZZLE_ENGINE §4).
- **No rotation** — every piece is always shown in its correct orientation.

### Start: scattered face-down pieces (GP-20, GP-27)

- **[Confirmed 2026-11-25]** The board is the primary gameplay workspace. At puzzle start every piece lies **face-down** (decorative back) at its own **scattered position on the board**. There is no tray in the primary interaction.
- Starting positions are seeded and randomised, independent of the correct positions, visibly distributed and individually selectable. No piece starts at its correct position, and the arrangement does not expose the solution.

### Memory preview (GP-21, GP-22)

1. A short introduction is shown while the pieces are face-down. The player cannot move pieces yet.
2. **[Confirmed]** Every piece flips face-up and stays visible for **exactly 4 seconds**. No interaction during the preview.
3. **[Confirmed]** Every piece flips face-down again and memory mode begins.

### Reveal, arrange and lock (GP-23 to GP-26, GP-15)

1. **[Confirmed]** **Tap to reveal:** tapping a face-down piece reveals only that piece. A revealed piece stays face-up, including while it is moved.
2. **[Confirmed]** **Free placement:** a revealed piece can be dragged anywhere on the board. Pieces may overlap temporarily; the piece being moved is drawn above the others. When pieces overlap, a touch selects the topmost selectable piece.
3. **[Confirmed]** An **incorrect** drop is accepted: the piece stays where it was dropped and is never sent back automatically. It can be picked up and repositioned as often as the player likes.
4. **[Confirmed]** When a piece is aligned with its correct position within the **snapping tolerance**, it **magnetically snaps** exactly into place and becomes **permanently locked** (GP-05, GP-15). Locked pieces cannot be moved or swapped.
5. Feedback (subtle animation now; sound later) accompanies reveal, pick-up and snap.

> The snapping tolerance, the introduction length and animation timings are tuning parameters kept in configuration (S-03). The 4-second preview length is a product decision, not a tuning parameter.

### Layout (GP-28)

- The board and its pieces fit different phone aspect ratios within the system safe area, with no hardcoded coordinates. Pieces always stay fully on the board area and remain individually selectable.

### Superseded (history)

- **Q-011, 2026-11-23 → revised 2026-11-25:** pieces previously started in a two-row, horizontally scrolling tray below the board, with comfortable touch targets, and enlarged to board scale when picked up (GP-03, GP-04, GP-16 to GP-19).
- **Q-010, 2026-11-23 → revised 2026-11-25:** previously only the correct position accepted a piece (GP-14), and incorrect drops animated back to their previous (tray) position (GP-06). Locking of correctly placed pieces (GP-15) is unchanged.

### Reference preview

- The player can optionally view the full reference image.
- The interaction (hold-to-peek, toggle button, thumbnail) is TBC.

### Completion

- The puzzle completes when every piece is correctly placed.
- Completion triggers, in order:
  1. Completion feedback (sound/visual).
  2. **Character/card reveal**: on a *designated* puzzle, the guaranteed card is awarded and its character comes to life (CC-04). A card already collected does not count as new collection progress (CC-06).
  3. **Coin reward animation**.
  4. Return to puzzle selection or continue (flow TBC).

- On a *non-designated* puzzle, step 2 is replaced by progression rewards (CC-05). The content of progression rewards, and how they are presented, is open (Q-020).

> **[Confirmed]** The first prototype puzzle is a designated card puzzle (CC-07), so that the full discovery and reward experience can be validated.

### Saving

- Unfinished puzzles are **saved automatically** (e.g. on each placement and when the app is backgrounded).
- Returning to a puzzle restores all piece positions, reveal states and locks. **Not yet implemented**; the persisted-layout requirement PS-23 is also outstanding.

### Audio

- Sound effects for reveal, pick-up, snap, completion, card reveal and coins (exact list TBC).
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
