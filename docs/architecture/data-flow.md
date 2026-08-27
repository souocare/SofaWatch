# Data Flow Architecture

This document describes how data moves through SofaWatch.

It complements the component-oriented architecture documents by focusing on end-to-end flows across Flutter, FastAPI, services, repositories, SQLite, external providers, and background jobs.

---

## 1. High-Level Data Flow

The normal request path is:

```text
User
 |
 v
Flutter Presentation
 |
 v
Cubit / Bloc
 |
 v
Domain Repository Contract
 |
 v
Data Repository
 |
 v
ApiClient / HTTP
 |
 v
FastAPI Route
 |
 v
Service
 |
 +---------> Provider
 |
 v
Repository
 |
 v
SQLite
```

Responses move back through the inverse representation path:

```text
SQLite / Provider
       |
       v
Backend Domain / Schema
       |
       v
JSON API Response
       |
       v
Frontend DTO
       |
       v
Domain Model
       |
       v
Cubit / Bloc State
       |
       v
UI
```

---

# 2. Ownership Boundaries

Not all data has the same owner.

## SofaWatch-Owned Data

Examples:

- internal media IDs
- users
- Library state
- watch history
- rewatches
- personal ratings
- authentication sessions
- security settings
- background job state

## Provider-Owned Metadata

Examples:

- titles
- overviews
- posters
- backdrops
- air/release dates
- external IDs
- provider ratings

## Client-Only State

Examples:

- selected tab
- scroll position
- active filter
- temporary loading state
- modal open/closed state
- unsaved text field content

Correct architecture depends on keeping these ownership categories separate.

---

# 3. Standard Read Flow

Example: load a user-specific feature.

```text
Page opens
   |
   v
Cubit.load()
   |
   v
Repository.getData()
   |
   v
GET /api/v1/...
   |
   v
FastAPI Route
   |
   v
CurrentUserDependency
   |
   v
Service
   |
   v
Repository query scoped by user_id
   |
   v
SQLite
   |
   v
Response Schema
   |
   v
JSON
   |
   v
Frontend DTO
   |
   v
Domain Model
   |
   v
Success State
   |
   v
Render
```

The frontend should not need to know how SQLAlchemy queries are implemented.

---

# 4. Standard Mutation Flow

Example: mutate user-owned state.

```text
User taps action
      |
      v
Cubit action
      |
      v
Domain repository method
      |
      v
HTTP mutation
      |
      v
Authenticated FastAPI route
      |
      v
Service applies business rule
      |
      v
Repository writes DB
      |
      v
Commit
      |
      v
Authoritative response
      |
      v
Frontend updates related state
```

The backend response should be treated as authoritative for server-owned state.

---

# 5. Authentication Flow — Web Login

```text
Login Form
   |
   v
AuthCubit.login()
   |
   v
Web Auth Repository
   |
   v
POST Login
   |
   v
Validate User + Argon2
   |
   v
Create WEB AuthSession
   |
   v
Set HttpOnly Cookie
   |
   v
Return auth state/access data
   |
   v
AuthCubit -> Authenticated
   |
   v
Application Shell
```

Persistent Web session state is carried by the browser cookie, not by JavaScript-readable long-lived storage.

---

# 6. Authentication Flow — Web Restore

```text
Flutter Web reload
      |
      v
AuthCubit.restore()
      |
      v
Session restore request
      |
      +--> browser automatically sends HttpOnly cookie
      |
      v
Backend validates WEB AuthSession
      |
      v
Current User
      |
      v
Authenticated frontend state
```

If the session is expired/revoked, the client returns to unauthenticated state.

---

# 7. Authentication Flow — Mobile Login

```text
Login Form
   |
   v
AuthCubit.login()
   |
   v
Mobile Auth Repository
   |
   v
POST Mobile Login
   |
   v
Validate credentials
   |
   v
Create MOBILE AuthSession
   |
   +--> short-lived access token
   |
   +--> refresh credential
   |
   v
Store refresh credential through client storage abstraction
   |
   v
Authenticated
```

