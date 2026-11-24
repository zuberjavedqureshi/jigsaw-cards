# ADR-0002: Dart pub workspace and enforced pure-Dart domain boundary

- Status: Accepted
- Date: 2026-11-24
- Deciders: Product owner, following the S-01 Hybrid Shell review
- Technical decision: **TD-04** (Confirmed)
- Evidence: [S-01 Hybrid Shell findings](https://github.com/zuberjavedqureshi/jigsaw-cards/blob/a17040da6281dda2f8ac8595d54688af0a691d50/docs/spikes/S-01-HYBRID-SHELL.md) §6 and §8, at commit `a17040d`; [PR #4](https://github.com/zuberjavedqureshi/jigsaw-cards/pull/4)

## Decision

1. The repository uses a **Dart pub workspace**:
   - `app/`: the Flutter application.
   - `packages/puzzle_domain/`: the pure-Dart puzzle domain package.
2. The domain boundary (no Flutter, Flame or `dart:ui` in `puzzle_domain`) is **enforced** by all of:
   - `depend_on_referenced_packages: error` in the domain package's `analysis_options.yaml`;
   - a **static guard** that rejects Flutter/Flame dependencies in the domain `pubspec.yaml`, and Flutter, Flame, `sky_engine` and `dart:ui`/`dart:ui_web` `import` or `export` directives in its sources;
   - **plain-Dart analysis and tests** (`dart analyze --fatal-infos` and `dart test` on the Dart VM).
3. The boundary guard **must run in CI**. Implementing CI is separate follow-up work under TD-08, which remains Pending.

## Context

The pure-Dart puzzle domain is a confirmed decision (PRD PS-03, §13; QG-02). ARCHITECTURE_OVERVIEW §4 proposed `app/` + `packages/puzzle_domain/`, expecting the package structure to enforce the boundary through the dependency graph. S-01 tested that assumption.

## Rationale

- The workspace works with all the required tooling on Flutter 3.50.1 / Dart 3.14.0:
  - one `flutter pub get` resolves everything into one `pubspec.lock`;
  - `flutter analyze`, `flutter test`, `dart analyze`, `dart test` and the Android profile build all work;
  - the app depends on `puzzle_domain` by version, with no `path:` dependency.
- **The workspace alone does not enforce the boundary.** All workspace packages share one `package_config.json`, so `puzzle_domain` can resolve `package:flutter` and `package:flame` even though it doesn't depend on them. With default lints, `dart analyze` reports only info-level hints and exits 0. The three enforcement layers close that gap.

## Alternatives considered

| Option | Assessment |
| --- | --- |
| **Pub workspace plus enforcement layers (chosen)** | Native Dart tooling; single lockfile; boundary enforced and tested |
| Pub workspace without extra enforcement | Rejected: S-01 showed Flutter/Flame imports in the domain package pass `dart analyze` |
| Separate repositories, or path dependencies without a workspace | Not prototyped. More lockfiles and version coordination, for no boundary benefit the chosen option lacks |
| Single Flutter package with the domain in a folder | Rejected: nothing would stop domain code importing Flutter (Development Rule 2) |

## Consequences and trade-offs

- When the production `app/` and `packages/puzzle_domain/` are created, they include the workspace root `pubspec.yaml`, the domain `analysis_options.yaml` rule and a boundary guard with its self-tests. The S-01 spike versions are the reference; the spike code itself is throwaway.
- The static guard is text-based, not a Dart parser. Comments and multi-line strings are removed before scanning, but unusual edge cases (such as nested block comments) are not modelled. The analyzer rule and VM tests remain as independent layers.
- CI must run the guard. Until TD-08 is implemented, the guard can only be run manually.
- A single lockfile means dependency upgrades apply to the whole workspace at once.

## Evidence from S-01

| Evidence | Result |
| --- | --- |
| Workspace resolution, analysis, tests, Android profile build | All work; also verified from a fresh clone |
| Domain package imports Flutter/Flame, default lints | `dart analyze` exits 0 with 2 info hints |
| Same, with `depend_on_referenced_packages: error` | `dart analyze` exits 3 with 2 errors |
| Static guard self-tests | 32/32 pass: 26 prohibited cases rejected, including `sky_engine` and `dart:ui_web` import/export; 6 allowed cases accepted |
| Guard weakened to omit `sky_engine` and `dart:ui_web` | Exactly those 4 tests fail |
| Domain tests on the plain Dart VM | 5/5 pass |

## Validation status

This architecture decision is **Accepted**. S-01's **Android device validation** (performance and lifecycle) is still outstanding. It doesn't bear directly on this decision, and S-01 is not marked complete.
