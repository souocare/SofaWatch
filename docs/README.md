# SofaWatch Documentation

Welcome to the technical documentation for **SofaWatch**.

SofaWatch is a self-hosted application for tracking TV shows and movies across Web, iOS, and Android. This documentation covers the architecture, implementation, API contracts, development workflows, and important technical decisions behind the project.

> [!NOTE]
> SofaWatch is under active development. Some documentation describes planned or evolving functionality and may change before the first stable release.

## Documentation Structure

### Architecture

[`architecture/`](architecture/) describes how SofaWatch is structured and how its major components interact.

Start with:

- [Architecture Overview](architecture/overview.md)
- [Backend Architecture](architecture/backend.md)
- [Database Architecture](architecture/database.md)
- [Background Jobs](architecture/background-jobs.md)

Additional architecture documentation is planned for frontend architecture, authentication/session architecture, and metadata provider architecture.

### Features

[`features/`](features/) documents individual SofaWatch capabilities.

Current feature documentation includes:

- [Library](features/library.md)
- [Metadata Synchronization](features/metadata-sync.md)
- [Show Search](features/show-search.md)
- [Viewing Progress](features/viewing-progress.md)

The [Implementation Status](features/implementation-status.md) is the master tracker for implemented, pending, planned, deferred, and exploratory functionality.

### API

[`api/`](api/) documents the HTTP API and the contract between the SofaWatch backend and its clients.

- [API Overview](api/overview.md)
- [Frontend API Contract](api/frontend-contract.md)

The backend API is versioned under `/api/v1`. FastAPI also exposes generated OpenAPI documentation through `/docs` and `/redoc` during development.

### Development

[`development/`](development/) contains practical documentation for working on SofaWatch.

- [Development Setup](development/setup.md)
- [Testing](development/testing.md)
- [Database Migrations](development/migrations.md)

Configuration, coding conventions, and debugging documentation can be added as those areas require dedicated guidance.

### Decisions

[`decisions/`](decisions/) records important architectural and product decisions.

- [Architecture Decisions](decisions/README.md)

This area is intended for decisions whose reasoning should remain available over time, such as SQLite as the primary database, backend source-of-truth ownership, internal media IDs, global Search, authentication/session design, and provider independence.

---

## Where Should I Start?

For a technical overview:

```text
README.md
    |
    v
docs/README.md
    |
    v
architecture/overview.md
    |
    +--> architecture/backend.md
    +--> architecture/database.md
    +--> architecture/background-jobs.md
    |
    v
features/
```

For development work:

1. [Development Setup](development/setup.md)
2. [Architecture Overview](architecture/overview.md)
3. [Testing](development/testing.md)
4. The relevant feature document
5. The relevant backend or frontend README

For the detailed current product state, use [Implementation Status](features/implementation-status.md).

---

## Documentation Responsibilities

| Documentation | Purpose |
| --- | --- |
| Root `README.md` | Project overview, major features, quick start, and public-facing introduction |
| `backend/README.md` | Backend-specific architecture, setup, configuration, API, database, providers, jobs, authentication, and testing |
| `frontend/README.md` | Flutter architecture, navigation, state management, responsive strategy, configuration, and testing |
| `docs/architecture/` | How the system is structured and why |
| `docs/features/` | How individual product capabilities behave |
| `docs/features/implementation-status.md` | Detailed implementation and roadmap tracker |
| `docs/api/` | HTTP contracts and API conventions |
| `docs/development/` | How to develop, test, migrate, configure, and debug SofaWatch |
| `docs/decisions/` | Why important architectural/product decisions were made |

Documentation should link to another document instead of duplicating large sections whenever possible.

---

## Core Architecture Principles

### Backend as the Source of Truth

Persisted state and application business rules belong to the backend. The frontend coordinates presentation and interaction state but should not independently redefine server-owned business rules.

### Internal Domain Identity

Imported media receives internal SofaWatch identifiers. TMDB IDs, future TVDB IDs, and possible IMDb IDs are provider identifiers rather than primary SofaWatch domain identity.

### Provider Independence