---

# 8. Authentication Flow — Mobile Refresh

```text
Access token expired / session restore
           |
           v
Load refresh credential
           |
           v
POST refresh
           |
           v
Hash presented credential
           |
           v
Validate MOBILE AuthSession
           |
           v
Rotate credential
           |
           +--> new access token
           |
           +--> new refresh credential
           |
           v
Replace stored refresh credential
```

The old credential becomes invalid.

---

# 9. Current User Resolution

A protected backend request flows through:

```text
Request
  |
  +-- Bearer supplied?
  |      |
  |      +-- yes --> validate --> User / 401
  |
  +-- otherwise Web session cookie?
         |
         +-- yes --> validate AuthSession --> User / 401
         |
         +-- no --> 401
```

An explicitly invalid Bearer token does not silently fall back to a cookie.

---

# 10. Administrator Authorization Flow

```text
Request
   |
   v
Authenticate User
   |
   v
Admin dependency
   |
   +-- is_admin = true --> service
   |
   +-- false -----------> 403
```

Frontend Admin visibility is only presentation behavior.

---

# 11. First-Run Setup Flow

```text
App starts
   |
   v
Check setup status
   |
   +-- users exist --> Login/Auth restore
   |
   +-- no users
          |
          v
       Setup UI
          |
          v
Create first account
          |
          v
Backend transaction verifies still first
          |
          v
User created as Administrator
          |
          v
setup_required = false
```

Concurrency protection belongs to the backend/database transaction boundary.

---

# 12. Open Registration Flow

```text
Login UI
   |
   v
Read registration status
   |
   +-- closed --> hide Sign Up
   |
   +-- open ---> offer Sign Up
```

Registration submission always flows through backend policy:

```text
Registration request
       |
       v
Backend reads Open Registration
       |
       +-- false --> reject
       |
       +-- true --> create normal User
```

---

# 13. Search Flow

```text
User types query
     |
     v
SearchBloc
     |
     v
Debounce / normalize
     |
     v
SearchRepository
     |
     v
CachedSearchRepository
   /                    \
  v                      v
Cache hit?             Cache miss
  |                      |
  v                      v
Return              ApiSearchRepository
                         |
                         v
                     Backend Search
                         |
                         v
                       TMDB
                         |
                         v
                  Normalize result
                         |
                         v
                       Cache
                         |
                         v
                    SearchBloc
                         |
                         v
                        UI
```

Search is global and separate from Explore.

---

# 14. Search Pagination Flow

```text
User reaches list end
       |
       v
SearchBloc requests next page
       |
       v
Preserve current results
       |
       v
Fetch next page
       |
       +-- success --> append
       |
       +-- failure --> keep existing results + pagination error
```

Pagination failure should not destroy already loaded Search results.

---

# 15. Media Preview Flow

```text
Search / Explore item
       |
       v
Open Preview
       |
       v
Preserve originating query/filter/scroll
       |
       v
Load preview/details data
       |
       v
User closes preview
       |
       v
Restore originating context
```

Preview navigation should not unnecessarily recreate Search or Explore state.

---

# 16. Media Import Flow

```text
External result
      |
      v
Import request using provider ID
      |
      v
FastAPI Route
      |
      v
Import Service
      |
      v
Provider fetch
      |
      v
Map provider DTO
      |
      v
Check existing provider mapping
      |
      +-- exists --> reuse/update local entity
      |
      +-- missing --> create local entity
      |
      v
Return SofaWatch internal ID
```

Import and Library membership are separate operations.

---

# 17. Add to Library Flow

```text
Local SofaWatch media
        |
        v
User chooses Library action
        |
        v
Authenticated mutation
        |
        v
Library Service
        |
        v
Create/update user-scoped LibraryEntry
        |
        v
Authoritative Library state returned
```

SearchBloc should not own Library mutation business logic.

---

# 18. Show Details Flow

