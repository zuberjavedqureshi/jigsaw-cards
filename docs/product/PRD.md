# Jigsaw Cards — Product Requirements Document

| Field | Value |
| --- | --- |
| Version | 1.0 |
| Status | Approved for technical validation |
| Platform | Android first, portrait |
| Tagline | **Solve. Discover. Collect.** |

> This document consolidates the approved product decisions. Items marked **TBC** (to be confirmed) are not yet decided and are tracked in [OPEN_QUESTIONS.md](../../planning/OPEN_QUESTIONS.md). Changes to confirmed scope require explicit approval.

---

## 1. Product Vision

Jigsaw Cards is a magical storybook puzzle adventure. Players solve beautifully illustrated image puzzles to discover animated characters, collect cards, complete themed collections and unlock new fantasy worlds.

The experience should feel like turning the pages of an enchanted storybook: calm, satisfying and rewarding, with every completed puzzle revealing something new.

## 2. Unique Selling Proposition

Jigsaw Cards combines three things that are usually separate:

1. **Satisfying jigsaw gameplay** — tactile drag-and-snap puzzles designed for short mobile sessions.
2. **Discovery** — each completed puzzle reveals an animated character rather than just a finished picture.
3. **Collection** — revealed characters become cards in themed collections that drive progression into new worlds.

A recurring mascot character ties the journey together and gives the game a recognisable identity.

## 3. Target Audience

**TBC.** The product is a casual mobile puzzle game with a storybook fantasy theme. The specific primary audience (age range, player profile, family/child audience considerations) has not been formally confirmed. This decision affects art direction, monetization, data collection and store compliance, and must be resolved before MVP content production. See OPEN_QUESTIONS Q-001.

## 4. Visual Identity

- Magical storybook aesthetic: beautifully illustrated, warm and inviting.
- Animated characters revealed on puzzle completion (Rive, subject to technical validation).
- One recurring mascot character who guides the player.
- Each world has its own distinct visual theme.

Details: [VISUAL_IDENTITY.md](VISUAL_IDENTITY.md).

## 5. Worlds

| # | World |
| --- | --- |
| 1 | Enchanted Forest |
| 2 | Ocean Kingdom |
| 3 | Fantasy Kingdom |
| 4 | Cosmic Adventures |

Worlds are unlocked through progression. The number of puzzles, characters and collections per world is **TBC**. See [GAME_PROGRESSION.md](GAME_PROGRESSION.md).

## 6. Core Gameplay Loop

```
Select puzzle → Solve puzzle → Character/card reveal → Coin reward
      ↑                                                     │
      └──── Complete collections → Unlock new worlds ◄──────┘
```

### Initial puzzle gameplay (confirmed)

- One 4×4 logical board.
- Mixed-sized rectangular pieces.
- Pieces arranged in a tray below the board.
- Drag pieces from the tray onto the board.
- Automatic magnetic snapping.
- Incorrect placement returns the piece to its previous position.
- No rotation in the initial prototype.
- Optional reference-image preview.
- Completion detection.
- Character/card reveal.
- Coin reward animation.
- Sound effects.
- Automatic saving of unfinished puzzles.

Details: [GAMEPLAY.md](GAMEPLAY.md).

## 7. Card Collection

- Completing a puzzle reveals a character and awards the corresponding card.
- Cards belong to themed collections.
- Completing collections unlocks new fantasy worlds.
- Card rarity, duplicates, card detail views and collection size are **TBC**.

## 8. Rewards

- **Coins** are awarded on puzzle completion, shown with a reward animation.
- **Cards** are awarded through character reveals.
- **Worlds** are unlocked through collection progress.
- What coins can be spent on (e.g. hints, unlocks, cosmetics) is **TBC**. See OPEN_QUESTIONS Q-003.

## 9. MVP Scope

The MVP scope will be finalised after technical validation. It is expected to include:

- The confirmed initial puzzle gameplay (Section 6).
- Character/card reveal and coin reward.
- Card collection view for at least the first world.
- Local-first persistence of progress and unfinished puzzles.
- Sound effects.
- Android, portrait.

Exact content volume (number of puzzles and cards in the MVP) is **TBC**.

## 10. Excluded Features (not in initial prototype / MVP unless approved)

The following are **future puzzle styles** and are explicitly out of scope for the initial prototype:

- Traditional irregular jigsaw pieces.
- Piece rotation.
- Connected-piece grouping.
- Zoom and pan.
- Different board sizes and difficulty levels.

Also not in scope without explicit approval:

- iOS release.
- Landscape orientation.
- Backend / online features (Firebase is used only when justified).
- Multiplayer or social features.
- Monetization implementation (model TBC).

## 11. Success Criteria

**Technical validation phase**

- Flame and Riverpod integrate cleanly in the hybrid architecture.
- Dragging and magnetic snapping feel smooth and responsive on target Android devices.
- Puzzle domain logic is independent of Flame and covered by unit tests.
- Rive character animation is validated (or an alternative is decided).
- A local persistence approach is selected and documented.

**Prototype**

- A player can complete one 4×4 mixed-rectangle puzzle end to end: drag, snap, reject incorrect placement, complete, reveal, reward.
- Leaving mid-puzzle and returning restores the exact puzzle state.

**MVP** — product KPIs (retention, session length, completion rate) and their targets are **TBC**. See OPEN_QUESTIONS Q-005.
