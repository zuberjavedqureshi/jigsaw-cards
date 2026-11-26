# Puzzle Engine

> Status: **Specification draft.** Requirements marked **[Confirmed]** come from the PRD. Everything else is a **[Proposed]** design to be validated by tests and prototyping. No algorithm in this document is approved until recorded in an ADR.

The puzzle engine is the pure-Dart puzzle domain. It has **no dependency on Flutter or Flame**.

**[Confirmed]** Hybrid puzzle system (PRD §7.1, PS-04 to PS-18):

- Two **separate puzzle styles**: **rectangular tile** (initial development) and **traditional irregular jigsaw** (future). They are not necessarily combined within one puzzle.
- **Shared across styles:** puzzle session management, level configuration framework, common interaction contracts where practical, progress and completion reporting, and reward integration.
- **Separate per style:** geometry generation and rendering.

Sections 3 to 10 specify the **rectangular tile style**. Section 11 covers the boundary with the future irregular style.

## 1. Responsibilities

- Hold puzzle configuration and current puzzle state.
- Apply and validate tile swaps.
- Track grid occupancy (the tile arrangement).
- Detect completion.
- Produce serialisable state for auto-save and restore.

Not responsibilities: rendering, gestures, animation, audio, screen coordinates, persistence I/O.

## 2. Puzzle Configuration

**[Confirmed]** Levels are configuration-driven.

**[Proposed]** A puzzle configuration contains:

| Field | Description |
| --- | --- |
| `id` | Stable puzzle identifier |
| `imageRef` | Reference to the puzzle image asset |
| `style` | Puzzle style: `rectangularTile` (now) or `irregularJigsaw` (future, reserved) |
| `geometry` | Style-specific. For rectangular tile (picture-swap): `rows`, `columns` (**4 × 4** for the prototype) and the shuffle seed; tiles are equal-sized, so no piece definitions or partition settings are needed (Q-022; see §4, §5) |
| `cardId` (optional) | Present only on designated puzzles; the card is guaranteed on completion (CC-04). Reward logic is applied by the shared reward integration, not by style-specific geometry code. |
| `coinReward` | Coins, all puzzles |
| `progressionRewards` | Non-designated puzzles (CC-05); content open (Q-020) |

Field names match [DATA_MODELS.md](DATA_MODELS.md) and are proposed.

**[Confirmed, revised 2026-11-25 by Q-022]** The picture-swap gameplay divides the illustration into a uniform grid of equal-sized tiles; rectangular partition generation (PS-08) is superseded for this gameplay. How the shuffle seed is supplied is a technical choice (TD-02).

## 3. Logical Grid

- **[Confirmed]** 4×4 logical board for the prototype.
- **[Proposed]** Cells are addressed by integer `(row, column)` with `(0, 0)` at top-left.
- **[Proposed]** The grid is purely logical; mapping cells to pixels is the rendering layer's job.
- Grid size is a configuration value, not a constant, so that future board sizes do not require a rewrite — but only 4×4 is supported and tested for now.

## 4. Tile Model

- **[Confirmed]** Equal-sized rectangular tiles on a uniform grid (Q-022, resolved 2026-11-25): a 4×4 grid of 16 tiles with identical dimensions, one tile per cell; the source illustration is divided into equal rectangular fragments. No rotation.
- **[Implemented]** The model is `PicturePuzzle` in `packages/puzzle_domain`:

| Concept | Mutability | In the model |
| --- | --- | --- |
| Tile identity | **Immutable** | `PictureTile.id`: the row-major index of the tile's target cell |
| Target cell | **Immutable** | `PictureTile.target`: the cell where the tile belongs |
| Image fragment | **Immutable** | `sourceRectOf(tile)`: the equal-sized slice of the source at the tile's *target* cell, so content always follows identity |
| Current cell | Mutable (by swapping) | `cellOf(tile)` |
| Board arrangement | Mutable (by swapping) | `arrangement[cell] = tileId`: always a permutation; every cell holds exactly one tile and every tile is in exactly one cell |
| Correct position | Derived | `isTileCorrect(tile)`: true when the current cell equals the target cell; `correctCount` counts them |
| Completion | Derived | `isComplete`: every tile is in its target cell |

- Puzzles are immutable values: a swap returns a new puzzle.
- **Correct-position status never restricts future swaps (Q-023).** Correct tiles are not locked; it is derived information, used only for feedback and completion.

**Coverage invariant [Confirmed]:** the tiles at their target cells cover the illustration exactly. Every cell is covered once, with no overlap and nothing outside the grid, and every arrangement keeps exactly one tile per cell. **[Implemented]** `validateArrangement` enforces this in every constructor.

