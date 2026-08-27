# ADR-002: Backend as the Source of Truth

- Status: Accepted
- Date: 2026-08-27

## Context

SofaWatch has multiple clients and multiple domains of persisted application state.

Current clients include:

```text
Flutter Web
Flutter iOS
Flutter Android
```

The application manages state and business rules for areas such as:

- users and authentication;
- Library membership and status;
- TV Show progress;
- Episode watched state;
- Episode viewing history;
- rewatches;
- Movie watched state;
- Movie viewing history;
- Statistics;
- Upcoming;
- Watch Next;
- administrative settings;
- background jobs;
- metadata synchronization.

Many of these values are related rather than independent.

For example, marking an Episode as watched can affect:

```text
Episode watch history
Episode watch_count
Episode watched_at
Episode is_watched
Season progress
Show progress
Watch Next
Haven't Watched in a While
Recent Activity
Statistics
```

If each client independently implemented these rules, SofaWatch would risk producing different results depending on whether the action was performed through Web, iOS, Android, or a future client.

The same problem applies to security.

A Flutter client can hide an Administrator button, but it cannot be trusted to enforce Administrator authorization.

SofaWatch therefore needs one authoritative location for persisted state and application business rules.

---

## Decision

The **SofaWatch backend is the source of truth for persisted application state and business rules**.

Clients may maintain local presentation and application state for responsiveness, but that state is a representation of backend-owned truth rather than an independent authority.

Conceptually:

```text
Web ───────┐
           │
iOS ───────┼──> SofaWatch Backend ───> Persisted State
           │
Android ───┘
```

Business rules that affect persisted state or cross-feature consistency belong on the backend.

The backend validates mutations, applies business rules, persists results, and returns authoritative state.

---

## What "Source of Truth" Means

The decision does **not** mean every UI decision belongs on the backend.

It means that when a question concerns persisted SofaWatch state or application-wide business semantics, the backend is authoritative.

Examples:

```text
Is this Episode watched?
How many times was it watched?
What was the latest watched_at?
Does this Library entry belong to this user?
Is this user allowed to perform this Admin action?
What counts as a rewatch?
What is the user's viewing history?
What data contributes to Statistics?
```

These are backend-owned questions.

---

## What the Frontend Owns

Flutter remains responsible for client-side concerns such as:

- visual state;
- navigation;
- responsive/adaptive presentation;
- selected tabs;
- modal/sheet behavior;
- scroll position;
- temporary form state;
- loading indicators;
- optimistic presentation where explicitly safe;
- presentation-specific grouping;
- local interaction state.

Examples:

```text
selected Shows tab
expanded Season accordion
Search modal open/closed
current scroll position
desktop dialog vs mobile bottom sheet
per-row loading indicator
```

These do not need to be persisted as backend business state unless a product requirement explicitly says otherwise.

---

## Backend-Owned Business Rules

Examples of rules that belong on the backend include:

### Viewing Events

Each viewing is represented by a real watch event.

```text
first watch
-> event A

rewatch
-> event B

rewatch
-> event C
```

The frontend does not calculate a rewatch by incrementing a local counter.

---

### Watched State

Values such as:

```text
is_watched
watch_count
watched_at
```

are backend-owned.

When a viewing event is created or removed, the backend determines the resulting state.

---

### Library State

The backend determines whether a Show or Movie is in a user's Library and enforces the valid relationship.

The frontend does not become authoritative simply because it displays a filled Library icon.

---

### Progress

Episode, Season, and Show progress is derived from persisted backend state.

Flutter may display progress and temporarily reflect a successful mutation, but it should not create an independent progress algorithm that can disagree with the server.

---

### Watch Next

Eligibility and ordering rules for Watch Next are backend business rules.

Examples include:

- caught-up Shows should not appear;
- a new Episode can make a Show eligible again;
- an ended Show may still have unwatched Episodes;
- absence of a known next Episode should not create invented content.

---

### Statistics

