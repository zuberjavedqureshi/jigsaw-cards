# Game Progression

> Status: structure confirmed; numbers and economy TBC.

## 1. Progression Structure

**[Confirmed]** Progression is world-based: the World Journey of five locations (PRD WP-06). Cards have rarity and belong to themed collections.

**[Confirmed]** *(authoritative unlock rule, PRD WP-08; reconciled 2026-11-28)* Levels unlock **sequentially**. The first level of the first location is always available. Every other level unlocks when the level before it is completed. Completing **level 10 of locations 1–4** unlocks **level 1 of the next location**. Completing **level 10 of location 5** completes the **main World Journey** and shows a **final completion experience** (design not yet specified; not yet implemented). Further locations may be added later only through separate, approved content updates. Completed levels **remain replayable** (WP-09). Collections, cards and coins do **not** unlock levels or locations.

```
Location (10 levels, played in order)
 ├── Level n ── first completion → unlocks level n+1
 │     │        (level 10 of locations 1–4 → level 1 of the next location;
 │     │         level 10 of location 5 → main World Journey complete)
 │     ├── completion → coins
 │     ├── designated puzzle → guaranteed Card (+ character reveal)
 │     └── non-designated puzzle → progression rewards
 └── Themed Collection(s) ── made of Cards (no effect on unlocking)
```

- Every completed puzzle awards coins.
- A designated puzzle guarantees its card on completion (CC-04).
- Non-designated puzzles award coins and progression rewards (CC-05). What progression rewards consist of is **[Open]** (Q-020).
- A previously collected card is not awarded as new collection progress (CC-06).
- Which puzzles are designated, and how many cards a collection has, is **[Open]** (Q-002).
- Rarity tiers and their effect are **[Open]** (Q-007).
- A recurring mascot guides the player through the journey.

*History:* until 2026-11-28 this page proposed that completing collections unlocks the next world (PRD WP-03, RW-03). That proposal is **superseded** by sequential level unlocking.

## 2. Locations

**[Confirmed]** *(World Journey, approved in W0/W1; PRD WP-06 to WP-10)* Five locations (worlds in code), each with ten levels, unlocked sequentially; completed levels can be replayed. In player-facing text a world is called a **location**: an adventure chapter with an original name and tagline (PRD WP-04). Its ten pictures are deliberately varied in subject, colour and composition (PRD VI-04).

**Current working titles in code** (unchanged until names are approved): Sunny Meadows, Enchanted Forest, Fantasy Kingdom, Ocean Kingdom, Sky Kingdom. *(The earlier PRD list was Enchanted Forest, Ocean Kingdom, Fantasy Kingdom, Cosmic Adventures.)*

**[Proposed — candidates only, not approved; naming review pending]** *(2026-11-28, W4-R1; Q-021)* Original names and draft taglines. None of them is copied from the reference game. Each must pass an app-store and trademark conflict check before approval.

| Candidate name | Draft tagline |
| --- | --- |
| Brightwater Landing | Your adventure starts with a splash of colour! |
| Copperbell Lane | Treasures wait behind every door! |
| Honeyglade | Sweet surprises in every piece! |
| Starling Cove | Where curious minds come to play! |
| Wonderglow Realm | Let your imagination wander! |
| Lanternfield | Light the way to wonder! |
| Saffron Bazaar | A market full of marvels! |
| Driftwood Isles | Sail into something unexpected! |
| Clockwork Quarter | Big wheels, bright ideas! |
| Moonpetal Gardens | Quiet beauty, one piece at a time! |
| Emberglow Canyon | Bold colours, warm horizons! |
| Aurora Heights | Reach for the shimmering sky! |

*Note:* "Wonderglow Realm" and its tagline came from the product owner's own example list. The others were proposed in W4 review.

## 3. Unlock Rules

**[Confirmed]** Sequential level unlocking, as in §1 (PRD WP-08, WP-09). The earlier open points are settled as follows:

- **Levels per location:** ten (WP-06).
- **What unlocks the next location:** completing the previous location's level 10 (locations 1–4). Collections play no part.
- **End of the journey:** location 5 level 10 completes the main World Journey and shows a final completion experience; more locations only via separate content updates.
- **Order within a location:** sequential; levels are not freely selectable until unlocked.
- **Coins:** coins do not unlock levels or locations. Any other unlock mechanism would need a new product decision.

Still open (Q-002): the number and size of collections per location, and which puzzles are designated.

## 4. Economy (TBC)

- Coin amounts per puzzle.
- Coin sinks (hints, preview, unlocks, cosmetics).
- Any monetization relationship.

## 5. Difficulty Curve

**[Confirmed]** *(World Journey; PRD WP-07, WP-10)* Two difficulties: **Normal 4×4** (16 tiles) and **Hard 5×5** (25 tiles). Each level has one fixed difficulty. Level 10 of every location is Hard, and Hard levels become more frequent in later locations:

| Location | Hard levels |
| --- | --- |
| 1 | 4, 7, 10 |
| 2 | 3, 5, 8, 10 |
| 3 | 2, 4, 6, 8, 10 |
| 4 | 2, 4, 5, 7, 9, 10 |
| 5 | 2, 3, 5, 6, 8, 9, 10 |

There is no 6×6 difficulty at this stage. Picture complexity also affects difficulty, so the artwork review checks every picture at both sizes (PRD VI-12).

## 6. Configuration

All progression (worlds, collections, puzzles, rewards, unlock rules) must be **configuration-driven**, not hardcoded. See [DATA_MODELS.md](../architecture/DATA_MODELS.md).
