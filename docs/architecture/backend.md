# Backend Architecture

This document describes the architecture of the SofaWatch backend.

It focuses on responsibility boundaries, dependency direction, request handling, persistence, authentication, provider integration, background processing, and the rules that should guide future backend development.

> [!NOTE]
> SofaWatch is under active development. This document describes the intended current architecture and should evolve alongside meaningful architectural changes.

---

## Overview

The SofaWatch backend is implemented with FastAPI, SQLAlchemy, Pydantic, Alembic, and SQLite.

At a high level:

```text
HTTP Client
    |
    v
FastAPI
    |
    v
Routes / Dependencies
    |
    v
Services
    |
    +--------------------+
    |                    |
    v                    v
Repositories         Providers
    |                    |
    v                    v
SQLAlchemy           External APIs
    |
    v
SQLite
```

The backend is the source of truth for persisted application state and business rules.

External metadata providers supply information to SofaWatch but do not define SofaWatch domain identity or user-owned state.

---

## Core Responsibilities

The backend owns:

- authentication
- authorization
- users and sessions
- Library state
- TV and Movie persistence
- viewing progress
- watch events
- rewatches
- statistics
- metadata import and synchronization
- administrative rules
- background jobs
- server diagnostics
- import/export
- security settings

The frontend may coordinate UI state, but backend-owned rules should not be independently reimplemented in Flutter.

---

## Project Structure

The main backend areas are:

```text
app/
├── api/
│   ├── routes/
│   ├── dependencies.py
│   ├── error_handlers.py
│   └── router.py
│
├── core/
├── db/
├── jobs/
├── models/
├── providers/
├── repositories/
├── schemas/
├── services/
└── main.py
```

Each area should remain focused on a clear responsibility.

---

# 1. API Layer

The API layer lives primarily under:

```text
app/api/
```

It is responsible for HTTP concerns.

These include:

- route definitions
- path/query/body parameters
- authentication dependencies
- authorization dependencies
- response schemas
- status codes
- request validation
- safe error responses

Routes should remain thin.

A typical request should look conceptually like:

```text
Route
  |
  v
Dependency-provided Service
  |
  v
Business operation
  |
  v
Response schema
```

Routes should not become the place where domain workflows, complex SQLAlchemy queries, or provider-specific parsing live.

---

## 1.1 API Versioning

The application API is mounted under:

```text
/api/v1
```

Versioning at the router level provides a stable boundary for future API evolution.

---

## 1.2 Public and Private Routes

The main API router separates authenticated application resources from routes that must remain public.

Conceptually:

```text
/api/v1
   |
   +-- public authentication/bootstrap routes
   |
   +-- private application routes
          |
          +-- authenticated user required
```

Private resources are protected through the current-user dependency.

Public routes are limited to flows that genuinely need to be reachable without an existing authenticated user, such as:

- authentication
- initial setup
- registration availability/registration
- authentication handoff exchange
- password recovery flows where applicable

A route should not be made public merely because the frontend hides it.

---

# 2. Dependency Injection

FastAPI dependencies are used to compose request-scoped application objects.

The dependency module creates objects such as:

- repositories
- services
- provider clients
- authentication services
- token services
- background job infrastructure
- server/admin services

For example:

```text
Database Session
      |
      +--> Repository
      |
      +--> Repository
      |
      v
    Service
      |
      v
     Route
```

This makes dependencies explicit and allows services to be tested without depending directly on FastAPI request handling.

---

## 2.1 Request-Scoped Resources

Objects that depend on a database session should normally be scoped to the request.

External clients that require cleanup should use generator dependencies where appropriate.

For example:

```text
Create TMDB client
       |
       v
Use during request
       |
       v
Close client
```

Resource lifecycle should remain explicit.

---

# 3. Services

Application and business logic belongs primarily in:

```text
app/services/
```

Services coordinate operations that are more than simple persistence.

Examples include:

- media import
- media search
- Explore discovery
- Library workflows
- Watch Next
- stale/inactive Watching logic
- viewing history
- episode progress
- season/episode synchronization
- statistics
- initial setup
- registration
- authentication
- password recovery
- server diagnostics
- import/export

A service may coordinate:

```text
Service
   |
   +--> Repository A
   |
   +--> Repository B
   |
   +--> Provider
   |
   +--> Supporting service
```

This is preferable to placing cross-domain orchestration in routes or repositories.

---

## 3.1 Transaction Ownership

Some workflows require multiple persistence operations to succeed together.

Those workflows should have a clear transaction owner.

In general, if a service coordinates multiple repositories as one business operation, transaction behavior should remain explicit and predictable.

Repositories should not silently commit in ways that make higher-level atomic operations impossible to reason about.

---

## 3.2 Business Rules

Business rules belong in backend services when they govern application truth.

Examples:

- whether a Show belongs in Watch Next
- caught-up behavior
- whether an Episode is considered watched
- how watch counts are derived
- how rewatches affect history
- what registration is allowed
- whether a user can access an Administrator operation

These should not be reproduced separately by different frontend screens.

---

# 4. Repositories

Persistence logic belongs under:

```text
app/repositories/
```

Repositories isolate SQLAlchemy query logic from higher-level application services.

Typical responsibilities include:

- loading entities
- filtering
- existence checks
- user-scoped queries
- persistence
- deletion
- ordering
- pagination
- specialized database queries

A repository should primarily answer persistence questions.

It should not become responsible for presentation logic or external HTTP calls.

---

## 4.1 User Scoping

User-owned resources must remain scoped to the authenticated user.

Examples include:

- Library
- watch history
- progress
- ratings
- authentication sessions

Repository and service APIs should make user ownership explicit where relevant.

This reduces the risk of accidental cross-user access.

---

# 5. SQLAlchemy Models

Persistence models live under:

```text
app/models/
```

Models represent local SofaWatch data.

Examples include concepts such as:

- User
- AuthSession
- Show
- Season
- Episode
- Movie
- Genre
- LibraryEntry
- Episode progress
- Episode watch events
- Movie watch events
- background jobs
- password reset credentials

Models define:

- persistent fields
- relationships
- constraints
- database identity

They should not contain HTTP concerns.

---

# 6. Schemas

Pydantic schemas live under:

```text
app/schemas/
```

They are used for:

- API request payloads
- API responses
- structured application data transfer
- provider-facing data structures where appropriate

Schemas form an explicit boundary between persistence/domain state and external representation.

SQLAlchemy models should not automatically become public API contracts.

---

# 7. Database

SofaWatch uses SQLite as its intended database.

SQLite is not a temporary development database.

Persistence flow:

```text
Service
   |
   v
Repository
   |
   v
SQLAlchemy Session
   |
   v
SQLite
```

Database configuration and session creation live outside route code.

---

## 7.1 Foreign Keys

SQLite foreign-key enforcement is explicitly enabled:

```sql
PRAGMA foreign_keys=ON;
```

This must remain true in development, production, and tests.

---

## 7.2 Migrations

Schema changes are managed through Alembic.

Important commands include:

```bash
alembic upgrade head
alembic current
alembic check
```

Autogenerated migrations should always be reviewed before use.

Migration quality includes preserving existing user data rather than merely making fresh databases work.

Before stable releases, migrations should also be validated against older SofaWatch database snapshots.

See [Database Architecture](database.md) and [Database Migrations](../development/migrations.md).

---

# 8. Internal Media Identity

SofaWatch distinguishes internal identity from provider identity.

Example:

```text
TMDB Show ID
     |
     v
Import
     |
     v
SofaWatch Show ID
```

After import, application relationships should use the internal SofaWatch entity.

External identifiers are metadata/mappings used to communicate with providers.

This rule applies to Shows, Movies, and future provider integrations.

---

# 9. Providers

External API integrations live under:

```text
app/providers/
```

TMDB is currently the primary provider.

Provider code is responsible for:

- HTTP communication
- provider authentication
- provider-specific schemas
- provider-specific errors
- provider response handling

