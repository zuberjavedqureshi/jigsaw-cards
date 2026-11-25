# Jigsaw Cards

> **Solve. Discover. Collect.**

Jigsaw Cards is a magical storybook puzzle adventure for Android. Players solve beautifully illustrated image puzzles to discover animated characters, collect cards, complete themed collections and unlock new fantasy worlds.

> **Project status: Early prototype — technical validation.**
> The current playable build (`feature/gameplay-picture-swap`) is a rectangular picture-swap puzzle: a shuffled 4×4 grid of picture tiles, where the player drags one tile onto another to swap them until the picture is whole. It uses code-drawn placeholder artwork and has not been validated on a physical Android device. Cards, coins, rewards, hints (planned for v1), audio, persistence and the reference preview are not implemented. Earlier tray and memory/free-placement builds are superseded. See [Implementation Status](planning/IMPLEMENTATION_STATUS.md).

---

## Game Vision

Every puzzle is a page in a storybook. Completing puzzles rewards coins, and completing a designated puzzle guarantees a collectible card, revealed through an animated character. Cards have rarity and belong to themed collections. Completing collections is proposed as the way to unlock new fantasy worlds (mechanism still open). One recurring mascot character guides the player throughout the journey.

**Worlds** (proposed working names; world-based progression is confirmed)

1. Enchanted Forest
2. Ocean Kingdom
3. Fantasy Kingdom
4. Cosmic Adventures

**Hybrid puzzle system:** two separate puzzle styles. Rectangular tile puzzles (mixed-sized rectangular pieces) come first; traditional irregular jigsaw puzzles are planned as future functionality. Both share session, configuration, progress and reward systems.

**Initial puzzle prototype**

- One 4×4 logical board with mixed-sized rectangular pieces.
- A fixed 4×4 grid filled with face-up picture tiles in a shuffled order (no tray, no empty cells).
- Drag one tile onto another and release: the two tiles swap places. Wrong swaps are allowed; a release outside another tile cancels.
- Correctly placed tiles merge into the picture; the puzzle completes when every tile is in place. Hints are planned for v1.
- Seeded generation of layouts with between 8 and 12 pieces (inclusive) of 1×1, 1×2, 2×1 or 2×2; the layout is saved with the puzzle.
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
