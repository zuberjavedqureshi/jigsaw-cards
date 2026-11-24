# ADR-0003: Hand-written Riverpod providers, no code generation

- Status: Accepted
- Date: 2026-11-24
- Deciders: Product owner, following the S-01 Hybrid Shell review
- Technical decision: **TD-05** (Confirmed)
- Evidence: [S-01 Hybrid Shell findings](https://github.com/zuberjavedqureshi/jigsaw-cards/blob/a17040da6281dda2f8ac8595d54688af0a691d50/docs/spikes/S-01-HYBRID-SHELL.md) §9, at commit `a17040d`; [PR #4](https://github.com/zuberjavedqureshi/jigsaw-cards/pull/4)

## Decision

1. Riverpod providers are **hand-written**, using `Notifier` / `NotifierProvider`.
2. **Riverpod code generation (`riverpod_generator`, `riverpod_annotation`) and `build_runner` are not introduced** at the current project scale.
3. **Reconsider** this if provider complexity or boilerplate grows materially. Any change requires a new ADR that supersedes this one.

## Context

Riverpod is the confirmed state-management library (PRD §13). Riverpod 3 supports both hand-written providers and annotation-based code generation. Development Rules 1 and 7 discourage unnecessary dependencies and abstractions.

## Rationale

- At this scale, code generation saves very little: about 3 lines per provider declaration.
- In return it adds a build step, a second, generated source of truth, and 18 extra locked packages.
- Hand-written providers keep the provider type visible in source, and need no build step during development or CI.

## Alternatives considered

| Option | Assessment |
| --- | --- |
| **Hand-written `Notifier` providers (chosen)** | No build step; explicit; 3-line provider declaration in S-01 |
| `riverpod_generator` + `riverpod_annotation` + `build_runner` | Works; less boilerplate per provider; adds build time and dependencies |

## Consequences and trade-offs

- Slightly more boilerplate per provider, especially for families and parameterised providers.
- No generated files to keep in sync, and no `build_runner` step in development or CI.
- Riverpod features that rely on code generation are not available without revisiting this ADR.

## Evidence from S-01

Measured in a throwaway copy of the S-01 app, outside the repository:

| Measure | Hand-written | Code generation |
| --- | --- | --- |
| Provider declaration | 3 lines | `part` directive plus annotation; 62 generated lines |
| Build step | None | `build_runner` cold run 42 s; 1.2 s with no changes |
| Locked packages | 75 | 93 (+18) |
| Tests | 12/12 pass | 11/11 pass (the copy predates the 12th test) |

## Validation status

This architecture decision is **Accepted**. S-01's **Android device validation** (performance and lifecycle) is still outstanding. It doesn't bear on this decision, and S-01 is not marked complete.
