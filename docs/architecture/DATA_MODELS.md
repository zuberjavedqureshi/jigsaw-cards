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
| geometry | style-specific | Rectangular tile: partition generation settings and/or piece layout (see below). Irregular: future, not specified |
| cardId | string? | Present only on **designated** puzzles, which guarantee this card on completion (CC-04). Presence marks the puzzle as designated |
| coinReward | int | All puzzles |
| progressionRewards | TBC | Non-designated puzzles (CC-05). Content open (Q-020) |

Shared fields (id, imageRef, style, cardId, rewards) belong to the common level configuration framework (PS-14). Geometry is style-specific (PS-18).

### RectangularTileGeometry (rectangular tile style)
| Field | Type | Notes |
| --- | --- | --- |
| rows / columns | int | 4 / 4 for the prototype |
| generation | object? | Partition generation parameters, e.g. seed or size constraints. Open (Q-009, TD-02) |
| pieces | list<PieceDefinition>? | Generated layout, or authored if supported (open) |

### PieceDefinition
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
| layout | style-specific? | Generated layout, saved if it cannot be reproduced exactly (e.g. no deterministic seed) |
| pieceLocations | map<pieceId, Location> | `inTray(slot)` or `onBoard(origin)` |
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
