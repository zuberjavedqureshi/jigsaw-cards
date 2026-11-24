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

### 1.1 Confirmed Technical Decisions (ADRs)

Approved by the product owner on 2026-11-24, following the S-01 Hybrid Shell review. S-01's Android device validation (performance and lifecycle) is **still outstanding**. These decisions do not mark it complete.

| ID | Decision | ADR | Confirmed |
| --- | --- | --- | --- |
| TD-03 | Manual Flutter ↔ Flame bridge (intent callbacks out, small view interface in); no Riverpod in Flame game or component classes; no `flame_riverpod` in production; explicit initial-state sync | [ADR-0001](../decisions/ADR-0001-flame-riverpod-manual-bridge.md) | 2026-11-24 |
| TD-04 | Dart pub workspace: `app/` (Flutter) and `packages/puzzle_domain/` (pure Dart). Domain boundary enforced by `depend_on_referenced_packages: error`, a static dependency/import/export guard, and plain-Dart analysis and tests. The guard must run in CI (implementation follows under TD-08) | [ADR-0002](../decisions/ADR-0002-pub-workspace-and-domain-boundary.md) | 2026-11-24 |
| TD-05 | Hand-written Riverpod `Notifier` providers; no code generation or `build_runner` at the current scale; reconsider if provider complexity or boilerplate grows materially | [ADR-0003](../decisions/ADR-0003-handwritten-riverpod-providers.md) | 2026-11-24 |

## 2. Conditionally Confirmed

| Area | Decision | Condition |
| --- | --- | --- |
| Character animation | Rive | Subject to technical validation (performance, tooling, file size, Flame integration). Fallback TBC. |

## 3. Pending Decisions

| ID | Topic | Notes |
| --- | --- | --- |
| TD-01 | Local database / storage | To be evaluated in Phase 1 against: simplicity, migration support, performance, dependency weight. No candidate is pre-selected. |
| TD-02 | Rectangular partition generation algorithm | Product constraints approved via Q-009 (PRD PS-19 to PS-24: piece sizes, 8–12 pieces inclusive as a generation constraint, seeded generation, persisted layout). Still pending: the algorithm, runtime vs build-time generation and seed source (PUZZLE_ENGINE.md §5) |
| TD-06 | Minimum Android version / target devices | Needed for performance validation |
| TD-07 | Flutter / Flame version pinning policy | |
| TD-08 | CI setup | Analyzer, formatter, tests on PRs |

Each pending decision is resolved through an ADR. TD-03, TD-04 and TD-05 were resolved on 2026-11-24 and moved to §1.1 ([ADR-0001](../decisions/ADR-0001-flame-riverpod-manual-bridge.md), [ADR-0002](../decisions/ADR-0002-pub-workspace-and-domain-boundary.md), [ADR-0003](../decisions/ADR-0003-handwritten-riverpod-providers.md)).

## 4. Feasibility Review Recommendations (not decisions)

Recommendations from the [Technical Feasibility & Architecture Review](TECHNICAL_FEASIBILITY_REVIEW.md) (2026-11-23), kept as written. TD-03, TD-04 and TD-05 have since been confirmed (§1.1); the others remain **Pending** until an ADR is approved.

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