```text
Open Show Details
       |
       v
ShowDetails Cubit
       |
       v
Show Repository
       |
       v
Backend
       |
       +--> local Show metadata
       +--> Library state
       +--> progress
       |
       v
Render Details
```

Season/Episode loading is intentionally more granular.

---

# 19. Season Expansion Flow

```text
User expands Season
       |
       v
Season-specific state
       |
       v
Check local Episodes
       |
       v
Need synchronization?
   /             \
  no              yes
  |                |
  v                v
render       provider synchronization
                   |
                   v
               persist Episodes
                   |
                   v
                 render
```

One Season can fail independently from another.

---

# 20. Mark Episode Watched Flow

```text
User taps Mark Watched
       |
       v
Episode action Cubit/UI state
       |
       v
POST watch event
       |
       v
Backend validates business rule
       |
       v
Create EpisodeWatchEvent
       |
       v
Recalculate Episode progress
       |
       v
Commit
       |
       v
Return authoritative progress
       |
       v
Refresh affected frontend state
```

Affected state may include:

- Episode row
- Season progress
- Show progress
- Watch Next
- Watch History
- Home sections
- Statistics when reloaded

---

# 21. Rewatch Flow

```text
Already watched Episode
        |
        v
Watched Again
        |
        v
Create NEW EpisodeWatchEvent
        |
        v
Previous events remain
        |
        v
watch_count += 1
watched_at = newest event
```

Rewatch never replaces the original viewing.

---

# 22. Remove Watch Event Flow

```text
Watch History
     |
     v
Remove individual event
     |
     v
DELETE event
     |
     v
Backend deletes target event
     |
     v
Load remaining events
     |
     v
Recalculate:
  is_watched
  watch_count
  watched_at
     |
     v
Return updated state
```

If another event remains, the Episode is still watched.

---

# 23. Watch Next Flow

```text
User Library
     |
     v
Backend evaluates Shows
     |
     +-- status eligible?
     +-- progress started?
     +-- next aired unwatched Episode?
     +-- caught up?
     |
     v
Watch Next results
```

Important rules:

- caught-up Shows are excluded
- new eligible Episodes can return a Show
- Ended does not automatically mean Completed
- no next Episode is invented

---

# 24. Haven't Watched in a While Flow

```text
Watching Shows
      |
      v
Started?
      |
      v
Last viewing timestamp
      |
      v
Inactive beyond threshold?
      |
      v
Eligible next Episode?
      |
      v
Order by inactivity
```

Backend rules should prevent inappropriate duplication with Watch Next.

---

# 25. Upcoming Flow

```text
Local Episodes
      |
      v
air_date
      |
      v
Requested temporal range
      |
      v
Chronological grouping
      |
      v
Today / Tomorrow / Future / Historical UI
```

Date-only provider metadata remains date-only.

Air time must not be fabricated.

---

# 26. Movie Watch Flow

```text
Movie Details
     |
     v
Mark Watched / Rewatch
     |
     v
Create MovieWatchEvent
     |
     v
Persist viewing
     |
     v
Update movie watched state/history
     |
     v
Statistics count viewing
```

Each rewatch is another MovieWatchEvent.

---

# 27. History Flow

```text
EpisodeWatchEvents ----+
                       |
                       +--> combine/order by watched_at DESC
                       |
MovieWatchEvents ------+
                       |
                       v
                 History API
                       |
                       v
               Frontend History
```

History is event-based, not simply a list of media marked watched.

---

# 28. Statistics Flow

```text
Persisted Watch Events
        |
        +-- Episode events
        +-- Movie events
        |
        v
Statistics Service
        |
        v
Aggregations
        |
        +-- watch time
        +-- unique media
        +-- rewatches
        +-- streaks
        +-- genres
        +-- activity
        |
        v
Statistics API
        |
        v
Reusable frontend Statistics feature
```

Home/Profile reuse this feature rather than recalculating statistics independently.

---

# 29. Explore Flow

```text
Explore UI
    |
    v
Explore Repository
    |
    v
Backend Explore
    |
    v
TMDB discovery/trending/popular
    |
    v
Normalized media results
    |
    v
Explore UI
```

