# Jigsaw Cards — Product Requirements Document

| Field | Value |
| --- | --- |
| Version | 1.0 (canonical repository edition, reconciliation 4: Q-001 resolved) |
| Status | Approved product decisions; pre-development technical validation |
| Platform | Android first, portrait |
| Tagline | **Solve. Discover. Collect.** |

## 0. How to Read This Document

This is the canonical product specification for the repository. Every requirement carries one of these labels:

| Label | Meaning |
| --- | --- |
| **[Confirmed]** | Approved product decision. Changing it requires explicit approval. |
| **[Proposed]** | Recommended approach, not yet approved. |
| **[Open]** | Undecided. Tracked in [OPEN_QUESTIONS.md](../../planning/OPEN_QUESTIONS.md). |
| **[Source text needed]** | The approved PRD v1.0 covers this topic, but its approved wording has not yet been supplied to the repository. Content here is limited to what has been confirmed so far. Nothing is invented to fill the gap. |

**Provenance.** The approved PRD v1.0 was produced in an earlier planning discussion that is not stored in this repository. This edition consolidates the decisions confirmed in the repository setup brief and the reconciliation brief. Sections marked **[Source text needed]** must be completed from the approved PRD text (OPEN_QUESTIONS Q-019).

Requirement IDs (e.g. `GP-03`) are stable and may be referenced from issues, ADRs and tests.

---

## 1. Product Vision

**[Confirmed]** Jigsaw Cards is a magical storybook puzzle adventure. Players solve beautifully illustrated image puzzles to discover animated characters, collect cards, complete themed collections and unlock new fantasy worlds.

The product identity is **Solve. Discover. Collect.**

| Pillar | Meaning |
| --- | --- |
| Solve | Satisfying, tactile jigsaw gameplay designed for mobile |
| Discover | Puzzles reveal animated characters within a storybook world |
| Collect | Collectible cards, themed collections and new worlds to unlock |

## 2. Unique Selling Proposition

**[Confirmed — principle]** Jigsaw Cards combines three experiences that are usually separate:

1. **Satisfying jigsaw gameplay** with drag-and-snap pieces.
2. **Character discovery**: puzzles reveal animated characters, not just a finished picture.
3. **Card collection**: collectible cards, with rarity, in themed collections that drive progression into new worlds.

A recurring mascot guide gives the game a recognisable identity.

**[Source text needed]** The approved PRD's exact USP statement and competitive positioning.

## 3. Target Audience

**[Confirmed]** (Q-001, resolved 2026-11-24)

Jigsaw Cards is a broad casual puzzle game primarily designed for teenagers and adults, with a core target audience of 16–35 years. The game should remain welcoming and enjoyable for players aged 13 and above, without specifically targeting children under 13.

| ID | Dimension | Decision |
| --- | --- | --- |
| TA-01 | Core age group | 16–35 |
| TA-02 | Overall intended audience | 13+ |
| TA-03 | Primary players | Teenagers and adults |
| TA-04 | Under-13 audience | Not an intended target audience. Children under 13 are not specifically targeted; this does not describe them as prohibited from playing |
| TA-05 | Player interests | Puzzles, collecting, exploration and relaxing games |
| TA-06 | Difficulty | Easy to learn, progressively challenging |
| TA-07 | Art direction | Magical, colourful storybook aesthetic; not exclusively child-oriented |
| TA-08 | Experience | Relaxing, satisfying, rewarding and engaging |

**Product design implications [Confirmed]**

- Gameplay should be easy to learn, with progressively increasing puzzle complexity.
- Visual identity should appeal to teens and adults rather than looking exclusively designed for young children.
- Progression should provide meaningful collection and world-unlocking rewards.
- The mascot should be charming and memorable without making the game feel exclusively child-oriented. The mascot's design remains open (Q-006).
- UI should remain readable, intuitive and comfortable to use.

**Compliance distinction.** This is a product-positioning decision. It is **not** a Google Play age rating, content rating or target-audience declaration, and it does not by itself establish how the game is classified for regulatory or store-policy purposes. Google Play target-audience and content requirements, the Families Policy, advertising, privacy and data-collection requirements must be assessed separately before release. Monetization (Q-004) and those compliance matters are not decided here.