Application services then map provider data into SofaWatch-owned structures.

---

## 9.1 Provider Boundary

The desired direction is:

```text
SofaWatch Services
        |
        v
Provider Abstraction / Client
        |
        v
External Provider
```

Provider response models should not become the internal SofaWatch domain model.

Provider-specific errors should be translated into safe application-level behavior.

---

## 9.2 TMDB

TMDB currently supports areas including:

- Search
- TV metadata
- Movie metadata
- Seasons
- Episodes
- Genres
- Images
- Trending
- Popular/discovery
- metadata synchronization

TMDB-specific logic should remain isolated so future provider integrations do not require rewriting application business rules.

---

## 9.3 Future Providers

TVDB is planned as a complementary provider, particularly for TV content.

IMDb or another legitimate source may later be evaluated for external ratings and identifiers.

Future provider work should introduce mappings/adapters instead of scattering provider-specific IDs throughout services.

---

# 10. Authentication

SofaWatch uses real multi-user authentication.

The legacy fixed/local-user model has been removed.

The backend supports two main authenticated client models:

```text
Web
 |
 +-- persistent HttpOnly Web session

Mobile
 |
 +-- short-lived access token
 +-- rotating refresh credential
```

Both resolve to the same User model.

---

## 10.1 Current User Resolution

Authenticated routes use a current-user dependency.

The dependency supports:

- Bearer access tokens
- persistent Web session cookie

Bearer authentication has precedence when explicitly supplied.

An invalid explicit Bearer token must not silently fall back to a Web session.

Conceptually:

```text
Request
   |
   +-- Bearer present?
   |       |
   |       +-- yes --> validate Bearer --> User / 401
   |
   +-- otherwise Web cookie?
           |
           +-- yes --> resolve Web session --> User / 401
           |
           +-- no --> 401
```

Inactive or missing users must not authenticate successfully.

---

## 10.2 Access Tokens

Access tokens are short-lived.

They are used for API access but are not the persistent authentication mechanism.

Token creation and validation belong behind dedicated security/token services.

---

## 10.3 Web Sessions

Web authentication uses persistent server-side `AuthSession` state.

The browser stores a session credential in an HttpOnly cookie.

The backend stores only the server-side hash/representation required to validate the persistent credential.

The persistent cookie should not be exposed to JavaScript.

---

## 10.4 Mobile Sessions

Mobile clients use:

```text
access token
    +
refresh credential
```

Refresh credentials rotate.

After a successful refresh:

```text
Credential A
    |
    v
Credential B
```

Credential A becomes invalid.

Reuse of an invalidated persistent credential must be rejected.

---

## 10.5 Initial Setup

A fresh installation with no users enters setup mode.

The first successfully created account becomes the initial Administrator.

The backend protects this operation so concurrent setup attempts cannot create multiple first Administrators.

After setup, the bootstrap path is no longer available.

---

## 10.6 Registration

Public registration is governed by the global Open Registration setting.

Default:

```text
false
```

Only an Administrator may change it.

The backend must reject public registration while registration is closed, regardless of what the frontend displays.

---

## 10.7 Password Recovery

Regular users can be recovered using temporary recovery credentials.

Recovery credentials are:

- random
- short-lived
- user-bound
- stored as hashes
- single-use

Successful password recovery revokes existing sessions for the user.

Administrator recovery is also available from the server using the dedicated reset command.

---

## 10.8 Authentication Handoff

Mobile-to-Web authentication uses a separate temporary handoff credential.

A handoff is:

- short-lived
- user-bound
- single-use
- not an access token
- not a refresh credential

The Web client exchanges it for its own Web session.

---

# 11. Authorization

Authentication answers:

```text
Who is the user?
```

Authorization answers:

```text
Is this user allowed to perform this operation?
```

The backend must enforce both.

Administrator-only functionality must use backend authorization dependencies.

Frontend visibility is not a security mechanism.

Examples of Administrator-only areas include:

- server diagnostics
- logs
- background job administration
- security settings
- password recovery administration

---

