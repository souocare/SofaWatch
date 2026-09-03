# API Overview

SofaWatch exposes a versioned REST API through FastAPI.

The API is the contract between the SofaWatch backend and its Flutter clients and is the authoritative boundary for persisted application state, authentication, authorization, and business rules.

> [!NOTE]
> SofaWatch is under active development. Generated OpenAPI documentation is the most precise source for the current endpoint/schema surface, while this document explains the API's structure, conventions, resource model, and intended client behavior.

---

## 1. Base Path

All application API routes are versioned under:

```text
/api/v1
```

Example:

```text
GET /api/v1/shows/{show_id}
```

The version prefix allows future incompatible API changes to be introduced without silently changing the meaning of existing routes.

---

## 2. Interactive API Documentation

While the backend is running, FastAPI exposes generated OpenAPI documentation.

Swagger UI:

```text
http://127.0.0.1:8000/docs
```

ReDoc:

```text
http://127.0.0.1:8000/redoc
```

For exact request/response schemas, required parameters, and the current route list, use the generated documentation.

This Markdown documentation should explain higher-level contracts and behavior rather than duplicate the complete OpenAPI schema manually.

---

## 3. API Structure

At a high level:

```text
/api/v1
   |
   +-- Authentication / Bootstrap
   |
   +-- Search
   +-- Explore
   |
   +-- Shows
   +-- Seasons
   +-- Episodes
   +-- Movies
   +-- Genres
   |
   +-- Library
   +-- Statistics
   +-- Users / Profile
   |
   +-- Images
   |
   +-- Background Jobs
   +-- Server Administration
   +-- Security
```

Most application routes are authenticated.

Authentication/bootstrap routes remain public where authentication cannot already be required.

---

## 4. Public vs Private API

The API router distinguishes between:

```text
public routes
```

and:

```text
authenticated application routes
```

Private routes require resolution of the current user before the request reaches the resource handler.

Conceptually:

```text
Request
   |
   v
Private API Router
   |
   v
CurrentUserDependency
   |
   +-- authenticated --> route
   |
   +-- unauthenticated --> 401
```

Public routes are limited to flows that genuinely need to exist before an authenticated session is available.

Examples include:

- setup/bootstrap status;
- first-user setup;
- login;
- registration state/registration where allowed;
- session/refresh flows where appropriate;
- password-recovery token flows;
- Mobile-to-Web handoff exchange.

A route must not be made public merely because the frontend hides or shows a button conditionally.

---

## 5. Authentication Models

SofaWatch supports Web and native/mobile authentication.

### Web

Persistent Web authentication uses a server-managed HttpOnly session cookie.

### Mobile

Native clients use:

```text
short-lived access token
+
rotating refresh credential
```

### Unified API Identity

Both mechanisms ultimately resolve to the same SofaWatch `User`.

Protected resource routes do not have separate Web-user and mobile-user versions.

See [Authentication Architecture](../architecture/authentication.md).

---

## 6. Authorization

Authentication and authorization are separate.

Examples of normal authenticated resources include:

- Library;
- Shows;
- Movies;
- viewing history;
- Statistics;
- Search;
- Explore.

Administrator-only resources require additional backend authorization.

Examples include:

- server diagnostics;
- background-job administration;
- security settings;
- logs/admin operations where exposed;
- administrative password recovery.

Frontend visibility is not an authorization boundary.

---

## 7. Resource Identity

SofaWatch uses internal identifiers for imported/local entities.

External provider identifiers remain separate.

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

Once media exists locally, frontend clients should use the SofaWatch internal ID for application operations.

Movies follow the same explicit distinction:

```text
GET /api/v1/movies/{movie_id}
```
uses the internal SofaWatch Movie UUID, while:
```text
GET /api/v1/movies/tmdb/{tmdb_id}
```
uses the TMDB identifier.

Provider IDs should only be used on provider-specific routes or explicit provider-mapping/import operations.

---

## 8. Internal vs Provider IDs

