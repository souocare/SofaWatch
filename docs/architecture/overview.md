# SofaWatch Architecture Overview

This document provides a high-level technical overview of SofaWatch.

It explains how the main components fit together, where responsibilities live, how data moves through the system, and which architectural boundaries should be preserved as the project evolves.

> [!NOTE]
> SofaWatch is under active development. Some components described here are planned extensions of the current architecture, but the core dependency direction and ownership rules are already established.

---

## System Overview

SofaWatch is a self-hosted application composed of:

- Flutter clients for Web, iOS, and Android
- a FastAPI backend
- a SQLite database
- background job infrastructure
- external metadata providers

At a high level:

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

The backend owns persisted application state and business rules.

The frontend owns presentation, interaction state, navigation, and responsive behavior.

External providers supply metadata and discovery information but do not define SofaWatch domain identity.

---

## Core Architectural Principles

### Backend as the Source of Truth

The backend is authoritative for:

- user data
- Library state
- media tracking status
- watched/unwatched state
- watch counts
- watch history
- rewatches
- ratings
- authentication/session state
- administrative rules
- business rules

The frontend may optimistically update presentation state when appropriate, but server-owned rules should not be independently reimplemented in Flutter.

### Internal SofaWatch Identity

Imported media receives internal SofaWatch identifiers.

External IDs such as:

```text
TMDB
TVDB
IMDb
```

are external/provider identifiers.

Conceptually:

```text
External Provider Result
          |
          v
      Import/Mapping
          |
          v
Local SofaWatch Entity
          |
          v
User-specific state
```

This keeps user data and business rules independent from any single metadata provider.

### Provider Independence

The application domain should not become provider-specific.

Desired direction:

```text
SofaWatch Domain
       ^
       |
Provider Mapping / Adapter
       |
       +-- TMDB
       +-- TVDB
       +-- IMDb / external source
```

TMDB is currently the primary provider.

TVDB is planned as a complementary provider.

IMDb or another legitimate source may later be used for external identifiers and ratings.

### Feature Boundaries

Frontend code is organized primarily by feature.

Backend code is organized by responsibility and domain/application layer.

Features should reuse shared domain/application behavior instead of duplicating it across Home, Shows, Movies, Explore, Search, and Profile.

---

## Frontend Architecture

The Flutter frontend follows a Feature First structure with a lightweight Clean Architecture approach.

```text
Presentation
     |
     v
Application
     |
     v
Domain
     ^
     |
Data
```

Typical feature structure:

```text
feature/
├── presentation/
├── application/
├── domain/
└── data/
```

### Presentation

Responsible for:

- pages
- widgets
- dialogs
- sheets
- responsive layouts
- navigation interaction
- user-facing loading/error/empty states

Presentation should not contain backend business rules or raw API parsing.

### Application

Responsible for:

- Cubits
- BLoCs
- application state
- orchestration
- retries
- refresh flows
- UI-facing workflows

### Domain

Responsible for:

- entities
- repository contracts
- domain-facing abstractions

The domain layer should not depend on:

- Flutter widgets
- Dio
- raw JSON

### Data

Responsible for:

- DTOs
- API repository implementations
- mapping
- local storage adapters
- transport-specific behavior

---

## Frontend Navigation

SofaWatch uses `go_router`.

Primary application areas are:

```text
Home
Shows
Movies
Explore
Profile
```

These are hosted through a stateful shell so branch state can be preserved where appropriate.

Global destinations such as Search and media details are placed outside a single branch when needed.

Web and mobile share the same product structure while presenting navigation differently.

### Web

Web/Desktop uses a top navigation experience.

Search is presented as a global modal-style experience where appropriate.

### Mobile

Mobile uses a dedicated shell and integrates Search into the Dual-Pill experience.

Search is still one global feature and is not duplicated inside Explore.

---

## Frontend State Management

SofaWatch uses `flutter_bloc`.