## 4. Visual Identity — Magical Storybook

**[Confirmed]**

- **VI-01** Magical Storybook visual identity: the game should feel like an enchanted, illustrated storybook.
- **VI-02** Puzzle images are beautifully illustrated, and the artwork is part of the reward.
- **VI-03** Characters are revealed with animation (Rive, subject to technical validation, TD).
- **VI-04** Each world has its own visual theme.
- **VI-05** Portrait UI that frames the artwork rather than competing with it.

Details: [VISUAL_IDENTITY.md](VISUAL_IDENTITY.md).
**[Source text needed]** Any approved palette, typography or style-guide direction.

## 5. Mascot and Character Discovery

**[Confirmed]**

- **MC-01** One recurring mascot character serves as the player's guide throughout the game.
- **MC-02** Characters are discovered through an animated reveal that accompanies the award of their card (CC-03, CC-04).

**[Open]** Mascot design, name, personality and where the mascot appears (onboarding, world transitions, hints) (Q-006).

## 6. Worlds and World-Based Progression

- **WP-01 [Confirmed]** Progression is world-based: content is organised into worlds.
- **WP-02 [Proposed]** Working world names (exact names not confirmed, Q-021):

  | # | World |
  | --- | --- |
  | 1 | Enchanted Forest |
  | 2 | Ocean Kingdom |
  | 3 | Fantasy Kingdom |
  | 4 | Cosmic Adventures |

- **WP-03 [Proposed]** Completing themed collections unlocks new fantasy worlds.

**[Open]** The exact world unlocking mechanism, unlock order and rules, and the number of puzzles and collections per world (Q-002).

Details: [GAME_PROGRESSION.md](GAME_PROGRESSION.md).

## 7. Puzzle System

### 7.1 Hybrid puzzle system

**[Confirmed]** The puzzle system is hybrid (Q-018, resolved):

- **PS-01** Mixed-sized rectangular pieces are used for the first prototype.
- **PS-02** Traditional irregular jigsaw pieces are future functionality.
- **PS-03** Puzzle rules live in an independent pure-Dart puzzle engine (Section 13).
- **PS-04** Jigsaw Cards will eventually support two **puzzle styles**: **rectangular tile puzzles** and **traditional irregular jigsaw puzzles**.
- **PS-05** The two styles are **separate puzzle styles**. They are not necessarily combined within one puzzle.

**Initial development: rectangular tile style [Confirmed]**

- **PS-06** Mixed-sized rectangular pieces.
- **PS-07** Logical grid occupancy.
- **PS-08** Rectangular partition generation.

**Future expansion: irregular jigsaw style [Confirmed as future; not approved for implementation]**

- **PS-09** Traditional interlocking jigsaw geometry.
- **PS-10** Tabs and blanks.
- **PS-11** Rotation.
- **PS-12** Connected-piece grouping.

**Shared across both styles [Confirmed]**

| ID | Shared capability |
| --- | --- |
| PS-13 | Puzzle session management |
| PS-14 | Level configuration framework |
| PS-15 | Common interaction contracts, where practical |
| PS-16 | Progress and completion reporting |
| PS-17 | Reward integration |

**Separate per style [Confirmed]**

- **PS-18** Geometry generation and rendering may remain separate for each style.

**Rectangular piece generation for the initial prototype [Confirmed]** (Q-009, resolved 2026-11-23):

| ID | Requirement |
| --- | --- |
| PS-19 | The initial prototype uses a 4×4 logical board (as GP-01) |
| PS-20 | Allowed rectangular piece dimensions are 1×1, 1×2, 2×1 and 2×2 |
| PS-21 | Piece-count constraint: every generated prototype layout must contain between 8 and 12 pieces, inclusive |
| PS-22 | Valid layouts are generated using seeded generation |
| PS-23 | The selected/generated layout is persisted, so an unfinished puzzle retains exactly the same arrangement |
| PS-24 | Hand-authored layouts are not required for the initial prototype; they may be supported in a later phase |

**[Open — technical, TD-02]** The generation algorithm, and whether generation runs at runtime or when content is built. These are technical choices within the approved constraints above.

### 7.2 Prototype gameplay