*History (superseded 2026-11-25, Q-022):* the earlier model was mixed-size pieces (`id`, `correctOrigin`, `size` of 1×1, 1×2, 2×1 or 2×2) whose rectangles had to tile the 4×4 grid (the partition tiling invariant from PS-08). Its runtime location was proposed as `inTray(slot)`/`onBoard(origin)`, then implemented as free continuous positions with reveal and lock flags. All of this is superseded. The free-placement code remains in Git history.

## 5. Starting Arrangement

**Superseded for the picture-swap gameplay (Q-022, 2026-11-25): rectangular partition generation.** The original confirmed constraints (Q-009, 2026-11-23: pieces 1×1, 1×2, 2×1, 2×2; 8–12 pieces per layout; seeded layout generation; persisted layout; no hand-authored layouts) and the open TD-02 question of which partition algorithm to use no longer apply to the current gameplay. Q-009 and PRD PS-19 to PS-24 keep the original wording as history, with dated revisions. The domain package still contains the provisional partition generator (`LayoutGenerator`, `ProvisionalRandomFillGenerator`) with its tests, but **no active gameplay path uses it** and it is not a requirement.

**Still valid:** the 4×4 board (PS-19), exact coverage (§4), seeded generation, now of the starting arrangement (PS-22 revised), and persistence of the arrangement (PS-23 revised; not implemented).

**[Open — technical, TD-02]** Where the shuffle seed comes from, and whether arrangements are generated at runtime or with content.

**[Implemented, provisional]** Picture-swap start (GP-31): `PicturePuzzle.shuffled` uses a seeded Fisher–Yates shuffle and repeats it until the board is not solved and at least 75% of the tiles are misplaced. The 75% threshold is provisional. Any permutation can be solved by swaps; `minimumSwapsToSolve` is `n − cycles`. Tests cover 1,000 seeds for validity and solve 300 of them in the minimum number of swaps. *(The earlier seeded scatter for free placement is superseded.)*

**[Confirmed]** Every starting arrangement must satisfy the coverage invariant in §4 and must not already be solved (GP-31). **[Confirmed]** Shuffling is puzzle domain logic and therefore must be unit-tested (Development Rule 5).

## 6. Grid Occupancy

- **[Implemented]** Occupancy *is* the arrangement (`cell → tileId`), the single source of truth. There are never empty cells (GP-29). `tileAt(cell)` and `cellOf(tile)` are derived from it.

## 7. Swap Rules

**[Confirmed]** Drag-and-swap (Q-010 revised again 2026-11-25; PRD GP-32, GP-33):

- A single tile's move is a **swap** of two cells: their tiles exchange positions. Exactly two cells change; every tile stays in exactly one cell and no cell is ever empty. A tile in a connected group moves with its group (§7a).
- Incorrect swaps are accepted. There is no rejection for being wrong, no limit and no penalty, and tiles can be moved repeatedly.
- **[Confirmed, Q-023]** Correctly positioned tiles are **not locked**. Any two tiles can be swapped at any time, whether or not either is already correct. Correct-position status is never checked when a swap is validated.
- **[Implemented]** `swap(from, to)` returns `TilesSwapped(puzzle, movedTile, displacedTile, nowCorrect, completedPuzzle)` or `SwapRejected(reason)`. It is rejected, with the board unchanged and nothing thrown, when a cell is outside the grid (`outOfBounds`), both cells are the same (`sameCell`), or the puzzle is already complete (`complete`). Puzzles are immutable.
- **[Implemented]** `validateArrangement` checks occupancy: every cell is filled and no tile appears twice. Every constructor enforces it.
- A drag released outside another tile is a rendering-level cancel; the domain is not called.
- No rotation.

*History:* the strict rule (2026-11-23) was superseded by free placement with snapping and locking (2026-11-25), which was itself superseded by drag-and-swap (2026-11-25).

## 7a. Connected Tile Groups

**[Confirmed, implemented 2026-11-26]** (PRD GP-41 to GP-44.) The rules are a pure-Dart `TileGroups` extension on `PicturePuzzle` (`tile_groups.dart`). `PicturePuzzle` and `swap()` are unchanged.

- **Detection (`connectedGroups`, `groupAt`, `unitAt`):** the *offset* of a tile is its current cell minus its correct cell. Two board neighbours (4-way) are joined when their offsets are equal, so they touch exactly as in the picture. Groups are the connected components of this relation with at least two tiles, at any offset (zero = correctly placed). Groups are derived from the arrangement and never stored.
- **Movement (`moveGroup(from, to)`):** the *unit* is the group containing `from`, or that single tile.
  - Every unit cell moves by `d = to − from`. The move is refused (`outOfBounds`) if any destination cell is off the board, and also for `sameCell` and `complete`.
  - Each tile in a destination cell the unit does not cover moves to `c − k·d` for the smallest `k ≥ 1` that leaves the destination set. That cell is always one the unit vacated, and the mapping is one-to-one, so the result is a permutation and the board stays full.
  - When the old and new unit cells do not overlap, `k = 1` for every displaced tile, so a displaced block, including another whole group, keeps its shape.
  - A single-tile unit delegates to `swap()`, so its result is identical to the original swap.