Conceptually:

```text
SofaWatch Show
    id = local identifier

External identifiers
    TMDB = provider identifier
    TVDB = future provider identifier
    IMDb = future/external identifier
```

Do not assume that the same numeric/string namespace is shared between SofaWatch and providers.

This becomes increasingly important as TVDB and external ratings are introduced.

---

## 9. Main Resource Areas

### Authentication

Handles:

- first-run setup;
- login;
- session restoration;
- mobile refresh;
- logout;
- logout everywhere;
- registration state;
- registration;
- password-related auth flows;
- Mobile-to-Web handoff.

Authentication endpoints do not replace authorization on application resources.

---

### Users / Profile

User endpoints expose authenticated account/profile information and account operations.

Current user data includes concepts such as:

- internal user ID;
- username;
- email;
- display name;
- Administrator state.

Administrative user-management functionality is intentionally broader future work and should not be assumed complete merely because user-list/recovery APIs exist.

---

### Security

Security endpoints support Administrator-controlled global security settings.

A key current setting is:

```text
Open Registration
```

Default:

```text
false
```

The backend enforces the setting regardless of frontend presentation.

---

### Search

Search is global and supports TV Shows and Movies.

The backend normalizes provider results into a common media contract rather than exposing raw TMDB response objects.

Search behavior includes:

- media-type filtering;
- pagination;
- language;
- provider error mapping.

People are not part of the current normalized media Search result set.

---

### Explore

Explore is discovery-oriented and separate from Search.

It supports provider-backed discovery concepts such as:

- Trending;
- Popular Shows;
- Popular Movies;
- genre-aware discovery.

Explore should not become a second independent Search API.

---

### Shows

Show resources cover locally imported TV Shows.

Capabilities include areas such as:

- listing local Shows;
- Show details;
- provider-backed import;
- metadata refresh;
- progress;
- Watch Next-related information;
- Upcoming-related information;
- bulk watched operations across eligible regular Episodes;
- Seasons.

Local Show routes use internal SofaWatch identity.

---

### Seasons

Season resources cover locally persisted Seasons associated with Shows.

Capabilities include:

- Season information;
- Episode listing;
- progress;
- bulk watched operations for aired/watchable Episodes;
- lazy Episode synchronization where applicable.

Season loading/synchronization may be performed independently rather than requiring every Episode during initial Show import.

---

### Episodes

Episode resources support:

- Episode details;
- watched state;
- watch-event creation;
- viewing history;
- removing individual viewing events;
- previous-unwatched Episode detection;
- catch-up mutations that can mark eligible previous Episodes together with
  the selected Episode.
- rewatch behavior.


Viewing history is event-based.

A rewatch creates a new event rather than overwriting the previous viewing.

Bulk and catch-up watched operations do not create additional watch events for
Episodes that were already watched.

Eligibility for previous-Episode catch-up and bulk mutations is a backend
business rule. Clients request the operation rather than independently
reconstructing the rule.

---

### Movies

Movies are first-class SofaWatch resources.

Capabilities include:

- local Movie persistence;
- provider-backed import;
- Library/watchlist state;
- watched state;
- Movie watch events;
- rewatches;
- history;
- Statistics integration.

Importing a Movie and adding it to a user's Library remain separate operations.

---

### Genres

Genres are local SofaWatch entities.

Provider genre IDs are mapping information, not the internal Genre identity.

The API exposes Genre information used by Library/discovery/filtering features.

---

### Library

Library resources are user-scoped.

Library entries can reference:

```text
Show
OR
Movie
```

according to the application's media constraint.

Library operations include:

- adding media;
- removing media;
- changing tracking state;
- listing user Library data.

Media import does not automatically imply Library membership.

---

### Statistics

Statistics endpoints expose user-scoped viewing analytics derived from persisted watch history.

Statistics may include concepts such as:

- viewing time;
- Episode viewings;
- Movie viewings;
- rewatches;
- streaks;
- activity;
- genre/content insights;
- Library statistics.