All requirements below are **[Confirmed]** unless marked **Superseded**. GP-06 was confirmed, and GP-14 to GP-19 added, when Q-010 and Q-011 were resolved (2026-11-23). On 2026-11-25 the product owner revised Q-010 and Q-011 after Android device testing and approved the free-placement memory gameplay (GP-20 to GP-28): tap to reveal, free placement and an exactly 4-second preview. Superseded requirements keep their IDs as history and must not be implemented. On 2026-11-25 the product owner then **rejected** the memory and free-placement gameplay and approved the **rectangular picture-swap puzzle** from a reference gameplay recording (GP-29 to GP-36). GP-20 to GP-28 are superseded.

| ID | Requirement |
| --- | --- |
| GP-01 | One 4×4 logical board |
| GP-02 | Mixed-sized rectangular pieces. **Under review (Q-022):** the picture-swap prototype uses equal-size tiles (GP-30) |
| GP-03 | ~~Piece tray below the board~~ **Superseded 2026-11-25** by GP-20 and GP-27 (Q-011 revised) |
| GP-04 | ~~Pieces are dragged from the tray onto the board~~ **Superseded 2026-11-25** by GP-24 (pieces are dragged freely on the board) |
| GP-05 | ~~Automatic magnetic snapping (at the correct position, within the snapping tolerance; GP-26)~~ **Superseded 2026-11-25** by GP-32 (tiles always settle exactly into grid cells by swapping) |
| GP-06 | ~~Incorrectly dropped pieces animate back to their previous position (Q-010)~~ **Superseded 2026-11-25** by GP-25 (incorrect drops stay where placed) |
| GP-07 | No rotation in the prototype |
| GP-08 | Optional reference-image preview (separate from the start-of-puzzle preview, GP-21; interaction still open, Q-008) |
| GP-09 | Completion detection |
| GP-10 | Character/card reveal |
| GP-11 | Coin reward animation |
| GP-12 | Sound effects |
| GP-13 | Automatic saving of unfinished puzzles |
| GP-14 | ~~Only a piece's correct position accepts it (Q-010)~~ **Superseded 2026-11-25** by GP-24 and GP-25 (free placement) |
| GP-15 | ~~Correctly placed pieces become permanently locked; locked pieces cannot be moved or swapped (Q-010; still applies under free placement)~~ **Superseded 2026-11-25** by GP-32; whether correct tiles lock in the picture-swap puzzle is open (Q-023) |
| GP-16 | ~~The tray below the board has two rows and scrolls horizontally (Q-011)~~ **Superseded 2026-11-25** (no tray in the primary interaction) |
| GP-17 | ~~Tray pieces keep comfortable touch targets (Q-011)~~ **Superseded 2026-11-25**; touch-target intent continues in GP-28 |
| GP-18 | ~~Picking up a piece enlarges it to board scale (Q-011)~~ **Superseded 2026-11-25** (pieces are always at board scale on the board) |
| GP-19 | ~~The board and tray layout adapts to different phone screen sizes (Q-011)~~ **Superseded 2026-11-25** by GP-28 |
| GP-20 | ~~At puzzle start, every piece is placed face-down (decorative back) at its own seeded, randomised position scattered across the board; starting positions are independent of the correct positions, visibly distributed, individually selectable and do not expose the solution (Q-011 revised)~~ **Superseded 2026-11-25** by GP-29 to GP-31 |
| GP-21 | ~~After a short introduction, every piece flips face-up and stays face-up for **exactly 4 seconds** (the preview); no interaction during the introduction or the preview~~ **Superseded 2026-11-25** by the picture-swap puzzle (no preview) |
| GP-22 | ~~After the preview, every piece flips face-down and play begins (memory mode)~~ **Superseded 2026-11-25** by the picture-swap puzzle (no memory mode) |
| GP-23 | ~~**Tap to reveal:** tapping a face-down piece reveals only that piece; a revealed piece stays face-up, including while it is moved~~ **Superseded 2026-11-25** by GP-30 (tiles are face-up from the start) |
| GP-24 | ~~**Free placement:** a revealed, unlocked piece can be dragged anywhere within the playable board area; pieces may overlap temporarily; the selected piece is drawn above the others (Q-010 revised)~~ **Superseded 2026-11-25** by GP-32 (drag-and-swap) |
| GP-25 | ~~An incorrectly placed piece stays where it was dropped and is never returned automatically; it can be picked up and repositioned repeatedly (Q-010 revised)~~ **Superseded 2026-11-25** by GP-32 and GP-33 |
| GP-26 | ~~When a piece is aligned with its correct position within the snapping tolerance, it animates exactly into place and locks (GP-05, GP-15); the tolerance is configurable~~ **Superseded 2026-11-25** by GP-32 |
| GP-27 | ~~The board is the primary gameplay workspace; the two-row tray is not part of the primary puzzle interaction (Q-011 revised)~~ **Superseded 2026-11-25** by GP-29 |
| GP-28 | ~~The board and its pieces fit different phone aspect ratios within the safe area; pieces stay fully accessible and never leave the board area; overlapping pieces remain individually selectable (the topmost selectable piece is chosen)~~ **Superseded 2026-11-25** by GP-35 |
| GP-29 | **Board:** a fixed rectangular grid (4 × 4 for the prototype, GP-01). Every cell holds exactly one tile: no empty cells, no overlap, no free-floating pieces; tiles never leave the board |
| GP-30 | **Tiles:** equal-size fragments of one illustration, cut on the grid without stretching; every tile is face-up from the start and always shows its own fragment. A tile's identity and correct cell are separate from its current cell |
| GP-31 | **Start:** the tiles begin in a seeded, deterministic shuffled arrangement that is never already solved; every arrangement is solvable by swaps |
| GP-32 | **Drag-and-swap:** the player presses a tile (clear selection feedback), drags it over another tile (clear target feedback) and releases; the two tiles exchange cells with a smooth animation. Incorrect swaps are allowed and never rejected; swaps are unlimited with no penalty. Direct drag-and-drop is the interaction (no tap-then-tap). No rotation |
| GP-33 | A drag released outside another tile is cancelled: the tile returns to its own cell |
| GP-34 | **Completion:** detected only when every tile is in its correct cell; tiles landing in their correct cell get visible feedback; completion shows the finished illustration and a New puzzle or Continue action, ready for future rewards and progression |
| GP-35 | **Layout:** the board keeps the illustration's aspect ratio, fits different phone screens within the safe area, is never clipped and keeps comfortable touch targets |
| GP-36 | **Hints** are intentionally excluded from the initial prototype and are planned for v1 (design not yet specified) |

