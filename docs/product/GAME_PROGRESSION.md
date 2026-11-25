# Game Progression

> Status: structure confirmed; numbers and economy TBC.

## 1. Progression Structure

**[Confirmed]** Progression is world-based. Cards have rarity and belong to themed collections.
**[Proposed]** Completing collections unlocks new worlds (PRD WP-03). The exact unlocking mechanism is open (Q-002).

```
World
 ├── Puzzles ── completion → coins
 │     ├── designated puzzles → guaranteed Card (+ character reveal)
 │     └── non-designated puzzles → progression rewards
 └── Themed Collection(s) ── made of Cards
         └── completion → unlock next World [Proposed]
```

- Every completed puzzle awards coins.
- A designated puzzle guarantees its card on completion (CC-04).
- Non-designated puzzles award coins and progression rewards (CC-05). What progression rewards consist of is **[Open]** (Q-020).
- A previously collected card is not awarded as new collection progress (CC-06).
- Which puzzles are designated, for example how many per collection, is **[Open]** (Q-002).
- Rarity tiers and their effect are **[Open]** (Q-007).
- Cards belong to themed collections.
- **[Proposed]** Completing collections unlocks the next world.
- A recurring mascot guides the player through the journey.

## 2. Worlds [Proposed]

The names below are working names, not confirmed (PRD WP-02, Q-021).

1. Enchanted Forest
2. Ocean Kingdom
3. Fantasy Kingdom
4. Cosmic Adventures

The order above follows the PRD listing. Whether it is the final unlock order is to be confirmed with content design.

## 3. Unlock Rules (TBC)

To be decided (OPEN_QUESTIONS Q-002):

- Number of puzzles per collection and collections per world.
- Whether a world unlocks after *all* or *some* of the previous world's collections.
- Whether puzzles within a world unlock sequentially or are freely selectable.
- Whether coins can be used to unlock content.

## 4. Economy (TBC)

- Coin amounts per puzzle.
- Coin sinks (hints, preview, unlocks, cosmetics).
- Any monetization relationship.

## 5. Difficulty Curve

The initial prototype uses only a uniform 4×4 board of 16 equal-sized tiles (picture-swap, Q-022). Difficulty variation through board size, irregular pieces or rotation is a **future feature** and requires approval. Within 4×4, difficulty may be varied through image complexity (TBC). *(Varying the piece count or size mix applied to the mixed-size model, superseded 2026-11-25.)*

## 6. Configuration

All progression (worlds, collections, puzzles, rewards, unlock rules) must be **configuration-driven**, not hardcoded. See [DATA_MODELS.md](../architecture/DATA_MODELS.md).