External metadata providers should remain behind provider/data boundaries.

```text
SofaWatch Domain
       ^
       |
Provider Mapping / Abstraction
       |
       +-- TMDB
       +-- TVDB
       +-- IMDb or another approved source
```

### Feature First Frontend

Flutter code is organized primarily by feature:

```text
feature/
├── presentation/
├── application/
├── domain/
└── data/
```

Web and mobile should share domain and application logic wherever possible while adapting presentation to platform and screen size.

### Incremental Development

The normal workflow is:

1. Inspect the current implementation.
2. Identify the correct architectural owner.
3. Implement a focused change.
4. Run focused tests.
5. Run static analysis/linting where applicable.
6. Run the relevant full test suite.
7. Fix regressions before continuing.

---

## Main Components

```text
                   ┌──────────────────────┐
                   │   Flutter Clients    │
                   │ Web / iOS / Android  │
                   └──────────┬───────────┘
                              │
                         HTTP / REST
                              │
                   ┌──────────▼───────────┐
                   │   FastAPI Backend    │
                   └──────────┬───────────┘
                              │
             ┌────────────────┼─────────────────┐
             │                │                 │
      ┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐
      │   SQLite    │  │  Metadata   │  │ Background  │
      │  Database   │  │  Providers  │  │    Jobs     │
      └─────────────┘  └──────┬──────┘  └─────────────┘
                              │
                       ┌──────▼──────┐
                       │    TMDB     │
                       │  currently  │
                       └─────────────┘
```

TVDB is planned as a future complementary metadata provider. IMDb or another legitimate source may later be evaluated for external identifiers and ratings.

---

## Current Technology Stack

### Backend

- Python
- FastAPI
- SQLAlchemy
- Pydantic
- Alembic
- SQLite
- pytest
- Ruff

### Frontend

- Flutter
- Dart
- flutter_bloc
- go_router
- Dio

### Metadata

Current:

- TMDB

Planned or under evaluation:

- TVDB
- IMDb or another appropriate external-ratings source

---

## Implementation Status

SofaWatch already includes substantial functionality across TV tracking, movies, viewing history, rewatches, Search, discovery, statistics, authentication, administration, background jobs, and import/export.

The detailed state belongs in [Implementation Status](features/implementation-status.md), which should be treated as the master implementation tracker rather than duplicating the complete roadmap here.

---

## Testing

Backend:

```bash
pytest -q
```

Frontend:

```bash
flutter test
```

See [Testing](development/testing.md) for the development testing workflow.

---

## Contributing to the Documentation

Documentation should evolve alongside the implementation.

When changing behavior:

1. Update the relevant feature documentation if user-visible or business behavior changed.
2. Update architecture documentation if system boundaries or dependency direction changed.
3. Update API documentation if an HTTP contract changed.
4. Record a decision when important architectural reasoning should be preserved.
5. Update the implementation tracker when an item's status changes.

Avoid creating documentation solely to mirror source-code structure. A document should answer a useful question about the system.

---

## Documentation Conventions

### Implementation Status

Use:

```text
[x] Implemented
[ ] Pending
[~] In progress / partially implemented
[>] Planned
[-] Deferred
[?] Exploratory / requires a decision
[!] Needs review or final validation
```

Add notes when they provide useful context about business rules, architectural decisions, edge cases, limitations, reasons for deferral, future dependencies, or non-obvious behavior. Avoid notes that merely repeat the checklist item.

### Terminology

Prefer consistent SofaWatch terminology:

- **Show**
- **Season**
- **Episode**
- **Movie**
- **Library**
- **Watch List**
- **Watch Next**
- **Watch History**
- **Rewatch**
- **Upcoming**
- **Search**
- **Explore**
- **Administrator**
- **AuthSession**
- **Background Job**
- **Metadata Provider**

Provider-specific terminology should not unnecessarily leak into domain-level documentation.

---

## Related Documentation

- [Project README](../README.md)
- [Backend README](../backend/README.md)
- [Frontend README](../frontend/README.md)
- [Architecture Overview](architecture/overview.md)
- [Implementation Status](features/implementation-status.md)