Use:

- `Cubit` for direct state/action workflows
- `Bloc` where event-driven coordination is useful

Typical Cubit flow:

```text
Initial
   |
   v
Loading
   |
   +----> Success
   |
   +----> Failure
```

Some features preserve previous data during refresh.

Large screens such as Profile should maintain independent failure boundaries so one section can fail without breaking unrelated content.

### Cross-Feature Invalidation

Feature state remains independently scoped even when multiple features derive
data from the same persisted backend state.

When a successful mutation can affect other loaded features, SofaWatch may use
a lightweight cross-cutting invalidation signal rather than introducing
Cubit-to-Cubit dependencies.

Viewing state currently follows this model through
`ViewingStateChangeNotifier`.

    Viewing Mutation
          |
          v
    Backend Success
          |
          v
    Viewing-State Invalidation
       /       |       \
      v        v        v
    Home    History   Other consumers

The signal carries no duplicated domain state. Each consumer remains
responsible for refreshing the server-owned collections it displays.

Mutation failure produces no invalidation.

If persistence succeeds but a subsequent local read-back fails, invalidation
has already occurred because the backend remains authoritative.

---

## Design System

The frontend uses centralized design tokens:

```text
AppColors
AppTypography
AppSpacing
AppRadius
AppDurations
AppBreakpoints
```

These should be preferred over arbitrary styling values.

The application currently uses a dark theme.

Responsive decisions should reuse shared breakpoints when the decision is application-wide.

---

## Responsive Architecture

SofaWatch does not simply scale one mobile UI to larger screens.

The intended model is:

```text
Shared Domain / Application Logic
             |
             v
Responsive Presentation
       /               \
      v                 v
 Mobile UI         Web/Desktop UI
```

Platform-specific presentation is appropriate when interaction models differ.

Examples:

- top navigation vs mobile shell
- desktop modal vs mobile sheet/page
- Web authentication persistence vs native refresh credentials
- narrow/landscape behavior
- safe-area handling

Do not fork complete features when only presentation differs.

---

## Backend Architecture

The backend follows a layered architecture.

```text
HTTP Request
     |
     v
API Routes / Dependencies
     |
     v
Services
     |
     v
Repositories
     |
     v
SQLAlchemy Models
     |
     v
SQLite
```

### API Layer

Responsible for:

- route definitions
- request parsing
- response schemas
- authentication dependencies
- authorization
- HTTP status codes
- safe error responses

### Services

Responsible for:

- business rules
- application workflows
- orchestration
- cross-repository operations
- provider coordination

### Repositories

Responsible for:

- persistence
- database queries
- user-scoped access
- query composition

### Models

Responsible for:

- SQLAlchemy persistence models
- relationships
- constraints

### Providers

Responsible for:

- external API communication
- provider schemas
- provider-specific error handling
- provider mapping

---

## Database Architecture

SofaWatch uses SQLite as its intended production database.

SQLite is not a temporary development-only choice.

Database access uses SQLAlchemy.

Schema changes are managed through Alembic.

Foreign-key enforcement is explicitly enabled:

```sql
PRAGMA foreign_keys=ON;
```

User-owned state remains scoped to the authenticated user.

Examples include:

- Library
- viewing progress
- watch history
- ratings
- sessions

---

## Media Model

SofaWatch tracks both Shows and Movies.

### Shows

The local model supports:

```text
Show
  |
  +-- Seasons
         |
         +-- Episodes
```

Show tracking includes:

- Library state
- progress
- Watch Next
- Upcoming
- watch events
- rewatches
- metadata synchronization

### Movies

Movies are independent local entities with:

- Library/watchlist state
- watched state
- watch events
- rewatches
- history
- statistics integration

Importing media and adding it to a user's Library are separate operations.

---

## Library Architecture

Library state is user-specific.

Conceptually:

```text
Local Media Entity
        |
        v
User Library Entry
```

