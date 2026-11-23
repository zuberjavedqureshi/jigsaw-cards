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
- **[Confirmed]** Allowed piece dimensions: **1×1, 1×2, 2×1 and 2×2** (PS-20). Target piece count: **8–12** (PS-21).
- **[Confirmed]** Layouts are produced by **seeded generation** (PS-22). The generated layout is **persisted**, so an unfinished puzzle keeps exactly the same arrangement (PS-23).
- Hand-authored layouts are not required for the prototype; they may come in a later phase (PS-24).
- Pieces together cover the whole board exactly, with no overlap.
- **No rotation** — every piece is always shown in its correct orientation.

### Tray

- At puzzle start, all pieces are arranged in a **tray below the board**.
- **[Confirmed]** The tray has **two rows** and **scrolls horizontally** (GP-16).
- **[Confirmed]** Tray pieces keep **comfortable touch targets** (GP-17).
- **[Confirmed]** Picking up a piece **enlarges it to board scale** (GP-18).
- **[Confirmed]** The layout adapts to different phone screen sizes (GP-19), with no hardcoded coordinates.

### Dragging and snapping

1. The player drags a piece from the tray onto the board.
2. **[Confirmed]** Only the piece's **correct position** accepts it (GP-14). When released close enough to that position, the piece **magnetically snaps** into place.
3. **[Confirmed]** A correctly placed piece becomes **permanently locked**. Locked pieces cannot be moved or swapped (GP-15).
4. **[Confirmed]** If the drop is **incorrect**, the piece **animates back to its previous position** (GP-06). Because placed pieces are locked, a piece can only be picked up from the tray, so its previous position is its tray position.
5. Feedback (sound, subtle animation) accompanies snap and rejection.

> Snap distance and animation timing are tuning parameters, set during technical validation (S-03) and kept in configuration.

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