Explore remains discovery-oriented.

---

# 30. Metadata Synchronization Flow

Manual or scheduled metadata refresh converges on shared application logic.

```text
Manual Refresh ----------+
                         |
                         v
                 Metadata Sync Service
                         ^
                         |
Background Job ----------+
                         |
                         v
                  Refresh policy
                         |
                         v
                       TMDB
                         |
                         v
                 Map provider data
                         |
                         v
                 Persist metadata
```

User-owned state is preserved.

---

# 31. Background Job Flow

```text
Worker
  |
  v
Scheduler
  |
  v
Job due?
  |
  v
Executor
  |
  v
Create BackgroundJobRun
  |
  v
Handler
  |
  v
Application Service
  |
  v
Persist result
  |
  v
Set next execution
```

FastAPI is not required to trigger scheduled execution.

---

# 32. Metadata Job Batch Flow

```text
metadata_sync
    |
    v
Load candidate Shows
    |
    v
For each Show
    |
    +-- skip
    +-- refresh success
    +-- failure
    |
    v
Continue remaining Shows
    |
    v
Aggregate counters
    |
    v
Persist structured result
```

One failed Show does not stop the batch.

---

# 33. Server Health Flow

```text
Administrator UI
       |
       v
ServerHealthCubit
       |
       v
Server Repository
       |
       v
GET /server/health
       |
       v
Admin authorization
       |
       v
ServerHealthService
    /            \
   v              v
Database         TMDB
check            health
   \              /
    \            /
     v          v
   normalized health response
```

Non-Administrators should not construct/load this feature unnecessarily, and the backend independently rejects unauthorized access.

---

# 34. Password Change Flow

```text
Authenticated User
       |
       v
Current password + new password
       |
       v
Backend verifies current password
       |
       v
Argon2 hash new password
       |
       v
Persist
```

Username editing is a separate deferred product decision.

---

# 35. User Recovery Flow

```text
Administrator
      |
      v
Create recovery for User
      |
      v
Generate random credential
      |
      +--> return recovery URL/token once
      |
      v
Store hash + expiry
      |
      v
User submits new password
      |
      v
Validate token
      |
      v
Update password hash
      |
      v
Consume token
      |
      v
Revoke existing sessions
```

---

# 36. Administrator CLI Recovery Flow

```text
Server operator
      |
      v
python -m app.admin.reset_password <user>
      |
      v
getpass()
      |
      v
Hash password
      |
      v
Persist
      |
      v
Revoke sessions
```

Password never belongs in CLI arguments.

---

# 37. Mobile-to-Web Handoff Flow

```text
Authenticated Mobile
      |
      v
Request handoff
      |
      v
Backend creates short-lived single-use credential
      |
      v
Mobile opens browser URL
      |
      v
Web submits handoff
      |
      v
Backend validates/consumes handoff
      |
      v
Create WEB AuthSession
      |
      v
Set Web session cookie
      |
      v
Authenticated Web
```

The handoff credential is not a persistent access/refresh token.

---

# 38. Import / Export Flow

## Export

```text
Authenticated User
      |
      v
Export request
      |
      v
Load user-scoped data
      |
      v
Map into versioned export format
      |
      v
Return export file/data
```

## Import

```text
Import file
    |
    v
Validate format/version
    |
    v
Preview
    |
    v
Apply sections
    |
    +-- Library
    +-- History
    +-- Ratings
    |
    v
Conflict/duplicate handling
    |
    v
Progress + final summary
```

Partial failures should be explicit.

---

# 39. Error Flow

Backend:

```text
Provider / DB / Application Error
            |
            v
Application Exception / Safe Mapping
            |
            v
FastAPI Error Handler
            |
            v
Safe HTTP Response
```

Frontend:

```text
HTTP/Dio Failure
       |
       v
Data-layer Error Mapping
       |
       v
AppException
       |
       v
Cubit / Bloc Failure State
       |
       v
Safe UI Message + Retry
```