A Library entry may reference a Show or a Movie according to application constraints.

Provider search/import results do not automatically become Library entries.

---

## Watch Events and Rewatches

SofaWatch models each viewing as an individual event.

For Episodes:

```text
EpisodeWatchEvent
```

For Movies:

```text
MovieWatchEvent
```

A rewatch creates a new event rather than replacing old history.

Example:

```text
First watch  -> Event A
Rewatch      -> Event B
Rewatch      -> Event C
```

Derived state can then represent:

```text
watch_count = 3
watched_at = newest event timestamp
```

Removing a viewing event must recalculate derived watch state correctly.

This model allows Statistics and History to treat rewatches as real viewing activity.

---

## Search Architecture

Search is global.

It is separate from Explore.

Search backend responsibilities include:

- provider lookup
- normalization
- media-type filtering
- pagination
- safe provider errors

Search frontend responsibilities include:

- query state
- debounce
- stale-response protection
- pagination state
- filters
- retry
- loading/error/empty states
- responsive presentation

Search uses a bounded in-memory TTL/LRU cache in the data layer.

The cache is intentionally not persistent.

---

## Explore Architecture

Explore is discovery-oriented.

It may use provider data such as:

- trending
- popular content
- genres

Explore should not introduce a separate Search implementation.

Advanced editorial or personalized sections should only be added when a real discovery strategy exists.

---

## Statistics Architecture

Statistics is a standalone feature.

It should not be implemented separately inside Home or Profile.

Statistics is derived from persisted viewing data.

Because rewatches are separate viewing events, they count toward viewing totals.

The feature can be reused by multiple presentation areas.

---

## Authentication Architecture

SofaWatch supports real multi-user authentication.

The legacy fixed/local-user model has been removed.

Authentication is platform-aware while resolving to the same backend User model.

### Web

Web uses a persistent HttpOnly session cookie.

```text
Browser
   |
   +-- HttpOnly Web session credential
```

### Mobile

Mobile uses:

```text
Short-lived access token
        +
Rotating refresh credential
```

Persistent credentials are stored server-side as hashes.

### Unified User Resolution

Protected requests resolve through backend authentication dependencies.

Bearer and Web session authentication both resolve to the same User.

If a Bearer credential is explicitly present but invalid, the backend must not silently fall back to another authentication method.

### Authorization

Frontend visibility is not a security boundary.

Administrative API endpoints must independently enforce Administrator authorization.

---

## Initial Setup Architecture

A fresh SofaWatch installation with no users enters setup mode.

```text
No Users
   |
   v
Setup Required
   |
   v
Create First Account
   |
   v
First User becomes Administrator
```

After setup:

- setup is disabled
- normal authentication is used
- public registration remains closed by default

The backend protects against concurrent creation of multiple initial Administrators.

---

## Registration Architecture

Public registration is controlled by a global security setting:

```text
Open Registration
```

Default:

```text
false
```

The backend enforces the setting.

The frontend only reflects the allowed state.

---

## Password Recovery Architecture

Regular-user recovery uses temporary, hashed, single-use recovery credentials.

Administrator recovery is also available through a server-side command.

Successful password recovery revokes existing sessions for the affected user.

---

## Mobile-to-Web Authentication Handoff

The mobile application can create a temporary handoff credential.

```text
Mobile App
    |
    v
Temporary Handoff
    |
    v
Browser
    |
    v
Web Session
```

Handoff credentials are:

- short-lived
- user-bound
- single-use
- separate from access/refresh credentials

---

## Background Jobs Architecture

Background work is handled separately from normal request/response execution.

```text
FastAPI API             Background Worker
    |                         |
    |                         v
    |                  Background Jobs
    |                         |
    +-------------> Shared Database
```

The current deployment model is designed around a self-hosted single-worker scenario.

Background job infrastructure provides:

- job registry
- scheduling
- persistent job state
- execution history
- structured results
- failure information
- manual execution

