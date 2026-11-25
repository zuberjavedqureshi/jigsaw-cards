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
- Validate piece placements.
- Track grid occupancy.
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
| `geometry` | Style-specific. For rectangular tile: `rows`, `columns` (**4 × 4** for the prototype), partition generation settings and/or piece definitions (see §4, §5) |
| `cardId` (optional) | Present only on designated puzzles; the card is guaranteed on completion (CC-04). Reward logic is applied by the shared reward integration, not by style-specific geometry code. |
| `coinReward` | Coins, all puzzles |
| `progressionRewards` | Non-designated puzzles (CC-05); content open (Q-020) |

Field names match [DATA_MODELS.md](DATA_MODELS.md) and are proposed.

**[Confirmed]** Initial development includes rectangular partition generation (PS-08), within the approved constraints in §5 (PS-19 to PS-24). How generation is parameterised in configuration is a technical choice (TD-02).

## 3. Logical Grid

- **[Confirmed]** 4×4 logical board for the prototype.
- **[Proposed]** Cells are addressed by integer `(row, column)` with `(0, 0)` at top-left.
- **[Proposed]** The grid is purely logical; mapping cells to pixels is the rendering layer's job.
- Grid size is a configuration value, not a constant, so that future board sizes do not require a rewrite — but only 4×4 is supported and tested for now.

## 4. Piece Model

- **[Confirmed]** Rectangular pieces of mixed sizes; no rotation.
- **[Proposed]** A piece definition:

| Field | Description |
| --- | --- |
| `id` | Stable piece identifier |
| `correctOrigin` | Top-left cell `(row, column)` of the piece's correct position |
| `size` | `(rowSpan, columnSpan)` in cells, e.g. `(1,1)`, `(1,2)`, `(2,2)` |

- **[Implemented, picture-swap, 2026-11-25]** The active model is `PicturePuzzle`: a grid of `rows × columns` **equal tiles** cut from a source illustration (`SourceSize`). Each `PictureTile` has a fixed identity and a fixed **target cell**. The current arrangement is a permutation (`arrangement[cell] = tileId`): every cell holds exactly one tile and every tile is in exactly one cell. A tile's image region (`sourceRectOf`) comes from its target cell, so its content always follows its identity. *(History: the tray proposal `inTray(slot)`/`onBoard(origin)` and the free-placement model with continuous positions, reveal flags and a workspace were superseded on 2026-11-25. The free-placement code remains in Git history.)*
- **[Proposed]** The image region of a piece is derived from `correctOrigin` and `size`, so no separate image coordinates are stored.

**Tiling invariant [Confirmed, follows from PS-08]:** the set of piece rectangles at their correct origins tiles the grid exactly. Every cell is covered once, there are no overlaps, and nothing lies outside the grid. This is what makes a layout a *partition* of the 4×4 board (GP-01, PS-08), and it matches GAMEPLAY ("pieces together cover the whole board exactly, with no overlap"). It introduces no new product decision.

**[Proposed]** Enforcement mechanism: a layout or configuration that violates the invariant is rejected at load time.

## 5. Rectangular Partition Generation

**[Confirmed]** Rectangular partition generation is part of initial development (PS-08). The engine partitions the logical grid into mixed-sized rectangular pieces.

**[Confirmed] Product constraints** (Q-009, resolved 2026-11-23; PRD PS-19 to PS-24):

- 4×4 logical board for the initial prototype.
- Allowed piece dimensions: 1×1, 1×2, 2×1, 2×2.
- Piece-count constraint: every generated prototype layout must contain between 8 and 12 pieces, inclusive.
- Valid layouts are generated using seeded generation.
- The selected/generated layout is persisted, so an unfinished puzzle retains exactly the same arrangement.
- Hand-authored layouts are not required for the initial prototype; they may be supported in a later phase.

**[Open — technical, TD-02]** Still to be decided with an ADR:

- The generation algorithm, e.g. enumerate-and-select or constrained random splitting (see the [feasibility review](TECHNICAL_FEASIBILITY_REVIEW.md)).
- Whether generation runs at runtime or when content is built.
- Where the seed comes from (e.g. per puzzle in configuration, or per play).
- Any fairness or variety constraints beyond the approved size and count limits.

