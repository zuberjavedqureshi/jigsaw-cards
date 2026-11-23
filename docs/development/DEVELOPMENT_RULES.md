# Development Rules

These rules are mandatory for all contributors, human or AI.

1. **Do not introduce unnecessary dependencies.** Every new package must be justified in the pull request (what it solves, why built-in or existing code is insufficient, maintenance status, size).
2. **Keep puzzle logic independent of Flame.** The puzzle domain is pure Dart and must not import Flutter or Flame.
3. **Keep business logic out of rendering components.** Flame components and widgets render state and forward user intent; they do not decide rules, rewards or progression.
4. **Use configuration-driven levels.** Worlds, collections, puzzles, pieces and rewards are defined in configuration, not hardcoded.
5. **Write unit tests for puzzle domain logic.** No domain change is merged without tests.
6. **Avoid hardcoded screen coordinates.** Layout is derived from screen size and the logical grid.
7. **Avoid unnecessary abstractions.** Build what the current milestone needs; add abstraction when a second real use appears.
8. **Preserve existing product decisions.** The PRD and confirmed technical decisions are the source of truth.
9. **Do not implement future features without approval.** Irregular pieces, rotation, grouping, zoom/pan, board sizes and difficulty levels require explicit approval.
10. **Do not commit secrets, API keys or signing credentials.** This includes Firebase config files, keystores and `key.properties`.
11. **Document architectural decisions.** Significant decisions are recorded as ADRs in `docs/decisions/`.
12. **Keep pull requests focused and reviewable.** One concern per PR; split large changes.

## Related

- [CONTRIBUTING.md](../../CONTRIBUTING.md)
- [TESTING_STRATEGY.md](TESTING_STRATEGY.md)
- [ADR index](../decisions/ADR_INDEX.md)