Metadata synchronization is the primary recurring job currently.

Future multi-worker support would require stronger atomic claim/locking behavior.

---

## Metadata Synchronization

Metadata synchronization updates provider-owned metadata while preserving SofaWatch-owned user state.

Conceptually:

```text
Local Media
    |
    v
Refresh Policy
    |
    v
Provider Request
    |
    v
Map External Metadata
    |
    v
Update Local Metadata
```

Synchronization should not destroy:

- Library state
- watch history
- progress
- ratings
- user ownership

Automatic refresh follows configured freshness rules.

---

## Server Administration

Administrator-only functionality includes:

- server health
- database diagnostics
- storage diagnostics
- runtime diagnostics
- provider health
- background jobs
- logs
- import/export
- security settings

Diagnostics must not expose secrets.

Backend authorization remains mandatory regardless of frontend visibility.

---

## Import / Export Architecture

Import/export is designed around portable, versioned user data.

Potential exported/imported data includes:

- Library
- viewing history
- ratings
- relevant user/application data

Import should validate version and structure before applying changes.

Partial failures should be surfaced without silently corrupting user data.

---

## Provider Evolution

Current:

```text
TMDB
```

Planned:

```text
TVDB
```

Under evaluation:

```text
IMDb / external ratings source
```

The long-term provider architecture should explicitly define:

- external identifier mappings
- primary metadata source
- fallback metadata source
- title precedence
- image precedence
- date precedence
- episode numbering precedence
- external ratings
- provider failure behavior

A secondary provider failure should not make already-imported media unusable.

---

## Error Boundaries

Errors should be contained at the smallest reasonable boundary.

Examples:

- a failed Profile subsection should not break all Profile content
- a failed Season load should not break all Seasons
- a failed provider request should not leak provider internals to the frontend
- a failed secondary provider should not necessarily break local media

The frontend should display safe user-facing error states.

The backend should log enough operational context for diagnosis without exposing sensitive data.

---

## Configuration Boundaries

Backend configuration is environment-driven.

Frontend server configuration is runtime/persisted and can also be supplied through `--dart-define`.

Secrets belong on the backend.

The frontend should not embed provider secrets.

---

## Testing Strategy

The architecture is protected through automated tests.

### Backend

Tests cover areas such as:

- routes
- services
- repositories
- authentication
- authorization
- providers
- background jobs
- statistics
- viewing/history behavior

### Frontend

Tests cover:

- Cubits/BLoCs
- repositories
- DTO mapping
- widgets
- navigation
- loading/error/empty states
- responsive behavior

Focused tests should be run during implementation, followed by the relevant full suite.

---

## Dependency Direction

The intended dependency direction should remain simple.

### Backend

```text
Routes
  |
  v
Services
  |
  v
Repositories
  |
  v
Persistence
```

Routes should not become the home of business logic.

Repositories should not know presentation concerns.

External providers should not define the internal domain model.

### Frontend

```text
Presentation
     |
     v
Application
     |
     v
Domain
     ^
     |
Data
```

Presentation should not parse JSON.

Domain should not depend on Dio.

Data implementations should satisfy domain contracts.

---

## Future Architectural Work

Planned or exploratory areas include:

- richer provider abstraction
- TVDB integration
- external ratings
- localization
- backups
- production deployment guidance
- stronger multi-worker job locking if needed
- full Administrator user-management UI
- broader coordinated invalidation for additional cross-feature state where
  real product needs emerge
- final performance and accessibility audits

These should be introduced only when they solve real product or operational needs.

---

## Related Documentation

- [Project Documentation](../README.md)
- [Backend Architecture](backend.md)
- [Database Architecture](database.md)
- [Background Jobs](background-jobs.md)
- [Implementation Status](../features/implementation-status.md)
- [Backend README](../../backend/README.md)
- [Frontend README](../../frontend/README.md)
