# Database Architecture

This document describes the database architecture used by SofaWatch.

SofaWatch uses SQLite as its intended self-hosted production database, with SQLAlchemy providing the persistence layer and Alembic managing schema evolution.

> [!IMPORTANT]
> SQLite is an intentional architectural choice for SofaWatch. PostgreSQL is not part of the current roadmap.

---

## 1. Goals

The database architecture is designed to provide:

- simple self-hosted deployment
- strong relational integrity
- internal SofaWatch identity independent from metadata providers
- multi-user data isolation
- complete viewing history and rewatch support
- safe schema evolution through Alembic
- persistence for background jobs and administrative state
- upgrade compatibility without losing user data

---

## 2. High-Level Model

At a high level:

```text
Application Services
        |
        v
Repositories
        |
        v
SQLAlchemy Session
        |
        v
SQLite Database
```

Business rules should normally live above the repository layer.

SQLAlchemy models represent persistence structures, not public API contracts.

---

## 3. SQLite

SofaWatch uses SQLite for both development and the intended self-hosted deployment model.

The default database is stored under the SofaWatch data directory.

A typical development URL is:

```text
sqlite:///./data/sofawatch.db
```

SQLite keeps deployment simple because a standard SofaWatch installation does not require a separate database server.

---

## 4. SQLAlchemy Session

Database access is performed through SQLAlchemy sessions.

The current session factory is configured with:

```text
autoflush = false
autocommit = false
expire_on_commit = false
```

Conceptually:

```text
FastAPI Request / Job
        |
        v
Database Session
        |
        v
Repository Operations
        |
        v
Commit / Rollback
```

Transaction ownership should remain explicit when an application service coordinates multiple persistence operations.

---

## 5. Foreign-Key Enforcement

SQLite foreign keys are explicitly enabled:

```sql
PRAGMA foreign_keys=ON;
```

This is required because SQLite does not enforce foreign-key constraints by default.

The same behavior should remain enabled in:

- development
- production
- tests

Relational integrity should not depend solely on SQLAlchemy relationships.

---

## 6. Internal Identity

SofaWatch entities use internal database IDs.

External metadata-provider identifiers remain separate.

Example:

```text
TMDB Show ID 1396
       |
       v
Import / Mapping
       |
       v
SofaWatch Show ID 42
```

After import, internal relationships refer to:

```text
Show.id = 42
```

rather than the TMDB ID.

This makes it possible to associate the same local media with multiple providers in the future.

---

## 7. Main Entity Groups

The data model can be understood in several groups.

```text
Identity / Security
Media Metadata
User Tracking
Viewing History
Administration
Background Jobs
```

---

# 8. Users

`User` represents a real SofaWatch account.

SofaWatch is a multi-user application.

The old fixed/local-user model has been removed.

A user contains account/security information such as:

- username
- email
- display name
- password hash
- active state
- Administrator state

User-owned data remains associated with the internal user ID.

---

## 8.1 User-Owned Relationships

Examples of user-scoped data include:

```text
User
 |
 +-- Library Entries
 +-- Episode Progress
 +-- Episode Watch Events
 +-- Movie Watch Events
 +-- Ratings
 +-- Auth Sessions
```

Queries returning user-owned resources must remain explicitly scoped to the authenticated user.

---

# 9. Authentication Sessions

Persistent authenticated sessions are represented by `AuthSession`.

Sessions may represent:

```text
WEB
MOBILE
```

Persistent credentials are stored server-side as hashes rather than plaintext secrets.

Session data supports lifecycle concepts such as:

- creation
- expiration
- revocation
- last use
- client/session type

This enables session-level logout and global session revocation.

---

# 10. Password Recovery Data

Temporary password-recovery credentials are also modeled as server-side state.

Recovery secrets are:

- temporary
- user-bound
- hashed
- expiring
- single-use

They must not be stored in plaintext.

Successful recovery invalidates the credential and revokes existing sessions for the user.

---

# 11. Shows

`Show` represents a locally imported television series.

A Show stores normalized local metadata and external-provider mappings/data required by SofaWatch.

Conceptually:

