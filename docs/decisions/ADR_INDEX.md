# Architecture Decision Records

ADRs capture significant technical decisions, their context and consequences.

## Index

| ADR | Title | Status | Date |
| --- | --- | --- | --- |
| — | No ADRs recorded yet | — | — |

Planned ADRs (from [TECHNICAL_DECISIONS.md](../architecture/TECHNICAL_DECISIONS.md) pending list):

- Local persistence selection (TD-01)
- Rectangular partition generation algorithm (TD-02)
- Flame ↔ Riverpod bridge (TD-03)
- Repository / project layout (TD-04)
- Riverpod code generation (TD-05)
- Minimum Android version and target devices (TD-06)
- Flutter / Flame version pinning policy (TD-07)
- CI setup (TD-08)
- Rive validation outcome

Recommendations for each are in the [Technical Feasibility & Architecture Review](../architecture/TECHNICAL_FEASIBILITY_REVIEW.md).

## Process

1. Copy the template below into `docs/decisions/ADR-NNNN-short-title.md` (next sequential number).
2. Open a pull request with status **Proposed**.
3. After approval, set status to **Accepted** and add it to the index.
4. To change a decision, write a new ADR that **supersedes** the old one; do not rewrite accepted ADRs.

Statuses: `Proposed` · `Accepted` · `Rejected` · `Superseded by ADR-NNNN`

## Template

```markdown
# ADR-NNNN: Title

- Status: Proposed
- Date: YYYY-MM-DD
- Deciders:

## Context
What problem are we solving? What constraints apply?

## Options Considered
1. Option A — pros / cons
2. Option B — pros / cons

## Decision
What we chose and why.

## Consequences
What becomes easier or harder. Follow-up work.
```