Statistics are computed from authoritative persisted viewing data.

Flutter should not independently recalculate the complete Statistics model from whichever subset of history happens to be loaded on screen.

---

### Authorization

Administrator authorization is enforced by the backend.

Frontend visibility:

```text
user.isAdmin
```

improves UX and prevents unnecessary requests.

It is not a security boundary.

---

## Mutation Flow

A normal mutation should conceptually follow:

```text
User action
    |
    v
Flutter application layer
    |
    v
Repository
    |
    v
Backend API
    |
    v
Service / business rules
    |
    v
Repository / database
    |
    v
Authoritative response
    |
    v
Flutter state refresh/reconciliation
```

The client should reconcile affected state with the result of the authoritative mutation.

---

## Example: Mark Episode Watched

The incorrect model would be:

```text
Flutter
  |
  +--> is_watched = true
  +--> watch_count += 1
  +--> watched_at = now
  +--> update progress locally
  +--> guess next Episode
  |
  v
send something to backend
```

This makes Flutter an independent business-rule engine.

The intended model is:

```text
Flutter
  |
  v
request viewing mutation
  |
  v
Backend creates watch event
  |
  +--> recalculates watched state
  +--> persists history
  +--> updates/derives progress
  +--> applies Watch Next rules
  |
  v
authoritative result
  |
  v
Flutter refreshes/reconciles affected views
```

---

## Example: Rewatch

A rewatch is not:

```text
watch_count = watch_count + 1
```

as an isolated frontend operation.

It is:

```text
create another viewing event
```

The backend then derives the aggregate watched state.

This ensures History and Statistics remain consistent.

---

## Example: Removing a Watch Event

Removing one viewing can change:

```text
watch_count
watched_at
is_watched
progress
Statistics
Watch Next
```

The frontend should not try to reverse all these values independently.

The backend removes the event and derives the resulting authoritative state.

---

## User-Scoped Data

User-owned resources are scoped from authenticated backend identity.

Examples:

- Library;
- progress;
- viewing history;
- ratings;
- Statistics;
- sessions.

Normal client requests should not choose an arbitrary `user_id` to determine ownership.

Conceptually:

```text
authenticated credential
        |
        v
CurrentUserDependency
        |
        v
current User
        |
        v
user-scoped operation
```

This prevents the client from becoming the authority for data ownership.

---

## Authentication

The backend owns authentication validity.

The frontend may store or transport credentials according to the authentication model, but it does not decide whether they are valid.

Examples:

```text
access token validity
AuthSession validity
refresh credential rotation
session revocation
Open Registration
Administrator authorization
recovery-token validity
handoff-token validity
```

are backend-owned.

See [ADR-005](005-authentication-model.md).

---

## Metadata Providers

External providers are not the SofaWatch source of truth for user state.

TMDB may provide metadata such as:

- title;
- overview;
- poster;
- air date;
- Episode metadata.

But TMDB does not determine:

```text
whether Gonçalo watched an Episode
whether a Movie is in a user's Library
personal rating
SofaWatch user permissions
```

Provider data enters SofaWatch through backend integration boundaries.

---

## Imported Media

After import, SofaWatch maintains local entities using internal IDs.

The provider may remain authoritative for some external metadata fields during synchronization, but the local entity identity and user-owned application state belong to SofaWatch.

See [ADR-003](003-internal-media-ids.md) and [ADR-006](006-provider-independence.md).

---

## Frontend Caching

Frontend state may cache backend data for UX/performance.

Examples:

```text
Search results
Show Details
Library preview
Statistics summary
History preview
```

Cached state does not become authoritative merely because it is already loaded.

A successful mutation may require:

- targeted local reconciliation;
- refetch;
- invalidation;
- coordinated refresh.

The correct strategy depends on the feature.

---

## Optimistic UI

Optimistic UI is allowed only when it preserves a clear path back to backend truth.

For a mutation:

```text
optimistic visual update
        |
        v
backend request
        |
        +-- success --> reconcile
        |
        +-- failure --> rollback/error
```

Do not use optimistic updates when the client cannot reliably predict the resulting business state.

For complex cross-feature mutations, waiting for the backend result may be simpler and safer.

---

## Derived UI State

The frontend may derive presentation state from backend data.

Example:

```text
backend:
is_watched = true
watch_count = 3

frontend:
show "3×"
```

The display format is presentation logic.

The value `3` remains backend-owned.

---

## Dates and Time

Clients may format dates according to locale and presentation needs.

However, persisted timestamps and business comparisons should use backend-defined semantics.

For example:

```text
watched_at
```

is persisted by the backend.

The UI decides whether to display:

```text
Today, 21:30
```

or:

```text
27 Aug 2026
```

but it should not silently rewrite the stored event timestamp.

---

## Current Time in Mutations

Where the product action means:

```text
Watched now
```

the backend should own the persisted timestamp semantics rather than trusting an arbitrary client clock unless the endpoint explicitly supports user-selected dates.

This prevents different device clocks from becoming independent sources of truth.

---

## Cross-Feature Consistency

One mutation may affect multiple features.

Example:

```text
Mark Episode Watched
    |
    +--> Show Details
    +--> Watch Next
    +--> Watch History
    +--> Home
    +--> Statistics
```

The backend ensures the underlying state is coherent.

The frontend still needs a synchronization strategy so currently loaded screens reflect that truth.

This is a client state-management concern, not a reason to duplicate the backend business rule.

---

## Partial Refresh

Backend source-of-truth does not imply that every mutation must reload the entire application.

Prefer the smallest correct reconciliation.

Examples:

```text
refresh affected Season
refresh Watch Next
reload History preview
invalidate Statistics summary
```

rather than:

```text
reload everything
```

when targeted updates are sufficient.

---

## Offline Behavior

SofaWatch does not currently define a fully offline-first synchronization model.

Therefore the frontend should not maintain a second independently writable database of SofaWatch business state and later attempt arbitrary conflict resolution.

If offline-first support becomes a product goal, it will require a separate architectural decision defining:

- local persistence;
- mutation queues;
- conflict resolution;
- timestamps/versioning;
- synchronization guarantees.

That is outside the current architecture.

---

## Background Jobs

Background jobs also operate through backend business/services/repositories.

A background worker is another backend execution path, not an independent source of truth.

Conceptually:

```text
HTTP API ───────┐
                │
                v
        backend business rules
                ^
                │
Worker ─────────┘
```

Where possible, shared application behavior should be implemented in reusable backend services rather than duplicated between route handlers and jobs.

---

## Import / Export

Import is a backend-owned mutation process.

The frontend may:

- select a file;
- request preview;
- display progress;
- display conflicts;
- display partial failures.

The backend owns:

- validation;
- version interpretation;
- deduplication rules;
- persisted mutations;
- user scoping.

Similarly, Export should be generated from authoritative persisted backend data.

---

## Error Handling

The backend owns the semantic result of an operation.

Expected failures should be represented through the normalized API error contract.

Flutter maps those failures into `AppException` and presentation states.

The frontend should not reinterpret:

```text
403
```

as:

```text
maybe the user is actually allowed
```

or otherwise override backend authorization/business decisions.

See [API Errors](../api/errors.md).

---

## Consequences

### Positive

#### Consistent Behavior Across Platforms

Web, iOS, and Android use the same business rules.

#### Security

Authorization cannot be bypassed by modifying Flutter UI/client state.

#### Easier Maintenance

A business rule is implemented once rather than separately in every client.

#### Reliable Statistics and History

All clients mutate the same persisted event/state model.

#### Easier Future Clients

A future client can use the API without reimplementing the entire SofaWatch domain.

#### Provider Isolation

External APIs remain data sources rather than owners of SofaWatch user state.

---

### Trade-offs

#### Network Dependency

Most meaningful mutations require backend availability.