Details: [GAMEPLAY.md](GAMEPLAY.md). Technical specification: [PUZZLE_ENGINE.md](../architecture/PUZZLE_ENGINE.md).

### 7.3 Future puzzle functionality (not approved for implementation)

| ID | Feature | Notes |
| --- | --- | --- |
| FP-01 | Traditional irregular jigsaw pieces | Irregular jigsaw style, with interlocking geometry, tabs and blanks (PS-09, PS-10) |
| FP-02 | Rotation | Listed under irregular jigsaw expansion (PS-11) |
| FP-03 | Connected-piece grouping | Listed under irregular jigsaw expansion (PS-12) |
| FP-04 | Zoom and pan | Not assigned to a style |
| FP-05 | Different board sizes and difficulty levels | Not assigned to a style |

## 8. Core Gameplay Loop

**[Confirmed — structure]**, except the world-unlock step, which is **[Proposed]** (WP-03, Q-002).

```
Select puzzle (within a world)
      │
      ▼
Solve puzzle (drag, snap, complete)
      │
      ▼
Reward: coins
        + designated puzzle → guaranteed card (character reveal), if not already collected
        + non-designated puzzle → progression rewards
      │
      ▼
Grow themed collections
      │
      ▼
Complete collections → unlock next world [Proposed] ──► back to Select puzzle
```

The mascot guides the player through the loop (MC-01).

**[Source text needed]** Any additional loop steps in the approved PRD, such as a meta-loop, daily content or spending coins.

## 9. Collectible Cards

**[Confirmed]**

- **CC-01** Cards are collectible and belong to themed collections.
- **CC-02** Cards have **rarity**.
- **CC-03** A card is **guaranteed** when a **designated** puzzle is completed. A designated puzzle always grants its card on completion, accompanied by the character reveal.