- **Result:** `GroupMoved(puzzle, from, to, unit, displaced)` or `GroupMoveRejected(reason)`. Group moves return a new puzzle through `fromArrangement`, which validates occupancy.
- **Solvability:** moving any unit so that the dragged tile lands in its correct cell puts the whole unit in its correct cells. This never disturbs a correctly placed tile, because those cells belong to the unit's own tiles, and it adds at least one correct tile, so every board can be finished.

## 7b. Connection Events

**[Implemented 2026-11-26]** (PRD GP-45.) `connectionEvents(before, after)` (`connection_events.dart`) describes what a move connected. For each group in `after`, the tiles are traced back to their groups in `before`.

- A former group **counts** only if at least two of its tiles are still together; a lone tile left over from a split group counts as loose.
- The group is **new** if it contains loose tiles or at least two former groups. It is then reported as **formed** (loose tiles only), **grew** (one former group plus loose tiles) or **merged** (two or more former groups), with its cells, the number of groups joined and the number of tiles added.
- A group that only moved, or became smaller, produces no event.

The function is pure and deterministic. Which praise to show is presentation policy and is not part of the domain (`PraiseRules` in the app).

## 8. Magnetic Snapping

- **[Superseded 2026-11-25]** Not part of the picture-swap puzzle: tiles always settle exactly into grid cells. The earlier snapping-tolerance rule is kept in history.

## 9. Completion Detection

- **[Confirmed]** Completion detection (GP-09, GP-34). Completion is reported through the shared completion reporting (PS-16); the application layer then applies rewards: the card reveal on designated puzzles (CC-04), progression rewards on non-designated puzzles (CC-05), and coins on both.
- **[Implemented]** The puzzle is complete exactly when every tile is in its target cell (`correctCount == tileCount`; 16 of 16 in the prototype), judged on the whole board matching the target arrangement. The swap that completes it reports `completedPuzzle`. `isTileCorrect` and `correctCount` drive the correct-tile feedback, which is visual only (Q-023). Once complete, further swaps are rejected (`complete`) because the puzzle has ended; this is not tile locking.

## 10. Save / Restore

- **[Confirmed]** Unfinished puzzles are saved automatically.
- **[Confirmed]** The tile arrangement is persisted, so an unfinished puzzle retains exactly the same arrangement (PS-23, revised 2026-11-25 by Q-022).
- **[Proposed]** Puzzle state is serialisable to a plain data structure: puzzle id, puzzle style, grid size, source size, shuffle seed, the current arrangement, and a schema version. Restoring the same data yields an identical state (`PicturePuzzle.fromArrangement` already validates a restored arrangement).
- **[Not implemented]** Serialisation and restore are not implemented yet, so PS-23 (persisted arrangement) and GP-13 (auto-save) remain outstanding.

## 11. Future Puzzle Style: Traditional Irregular Jigsaw

**[Confirmed as future; not approved for implementation]** The irregular jigsaw style is a separate puzzle style (PS-05) with:

- Traditional interlocking jigsaw geometry.
- Tabs and blanks.
- Rotation.
- Connected-piece grouping.

**Boundary with the rectangular tile style [Confirmed]**

| Concern | Shared or separate |
| --- | --- |
| Puzzle session management | Shared |
| Level configuration framework | Shared (style-specific geometry settings inside it) |
| Interaction contracts | Shared where practical |
| Progress and completion reporting | Shared |
| Reward integration | Shared |
| Geometry generation | Separate |
| Rendering | Separate |

**[Proposed]** Examples of shared session operations: start, save, restore, complete. Examples of interaction contracts: pick up, move, drop, placement result. For the rectangular style, keep the shared concerns behind small, style-neutral contracts, such as a completion signal and a serialisable session snapshot, so that a second style can reuse them. Do not build the irregular style or speculative abstractions for it now (Development Rules 7 and 9).

**[Open]** The irregular style's geometry model, placement and snapping rules, and whether it uses a logical grid internally. These will be specified when the style is approved.

## 12. Testing

All engine behaviour must be unit-tested in pure Dart. See [TESTING_STRATEGY.md](../development/TESTING_STRATEGY.md).
