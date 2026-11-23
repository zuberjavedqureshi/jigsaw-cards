# Puzzle Engine

> Status: **Specification draft.** Requirements marked **[Confirmed]** come from the PRD. Everything else is a **[Proposed]** design to be validated by tests and prototyping. No algorithm in this document is approved until recorded in an ADR.

The puzzle engine is the pure-Dart puzzle domain. It has **no dependency on Flutter or Flame**.

**[Confirmed]** Hybrid puzzle system: mixed-sized rectangular pieces for the first prototype; traditional irregular jigsaw pieces as future functionality (PRD §7.1). The engine implements only rectangular pieces now, but must not prevent the irregular extension (§11).

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
| `rows`, `columns` | Logical grid size — **4 × 4** for the prototype |
| `pieces` | List of piece definitions (see §4) |
| `cardId` (optional) | Present only on designated puzzles; the card is guaranteed on completion (CC-03). Reward logic is applied by the application layer, not the engine. |
| `reward` | Coin reward |

Whether the piece layout is **authored** in configuration or **generated** at runtime is open (see §5).

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

## 5. Mixed Rectangular Piece Generation

**[Open]** The method for producing the mixed-size layout is **not decided**. Options to evaluate:

| Option | Description | Notes |
| --- | --- | --- |
| A. Authored layouts | Designers specify pieces per puzzle in config | Full control, simplest engine; more content work |
| B. Template library | A set of validated 4×4 layouts reused across puzzles | Predictable; limited variety |
| C. Procedural generation | Partition the grid into rectangles at runtime, possibly seeded | Variety; needs constraints (min/max piece size, piece count) and fairness tuning |

Whatever is chosen, the result must satisfy the tiling invariant in §4 and be validated by unit tests. A decision should be recorded as an ADR. Constraints such as allowed piece sizes and piece count range are TBC (OPEN_QUESTIONS Q-009).

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

- **[Confirmed]** Completion detection triggers the reveal.
- **[Proposed]** The puzzle is complete when every piece is on the board at its `correctOrigin`. Under the strict rule this is equivalent to "all pieces placed".
- **[Proposed]** Completion is reported as part of the placement result so the app layer can react once.

## 10. Save / Restore

- **[Confirmed]** Unfinished puzzles are saved automatically.
- **[Proposed]** Puzzle state is serialisable to a plain data structure: puzzle id, layout (if generated), each piece's location, and a schema version. Restoring the same data yields an identical state.

## 11. Future Extension: Irregular Jigsaw Pieces

Not approved for implementation. Design considerations so the prototype does not block it:

- Irregular pieces still occupy a logical grid cell (or cells); tab/blank shapes are a rendering concern, with edge definitions shared between neighbours.
- Rotation would add an orientation field to piece location and to the correctness check.
- Connected-piece grouping would add a group concept above pieces; placement would apply to groups.
- Zoom/pan and larger boards are rendering/layout concerns; grid size is already configuration.

These are notes, not commitments. Each requires approval and an ADR.

## 12. Testing

All engine behaviour must be unit-tested in pure Dart. See [TESTING_STRATEGY.md](../development/TESTING_STRATEGY.md).
