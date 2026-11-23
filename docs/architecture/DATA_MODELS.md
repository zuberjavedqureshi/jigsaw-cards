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
| rarity | ? | TBC |

### PuzzleConfig
| Field | Type | Notes |
| --- | --- | --- |
| id | string | |
| imageRef | string | |
| rows / columns | int | 4 / 4 for prototype |
| pieces | list<PieceDefinition> | Authored or generated — TBC |
| cardId | string | Revealed on completion |
| coinReward | int | |

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
| ownedCardIds | set<string> | Duplicate handling TBC |

### PuzzleSessionSnapshot
| Field | Type | Notes |
| --- | --- | --- |
| schemaVersion | int | |
| puzzleId | string | |
| layout | list<PieceDefinition>? | Only if pieces are generated at runtime |
| pieceLocations | map<pieceId, Location> | `inTray(slot)` or `onBoard(origin)` |
| updatedAt | timestamp | |

### Settings
| Field | Type |
| --- | --- |
| soundEnabled | bool |
| musicEnabled | bool (if music is added) |

## 3. Rules

- Content is configuration-driven; adding a puzzle must not require code changes.
- Domain models are immutable and free of Flutter/Flame types.
- Persisted models carry a `schemaVersion`.
- No personal data is collected in the prototype. Any future data collection must be reviewed against the target audience decision (OPEN_QUESTIONS Q-001).
