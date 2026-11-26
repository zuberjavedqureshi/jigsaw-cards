# Gameplay

**Hybrid puzzle system [Confirmed]:** Jigsaw Cards will support two separate puzzle styles:

| Style | Status | Characteristics |
| --- | --- | --- |
| Rectangular tile | Initial development and first prototype | Picture-swap puzzle: equal-sized rectangular tiles on a uniform grid, logical grid occupancy (Q-022; originally mixed-sized pieces from rectangular partition generation, superseded 2026-11-25) |
| Traditional irregular jigsaw | Future expansion, not approved for implementation | Interlocking geometry, tabs and blanks, rotation, connected-piece grouping |

The styles are not necessarily combined within one puzzle. Both share puzzle session management, level configuration, common interaction contracts where practical, progress and completion reporting, and reward integration (PRD PS-13 to PS-17).

This document describes player-facing gameplay. Requirement IDs (GP-xx, FP-xx, CC-xx) refer to the [PRD](PRD.md). Technical behaviour is specified in [PUZZLE_ENGINE.md](../architecture/PUZZLE_ENGINE.md).

## 1. Initial Prototype — Confirmed Behaviour

### Picture-swap puzzle (approved 2026-11-25; PRD GP-29 to GP-36)

The product owner chose this gameplay from a reference gameplay recording. It replaces the earlier tray and memory/free-placement designs (history below).

### Board (GP-01, GP-29, GP-35, GP-38)

- A fixed, uniform **rectangular grid**: **4 × 4** for the prototype (Q-022).
- Every cell always holds exactly **one tile**. There are no empty cells, no overlapping, no free placement and no free-floating pieces, and tiles never leave the board.
- The board keeps the illustration's aspect ratio and fits phone screens within the safe area, with comfortable touch targets.
- **[Confirmed 2026-11-26] Spacing (GP-38):** measured to the outer edge of the board frame, the horizontal margin to each screen edge is 20–32 dp, scaling with screen width. The board is centred vertically between the header and the bottom safe area, respects every safe area, has a maximum width on large screens and never touches a screen edge. No bottom action bar is reserved until hint and preview actions exist.

### Tiles (GP-30)

- **[Confirmed, Q-022]** The illustration is cut into **16 equal-sized rectangular tiles** with identical dimensions, without stretching. Each tile always shows its own fragment, wherever it currently is.
- Every tile is **face-up from the start**. There is no face-down state, preview or reveal.
- No rotation.
- Mixed-size pieces (1×1, 1×2, 2×1, 2×2; 8–12 pieces) are **superseded** for this gameplay (Q-022, Q-009 revised 2026-11-25).

### Start (GP-31)

- The tiles begin **shuffled** (seeded and deterministic). The arrangement is never already solved, and every arrangement can be solved by swapping.

### Puzzle introduction (GP-37; implemented, approved 2026-11-26)

1. Every new puzzle starts with all tiles showing the shared **card back**.
2. **Entrance:** the tiles fly in from below the board one by one, slightly tilted, and settle into their **actual shuffled cells**, row by row from the top-left.
3. **Reveal:** once every tile has arrived, the tiles flip to their picture in a fast, coordinated sequence.
4. **Ready:** every fragment is visible in the same shuffled arrangement and the player can drag and swap immediately.

- Input is disabled until the reveal has finished. The introduction never changes the arrangement and runs again for every new puzzle.
- It is a reusable presentation shared by all puzzles. Timings are provisional tuning values (about 1.7 s entrance and 1 s reveal).
- The card back is a code-drawn placeholder design (turquoise with a white border and mark) until branded artwork exists.

### Drag-and-swap (GP-32, GP-33)

1. The player presses a tile, which shows clear selection feedback.
2. The player drags it over another tile, which is clearly highlighted as the target.
3. On release, the **two tiles exchange cells** with a smooth animation.
4. Incorrect swaps are allowed and never rejected. Tiles can be moved repeatedly; swaps are unlimited, with no penalty.
5. Releasing outside another tile (or back on its own cell) **cancels**: the tile returns to its own cell.
6. The interaction is direct drag-and-drop; there is no tap-then-tap selection.

