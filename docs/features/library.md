# Library

## Overview

The SofaWatch Library stores the TV Shows and Movies that a user has chosen to track.

It is a user-scoped feature and represents local SofaWatch state, not raw metadata-provider state.

A media item can exist locally in SofaWatch without being in a user's Library.

Conceptually:

```text
Provider result
      |
      v
Import
      |
      v
Local SofaWatch Show / Movie
      |
      v
Optional Library entry
```

Importing media and adding media to the Library are intentionally separate operations.

This separation is important for Search, Explore, Details, History, and future provider integrations.

See:

- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)
- [ADR-003: Internal SofaWatch Media Identifiers](../decisions/003-internal-media-ids.md)

---

## Status

**Implemented / Validation**

The core Library feature supports both TV Shows and Movies and is user-scoped.

Implemented:

- TV Show Library entries;
- Movie Library entries;
- add/remove operations;
- tracking/watchlist state;
- user ownership;
- local internal media IDs;
- frontend Library previews;
- Profile Library integration;
- Library-aware Search/Explore/Details actions.

Remaining work is mainly around final grouping, visual consistency, responsive validation, and a few state-synchronization refinements.

See [Implementation Status](implementation-status.md).

---

# Goals

The Library is designed to:

- track media the authenticated user cares about;
- support both Shows and Movies;
- preserve per-user state;
- use local SofaWatch media identity after import;
- remain separate from Search/Explore provider results;
- support status-based organization;
- integrate with viewing progress and history;
- provide reusable Library state across Home, Shows, Movies, Search, Explore, and Profile;
- keep business rules authoritative on the backend.

---

# User Scoping

Library entries belong to the authenticated user.

Conceptually:

```text
User A
├── Show 1 -> Watching
├── Show 2 -> Planning
└── Movie 1 -> Watchlist

User B
├── Show 1 -> Completed
└── Movie 1 -> Watched
```

The same media can therefore exist in multiple users' Libraries with independent state.

The backend derives ownership from authenticated identity.

Normal Library operations should not trust an arbitrary user ID supplied by the client.

---

## Multi-User

SofaWatch is fully multi-user.

The previous legacy concept of a fixed local user has been removed.

Do not reintroduce:

```text
Local User
is_local
isLocal
```

Library relationships remain tied to real user IDs.

---

# Media Types

Library supports:

```text
TV Shows
Movies
```

A Library entry references exactly one media type.

Conceptually:

```text
show_id XOR movie_id
```

Valid:

```text
show_id = 42
movie_id = null
```

or:

```text
show_id = null
movie_id = 17
```

Invalid:

```text
show_id = 42
movie_id = 17
```

and:

```text
show_id = null
movie_id = null
```

The backend/database layer should preserve this invariant.

---

# Internal Media Identity

Library entries reference SofaWatch internal IDs.

Example:

```text
TMDB Show ID 1399
        |
        v
Import
        |
        v
SofaWatch Show ID 42
        |
        v
LibraryEntry.show_id = 42
```

Provider IDs are not the primary identity of Library relationships.

See [ADR-003](../decisions/003-internal-media-ids.md).

---

# Import vs Library Membership

These are distinct concepts.

A Show or Movie can be:

```text
imported locally
but
not in the user's Library
```

This is useful because local media may exist due to:

- Search preview;
- Explore interaction;
- shared metadata use;
- another user's Library;
- import before a later mutation.

Library membership is user-specific.

---

# Add to Library

A provider-backed result may need to be imported before it can be added to the Library.

Conceptually:

```text
Search / Explore result
        |
        v
resolve/import local media
        |
        v
SofaWatch internal ID
        |
        v
create Library entry
```

The frontend should not treat the provider result itself as the persisted Library entity.

---

# Remove from Library

Removing media from the Library removes the user's tracking relationship.

It does not necessarily mean:

- delete the local Show/Movie;
- delete metadata;
- delete viewing history;
- delete another user's Library entry.

These are separate concerns.

The exact cleanup behavior belongs to backend business rules.

---

# TV Show Tracking States

TV Show Library entries can use tracking states such as:

```text
Planning
Watching
Completed
Dropped
```

`Paused` has been deliberately deferred.

If historical code/data still contains a paused-like state, it should not automatically become a new product feature without an explicit decision.

---

## Planning

Planning means the user intends to watch the Show but has not started normal viewing progress.

Planning Shows may appear in appropriate discovery/upcoming contexts.

They should not automatically count as missed viewing activity.

---

## Watching

Watching indicates active tracking.

Watching Shows participate in features such as:

- Watch Next;
- Haven't Watched in a While;
- Upcoming;
- Missed Recently;
- progress views.

---

## Completed

Completed means the user's tracking state says the Show is complete for them.

This is not the same as the provider's Show status.

Important distinction:

```text
provider status = Ended
!=
user state = Completed
```

A Show can have ended while the user still has unwatched Episodes.

---

## Dropped

Dropped means the user no longer intends to continue normal tracking.

Dropped content should not be treated as actively Watching.

Exact visibility in historical/library contexts depends on the feature.

---

# Ended vs Completed

This distinction is a core product rule.

```text
Ended
-> provider/content lifecycle

Completed
-> user's Library/tracking state
```

Therefore:

```text
Ended + unwatched Episodes
```

can still require progress handling.

Do not automatically mark a Show Completed because TMDB reports it has ended.

---

# Caught Up / Up to Date

A Watching Show can be:

```text
caught up
```

when the user has watched all currently aired/eligible Episodes.

This is a derived progress condition, not necessarily a separate persisted Library tracking state.

A caught-up Show should not appear in Watch Next when there is no eligible next Episode.

When a new Episode becomes available, it may become actionable again.

---

# TV Show Library Organization

The full Shows Library can be organized into useful user-facing groups such as:

```text
Watching
Up to Date
Haven't Started
Finished
```

These are presentation/domain groupings and may derive from both Library state and viewing progress.

They do not all need to map one-to-one to persisted enum values.

---

## Watching Group

Contains Shows actively being watched and not currently caught up/completed according to the final grouping rules.

---

## Up to Date Group

Contains Watching Shows where the user has watched all currently eligible aired Episodes.

Final visual consistency for this grouping remains a validation area.

---

## Haven't Started Group

Contains Library Shows the user has not yet started.

This may correspond primarily to Planning state plus no watch progress.

---

## Finished Group

Contains Shows the user has completed.

Do not confuse provider-ended Shows with user-finished Shows.

---

# Movie Library

Movies use a different product model from episodic TV.

Useful Movie Library groupings include:

```text
Watchlist
Upcoming
Watched
```

The exact UI grouping can evolve, but Movie Library state remains separate from TV tracking-state semantics where appropriate.

---

## Movie Watchlist

A Movie can be in the user's Library/watchlist before being watched.

This is independent from whether the Movie already exists locally.

---

## Movie Upcoming

Future/unreleased Movies can be represented in Library-oriented discovery if reliable release-date metadata exists.

Do not invent release times or statuses beyond provider data.

---

## Movie Watched

Movie watched state is derived from Movie watch events.

A watched Movie can still remain part of Library/history according to the product experience.

---

# Library and Viewing Progress

Library membership and viewing progress are related but distinct.

Example:

```text
Show in Library
-> Planning
-> no Episode events yet
```

versus:

```text
Show in Library
-> Watching
-> Episode history exists
```

Progress should be derived from authoritative backend watch-event state.

See [Viewing Progress](viewing-progress.md).

---

# Library and Watch List

Watch List is derived from Library + viewing state.

Examples:

```text
Watching + next eligible Episode
-> Watch Next

Watching + inactive
-> Haven't Watched in a While

Planning + no progress
-> Haven't Started
```

Library does not need to duplicate these derived collections inside its own persistence model.

See [Watch List](watch-list.md).

---

# Library and Upcoming

Upcoming uses tracked Shows and Episode air dates.

Library status affects whether a Show is relevant to the user's upcoming context.

Examples:

```text
Watching
-> normal Upcoming relevance

Planning
-> can appear in appropriate Upcoming/Home "premiering" contexts

Dropped
-> normally not active tracking
```

Exact inclusion rules belong to backend/application logic.

---

# Library and Search

Search can show Library state/actions for provider-backed results.

However:

```text
Search
-> owns Search state

Library
-> owns Library mutations
```

SearchBloc should not become the source of truth for Library membership.

A known future refinement is synchronizing Search rows after Library mutation without rerunning Search.

See [Search](search.md).

---

# Library and Explore

Explore cards can expose Add/Remove Library actions.

The mutation still belongs to Library/application logic.

Explore should reconcile the affected card after backend success without becoming the owner of Library business rules.

See [Explore](explore.md).

---

# Library and Details

Show Details and Movie Details display current Library state and can expose Library mutations.

After a successful mutation, Details should reflect the backend result.

Other currently loaded feature states may also require targeted reconciliation.

---

# Profile Library Preview

Profile can expose compact recent Library previews for:

```text
Shows
Movies
```

The preview is not the full Library feature.

It should use reusable Library data and navigate to the appropriate full Library/details experience.

