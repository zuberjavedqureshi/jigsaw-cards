# Data Models

> Status: **Proposed conceptual models.** Field names and types are illustrative and will be finalised during Phase 2. Storage format/database is not yet selected.

## 1. Content Configuration (bundled, read-only)

### World
| Field | Type | Notes |
| --- | --- | --- |
| id | string | e.g. `enchanted_forest` |
| name | string | Display name |
| order | int | Unlock order |
| collectionIds | list<string> | |
| unlockRule | object | TBC (GAME_PROGRESSION.md) |

### Collection
| Field | Type | Notes |
| --- | --- | --- |
| id | string | |
| worldId | string | |
| name | string | |
| cardIds | list<string> | |

### Card / Character
| Field | Type | Notes |
| --- | --- | --- |
| id | string | |
| collectionId | string | |
| name | string | |
| cardArtRef | string | Asset reference |
| animationRef | string? | Rive asset reference (subject to validation) |
| rarity | enum? | Rarity is confirmed (CC-02); tiers are TBC (Q-007) |

### PuzzleConfig
| Field | Type | Notes |
| --- | --- | --- |
| id | string | |
| imageRef | string | |
| style | enum | `rectangularTile` (initial development) or `irregularJigsaw` (future, reserved). Confirmed concept (PS-04); field name proposed |
| geometry | style-specific | Rectangular tile: picture-swap grid (see below). Irregular: future, not specified |
| cardId | string? | Present only on **designated** puzzles, which guarantee this card on completion (CC-04). Presence marks the puzzle as designated |
| coinReward | int | All puzzles |
| progressionRewards | TBC | Non-designated puzzles (CC-05). Content open (Q-020) |

Shared fields (id, imageRef, style, cardId, rewards) belong to the common level configuration framework (PS-14). Geometry is style-specific (PS-18).

### RectangularTileGeometry (rectangular tile style)
| Field | Type | Notes |
| --- | --- | --- |
| rows / columns | int | 4 / 4 for the prototype: a uniform grid of 16 equal-sized tiles (PS-19, Q-022) |
| shuffleSeed | int? | Seed of the starting arrangement (PS-22 revised, GP-31). Seed source is technical (TD-02) |
| ~~generation~~ | — | **Superseded 2026-11-25 (Q-022):** partition generation parameters (pieces 1×1, 1×2, 2×1, 2×2; 8–12 pieces; PS-20, PS-21) do not apply to the picture-swap gameplay |
| ~~pieces~~ | — | **Superseded 2026-11-25 (Q-022):** tiles are derived from the grid; there is no generated or hand-authored piece layout (PS-24) |

### PieceDefinition — superseded 2026-11-25 (Q-022)

Kept as history of the mixed-size model. Picture-swap tiles have an `id` and a target cell only; their size is always one cell.

| Field | Type | Notes |
| --- | --- | --- |
| id | string | |
| correctOrigin | (row, column) | Top-left cell |
| size | (rowSpan, columnSpan) | |

## 2. Player Data (persisted locally)

### PlayerProgress
| Field | Type |
| --- | --- |
| schemaVersion | int |
| completedPuzzleIds | set<string> |
| unlockedWorldIds | set<string> |
| coins | int |

### CardCollection
| Field | Type | Notes |
| --- | --- | --- |
| ownedCardIds | set<string> | A card already in this set is not awarded as new collection progress (CC-06). Any other duplicate handling is open (Q-007) |

### PuzzleSessionSnapshot
| Field | Type | Notes |
| --- | --- | --- |
| schemaVersion | int | |
| puzzleId | string | |
| style | enum | Puzzle style of the session |
| layout | style-specific | The selected/generated layout, always persisted so an unfinished puzzle keeps exactly the same arrangement (PS-23) |
| arrangement | style-specific | Rectangular tile (picture-swap): grid size, source size, shuffle seed and `arrangement[cell] = tileId` (a permutation) (GP-29 to GP-31). Superseded 2026-11-25: free-placement piece states, and before that `inTray(slot)` / `onBoard(origin)`. Irregular: future, not specified |
| updatedAt | timestamp | |

### Settings
| Field | Type |
| --- | --- |
| soundEnabled | bool |
| musicEnabled | bool (if music is added) |

## 3. Rules

- Content is configuration-driven, including puzzle style and which puzzles are designated card puzzles (DL-01, DL-03); adding a puzzle must not require code changes.
- The prototype puzzle's configuration is a designated card puzzle (CC-07).
- Domain models are immutable and free of Flutter/Flame types.
- Persisted models carry a `schemaVersion`.
- No personal data is collected in the prototype. Any future data collection must be reviewed against the target audience decision (OPEN_QUESTIONS Q-001).