```text
Show
 |
 +-- Seasons
 |     |
 |     +-- Episodes
 |
 +-- Genres
 +-- Networks / related metadata
 +-- External provider identity
```

The Show's local ID remains stable independently from provider IDs.

---

# 12. Seasons

`Season` belongs to a Show.

A Show may contain multiple Seasons.

Season zero may represent specials when supplied by the metadata provider.

Episodes are synchronized lazily by Season where appropriate rather than requiring every Episode of every Season to be fetched during the initial Show import.

---

# 13. Episodes

`Episode` belongs to a Season.

Episodes store provider-derived metadata needed by SofaWatch, including values such as:

- episode number
- title
- overview
- air date
- runtime where available
- image/provider metadata

Air time must not be invented when the provider does not supply reliable information.

---

# 14. Movies

`Movie` is a first-class local SofaWatch entity.

Movie persistence is independent from Library membership.

Conceptually:

```text
TMDB Movie
    |
    v
Import
    |
    v
Local Movie
    |
    +--> optional User Library Entry
```

Movies can participate in:

- Library/watchlist
- viewing history
- rewatches
- statistics
- personal ratings

---

# 15. Genres

`Genre` is an internal SofaWatch entity.

A Genre should not be treated as belonging directly to one metadata provider.

Provider mappings represent relationships such as:

```text
SofaWatch Genre
     |
     +-- TMDB TV Genre ID
     +-- TMDB Movie Genre ID
     +-- future TVDB mapping
```

This prevents provider taxonomy from becoming internal identity.

---

# 16. Networks and Shared Metadata

Shared metadata such as television Networks may be associated with multiple Shows.

Shared entities should not be cascade-deleted simply because one Show is removed.

Ownership rules should reflect whether an entity is:

```text
owned by parent
```

or:

```text
shared across multiple entities
```

---

# 17. Library

`LibraryEntry` represents user-specific tracking/library state.

Library membership is separate from media import.

Conceptually:

```text
Local Show / Movie
       |
       v
LibraryEntry
       |
       v
User
```

A Library entry may refer to a Show or a Movie.

The conceptual constraint is:

```text
show_id XOR movie_id
```

Exactly one media reference must be present.

Never both.

Never neither.

---

## 17.1 Why Import and Library Are Separate

A local media object may exist because it was:

- searched
- previewed/imported
- synchronized
- referenced by another workflow

without necessarily belonging to a user's Library.

Keeping these concepts separate avoids coupling shared media metadata to user-specific tracking state.

---

# 18. Episode Progress

Episode progress associates a user with an Episode and stores derived/current tracking state.

Backend-owned values include:

```text
is_watched
watch_count
watched_at
```

These values are derived from or kept consistent with watch-event history.

The backend is authoritative for these fields.

---

# 19. Episode Watch Events

Each Episode viewing is represented by an individual `EpisodeWatchEvent`.

Example:

```text
First watch
   |
   +-- Event A

Rewatch
   |
   +-- Event B

Rewatch
   |
   +-- Event C
```

The resulting derived state may be:

```text
watch_count = 3
watched_at = timestamp(Event C)
```

This design preserves real viewing history.

---

## 19.1 Removing an Episode Watch Event

Removing one event must not simply mark the Episode unwatched.

The backend recalculates:

```text
is_watched
watch_count
watched_at
```

from the remaining events.

Example:

```text
A + B + C
remove C

watch_count = 2
watched_at = timestamp(B)
```

If no events remain, the Episode becomes unwatched.

---

# 20. Movie Watch Events

Movie viewing follows the same event-based principle.

Each viewing is represented by a `MovieWatchEvent`.

A rewatch creates another event rather than replacing history.

Statistics therefore count each Movie viewing.

---

# 21. Personal Ratings

Personal ratings are user-owned SofaWatch data.

They are conceptually separate from provider ratings.

Future external ratings may look like:

```text
Personal Rating
  -> SofaWatch user

External Rating
  -> TMDB
  -> IMDb
```

The database model should preserve provenance rather than silently combine these values.

---

# 22. Background Jobs

Background jobs persist two related concepts.

## BackgroundJob

Stores current state for a registered recurring job.

Typical concepts include:

- key
- current status
- last execution
- next execution
- scheduling state
- last result/error

## BackgroundJobRun

Stores execution history.

A run can contain:

- start/end time
- duration
- success/failure
- structured result
- safe error information

Conceptually:

```text
BackgroundJob
    |
    +-- BackgroundJobRun
    +-- BackgroundJobRun
    +-- BackgroundJobRun
```

Deleting a job may cascade to its owned execution history when appropriate.

---

# 23. Security Settings

Global security configuration that must persist across restarts belongs in database-backed application state where appropriate.

An example is:

```text
Open Registration
```

Default:

```text
false
```

Such settings are application state, not frontend preferences.

---

# 24. Metadata Ownership

The database stores both provider-owned metadata and SofaWatch-owned state.

These must remain conceptually distinct.

Provider-owned examples:

- title
- overview
- poster/backdrop
- air/release dates
- external IDs
- provider ratings

SofaWatch-owned examples:

- internal IDs
- Library state
- watch events
- progress
- user ratings
- authentication/session state
- administrative settings

Metadata synchronization must not overwrite SofaWatch-owned state.

---

# 25. Local Metadata Preservation

Where SofaWatch supports local overrides, provider refresh should preserve them.

Conceptually:

```text
provider_poster_path
local_poster_path
```

A metadata synchronization may update provider metadata while retaining explicitly local content.

This same ownership principle should apply to future overridable metadata.

---

# 26. Relationships and Cascades

Deletion behavior should reflect real ownership.

Examples of owned relationships:

```text
Show
  -> Seasons
      -> Episodes

BackgroundJob
  -> BackgroundJobRuns
```

Examples of user-owned relationships:

```text
User
  -> Library Entries
  -> Progress
  -> Watch Events
  -> Sessions
```

Shared entities such as Genre/Network should not be deleted merely because one media record is removed.

Cascade behavior must be validated both at ORM and database-constraint level.

---

# 27. Deletion and Historical Integrity

Deleting or removing a user-facing state record should preserve unrelated historical data according to the product rule.

Examples:

- removing one watch event must not delete other rewatches
- removing a Library entry should not automatically imply deleting globally imported media
- revoking one AuthSession should not revoke another session unless requested
- deleting one Show should not delete shared Genre records

Deletion should be explicit rather than inferred from UI state.

---

# 28. Metadata Synchronization

Metadata synchronization updates local provider-owned fields.

Conceptually:

```text
Local Media
    |
    v
Refresh Policy
    |
    v
Provider Fetch
    |
    v
Mapping
    |
    v
Persist Metadata
```

Synchronization must preserve:

- Library state
- progress
- watch history
- personal ratings
- user ownership

---

# 29. Transactions

Multi-step application workflows should have predictable transactional boundaries.

Examples include:

- first-user/Administrator bootstrap
- creating a watch event and updating derived progress
- password reset and session revocation
- multi-entity import
- metadata synchronization

A workflow should either commit a coherent result or fail without leaving inconsistent partial state, except where partial success is an explicit product feature.

---

# 30. Concurrency

SQLite is appropriate for the expected self-hosted workload, but concurrency-sensitive operations still require care.

Examples include:

- concurrent first-user creation
- duplicate media import
- refresh credential rotation
- background-job claiming
- simultaneous viewing mutations

Correctness should rely on:

- database constraints
- transactions
- idempotent operations
- explicit locking/claiming where needed

rather than frontend assumptions.

---

# 31. Idempotency

Operations that may be repeated should be idempotent where product semantics require it.

Example:

```text
POST /api/v1/movies/import/tmdb/{tmdb_id}
```

should reuse the existing local Movie rather than create duplicates for the same provider identity.

Future provider mappings should strengthen this behavior rather than weaken it.

---

# 32. Indexes

Indexes should be introduced based on query patterns and correctness requirements.

Likely important categories include:

- provider external IDs
- user-scoped Library lookups
- watch-event ordering by `watched_at`
- session credential hashes
- recovery credential hashes
- job scheduling/status fields
- media relationships

Indexes should not be added blindly; query behavior should guide optimization.

---

# 33. Date and Time Storage

