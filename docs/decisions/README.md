# Architecture Decision Records

This directory contains the Architecture Decision Records (ADRs) for SofaWatch.

ADRs document important technical and product-architecture decisions that shape the project over time. They explain not only **what** SofaWatch does, but **why** a particular approach was chosen, which alternatives were considered, and under which circumstances the decision should be revisited.

Feature documentation remains intentionally more complete and may repeat parts of these decisions. A feature document should explain the feature as a whole — its behavior, architecture, flows, constraints, edge cases, and implementation status — while linking to the relevant ADRs for the reasoning behind important architectural choices.

---

## Purpose

SofaWatch is an evolving self-hosted application with a growing backend, Flutter clients, authentication model, metadata integrations, background jobs, and user-scoped data.

Some decisions have consequences across many features.

Examples include:

- using SQLite as the intended self-hosted database;
- keeping the backend as the source of truth;
- using internal SofaWatch IDs after media import;
- maintaining one global Search experience;
- using different persistent authentication mechanisms for Web and native clients;
- keeping the domain independent from individual metadata providers.

Without an ADR, the reasoning behind these choices can eventually disappear into implementation details, old conversations, or commit history.

The ADRs in this directory provide a durable record of that reasoning.

---

## What Belongs in an ADR

An ADR should be created when a decision:

- has a meaningful architectural impact;
- affects multiple features or layers;
- establishes a long-term project constraint;
- involves important trade-offs;
- rejects an otherwise plausible alternative;
- would be costly or confusing to reverse without understanding the original reasoning.

An ADR is generally **not** necessary for:

- small implementation details;
- normal refactoring;
- UI spacing or styling changes;
- temporary development choices;
- straightforward bug fixes;
- decisions already fully local to one feature with no wider architectural consequence.

Those details belong in code, tests, feature documentation, or development documentation.

---

## ADRs and Feature Documentation

ADRs do not replace feature documentation.

For example:

```text
docs/features/show-search.md
```

should explain Search in detail:

- user behavior;
- supported media types;
- backend flow;
- Flutter architecture;
- filters;
- pagination;
- caching;
- loading/error states;
- preview behavior;
- state preservation;
- implementation status;
- future improvements.

The relevant ADR:

```text
docs/decisions/004-global-search.md
```

should instead answer questions such as:

```text
Why does SofaWatch have one global Search?

Why is Explore not a second Search implementation?

Why should Search behavior be shared across Web and mobile?

What alternatives were rejected?
```

Some repetition between both documents is expected and intentional.

Feature documentation optimizes for understanding the **feature**.

ADRs optimize for understanding the **decision**.

Feature documents should link to relevant ADRs, and ADRs may link back to the features and architecture documents they influence.

---

## ADR Format

SofaWatch uses a lightweight ADR format.

A typical record looks like:

```markdown
# ADR-001: Decision Title

- Status: Accepted
- Date: YYYY-MM-DD

## Context

What problem or architectural question required a decision?

## Decision

What did SofaWatch decide?

## Rationale

Why was this approach selected?

## Consequences

What follows from this decision?

### Positive

What does the decision improve or enable?

### Trade-offs

What limitations, complexity, or costs does it introduce?

## Alternatives Considered

What realistic alternatives were considered, and why were they not selected?

## Revisit When

What future conditions would justify reconsidering this decision?

## Related Documentation

Links to relevant architecture, API, feature, and development documentation.
```

Not every ADR needs exactly the same amount of detail.

The objective is to preserve useful reasoning, not to fill a template mechanically.

---

## Status

An ADR may use one of the following statuses.

### Proposed

The decision is being considered but has not yet been adopted.

```text
Status: Proposed
```

Code should not generally treat a Proposed ADR as an established architectural constraint.

### Accepted

The decision is currently adopted by SofaWatch.

```text
Status: Accepted
```

New implementation should respect it unless there is a deliberate reason to reconsider the decision.

### Superseded

A newer ADR has replaced the decision.

```text
Status: Superseded by ADR-XXX
```

The original ADR should remain in the repository because it still explains historical context.

Do not delete it simply because the architecture changed.

### Deprecated

The decision is no longer recommended or applicable, but there may not be one direct replacement.

```text
Status: Deprecated
```

Again, the record remains available for historical context.

---

## Changing an Accepted Decision

Accepted does not mean permanent.

Architecture should be able to evolve when requirements or evidence change.

However, significant accepted decisions should not be silently reversed in implementation.

If an accepted ADR needs to change substantially:

1. identify what changed;
2. understand the original rationale;
3. evaluate the new trade-offs;
4. create a new ADR when the architectural decision is materially different;
5. mark the previous ADR as superseded when appropriate;
6. update affected architecture and feature documentation;
7. implement the change deliberately.

This keeps architectural history understandable.

---

## Numbering

ADRs use sequential numeric identifiers:

```text
001
002
003
...
```

The identifier is permanent.

File names use:

```text
NNN-short-decision-name.md
```

Example:

```text
005-authentication-model.md
```

If an ADR is superseded, its number is never reused.

---

## Dates

The ADR date represents when the decision record was accepted or formally recorded.

Some initial ADRs document decisions that were already established before the ADR system itself was introduced.