---

# Backend Responsibility

The backend owns:

- user scoping;
- media relationship validation;
- state validation;
- add/remove persistence;
- tracking-state changes;
- derived Library/business rules;
- conflicts;
- authorization;
- internal ID relationships.

Flutter should not independently redefine these rules.

See [ADR-002](../decisions/002-backend-source-of-truth.md).

---

# Repository Layer

The backend repository layer handles persistence operations such as:

- create Library entry;
- find existing entry;
- list entries;
- filter entries;
- update tracking state;
- delete entry;
- user-scoped lookup.

Services should own business orchestration where rules go beyond simple persistence.

---

# API

Library APIs are versioned under:

```text
/api/v1
```

Exact routes and schemas are defined by the running OpenAPI documentation.

The API contract should use local SofaWatch media identity for normal local Library operations.

Provider IDs belong at provider/import boundaries.

---

# Frontend Architecture

Library follows the Flutter feature structure:

```text
library/
├── presentation/
├── application/
├── domain/
└── data/
```

Responsibilities:

```text
presentation
-> Library UI, groups, cards, actions

application
-> Cubits/state/orchestration

domain
-> Library entities and repository contracts

data
-> DTOs, API repository, mapping
```

Domain code should not depend on Dio or raw JSON.

---

# Library Preview State

Profile/Home-style previews should be independently loadable.

A Library preview failure should not make unrelated Profile sections fail.

This follows the broader independent-section failure strategy.

---

# Mutations

Library mutations include:

```text
add
remove
change tracking state
```

Each mutation should:

1. validate current backend state;
2. persist authoritative change;
3. return/enable reconciliation of the result;
4. update the relevant frontend state;
5. avoid duplicate submission while pending where necessary.

---

# Duplicate Add

Adding the same media repeatedly should not create duplicate Library entries for the same user/media combination.

The backend should enforce uniqueness/idempotent behavior according to the current endpoint semantics.

The frontend should still avoid unnecessary duplicate requests.

---

# Removing Missing Entries

Removing a Library entry that does not exist should produce a safe not-found/conflict result according to the API contract.

The frontend should not crash or fabricate success.

---

# Tracking-State Changes

Changing tracking state may affect derived collections.

Example:

```text
Planning -> Watching
```

can affect:

- Watch Next;
- Haven't Started;
- Upcoming;
- Home.

Frontend synchronization should refresh/reconcile affected features without duplicating backend rules.

---

# Partial Cross-Feature Refresh

If the Library mutation succeeds but a secondary refresh fails:

```text
Library mutation = success
Watch Next refresh = failure
```

the user should not be told that the Library mutation itself failed.

Primary and secondary failures should remain semantically distinct where possible.

---

# Loading States

Library UI should distinguish:

- initial loading;
- successful data;
- empty Library/group;
- mutation loading;
- refresh loading;
- failure;
- Retry.

A per-item mutation should not necessarily block the whole Library screen.

---

# Empty States

Empty states should reflect the current context.

Examples:

```text
No Shows in Library
No Movies in Watchlist
No completed Shows
No Up to Date Shows
```

Avoid showing a generic network-style error for a legitimate empty collection.

---

# Errors

Library errors use the common SofaWatch error architecture.

Relevant cases include:

- network failure;
- timeout;
- unauthorized;
- not found;
- conflict;
- validation;
- server failure;
- invalid response.

See [API Errors](../api/errors.md).

---

# Retry

Retry should repeat the failed Library load or secondary refresh.

For mutation failures, Retry behavior should consider whether the mutation endpoint is safe to repeat.

Do not blindly replay uncertain non-idempotent requests after a send/receive timeout without understanding endpoint semantics.

---

# Ordering

Backend ordering should be deterministic where business ordering matters.

Presentation group ordering may be decided by the Library feature.

Examples:

```text
Watching
Up to Date
Haven't Started
Finished
```

The final section ordering should remain consistent across responsive layouts.

---

# Responsive Design

Library should adapt to:

- mobile;
- tablet/narrow desktop;
- desktop;
- ultrawide displays.

Mobile concerns include:

- compact cards/rows;
- long titles;
- accessible action buttons;
- safe areas;
- reasonable vertical density.

Desktop concerns include:

- limiting content width;
- avoiding excessively stretched rows;
- useful grid/list density;
- clear grouping.

---

# Navigation

Library media navigates using SofaWatch internal IDs.

Conceptually:

```text
Library Show
-> Show Details(local show ID)

Library Movie
-> Movie Details(local movie ID)
```

Provider IDs should not be used as if they were local navigation identity after import.