**Card acquisition rules [Confirmed]** (Q-017, resolved):

- **CC-04** Designated card puzzles guarantee their associated collectible card.
- **CC-05** Non-designated puzzles award coins and progression rewards.
- **CC-06** Previously collected cards are not awarded as new collection progress.
- **CC-07** The first prototype puzzle must be a designated card puzzle, so that the full discovery and reward experience can be validated.

**[Open]**

- What "progression rewards" consist of for non-designated puzzles (Q-020).
- Which puzzles are designated, for example how many per collection (content design, Q-002).
- What, if anything, is shown or awarded when a designated puzzle's card is already collected (Q-007).
- Rarity tiers, how rarity is expressed and whether it affects acquisition (Q-007).
- The card detail view and collection size (Q-007).

> Correction in reconciliation 1: earlier repository text said that *every* completed puzzle awards a card. The confirmed rule is a guaranteed card after completion of a *designated* puzzle (CC-03).

## 10. Rewards

**[Confirmed]**

- **RW-01** Coins are awarded on puzzle completion, shown with a coin reward animation.
- **RW-02** Cards are guaranteed on designated puzzle completion (CC-03, CC-04). A card already collected does not count as new collection progress (CC-06).
- **RW-04** Non-designated puzzles award coins and progression rewards (CC-05). The content of progression rewards is open (Q-020).
- **RW-05** Reward integration is shared by both puzzle styles (PS-17).

**[Proposed]** **RW-03** World progression is driven by completing collections (WP-03).

**[Open]** What coins are spent on (Q-003) and the monetization model (Q-004).

## 11. Data-Driven Level System

**[Confirmed]**

- **DL-01** Levels and content are data-driven (configuration-driven). Worlds, collections, puzzles, pieces, card assignments (including which puzzles are designated) and rewards are defined in data, not hardcoded.
- **DL-02** Adding or changing a puzzle must not require changes to gameplay code.
- **DL-03** One level configuration framework serves both puzzle styles (PS-14). Each puzzle declares its style, and style-specific geometry settings sit alongside the shared fields.

**[Proposed]** Content data is validated when it is loaded, for example to check that pieces tile the board exactly (see [DATA_MODELS.md](../architecture/DATA_MODELS.md)).
**[Open]** Data format and authoring workflow.

## 12. Persistence Requirements

**[Confirmed]**

- **PR-01** Local-first persistence.
- **PR-02** Unfinished puzzles are saved automatically and restored exactly.
- **PR-03** Player progress (completed puzzles, unlocked worlds, cards, coins) persists across sessions.

**[Proposed]** Saved data is versioned to support migrations, and rewards are granted idempotently (never twice).
**[Open]** Storage technology (TD-01 / Q-014). Firebase-backed persistence, such as cloud save, only when justified.
**[Source text needed]** Any further persistence requirements in the approved PRD, such as save frequency or data-loss tolerance.

## 13. Technical Architecture (summary)

**[Confirmed]**

| Area | Decision |
| --- | --- |
| Platform / orientation | Android first, portrait |
| Framework / language | Flutter, Dart |
| Game engine | Flame |
| Architecture | Hybrid Flutter + Flame |
| State management | Riverpod |
| Puzzle domain | Independent pure-Dart puzzle engine, with no Flutter or Flame dependency |
| Audio | flame_audio |
| Character animation | Rive, subject to technical validation |
| Persistence | Local-first; database selection pending |
| Backend | Firebase, when justified |

Details: [ARCHITECTURE_OVERVIEW.md](../architecture/ARCHITECTURE_OVERVIEW.md) · [TECHNICAL_DECISIONS.md](../architecture/TECHNICAL_DECISIONS.md).

## 14. Technical Requirements and Quality Gates

**[Confirmed]**, from the approved Development Rules ([DEVELOPMENT_RULES.md](../development/DEVELOPMENT_RULES.md)):

