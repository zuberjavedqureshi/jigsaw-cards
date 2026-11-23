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

**[Confirmed]** Initial development includes rectangular partition generation (PS-08). How generation is parameterised in configuration is open (see §5).

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

- **[Proposed]** A piece's runtime location is one of: `inTray(slot)` or `onBoard(origin)`.
- **[Proposed]** The image region of a piece is derived from `correctOrigin` and `size`, so no separate image coordinates are stored.

**Invariant (proposed):** the set of piece rectangles at their correct origins tiles the grid exactly — every cell covered once, no overlaps, nothing outside the grid. Configuration that violates this is rejected at load time.

## 5. Rectangular Partition Generation

**[Confirmed]** Rectangular partition generation is part of initial development (PS-08). The engine partitions the logical grid into mixed-sized rectangular pieces.

**[Open]** The algorithm itself is **not approved**. To be decided, with an ADR (TD-02) and Q-009:

- Allowed piece sizes and the piece-count range for 4×4.
- Whether generation is seeded and deterministic, so the same layout can be reproduced for a level or restored from a save.
- Whether generation runs at runtime or when content is built, and whether hand-authored layouts are also supported.
- Fairness and variety constraints.

**[Proposed]** Whatever algorithm is chosen, every generated layout must satisfy the tiling invariant in §4. **[Confirmed]** Generation is puzzle domain logic and therefore must be unit-tested (Development Rule 5).

## 6. Grid Occupancy

- **[Proposed]** The engine maintains an occupancy map: `cell → pieceId | empty`, derived from pieces currently on the board.
- **[Proposed]** Occupancy is derived from piece locations (single source of truth) rather than stored separately, to avoid inconsistency.

## 7. Placement Validation

- **[Confirmed]** Incorrect placement returns the piece to its previous position.
- **[Open]** Definition of "correct placement" for the prototype. Two candidate rules:

  1. **Strict:** a placement is accepted only if the target origin equals the piece's `correctOrigin`. Pieces on the board are therefore always correct.
  2. **Free:** any in-bounds, non-overlapping placement is accepted; correctness is evaluated only at completion.

  The PRD's "incorrect placement returns the piece" behaviour points toward the **strict** rule, which is the working assumption for the prototype. It must be confirmed (OPEN_QUESTIONS Q-010).

- **[Proposed]** Placement checks, in order: piece exists → target in bounds → (strict rule) target equals correct origin → target cells not occupied by another piece.
- **[Proposed]** The operation returns a result value (`accepted` / `rejected(reason)`) and the new state; it never throws for normal gameplay rejections.
- **[Open]** Whether correctly placed pieces become locked (cannot be moved again).

## 8. Magnetic Snapping

Snapping spans two layers:

- **Rendering (Flame):** converts the drop point to the nearest candidate grid origin, using the piece's size and the current board layout. Decides whether the drop is "close enough" to snap.
- **Domain:** validates the candidate origin (§7).

- **[Open]** Snap threshold (e.g. a fraction of cell size), and whether snapping considers only the nearest cell or the piece's correct cell within a radius. These are feel parameters, to be tuned during validation and kept in configuration, not hardcoded.

## 9. Completion Detection

- **[Confirmed]** Completion detection (GP-09). Completion is reported through the shared completion reporting (PS-16); the application layer then applies rewards: the card reveal on designated puzzles (CC-04), progression rewards on non-designated puzzles (CC-05), and coins on both.
- **[Proposed]** The puzzle is complete when every piece is on the board at its `correctOrigin`. Under the strict rule this is equivalent to "all pieces placed".
- **[Proposed]** Completion is reported as part of the placement result so the app layer can react once.

## 10. Save / Restore

- **[Confirmed]** Unfinished puzzles are saved automatically.
- **[Proposed]** Puzzle state is serialisable to a plain data structure: puzzle id, puzzle style, the generated layout if it cannot be reproduced exactly from configuration, each piece's location, and a schema version. Restoring the same data yields an identical state.

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
