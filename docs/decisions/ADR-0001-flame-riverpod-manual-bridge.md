# ADR-0001: Manual bridge between Flame and the Riverpod application layer

- Status: Accepted
- Date: 2026-11-24
- Deciders: Product owner, following the S-01 Hybrid Shell review
- Technical decision: **TD-03** (Confirmed)
- Evidence: [S-01 Hybrid Shell findings](https://github.com/zuberjavedqureshi/jigsaw-cards/blob/a17040da6281dda2f8ac8595d54688af0a691d50/docs/spikes/S-01-HYBRID-SHELL.md) §4, §5 and §7, at commit `a17040d`; [PR #4](https://github.com/zuberjavedqureshi/jigsaw-cards/pull/4)

## Decision

1. Flutter ↔ Flame communication uses a **manual bridge**:
   - **Flame → application:** intents, delivered as plain callbacks that the host supplies to the game.
   - **Application → Flame:** a small view interface that the game implements and the host calls.
2. **Riverpod stays out of Flame game and component classes.** They do not import Riverpod or read providers. The hosting Flutter widget owns the Riverpod subscriptions (for example `ref.listen` in `build`) and forwards changes through the view interface.
3. **`flame_riverpod` is not used in production.**
4. **Initial state is synchronised explicitly** when the game is created, for example through constructor parameters. Riverpod listeners deliver only later changes.

## Context

The architecture is a confirmed hybrid of Flutter and Flame, with Riverpod for application state (PRD §13; ARCHITECTURE_OVERVIEW §2). Development Rules 2 and 3 require puzzle logic to stay independent of Flame, and business logic to stay out of rendering components. The open question was how Flame components should receive application state and report user intent. The two candidates were a hand-written bridge and the `flame_riverpod` integration package.

## Rationale

- **Coupling:** with the manual bridge, Flame code depends only on a two-member contract and has no Riverpod import, which keeps rendering separate from application state.
- **Testability:** the manual-bridge game runs in a plain `GameWidget` with a plain callback and no `ProviderScope`.
- **Lifecycle:** subscriptions belong to the hosting widget and are closed by Riverpod with it, so there is no manual disposal in Flame.
- **Maintenance:** only public APIs are used. `flame_riverpod` 5.5.5 imports Riverpod's private `package:riverpod/src/framework.dart`, which any Riverpod upgrade can break.
- **Simplicity:** no extra dependency (Development Rule 1), and about the same amount of glue code as the alternative.

## Alternatives considered

| Option | Assessment |
| --- | --- |
| **Manual bridge (chosen)** | Public APIs only; Flame free of Riverpod; testable without a `ProviderScope` |
| `flame_riverpod` 5.5.5 | First-party (Flame team) and version-aligned today. Requires `RiverpodGameMixin`, `RiverpodComponentMixin`, `RiverpodAwareGameWidget` and a `GlobalKey`; recreates subscriptions on every `GameWidget` rebuild and forces a rebuild when components mount or unmount; depends on a private Riverpod import |
| Passing a `ProviderContainer` or `ref` into the game | Not prototyped. Rejected for the same reason as `flame_riverpod`: it places Riverpod inside Flame code, contrary to point 2 of the decision |

## Consequences and trade-offs

- Each new piece of state the game needs means one more method on the view interface, plus a `ref.listen` in the host. This is explicit, but slightly more manual than watching a provider directly.
- Every bridged value needs an explicit initial sync. S-01 found that both bridge options needed this.
- Flame components stay unit- and widget-testable without Riverpod.
- **Possible follow-up (not decided here):** a static check, like the TD-04 boundary guard, that rejects Riverpod imports in Flame game and component code.

## Evidence from S-01

| Evidence | Result |
| --- | --- |
| Both bridges, same widget tests (Flutter → Flame, Flame → Flutter, overlay with the game mounted, lifecycle without duplicate listeners) | 8 of 8 pass for each bridge |
| Manual-bridge game with no Riverpod (`manual_bridge_test.dart`) | Passes |
| Glue code, non-blank and non-comment lines | Manual: about 27. `flame_riverpod`: 46 in the game file, plus `GlobalKey` wiring |
| `flame_riverpod` source review | Private Riverpod import; forced `GameWidget` rebuilds |
| Initial values | Neither bridge delivered them automatically; explicit sync added |

## Validation status

This architecture decision is **Accepted**. Separately, S-01's **Android device validation is still outstanding**: the §8.1 frame-timing measurements, and confirming `paused`/`resumed` on a physical low-end and mid-range device. S-01 is **not** complete for performance or lifecycle. If device validation reveals a problem with this approach, a new ADR will supersede this one.
