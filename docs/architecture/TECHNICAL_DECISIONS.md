# Technical Decisions

This is a summary register. Significant decisions are recorded in detail as ADRs in [docs/decisions/](../decisions/ADR_INDEX.md).

## 1. Confirmed Decisions

| Area | Decision | Notes |
| --- | --- | --- |
| Platform | Android first | iOS not in current scope |
| Orientation | Portrait | |
| Framework | Flutter | |
| Language | Dart | |
| Game engine | Flame | |
| State management | Riverpod | |
| Audio | flame_audio | |
| Architecture | Hybrid Flutter + Flame | |
| Puzzle domain | Independent pure-Dart module | No Flutter/Flame dependency |
| Persistence approach | Local-first | |
| Backend | Firebase, only when justified | Not needed for prototype |

## 2. Conditionally Confirmed

| Area | Decision | Condition |
| --- | --- | --- |
| Character animation | Rive | Subject to technical validation (performance, tooling, file size, Flame integration). Fallback TBC. |

## 3. Pending Decisions

| ID | Topic | Notes |
| --- | --- | --- |
| TD-01 | Local database / storage | To be evaluated in Phase 1 against: simplicity, migration support, performance, dependency weight. No candidate is pre-selected. |
| TD-02 | Rectangular partition generation algorithm | Generation is confirmed for initial development (PS-08); the algorithm, constraints and seeding are open (PUZZLE_ENGINE.md §5, Q-009) |
| TD-03 | Flame ↔ Riverpod bridge | Manual vs. integration package (GAME_STATE.md §4) |
| TD-04 | Repository layout | Proposed `app/` + `packages/puzzle_domain/` |
| TD-05 | Riverpod code generation | Use or avoid |
| TD-06 | Minimum Android version / target devices | Needed for performance validation |
| TD-07 | Flutter / Flame version pinning policy | |
| TD-08 | CI setup | Analyzer, formatter, tests on PRs |

Each pending decision is resolved through an ADR.