Raw internal exceptions should not cross boundaries unnecessarily.

---

# 40. Refresh Flow

A coordinated refresh should prefer:

```text
Current Success State
       |
       v
Refreshing
       |
       +-- keep useful current data visible
       |
       v
New authoritative data
```

rather than:

```text
Success
  |
  v
Blank full-screen Loading
```

when the existing data remains usable.

---

# 41. Provider Fallback Flow — Future

Once multiple providers exist:

```text
Request metadata field
       |
       v
Preferred provider has value?
    /                    \
  yes                     no
  |                        |
  v                        v
use preferred       fallback provider
                           |
                           v
                    still unavailable?
                           |
                           v
                     preserve existing /
                     leave unknown
```

Precedence must be explicit per field where necessary.

---

# 42. Provider Partial Failure Flow — Future

```text
Refresh local Show
   |
   +-- TMDB success
   |
   +-- TVDB timeout
   |
   v
Apply allowed TMDB changes
Preserve TVDB-owned/existing data
Record partial failure
```

A secondary provider outage should not make local media unusable.

---

# 43. Client State Preservation Flow

Navigation-sensitive features may preserve:

```text
query
filter
pagination
selected tab
scroll
historical range
```

Flow:

```text
Feature State
   |
   v
Open Details/Preview
   |
   v
Navigate back/close
   |
   v
Restore existing feature state
```

Do not reload purely because a modal/detail page was opened unless data actually needs refresh.

---

# 44. Dependency Direction

End-to-end data movement must still respect dependency direction.

Backend:

```text
Routes
  |
  v
Services
  |
  +--> Repositories
  |
  +--> Providers
```

Frontend:

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

Data flow is not permission for lower layers to depend upward.

---

# 45. Data Consistency Principles

When multiple UI areas represent the same backend truth:

```text
Watch Next
Show Details
History
Home
Statistics
```

mutations should eventually converge on the same authoritative backend state.

Avoid allowing each screen to invent its own interpretation of watched/progress data.

---

# 46. Security Data Flow Principles

Sensitive credentials should move only through the minimum required boundaries.

Examples:

```text
Password
  -> login/password endpoint
  -> Argon2 verification
  -> never persisted plaintext
```

```text
Web persistent credential
  -> HttpOnly cookie
  -> browser/backend
  -> not exposed to Flutter code
```

```text
Mobile refresh credential
  -> native storage abstraction
  -> refresh endpoint
  -> hashed server-side
```

---

# 47. Observability Flow

Operational information may flow into:

```text
Application / Worker
        |
        v
Logging
        |
        +--> server logs
        |
        +--> safe Admin log view
```

Sensitive values must be removed before Administrator-facing exposure.

Background jobs additionally persist structured execution summaries.

---

# 48. Adding a New End-to-End Feature

A normal new feature should be designed by tracing both directions.

Example checklist:

```text
Frontend Domain Model?
Frontend Repository Contract?
Frontend Application State?
Frontend Presentation?

API Contract?
Route?
Service?
Repository?
Persistence Model?
Provider interaction?
Authorization?
Tests?
```

Only add layers that have real responsibilities.

---

# 49. Anti-Patterns to Avoid

Avoid flows such as:

```text
Widget -> Dio directly
```

```text
Route -> complex SQLAlchemy queries + provider calls + business rules
```

```text
TMDB JSON -> Flutter Widget
```

```text
Frontend -> independently calculate backend-owned progress rule
```

```text
Background Job -> duplicate metadata-sync logic
```

```text
SearchBloc -> own Library business rules
```

The purpose of the architecture is to prevent these shortcuts from becoming long-term coupling.

---

## Related Documentation

- [Architecture Overview](overview.md)
- [Backend Architecture](backend.md)
- [Frontend Architecture](frontend.md)
- [Database Architecture](database.md)
- [Authentication Architecture](authentication.md)
- [Provider Architecture](provider-architecture.md)
- [Background Jobs](background-jobs.md)
- [Implementation Status](../features/implementation-status.md)