---

# Search/Explore Preview Reconciliation

A Library mutation from a Search/Explore preview should update the preview immediately after backend success.

The originating Search/Explore list may also need reconciliation.

This should be handled through clean cross-feature synchronization rather than merging feature ownership.

---

# Import Idempotency

Library depends on import being safe for already-known provider media.

Example:

```text
provider result
-> import
-> local Show 42

same provider result later
-> import
-> local Show 42
```

not another duplicate local entity.

Library creation then references the existing local media.

---

# Multi-Provider Future

Future TVDB/IMDb work should not change Library identity.

Library continues to reference SofaWatch internal media.

Provider mappings can evolve independently.

This is one of the main reasons Library does not key relationships directly to TMDB IDs.

See [ADR-006](../decisions/006-provider-independence.md).

---

# Genres and Library

Genre metadata can be used for filtering/statistics, but Library ownership is not defined by provider genre IDs.

Genres are internal/mapped metadata concepts.

Future Library filters should use stable SofaWatch-facing genre semantics.

---

# Statistics

Library contributes to Library Statistics such as:

- Shows added;
- Movies added;
- Shows completed.

These metrics should be calculated by the Statistics feature/backend rather than independently inside the Library UI.

---

# History Preservation

Removing media from Library should not automatically imply deleting its watch history unless a product rule explicitly defines that destructive behavior.

Library membership and viewing history are different concepts.

The same principle applies to personal ratings.

Data deletion semantics should remain explicit.

---

# Future User Administration

An Administrator managing another user's account in the future should not automatically gain an implicit "edit this user's Library" capability unless explicitly designed.

Normal Library APIs remain self-scoped by authenticated user.

---

# Testing

Backend Library tests should cover:

```text
user scoping
Show entries
Movie entries
show_id XOR movie_id invariant
duplicate prevention
add
remove
state change
filter/list behavior
not-found behavior
cross-user isolation
internal ID usage
```

Frontend tests should cover:

```text
initial load
success
empty states
failure
Retry
Show grouping
Movie grouping
add/remove action
mutation loading
mutation failure
Details navigation
admin/user independence
responsive behavior
```

Cross-feature regression tests should protect important synchronization behavior.

---

# Future Work

## Shows Library

```text
[ ] final Up to Date presentation validation
[ ] final grouping/order validation
[ ] caught-up edge cases
[ ] Ended/Completed edge cases
[ ] no-known-next-Episode behavior
[ ] mobile responsive validation
[ ] desktop/ultrawide validation
```

---

## Movies Library

```text
[ ] final Watchlist / Upcoming / Watched organization
[ ] responsive validation
[ ] richer Movie discovery integration where useful
```

---

## Cross-Feature Synchronization

```text
[ ] Search row reconciliation after Library mutation
[ ] preserve Search query/filter/pages/scroll
[ ] validate Explore reconciliation
[ ] validate Home/Profile preview refresh behavior
```

---

## Filters and Large Libraries

Possible future improvements:

```text
[ ] local Library search/filter if real Library size requires it
[ ] additional status filters
[ ] sorting controls if useful
```

These should remain distinct from global provider-backed Search.

---

# Notes

> Library is user-scoped. The same Show or Movie can exist in several users' Libraries with independent state.

> Importing media and adding it to Library are separate operations.

> Library uses SofaWatch internal media IDs after import.

> `Ended` is provider state; `Completed` is user tracking state.

> `Up to Date` is primarily a derived progress grouping, not necessarily a standalone persisted tracking state.

> `Paused` remains deliberately deferred.

> Removing Library membership should not implicitly erase History or other unrelated user data.

> Search and Explore may trigger Library actions, but Library remains the owner of Library business rules.

---

# Related Documentation

- [Implementation Status](implementation-status.md)
- [Search](search.md)
- [Explore](explore.md)
- [Viewing Progress](viewing-progress.md)
- [Watch List](watch-list.md)
- [Upcoming](upcoming.md)
- [Movies](movies.md)
- [Profile](profile.md)
- [Statistics](statistics.md)
- [Architecture Overview](../architecture/overview.md)
- [Database Architecture](../architecture/database.md)
- [Data Flow](../architecture/data-flow.md)
- [Frontend API Contract](../api/frontend-contract.md)
- [API Errors](../api/errors.md)
- [ADR-001: SQLite](../decisions/001-sqlite.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)
- [ADR-003: Internal SofaWatch Media Identifiers](../decisions/003-internal-media-ids.md)
- [ADR-006: Provider-Independent Domain Architecture](../decisions/006-provider-independence.md)