Statistics is a dedicated backend capability reused by frontend areas such as Home and Profile.

---

### Images

Image routes provide SofaWatch-facing image resources.

The frontend should not need to understand whether the image was:

- already cached locally;
- downloaded from TMDB;
- resolved from another future provider.

The API provides the appropriate SofaWatch image path/resource.

---

### Background Jobs

Administrator-only background-job APIs expose operational job state.

Capabilities include concepts such as:

- registered jobs;
- current status;
- last run;
- next run;
- execution duration;
- structured results;
- execution history;
- manual Run Now.

Background jobs run in a separate worker process.

---

### Server Administration

Administrator-only Server endpoints expose safe diagnostics.

Current areas include concepts such as:

- overall health;
- database health;
- storage diagnostics;
- runtime information;
- provider health.

Diagnostics must not expose secrets.

---

## 10. Search and Import Are Separate

Search results represent external provider media.

Import creates/reuses a local SofaWatch entity.

Library membership is a third concept.

Conceptually:

```text
Search Result
      |
      v
Import
      |
      v
Local SofaWatch Entity
      |
      v
Optional Library Entry
```

This separation is intentional.

A frontend should not assume:

```text
Search result == local entity
```

or:

```text
Imported entity == in Library
```

---

## 11. Viewing History Contract

Viewing history is based on individual viewing events.

Episode example:

```text
first watch -> Event A
rewatch     -> Event B
rewatch     -> Event C
```

The API should therefore preserve each event.

Derived state may include:

```text
is_watched = true
watch_count = 3
watched_at = timestamp(Event C)
```

Removing Event C should recalculate derived state from A and B rather than clearing all watched state.

Movie viewing follows the same principle.

---

## 12. Dates

Date-only values use ISO calendar format:

```text
YYYY-MM-DD
```

Example:

```json
{
  "air_date": "2026-08-27"
}
```

A date-only value must remain semantically distinct from a timestamp.

The API should not fabricate an Episode air time when the provider only supplies an air date.

---

## 13. Timestamps

Timestamps should use ISO 8601.

Example:

```json
{
  "watched_at": "2026-08-27T08:30:00+00:00"
}
```

The frontend is responsible for converting absolute timestamps into user-local presentation.

The backend should not return display-formatted strings such as:

```text
27/08/2026 09:30
```

as the canonical API timestamp representation.

---

## 14. Optional Values

Unavailable optional metadata should normally be represented as:

```json
null
```

rather than invented values.

Example:

```json
{
  "air_date": null,
  "overview": null
}
```

Empty collections should normally be represented as:

```json
[]
```

rather than `null`, where the schema models a collection.

---

## 15. Error Contract

Expected application errors use a safe structured API error contract.

Conceptually:

```json
{
  "error": {
    "code": "example_error",
    "message": "Safe human-readable message."
  }
}
```

Validation errors may include structured details.

The frontend should prefer stable error codes for behavior decisions rather than parsing human-readable messages.

Messages may evolve for clarity/localization.

---

## 16. HTTP Status Semantics

Common status classes include:

```text
2xx
successful operation

400 / 422
invalid request / validation

401
authentication missing or invalid

403
authenticated but not authorized

404
resource not found

409
conflicting state

5xx
server/provider failure
```

The exact status for each endpoint is defined by the route/OpenAPI contract.

Do not collapse `401` and `403` into the same meaning.

---

## 17. Provider Errors

External provider failures are translated into SofaWatch-level errors.

Examples include concepts such as:

- provider not configured;
- provider unavailable;
- provider timeout;
- resource not found;
- invalid provider response.

The frontend should not depend on raw `httpx`, TMDB, or future TVDB exceptions.

---

## 18. Validation Errors

FastAPI/Pydantic validates:

- path parameters;
- query parameters;
- request bodies.

Invalid input may fail before service code runs.

Frontend clients should send values according to the OpenAPI schema rather than relying on coercion.