In those cases, the ADR may use the date the decision was formally recorded and explain historical context where useful.

The date should not be interpreted as proof that the architecture only began using the decision on that day.

---

## Decision Scope

ADRs can capture both purely technical decisions and product decisions with significant architectural consequences.

For SofaWatch, examples include:

```text
Technical
---------
SQLite as the database
Authentication credential model
Provider abstraction

Product + Architecture
----------------------
One global Search
Backend-owned business rules
Internal media identity
```

The important criterion is architectural impact, not whether the original question came from product or engineering.

---

## Current Decisions

| ADR | Decision | Status |
| --- | --- | --- |
| [ADR-001](001-sqlite.md) | SQLite as the primary SofaWatch database | Accepted |
| [ADR-002](002-backend-source-of-truth.md) | Backend as the source of truth | Accepted |
| [ADR-003](003-internal-media-ids.md) | Internal SofaWatch media identifiers | Accepted |
| [ADR-004](004-global-search.md) | One global Search experience | Accepted |
| [ADR-005](005-authentication-model.md) | Web and native authentication model | Accepted |
| [ADR-006](006-provider-independence.md) | Provider-independent domain architecture | Accepted |

These records document decisions that are already part of the current SofaWatch architecture.

---

## Planned Initial ADR Set

### ADR-001 — SQLite

Documents why SQLite is an intentional database choice for SofaWatch's self-hosted deployment model rather than a temporary development database.

Topics include:

- self-hosting;
- operational simplicity;
- Alembic migrations;
- SQLite foreign keys;
- concurrency expectations;
- backup implications;
- when another database would actually be justified.

---

### ADR-002 — Backend as Source of Truth

Documents why persisted state and business rules are authoritative on the backend.

Topics include:

- Flutter as a client of application rules;
- progress calculation;
- viewing history;
- Library state;
- authorization;
- Statistics;
- avoiding duplicated business logic across Web/iOS/Android.

---

### ADR-003 — Internal Media IDs

Documents why imported Shows, Seasons, Episodes, Movies, and related entities use SofaWatch-owned identifiers.

External identifiers such as:

```text
TMDB
TVDB
IMDb
```

remain provider identifiers/mappings rather than becoming the primary identity of the SofaWatch domain.

---

### ADR-004 — Global Search

Documents why SofaWatch has one global Search experience shared conceptually across platforms.

It also records why:

```text
Search
```

and:

```text
Explore
```

are separate concepts.

Explore is discovery.

It should not become a second independent Search implementation.

---

### ADR-005 — Authentication Model

Documents the persistent authentication strategy.

Web:

```text
HttpOnly session cookie
+
server-side AuthSession
```

Native:

```text
short-lived access token
+
rotating refresh credential
+
server-side AuthSession
```

It also records the rationale for session revocation, credential hashing, refresh rotation, and unified current-user resolution.

---

### ADR-006 — Provider Independence

Documents why SofaWatch's domain should not be coupled to TMDB even though TMDB is currently the primary metadata provider.

The architecture is intended to support:

```text
TMDB
TVDB
IMDb / legitimate ratings source
other future providers
```

through explicit provider boundaries, mappings, and precedence rules.

---

## Future ADRs

New ADRs should be added when a future decision has sufficient architectural significance.

Potential examples may include:

```text
backup and restore architecture
image/cache storage strategy
notification architecture
production deployment model
external ratings model
metadata precedence strategy
localization architecture
background-job execution guarantees
```

These are examples only.

Do not create ADRs preemptively before the corresponding architectural decision has actually been made.

---

## Avoiding ADR Noise

The value of this directory depends on keeping the records meaningful.

Avoid creating records such as:

```text
ADR: Use StatelessWidget here
ADR: Rename this DTO
ADR: Add Retry button
ADR: Use a modal on desktop
```

unless a seemingly small choice genuinely establishes a broader architectural rule.

Most implementation decisions should remain closer to the code or feature documentation.

---

## Relationship to Code

An ADR describes an architectural decision.

Tests and code enforce it.

For example:

```text
ADR
-> invalid explicit Bearer must not fall back to Web cookie

Tests
-> verify Bearer precedence

Code
-> CurrentUserDependency implements the rule
```

When documentation and implementation disagree, investigate the discrepancy rather than automatically assuming either side is correct.

The intended outcome is:

```text
Decision
    |
    v
Architecture
    |
    v
Implementation
    |
    v
Tests
```

with all four remaining coherent.

---

## Relationship to the Roadmap

ADRs should distinguish:

```text
accepted architecture
```

from:

```text
future possibility
```

For example, TVDB support is planned, but provider independence is already an accepted architectural decision.

Similarly, IMDb or another external ratings source is under evaluation; the provider-independent design should support that possibility without pretending the integration already exists.

---

## Related Documentation

- [Documentation Index](../README.md)
- [Architecture Overview](../architecture/overview.md)
- [Backend Architecture](../architecture/backend.md)
- [Frontend Architecture](../architecture/frontend.md)
- [Data Flow](../architecture/data-flow.md)
- [API Overview](../api/overview.md)
- [Frontend API Contract](../api/frontend-contract.md)
- [Implementation Status](../features/implementation-status.md)
