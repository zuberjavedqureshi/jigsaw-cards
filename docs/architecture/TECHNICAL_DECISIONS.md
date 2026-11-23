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
| TD-02 | Rectangular partition generation algorithm | Product constraints approved via Q-009 (PRD PS-19 to PS-24: piece sizes, 8–12 pieces inclusive as a generation constraint, seeded generation, persisted layout). Still pending: the algorithm, runtime vs build-time generation and seed source (PUZZLE_ENGINE.md §5) |
| TD-03 | Flame ↔ Riverpod bridge | Manual vs. integration package (GAME_STATE.md §4) |
| TD-04 | Repository layout | Proposed `app/` + `packages/puzzle_domain/` |
| TD-05 | Riverpod code generation | Use or avoid |
| TD-06 | Minimum Android version / target devices | Needed for performance validation |
| TD-07 | Flutter / Flame version pinning policy | |
| TD-08 | CI setup | Analyzer, formatter, tests on PRs |

Each pending decision is resolved through an ADR.

## 4. Feasibility Review Recommendations (not decisions)

Recommendations from the [Technical Feasibility & Architecture Review](TECHNICAL_FEASIBILITY_REVIEW.md) (2026-11-23). All decisions above remain **Pending** until an ADR is approved.

| ID | Recommendation | Validate in |
| --- | --- | --- |
| TD-01 | Versioned JSON document with atomic writes behind a repository interface (prototype); exclude unmaintained `hive` and `isar`. Recovery policy (last-known-good backup vs defined default state) requires separate approval | S-06 |
| TD-02 | Enumerate/select (or constrained random split) with a seeded choice. Seeding and layout persistence are now product-approved requirements (Q-009); the algorithm remains a recommendation | S-04 |
| TD-03 | Manual bridge first; adopt `flame_riverpod` only if needed | S-01 |
| TD-04 | Dart pub workspace: `app/` + `packages/puzzle_domain/` | S-01 |
| TD-05 | No Riverpod code generation initially | S-01 |
| TD-06 | Start from Flutter's defaults (minSdk 24, latest targetSdk) as a baseline, not a decision; device matrix per review §5; API 36 large-screen orientation behaviour per review §6.4 | S-02, S-07 |
| TD-07 | Pin Flutter SDK version; commit app `pubspec.lock`; deliberate upgrade PRs | No spike |
| TD-08 | GitHub Actions on PRs: format, analyze, domain and app tests, added when code starts | No spike |