# 12. Watch Events

SofaWatch models viewing history as individual events.

For Episodes:

```text
EpisodeWatchEvent
```

For Movies:

```text
MovieWatchEvent
```

A rewatch creates a new event.

Example:

```text
First viewing -> Event A
Rewatch       -> Event B
Rewatch       -> Event C
```

Derived state such as:

```text
is_watched
watch_count
watched_at
```

is backend-owned.

Removing an individual event must recalculate derived state correctly.

This design preserves history and allows Statistics to count real viewing activity.

---

# 13. Library

Library state is user-scoped.

Media import and Library membership are separate operations.

Conceptually:

```text
Provider Result
      |
      v
Local Media
      |
      +--> may be added to User Library
```

A local Show or Movie may exist without belonging to a specific user's Library.

This separation prevents provider/import workflows from becoming user-state operations unnecessarily.

---

# 14. Search and Explore

Search and Explore are separate application concerns.

## Search

Search is global and provides:

- normalized provider results
- TV/Movie filtering
- pagination
- Library-aware context
- provider error mapping

## Explore

Explore provides discovery-oriented data such as:

- Trending
- Popular Shows
- Popular Movies
- genres

Explore should not become another Search implementation.

---

# 15. Statistics

Statistics is derived from persisted SofaWatch viewing data.

It should remain a dedicated backend capability rather than being implemented separately for Home and Profile.

Rewatches count because they are real additional viewing events.

---

# 16. Metadata Synchronization

Metadata synchronization updates provider-owned metadata while preserving SofaWatch-owned state.

Conceptually:

```text
Local Entity
    |
    v
Refresh Policy
    |
    v
Provider
    |
    v
Map Metadata
    |
    v
Persist Provider-owned Changes
```

Synchronization should not overwrite:

- Library membership
- progress
- watch events
- user ratings
- user ownership

Scheduled synchronization runs through the background job system.

---

# 17. Background Jobs

Background jobs live under:

```text
app/jobs/
```

The system includes:

- registry
- executor
- scheduler/worker
- persistent job state
- run history
- structured results

At a high level:

```text
Worker
  |
  v
Registry
  |
  v
Executor
  |
  v
Job Handler
  |
  v
Repositories / Services / Providers
```

Background jobs should reuse application services/repositories rather than duplicate business rules.

The current deployment model assumes one worker.

Future multiple-worker support would require stronger atomic claiming/locking.

See [Background Jobs](background-jobs.md).

---

# 18. Server Administration

Administrative backend capabilities include:

- server health
- database diagnostics
- storage diagnostics
- runtime information
- provider status
- logs
- background jobs
- import/export
- security settings

Diagnostics must expose enough information to operate SofaWatch without exposing secrets.

---

# 19. Error Handling

Application errors should be translated into safe API responses.

The FastAPI application has centralized exception handling for:

- application/API errors
- HTTP exceptions
- request validation errors

Routes should not return raw provider exceptions, SQLAlchemy errors, stack traces, or secret values.

A safe response should expose enough information for the frontend to handle the state without leaking internal details.

Operational details belong in logs where appropriate.

---

# 20. Logging

The backend configures logging by runtime component.

Examples include:

- API
- background worker

Logs should be operationally useful while avoiding sensitive values such as:

- passwords
- access tokens
- session credentials
- refresh credentials
- recovery tokens
- provider API secrets

Administrator-facing logs should expose safe messages.

---

# 21. CORS

CORS is configured centrally by the FastAPI application.

Development allows localhost/`127.0.0.1` origins on arbitrary ports.

Production uses explicit configured origins.

Credentials are allowed because Web authentication depends on cookies.

CORS should not be treated as an authorization mechanism.

---

# 22. Application Lifecycle

The FastAPI lifespan records server start time and provides startup/shutdown logging.

Runtime diagnostics may use this application state to calculate process uptime and start time.

Application startup should remain lightweight.

Long-running recurring work belongs in the separate background worker rather than the FastAPI process.

---

# 23. Import / Export

