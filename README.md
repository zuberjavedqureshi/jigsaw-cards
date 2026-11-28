# Jigsaw Cards

> **Solve. Discover. Collect.**

Jigsaw Cards is a premium casual puzzle adventure for Android. Players travel through a journey of locations, solving puzzles made from realistic photographs and semi-realistic illustrations, where every new level reveals a surprising picture. Along the way they discover animated characters, collect cards and complete themed collections.

> **Project status: Early prototype — technical validation.**
> The current playable build (`feature/gameplay-picture-swap`) is a rectangular picture-swap puzzle: a shuffled 4×4 grid of picture tiles, where the player drags one tile onto another to swap them until the picture is whole. It uses code-drawn placeholder artwork and has not been validated on a physical Android device. Cards, coins, rewards, hints (planned for v1), audio, persistence and the reference preview are not implemented. Earlier tray and memory/free-placement builds are superseded. See [Implementation Status](planning/IMPLEMENTATION_STATUS.md).

---

## Game Vision

Five locations of ten levels each are unlocked one level at a time: completing a level unlocks the next, level 10 of locations 1–4 opens the next location, level 10 of location 5 completes the main World Journey, and completed levels can be replayed. Completing puzzles rewards coins, and completing a designated puzzle guarantees a collectible card, revealed through an animated character. Cards have rarity and belong to themed collections. One recurring mascot character guides the player throughout the journey. See the [PRD](docs/product/PRD.md) (VI-01 to VI-13, WP-04 to WP-10).

**Locations:** five, each with an original name and tagline. No names are approved yet; candidates are listed in [Game Progression](docs/product/GAME_PROGRESSION.md#2-locations). The code uses working titles until names are approved.

**Hybrid puzzle system:** two separate puzzle styles. Rectangular tile puzzles (a picture-swap grid of equal-sized tiles) come first; traditional irregular jigsaw puzzles are planned as future functionality. Both share session, configuration, progress and reward systems.

**Initial puzzle prototype**

- A fixed, uniform 4×4 grid of 16 equal-sized picture tiles, all face-up, in a seeded shuffled order (no tray, no empty cells).
- Drag one tile onto another and release: the two tiles swap places. Wrong swaps are allowed; a release outside another tile cancels.
- Correctly placed tiles merge into the picture but stay movable (nothing locks); the puzzle completes when every tile is in place. Hints are planned for v1.
- The arrangement is saved with the puzzle (not yet implemented).
- No rotation in the initial prototype.
- Optional reference-image preview.
- Completion detection, character/card reveal, coin reward animation and sound effects.
- Automatic saving of unfinished puzzles.

See [Gameplay](docs/product/GAMEPLAY.md) for full details.

---

## Technology Stack

| Area | Choice | Status |
| --- | --- | --- |
| Platform | Android first, portrait | Confirmed |
| Framework / Language | Flutter / Dart | Confirmed |
| Game engine | Flame | Confirmed |
| State management | Riverpod | Confirmed |
| Audio | flame_audio | Confirmed |
| Character animation | Rive | Subject to technical validation |
| Persistence | Local-first | Confirmed approach; database selection pending |
| Backend | Firebase | Only when justified |
| Architecture | Hybrid Flutter + Flame, independent pure-Dart puzzle domain | Confirmed |

See [Technical Decisions](docs/architecture/TECHNICAL_DECISIONS.md).

---

## Current Development Status

| Item | Status |
| --- | --- |
| Product requirements | Documented (v1.0) |
| Architecture | Proposed, awaiting technical validation |
| Flutter project | Not created |
| Puzzle domain | Not started |
| Art / audio assets | Not started |

Live status: [planning/IMPLEMENTATION_STATUS.md](planning/IMPLEMENTATION_STATUS.md)

---

## Roadmap (summary)

> Proposed sequence, to be reconciled with the development phases in the approved PRD v1.0 (see [PRD §16](docs/product/PRD.md)).

| Phase | Goal |
| --- | --- |
| 0 — Foundation | Repository, documentation, open questions resolved |
| 1 — Technical validation | Validate Flame + Riverpod integration, drag/snap feel, Rive, persistence choice |
| 2 — Puzzle domain | Pure-Dart puzzle engine with unit tests |
| 3 — Playable prototype | One 4×4 puzzle end to end: drag, snap, complete, reveal, reward, save |
| 4 — MVP vertical slice | First world, card collection, progression, audio, polish |

Full detail: [ROADMAP.md](docs/development/ROADMAP.md) · [MILESTONES.md](docs/development/MILESTONES.md)

---

## Documentation

**Product**
- [Product Requirements (PRD)](docs/product/PRD.md)
- [Gameplay](docs/product/GAMEPLAY.md)
- [Visual Identity](docs/product/VISUAL_IDENTITY.md)
- [Game Progression](docs/product/GAME_PROGRESSION.md)

**Architecture**
- [Architecture Overview](docs/architecture/ARCHITECTURE_OVERVIEW.md)
- [Puzzle Engine](docs/architecture/PUZZLE_ENGINE.md)
- [Game State](docs/architecture/GAME_STATE.md)
- [Data Models](docs/architecture/DATA_MODELS.md)
- [Technical Decisions](docs/architecture/TECHNICAL_DECISIONS.md)
- [Technical Feasibility & Architecture Review](docs/architecture/TECHNICAL_FEASIBILITY_REVIEW.md)

**Development**
- [Roadmap](docs/development/ROADMAP.md)
- [Milestones](docs/development/MILESTONES.md)
- [Testing Strategy](docs/development/TESTING_STRATEGY.md)
- [Development Rules](docs/development/DEVELOPMENT_RULES.md)
- [Architecture Decision Records](docs/decisions/ADR_INDEX.md)

**Planning**
- [Backlog](planning/BACKLOG.md)
- [Open Questions](planning/OPEN_QUESTIONS.md)
- [Implementation Status](planning/IMPLEMENTATION_STATUS.md)

**Contributing**
- [Contribution Guidelines](CONTRIBUTING.md)

---

## Repository Layout

```
docs/         Product, architecture, development and decision documents
assets/       Game assets (artwork, characters, cards, worlds, audio, ui)
design/       Wireframes, references and style guide
planning/     Backlog, open questions, implementation status
.github/      Issue and pull request templates
```

## License

Copyright © 2026 Jigsaw Cards. All rights reserved. See [LICENSE](LICENSE).