**[Provisional implementation — not a TD-02 decision; not used by the picture-swap prototype, Q-022]** `packages/puzzle_domain` generates layouts through a replaceable `LayoutGenerator` interface. The only implementation, `ProvisionalRandomFillGenerator`, fills cells in row-major order, picks a fitting allowed size uniformly with a seeded `Random`, and retries until the layout passes validation (tiling, sizes, 8–12 pieces). It is deterministic per seed and tested over 500 seeds, but it is a placeholder for the first playable prototype; its distribution and variety are not evaluated. The app seeds it with `--dart-define=PUZZLE_SEED=<n>` or, if unset, the launch time. Layouts are **not yet persisted** (PS-23 outstanding). TD-02 remains Pending.

**[Implemented, provisional]** Picture-swap start (GP-31): `PicturePuzzle.shuffled` uses a seeded Fisher–Yates shuffle and repeats it until the board is not solved and at least 75% of the tiles are misplaced. The 75% threshold is provisional. Any permutation can be solved by swaps; `minimumSwapsToSolve` is `n − cycles`. Tests cover 1,000 seeds for validity and solve 300 of them in the minimum number of swaps. *(The earlier seeded scatter for free placement is superseded.)*

**[Confirmed]** Whatever algorithm is chosen, every generated layout must satisfy the tiling invariant in §4 (PS-08) and the approved size and count constraints (PS-20, PS-21). **[Confirmed]** Generation is puzzle domain logic and therefore must be unit-tested (Development Rule 5).

## 6. Grid Occupancy

- **[Proposed]** The engine maintains an occupancy map: `cell → pieceId | empty`, derived from pieces currently on the board.
- **[Proposed]** Occupancy is derived from piece locations (single source of truth) rather than stored separately, to avoid inconsistency.

## 7. Swap Rules

**[Confirmed]** Drag-and-swap (Q-010 revised again 2026-11-25; PRD GP-32, GP-33):

- The only move is a **swap** of two cells: their tiles exchange positions. Exactly two cells change.
- Incorrect swaps are accepted. There is no rejection for being wrong, no limit and no penalty.
- **[Implemented]** `swap(from, to)` returns `TilesSwapped(puzzle, movedTile, displacedTile, nowCorrect, completedPuzzle)` or `SwapRejected(reason)`. It is rejected, with the board unchanged and nothing thrown, when a cell is outside the grid (`outOfBounds`), both cells are the same (`sameCell`), or the puzzle is already complete (`complete`). Puzzles are immutable.
- **[Implemented]** `validateArrangement` checks occupancy: every cell is filled and no tile appears twice. Every constructor enforces it.
- A drag released outside another tile is a rendering-level cancel; the domain is not called.
- **[Open, Q-023]** Whether a correctly placed tile locks. The prototype keeps all tiles swappable.

*History:* the strict rule (2026-11-23) was superseded by free placement with snapping and locking (2026-11-25), which was itself superseded by drag-and-swap (2026-11-25).

## 8. Magnetic Snapping

- **[Superseded 2026-11-25]** Not part of the picture-swap puzzle: tiles always settle exactly into grid cells. The earlier snapping-tolerance rule is kept in history.

## 9. Completion Detection

- **[Confirmed]** Completion detection (GP-09, GP-34). Completion is reported through the shared completion reporting (PS-16); the application layer then applies rewards: the card reveal on designated puzzles (CC-04), progression rewards on non-designated puzzles (CC-05), and coins on both.
- **[Implemented]** The puzzle is complete exactly when every tile is in its target cell (`correctCount == tileCount`). The swap that completes it reports `completedPuzzle`. `isTileCorrect` and `correctCount` drive the correct-tile feedback.

## 10. Save / Restore

- **[Confirmed]** Unfinished puzzles are saved automatically.
- **[Confirmed]** The selected/generated layout is persisted, so an unfinished puzzle retains exactly the same arrangement (PS-23).
- **[Proposed]** Puzzle state is serialisable to a plain data structure: puzzle id, puzzle style, grid size, source size, shuffle seed, the current arrangement, and a schema version. Restoring the same data yields an identical state (`PicturePuzzle.fromArrangement` already validates a restored arrangement).
- **[Not implemented]** Serialisation and restore are not implemented yet, so PS-23 (persisted layout) and GP-13 (auto-save) remain outstanding.

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