Import/export workflows are backend-owned.

They are designed around versioned data and user-scoped information.

Import must:

- validate structure/version
- avoid unintended duplicates
- preserve integrity
- report conflicts
- handle partial failures safely

Export must avoid leaking data belonging to another user.

---

# 24. Security Boundaries

The backend should maintain explicit security boundaries.

## Secrets

Secrets belong on the server.

Do not expose:

- provider credentials
- authentication secret keys
- persistent credential hashes
- sensitive configuration

## User Isolation

User-owned data must remain scoped to the authenticated user.

## Administrator Isolation

Administrator operations require explicit authorization.

## External Providers

Provider failures or malformed provider data should not become an avenue for exposing backend internals.

---

# 25. Dependency Direction Rules

The general direction should remain:

```text
Routes
  |
  v
Services
  |
  +------> Repositories
  |
  +------> Providers
```

Lower layers should not depend on higher HTTP/presentation layers.

In particular:

- repositories should not import FastAPI routes
- models should not depend on API routes
- providers should not depend on frontend concepts
- business services should not depend on Flutter behavior
- routes should not contain persistence-heavy business logic

Background jobs should be able to reuse backend services outside HTTP requests.

---

# 26. When to Add a Service

Add or expand a service when the operation:

- coordinates multiple repositories
- applies a business rule
- combines provider data with local persistence
- needs transaction orchestration
- is reused outside an HTTP route
- has enough behavior to deserve focused unit tests

Do not introduce a service merely to wrap a single trivial repository call if it adds no meaningful boundary.

---

# 27. When to Add a Repository

Add repository behavior when it represents persistence logic such as:

- reusable queries
- filtering
- ordering
- pagination
- existence checks
- user-scoped retrieval
- persistence operations

Do not put external HTTP calls into repositories.

---

# 28. When to Add Provider Abstractions

Provider-specific abstraction should evolve when more than one provider needs to satisfy the same application responsibility.

Avoid premature generic interfaces that merely rename TMDB methods without solving a real multi-provider problem.

As TVDB is introduced, define abstractions around actual shared responsibilities such as:

- identifiers
- metadata
- matching
- fallback
- synchronization

---

# 29. Testing the Architecture

Backend tests should protect behavior at the appropriate layer.

## Route Tests

Verify:

- HTTP contract
- authentication
- authorization
- response status
- safe errors

## Service Tests

Verify:

- business rules
- orchestration
- edge cases
- provider/repository interaction

## Repository Tests

Verify:

- queries
- persistence
- constraints
- user scoping

## Provider Tests

Verify:

- request construction
- response mapping
- provider errors
- malformed responses

## Background Job Tests

Verify:

- scheduling/execution behavior
- persisted state
- structured results
- partial failures

Tests should not require live provider availability unless intentionally written as external integration tests.

---

# 30. Architectural Anti-Patterns to Avoid

Avoid:

- business logic in routes
- SQLAlchemy queries scattered through services/routes
- provider JSON leaking into application/domain logic
- frontend-specific concepts in backend services
- hidden UI treated as authorization
- persistent credentials stored in plaintext
- user-scoped queries without explicit ownership
- duplicate business rules across HTTP and background jobs
- abstraction layers added only for theoretical future flexibility
- hardcoded provider assumptions where an existing provider boundary already exists

---

# 31. Future Architectural Work

Known future areas include:

- provider-independent external identifier model
- TVDB integration
- metadata precedence/fallback rules
- external ratings
- stronger configuration validation
- legacy database migration validation
- production backup architecture
- optional multi-worker job locking if needed
- final API contract audit
- production/security audit

These should be implemented incrementally and only when the underlying requirement is real.

---

## Related Documentation

- [Architecture Overview](overview.md)
- [Database Architecture](database.md)
- [Background Jobs](background-jobs.md)
- [Development Setup](../development/setup.md)
- [Database Migrations](../development/migrations.md)
- [Testing](../development/testing.md)
- [Implementation Status](../features/implementation-status.md)
- [Backend README](../../backend/README.md)