SofaWatch is not currently an offline-first application.

#### State Reconciliation

Flutter must carefully update or refresh affected feature state after mutations.

#### Backend Complexity

The backend carries more domain/business responsibility than a thin CRUD API.

This complexity is intentional.

#### API Contract Matters

Changing backend behavior can affect all clients, so API semantics and regression tests are important.

---

## Alternatives Considered

### Client-Owned Business Logic

Each Flutter client could calculate progress, Watch Next, Statistics, and related behavior locally.

Rejected because it would:

- duplicate logic;
- create platform inconsistencies;
- complicate future clients;
- weaken authorization boundaries;
- make cross-feature state harder to reason about.

---

### Thin CRUD Backend

The backend could expose database records while leaving interpretation to clients.

Rejected because SofaWatch has real domain rules.

Examples:

```text
rewatches
caught-up behavior
Ended vs Completed
Library ownership
session revocation
```

are not merely CRUD concerns.

---

### Provider as Source of Truth

TMDB or another metadata provider could be queried directly by clients and treated as authoritative.

Rejected because providers do not own SofaWatch user state and because this would tightly couple clients to provider contracts.

It would also complicate future TVDB/IMDb integration.

---

### Shared Business Logic Package Across Clients and Backend

A shared implementation could theoretically attempt to execute identical business rules on Python and Dart clients.

This is not practical enough to justify the complexity and still would not remove the need for server authority over persisted state and authorization.

---

## Revisit When

The principle itself should be reconsidered only if SofaWatch's application model changes substantially.

Possible examples:

### Offline-First Becomes a Core Requirement

If users must be able to perform extensive mutations without server connectivity, SofaWatch would need a deliberate synchronization architecture.

The backend could remain authoritative eventually, but the definition of source of truth and conflict resolution would need expansion.

### Peer-to-Peer Architecture

If SofaWatch moves away from a central self-hosted server toward peer-to-peer replicated state, this ADR would no longer describe the complete system.

### Local-Only Client

If a future product mode intentionally runs without any backend, it would require a separate architecture rather than quietly moving rules into Flutter.

Normal UI evolution is not a reason to revisit this decision.

---

## Implementation Constraints

Code written under this decision should follow these rules:

```text
[ ] persisted business state is backend-owned
[ ] authorization is enforced by the backend
[ ] user ownership comes from authenticated identity
[ ] Flutter does not independently recreate core business rules
[ ] watch events are mutated through backend APIs
[ ] aggregate watched state is derived authoritatively
[ ] Statistics use backend-owned persisted data
[ ] provider metadata does not own user state
[ ] frontend caches remain reconcilable with backend truth
[ ] cross-feature mutations use deliberate refresh/reconciliation
[ ] offline-first synchronization is not introduced accidentally
```

---

## Relationship to Other Decisions

### SQLite

[ADR-001](001-sqlite.md) defines SQLite as the primary database holding the backend's persisted state.

Clients do not access SQLite directly.

### Internal Media IDs

[ADR-003](003-internal-media-ids.md) gives SofaWatch ownership of local media identity after import.

### Global Search

[ADR-004](004-global-search.md) defines one global Search experience while the backend/provider layer owns Search data normalization.

### Authentication

[ADR-005](005-authentication-model.md) defines how the backend establishes and maintains authenticated identity.

### Provider Independence

[ADR-006](006-provider-independence.md) keeps provider-specific data behind backend integration boundaries.

---

## Related Documentation

- [Documentation Index](../README.md)
- [Architecture Overview](../architecture/overview.md)
- [Backend Architecture](../architecture/backend.md)
- [Frontend Architecture](../architecture/frontend.md)
- [Data Flow](../architecture/data-flow.md)
- [Database Architecture](../architecture/database.md)
- [Frontend API Contract](../api/frontend-contract.md)
- [API Errors](../api/errors.md)
- [Viewing Progress](../features/viewing-progress.md)
- [Implementation Status](../features/implementation-status.md)