### Correctly positioned tiles (Q-023, GP-32, GP-34)

- **[Confirmed]** Correctly positioned tiles **remain movable**. No tile locks when it reaches its correct cell.
- Any two tiles can be swapped at any time, including tiles that are already correct. Every swap is valid whether or not either tile was correct.
- Correct-position feedback (a brief glow, and correct tiles joining seamlessly into the picture) is **visual only** and never restricts movement.

### Hints (GP-36)

- **Intentionally excluded from the initial prototype; planned for v1.** The hint design is not specified yet.

### Superseded (history)

- **Q-011, 2026-11-23:** pieces started in a two-row, horizontally scrolling tray below the board (GP-03, GP-04, GP-16 to GP-19). **Revised 2026-11-25:** pieces started face-down and scattered across the board (GP-20, GP-27, GP-28). **Revised again 2026-11-25:** fixed, fully filled grid (above).
- **Q-010, 2026-11-23:** strict placement. Only the correct position accepted a piece, incorrect drops animated back (GP-06, GP-14), and correct pieces locked (GP-15). **Revised 2026-11-25:** free placement, with a 4-second memory preview and tap to reveal (GP-21 to GP-26). **Revised again 2026-11-25:** drag-and-swap (above).
- Magnetic snapping (GP-05) and permanent locking (GP-15) belonged to those placement rules and do not apply to the picture-swap puzzle (Q-023: no locking).
- **Q-009, 2026-11-23:** mixed-size pieces (1×1, 1×2, 2×1, 2×2) and 8–12 pieces per layout. **Revised 2026-11-25 (Q-022):** a uniform 4×4 grid of equal-sized tiles.

### Reference preview

- The player can optionally view the full reference image.
- The interaction (hold-to-peek, toggle button, thumbnail) is TBC.

### Completion

- The puzzle completes only when **every tile (all 16) is in its correct cell**, judged on the whole board matching the target arrangement (GP-34). A tile that lands in its correct cell gets brief visual feedback, which does not lock it (Q-023).
- **[Confirmed 2026-11-26; implemented and approved on device] Celebration (GP-39):** a short, satisfying celebration plays (picture shine and a brief sparkle effect; about 1.1 s, provisional), then the finished illustration is shown with a **Next puzzle** action. Board input stays disabled during the celebration. **No coins, rewards, placeholder rewards or empty reward slots are shown** until reward rules are implemented; the celebration is built so that the reveal and coin steps below can be added later.
- **[Confirmed 2026-11-26; implemented and approved on device] Next puzzle (GP-40):** the board clears with a short exit animation (tiles fall away, about 0.6 s, provisional) and a new puzzle starts with a fresh seed. For now it **reshuffles the same placeholder picture**, and the puzzle introduction runs again. Repeated taps are ignored and sequences never overlap.
- Target completion flow with rewards (approved requirements; the reveal and coin steps are not yet implemented), in order:
  1. Completion feedback (sound/visual).
  2. **Character/card reveal**: on a *designated* puzzle, the guaranteed card is awarded and its character comes to life (CC-04). A card already collected does not count as new collection progress (CC-06).
  3. **Coin reward animation**.
  4. Return to puzzle selection or continue (flow TBC).

- On a *non-designated* puzzle, step 2 is replaced by progression rewards (CC-05). The content of progression rewards, and how they are presented, is open (Q-020).

> **[Confirmed]** The first prototype puzzle is a designated card puzzle (CC-07), so that the full discovery and reward experience can be validated.

### Saving

- Unfinished puzzles are **saved automatically** (e.g. after each swap and when the app is backgrounded).
- Returning to a puzzle restores the exact tile arrangement (PS-23 as revised). **Not yet implemented.**

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