| ID | Gate |
| --- | --- |
| QG-01 | Puzzle domain logic has unit tests; no domain change is merged without tests |
| QG-02 | The puzzle domain does not depend on Flame or Flutter |
| QG-03 | No business logic in rendering components |
| QG-04 | Levels are configuration-driven; no hardcoded screen coordinates |
| QG-05 | No unnecessary dependencies; each new dependency is justified |
| QG-06 | No secrets, API keys or signing credentials in the repository |
| QG-07 | Architectural decisions are documented as ADRs |
| QG-08 | Pull requests are focused and reviewable |
| QG-09 | Confirmed product decisions are preserved; future features are not implemented without approval |

**[Proposed]** Automated format, analyzer and test checks on every pull request ([TESTING_STRATEGY.md](../development/TESTING_STRATEGY.md)).

**[Source text needed]** The approved PRD's technical requirements and quality gates beyond the rules above, such as frame-rate targets, minimum Android version, app size, load-time limits, test-coverage thresholds and phase exit criteria. No numeric targets are set until they are supplied (Q-013, Q-019).

## 15. Prototype Scope

**[Confirmed]** The first prototype delivers the gameplay in Section 7.2 (GP-01 to GP-36, excluding requirements marked Superseded) for a single 4×4 puzzle with mixed rectangular pieces, on Android, in portrait.

**[Confirmed]** The prototype puzzle is a **designated card puzzle** (CC-07), so it validates the full discovery and reward experience: completion, character reveal, guaranteed card and coins.

**[Confirmed]** Initial development covers the rectangular tile style: mixed-sized rectangular pieces, logical grid occupancy and rectangular partition generation (PS-06 to PS-08), within the approved generation constraints (PS-19 to PS-24).

**Out of scope for the prototype [Confirmed]:** FP-01 to FP-05.

**[Proposed]** Prototype acceptance:

- A player completes one puzzle end to end: a shuffled 4 × 4 picture grid, drag one tile onto another to swap them until the picture is whole, completion, character/card reveal, coin animation and sound. (Revised 2026-11-25 for the picture-swap decision; earlier versions described the tray with strict placement, then the memory preview with free placement.)
- Leaving mid-puzzle and returning restores the exact state.
- Domain logic is unit-tested and independent of Flame.

## 16. Development Phases

**[Source text needed]** The approved PRD defines the development phases, and their approved names, order and exit criteria have not been supplied to the repository. Until then, the repository follows a **[Proposed]** sequence ([ROADMAP.md](../development/ROADMAP.md)):

1. Foundation (repository and documentation)
2. Technical validation
3. Puzzle domain
4. Playable prototype
5. MVP vertical slice

This sequence will be replaced by the approved phases when they are supplied (Q-019).

## 17. MVP Scope

**[Proposed]** The MVP builds on the prototype with:

- Content for the first world.
- A card collection view.
- World-based progression.
- The mascot guide.
- Local persistence of all progress.

**[Open]** Content volume and the final MVP feature list, to be set after the prototype.

## 18. Excluded Features

Not in the prototype, and not to be implemented without approval:

- Future puzzle functionality FP-01 to FP-05.
- iOS release.
- Landscape orientation.
- Backend or online features, unless justified and approved.
- Multiplayer and social features.
- Monetization implementation (model open, Q-004).

## 19. Success Criteria

**Technical validation [Confirmed — intent]**

- Flutter, Flame and Riverpod integrate cleanly in the hybrid architecture.
- Drag and snap feel smooth and responsive on target Android devices.
- The puzzle domain is independent and unit-tested.
- Rive is validated, or an alternative is decided.
- A local persistence technology is selected (ADR).

**Prototype:** see Section 15.

**MVP KPIs [Open]:** retention, session length, completion rate and their targets (Q-005).

## 20. Confirmed Decision Register

These must remain unchanged without explicit approval:

| # | Decision | Ref |
| --- | --- | --- |
| 1 | Android first | §13 |
| 2 | Portrait orientation | §13 |
| 3 | Flutter + Flame | §13 |
| 4 | Riverpod | §13 |
| 5 | Independent pure-Dart puzzle domain | PS-03, §13 |
| 6 | Hybrid puzzle system: separate rectangular tile and irregular jigsaw styles with shared session, configuration, interaction contracts, progress/completion reporting and reward integration | PS-04 to PS-18 |
| 7 | Mixed rectangular pieces for the first prototype (picture-swap prototype uses equal tiles; under review, Q-022) | PS-01, GP-02 |
| 8 | Traditional irregular jigsaw as future functionality | PS-02, FP-01 |
| 9 | ~~Piece tray below the board~~ Superseded 2026-11-25 by #31 | GP-03 |
| 10 | ~~Drag pieces from tray onto board~~ Superseded 2026-11-25 by #32 | GP-04 |
| 11 | ~~Automatic magnetic snapping~~ Superseded 2026-11-25 by #34 | GP-05 |
| 12 | No rotation in the prototype | GP-07 |
| 13 | Optional reference-image preview | GP-08 |
| 14 | Guaranteed card after designated puzzle completion | CC-03, CC-04 |
| 15 | One recurring mascot serving as a guide | MC-01 |
| 16 | Automatic saving of unfinished puzzles | GP-13, PR-02 |
| 17 | World-based progression | WP-01 |
| 18 | Magical Storybook visual identity | VI-01 |
| 19 | Collectible cards with rarity | CC-01, CC-02 |
| 20 | Data-driven level system | DL-01 |
| 21 | Local-first persistence; Firebase only when justified | PR-01, §13 |
| 22 | flame_audio; Rive subject to validation | §13 |
| 23 | Designated card puzzles guarantee their card; non-designated puzzles award coins and progression rewards | CC-04, CC-05 |
| 24 | Previously collected cards are not awarded as new collection progress | CC-06 |
| 25 | First prototype puzzle is a designated card puzzle | CC-07 |
| 26 | Initial development: rectangular partition generation with logical grid occupancy | PS-06 to PS-08 |
| 27 | Prototype piece generation: 4×4; pieces 1×1, 1×2, 2×1, 2×2; 8–12 pieces inclusive (generation constraint); seeded generation; layout persisted; hand-authored layouts not required for the prototype | PS-19 to PS-24 |
| 28 | ~~Strict placement: only the correct position accepts a piece; incorrect drops animate back to the previous position; correct pieces are permanently locked and cannot be moved or swapped~~ Superseded 2026-11-25 by #32 (locking retained) | GP-06, GP-14, GP-15 |
| 29 | ~~Two-row, horizontally scrollable tray; comfortable touch targets; picked-up piece enlarges to board scale; layout adapts to phone screen sizes~~ Superseded 2026-11-25 by #31 | GP-16 to GP-19 |
| 30 | Target audience: core 16–35; overall intended audience 13+; teenagers and adults; under-13 not an intended target audience (product positioning, not a compliance determination) | TA-01 to TA-08 |
| 31 | ~~Pieces start face-down and scattered across the board, which is the primary workspace; no tray in the primary interaction; layout fits phone aspect ratios (Q-011 revised 2026-11-25)~~ Superseded 2026-11-25 by #34 | GP-20, GP-27, GP-28 |
| 32 | ~~Free placement: drag revealed pieces anywhere on the board; temporary overlap allowed; incorrect drops stay where placed and can be repositioned; correct alignment within the snapping tolerance snaps and permanently locks (Q-010 revised 2026-11-25)~~ Superseded 2026-11-25 by #34 | GP-15, GP-24 to GP-26 |
| 33 | ~~Memory reveal: all pieces face-up for exactly 4 seconds after a short introduction, then face-down; tap to reveal one piece at a time; revealed pieces stay face-up (2026-11-25)~~ Superseded 2026-11-25 by #34 | GP-21 to GP-23 |
| 34 | Rectangular picture-swap puzzle: fixed grid fully filled with face-up tiles in a shuffled arrangement; drag one tile onto another to exchange them; incorrect swaps allowed, unlimited, no penalty; release outside another tile cancels; completion when every tile is correct (Q-010 and Q-011 revised again 2026-11-25) | GP-29 to GP-35 |
| 35 | Hints excluded from the initial prototype; planned for v1 (2026-11-25) | GP-36 |

## 21. Source Gaps Summary

These sections need the approved PRD v1.0 text (Q-019):

| Section | Missing |
| --- | --- |
| §2 | Exact USP statement and positioning |
| §4 | Detailed visual direction, if specified |
| §8 | Any further loop steps |
| §12 | Further persistence requirements |
| §14 | Numeric technical requirements and quality gates |
| §16 | Approved development phases and exit criteria |