Server-side timestamps should be stored consistently.

Application code should distinguish:

- absolute timestamps
- date-only provider values such as Episode air dates
- user-local presentation

An air date without a reliable provider air time must remain a date rather than being converted into an invented timestamp.

Frontend localization/presentation should not change persisted semantic meaning.

---

# 34. Migrations

Alembic manages schema evolution.

Common commands:

```bash
alembic current
alembic upgrade head
alembic check
```

To generate a candidate migration:

```bash
alembic revision --autogenerate -m "describe change"
```

Autogenerated migrations must be reviewed manually.

---

## 34.1 Migration Quality Rules

A migration should be evaluated for:

- correctness on a fresh database
- correctness on an existing database
- preservation of user IDs
- preservation of Library
- preservation of progress
- preservation of watch history
- preservation of Movie history
- preservation of ratings
- preservation of other user-scoped relationships

Tests against only a newly created database are not sufficient for final release confidence.

---

# 35. Legacy Database Upgrade Testing

Before stable releases, SofaWatch should test upgrades from an older real database snapshot.

Flow:

```text
Old SofaWatch DB
      |
      v
alembic upgrade head
      |
      v
Current Schema
      |
      v
Data Integrity Verification
```

This is especially important after major changes such as migration from the legacy local-user concept to real multi-user accounts.

---

# 36. SQLite WAL

Production operation may use SQLite WAL behavior depending on application configuration/deployment.

Backup and restore documentation must eventually account for SQLite journal/WAL semantics correctly.

Do not copy a live database file blindly as a documented backup strategy without validating consistency.

---

# 37. Backups

A complete SofaWatch backup system is planned but not yet considered implemented.

Future database backup architecture should define:

- safe SQLite snapshot method
- WAL handling
- backup target
- retention
- verification
- restore
- migration interaction
- failure reporting

Server diagnostics should not report fictional backup health before this exists.

---

# 38. Import / Export vs Database Backup

Application Import/Export and database backup solve different problems.

```text
Import / Export
  -> portable versioned application/user data

Database Backup
  -> operational recovery of SofaWatch storage
```

They should not be treated as interchangeable.

---

# 39. Database Diagnostics

Administrator diagnostics may expose safe operational information such as:

- engine
- database size
- WAL size
- connectivity
- integrity check
- foreign-key check
- Alembic revision

Diagnostics must not expose sensitive user data or credentials.

---

# 40. Integrity Checks

SQLite operational diagnostics can use database integrity mechanisms.

Examples:

```sql
PRAGMA integrity_check;
PRAGMA foreign_key_check;
```

These are administrative diagnostics, not ordinary request-time operations.

Potentially expensive diagnostics should be run deliberately.

---

# 41. Testing

Database tests should verify behavior such as:

- foreign-key enforcement
- constraints
- cascading behavior
- repository queries
- user isolation
- viewing-event recalculation
- migration behavior
- idempotent imports
- authentication-session persistence

Tests should use SQLite with the same important behavioral settings as production, especially foreign-key enforcement.

---

# 42. Anti-Patterns to Avoid

Avoid:

- treating SQLite as temporary and writing PostgreSQL-specific abstractions without need
- using provider IDs as internal primary keys
- queries missing explicit user scoping
- committing from arbitrary repository methods without clear transaction ownership
- deleting shared metadata through inappropriate cascades
- destroying previous viewing events on rewatch
- storing persistent authentication secrets in plaintext
- depending only on ORM cascades without validating database constraints
- assuming fresh-database migration tests prove upgrade safety
- putting provider JSON blobs in the database without a real requirement

---

# 43. Future Work

Known database-related work includes:

- external provider identifier mappings
- TVDB mappings
- external-rating persistence
- legacy database upgrade testing
- final Alembic chain audit
- backup/restore architecture
- WAL-safe operational documentation
- query/index performance audit before stable release

---

## Related Documentation

- [Architecture Overview](overview.md)
- [Backend Architecture](backend.md)
- [Provider Architecture](provider-architecture.md)
- [Authentication Architecture](authentication.md)
- [Database Migrations](../development/migrations.md)
- [Implementation Status](../features/implementation-status.md)