---

## 19. Pagination

SofaWatch currently uses pagination appropriate to the underlying resource.

There are two important conceptual families.

### Local Collection Pagination

Large local collections may use offset/limit-style pagination.

Conceptually:

```json
{
  "items": [],
  "total": 0,
  "offset": 0,
  "limit": 20,
  "has_next": false
}
```

### Provider/Search Pagination

Provider Search may use page-based pagination.

Conceptually:

```json
{
  "page": 1,
  "results": [],
  "total_pages": 1,
  "total_results": 0
}
```

Frontend code should not force both models into one abstraction if their semantics differ.

A dedicated pagination document may be added as the API surface evolves.

---

## 20. Ordering

Where ordering is part of product semantics, the backend should return deterministic ordering.

Examples:

```text
Watch History
-> watched_at DESC

Upcoming
-> chronological

inactive Shows
-> inactivity rule
```

The frontend should not reimplement a different business ordering unless presentation specifically requires it.

---

## 21. User Scoping

User-owned API resources must be scoped by the authenticated user.

Examples:

- Library;
- Episode progress;
- Episode watch history;
- Movie watch history;
- ratings;
- Statistics;
- AuthSessions.

A resource identifier alone must not allow one user to access another user's private state.

---

## 22. Administrator Scoping

Administrator authorization is checked separately from normal user authentication.

Example:

```text
GET /api/v1/server/...
```

must not become accessible to a normal user even if they know the URL.

The same applies to Security and other administrative APIs.

---

## 23. Images

The frontend should prefer SofaWatch image resources/URLs returned by API models rather than constructing TMDB URLs directly.

This allows the backend to own:

- provider image paths;
- local caching;
- future provider selection;
- fallback rules.

Image absence should result in a frontend placeholder rather than constructing an invalid provider URL.

---

## 24. Provider Independence

API contracts should expose SofaWatch concepts wherever practical.

For example:

```text
Media Search Result
Show
Movie
Episode
External Rating
```

rather than forcing clients to know provider response shapes.

Provider provenance should remain explicit where it matters, such as:

```text
TMDB rating
IMDb rating
```

but provider implementation details should remain behind the backend boundary.

---

## 25. Language

Provider-backed operations may accept or derive metadata language.

Current/future behavior must distinguish:

```text
application UI localization
```

from:

```text
provider metadata language
```

These are related but not identical responsibilities.

The API should use stable language identifiers such as:

```text
en-US
pt-PT
```

according to backend/provider support.

---

## 26. API Response Stability

Once a response field is part of the frontend contract, changing its:

- name;
- type;
- nullability;
- semantics;

is an API contract change.

During active development, contracts can evolve, but backend and frontend must be updated coherently.

Do not change DTO shapes casually without updating:

- backend schemas;
- frontend DTOs/mappers;
- tests;
- documentation where relevant.

---

## 27. OpenAPI as Exact Schema Reference

Markdown documentation intentionally does not list every field of every Pydantic schema.

For exact schemas:

```text
/docs
/redoc
```

are authoritative for the running version.

This avoids maintaining duplicate schema definitions manually in Markdown.

---

## 28. Frontend Contract Documentation

More detailed frontend-facing behavior is documented in:

[Frontend API Contract](frontend-contract.md)

That document focuses on:

- client expectations;
- shared conventions;
- feature flows;
- error handling;
- pagination;
- dates/timestamps;
- backend/frontend responsibility boundaries.

---

## 29. Backward Compatibility

SofaWatch has not yet reached a frozen stable API.

Before stable releases, API evolution should become more deliberate.

Potential future policy may define:

- what constitutes a breaking change;
- compatibility window;
- deprecation strategy;
- API version migration.

Until then, `/api/v1` still represents the current versioned contract rather than a promise that every field is permanently frozen.

---

## 30. API Security Rules

Never expose through API responses:

- passwords;
- password hashes;
- secret key;
- access tokens except where explicitly required by auth response;
- refresh credential hashes;
- Web session credential hashes;
- recovery credential hashes;
- provider API tokens;
- TVDB PIN/API key;
- sensitive internal configuration.

Server diagnostics should expose booleans/status such as:

```text
configured = true
```

rather than the credential value.

---

## 31. Logging vs API Errors

API errors should be safe for clients.

Operational details belong in backend logs where appropriate.

Conceptually:

```text
Internal exception
     |
     +--> detailed safe server log
     |
     +--> normalized API error
```

Do not send stack traces or raw provider/database exceptions to Flutter.

---

## 32. Client Retry

Retry behavior depends on the operation.

Appropriate candidates include:

- network failure;
- timeout;
- provider unavailable;
- pagination failure;
- independent section loading failure.

Retry should not blindly repeat:

- invalid validation input;
- forbidden actions;
- consumed single-use credentials;
- non-idempotent mutations without understanding their semantics.

---

## 33. Idempotency

Some operations are explicitly intended to be repeatable safely.

Media import is a key example.

A repeated import for the same provider identity should reuse/update the existing local media rather than create duplicates where the endpoint contract defines idempotent behavior.

Do not assume every POST endpoint is idempotent.

---

## 34. Background API vs Worker

Background job APIs expose and control server-side job state.

The API process and worker are separate.

Conceptually:

```text
Flutter Admin UI
       |
       v
FastAPI
       |
       v
Background Job persistent state
       ^
       |
Background Worker
```

The API does not itself become the scheduled worker.

---

## 35. API Testing

Backend route tests should protect:

- authentication;
- authorization;
- status codes;
- validation;
- response schemas;
- error codes;
- user scoping;
- Administrator scoping.

Frontend repository tests should protect:

- endpoint paths;
- payloads;
- query parameters;
- DTO mapping;
- error mapping.

See [Testing](../development/testing.md).

---

## 36. Adding a New API Capability

Before adding a route, identify:

```text
Who owns the business rule?
Does an existing route/service already solve it?
Is the resource user-scoped?
Does it require Administrator access?
What is the internal ID?
Is provider access required?
What is the safe error contract?
Does it need pagination?
Is the operation idempotent?
What tests protect it?
```

Prefer expanding a coherent resource API over creating ad-hoc endpoints tied to one screen.

---

## 37. Screen-Specific APIs

Avoid creating backend endpoints whose only abstraction is the current UI layout when the underlying capability is reusable.

For example:

```text
Home
Profile
Shows
```

may consume shared:

```text
Statistics
Watch History
Watch Next
```

rather than each receiving duplicate business APIs.

A dashboard aggregation endpoint may still be valid if it solves a real performance/consistency need, but it should be a deliberate API design decision.

---

## 38. Current Route Registration

The current API composition includes authenticated routers for:

- Genres;
- Search;
- Shows;
- Seasons;
- Episodes;
- Library;
- Background Jobs;
- Images;
- Movies;
- Explore;
- Statistics;
- Users;
- Server;
- Security.

Authentication/bootstrap routes are included separately as public routes.

The running OpenAPI schema remains the authoritative source for the exact route set.

---

## 39. Planned API Evolution

Likely future API areas include:

- TVDB/provider mapping support;
- external ratings;
- full Administrator user management;
- account activation/deactivation;
- backups/restore administration;
- localization-related preferences;
- additional production/operational APIs where justified.

Do not add placeholder endpoints for features that do not yet exist.

---

## Related Documentation

- [Frontend API Contract](frontend-contract.md)
- [Architecture Overview](../architecture/overview.md)
- [Data Flow](../architecture/data-flow.md)
- [Backend Architecture](../architecture/backend.md)
- [Authentication Architecture](../architecture/authentication.md)
- [Provider Architecture](../architecture/provider-architecture.md)
- [Development Setup](../development/setup.md)
- [Testing](../development/testing.md)
- [Backend README](../../backend/README.md)
- [Frontend README](../../frontend/README.md)
