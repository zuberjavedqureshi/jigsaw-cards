# Contributing to Jigsaw Cards

Thank you for contributing. Jigsaw Cards is a long-term commercial project, so consistency, clarity and reviewability matter more than speed.

Before contributing, read:

- [Development Rules](docs/development/DEVELOPMENT_RULES.md) — mandatory.
- [Product Requirements](docs/product/PRD.md) — the source of truth for scope.
- [Architecture Overview](docs/architecture/ARCHITECTURE_OVERVIEW.md).

## Branching Model

| Branch | Purpose |
| --- | --- |
| `main` | Reviewed, stable work only. No direct commits for substantial changes. |
| `feature/<short-description>` | New features, e.g. `feature/puzzle-grid-model`. |
| `fix/<short-description>` | Bug fixes. |
| `docs/<short-description>` | Documentation-only changes. |
| `spike/<short-description>` | Time-boxed technical validation; not merged as production code without review. |

## Workflow

1. Check [planning/BACKLOG.md](planning/BACKLOG.md) and open issues; open an issue for new work.
2. Branch from the latest `main`.
3. Keep the change focused on one concern.
4. Add or update tests (puzzle domain logic must have unit tests).
5. Update documentation affected by the change.
6. Open a pull request using the template and link the issue.
7. Merge only after review.

## Commit Messages

Use short, imperative subject lines (≤ 72 characters), optionally with a scope:

```
docs: add puzzle engine placement rules
puzzle: add grid occupancy model
```

Explain *why* in the body when the change is not obvious.

## Scope Changes

Product decisions listed in the PRD are confirmed. Proposals that change scope, add future features, or alter the technology stack must be raised as a **feature proposal issue** or an **Architecture Decision Record** (see [ADR index](docs/decisions/ADR_INDEX.md)) and approved before implementation.

## Security

Never commit secrets, API keys, Firebase configuration files, keystores or signing credentials. See `.gitignore`. If a secret is committed accidentally, report it immediately so it can be rotated — removing it from history alone is not sufficient.

## Assets

Only commit assets the project has the right to use. Record the source and license of any reference or third-party material in the relevant folder.
