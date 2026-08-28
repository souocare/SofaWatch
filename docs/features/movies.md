# Movies

## Overview

Movies is SofaWatch's movie tracking domain.

It covers the lifecycle from discovering or searching for a Movie through importing it into SofaWatch, tracking it in the user's Library, recording viewings and rewatches, displaying Movie Details, and feeding History and Statistics.

The main conceptual separation is:

```text
Movie identity
Library / Watchlist state
Viewing state
Viewing history
Personal rating
External metadata / ratings
```

These concepts are related, but they are not the same state.

See:

- [Library](library.md)
- [Viewing Progress](viewing-progress.md)
- [History](history.md)
- [Statistics](statistics.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)
- [ADR-003: Internal Media IDs](../decisions/003-internal-media-ids.md)
- [ADR-006: Provider Independence](../decisions/006-provider-independence.md)

---

## Status

**Implemented / Evolving**

Implemented or established:

- internal Movie model;
- Movie repository/data layer;
- Movie DTOs/mapping;
- TMDB Movie import;
- idempotent TMDB import;
- Movie Library support;
- Movie watchlist behavior;
- Movie Details infrastructure;
- Movie watched state;
- `MovieWatchEvent`;
- Movie viewing history;
- Movie rewatches;
- integration with global History;
- integration with Statistics;
- Search and Explore Movie support.

Future work is mainly richer Movie-specific discovery/details, final responsive validation, external ratings/provider work, and any additional Library presentation refinements.

See [Implementation Status](implementation-status.md).

---

# Goals

The Movies feature should allow the user to:

- discover Movies;
- search for Movies;
- preview provider results;
- import a Movie into SofaWatch;
- add/remove it from their Library;
- maintain a Movie watchlist;
- record a viewing;
- record rewatches;
- inspect viewing history;
- rate Movies personally;
- see useful external metadata;
- distinguish personal ratings from provider ratings;
- use Movie activity throughout Home, History, Statistics, and Profile.

---

# Movie Identity

Once imported, a Movie receives an internal SofaWatch ID.

Conceptually:

```text
TMDB Movie
    |
    v
import
    |
    v
SofaWatch Movie
id = internal ID
    |
    +-> TMDB identifier
    +-> future IMDb identifier
    +-> future provider mappings
```

Core application relationships should reference the internal Movie ID.

See [ADR-003: Internal Media IDs](../decisions/003-internal-media-ids.md).

---

# Import vs Library

Importing a Movie and adding it to a user's Library are separate operations.

Conceptually:

```text
provider result
    |
    v
import Movie
    |
    v
local Movie entity
    |
    v
optional Library membership
```

This distinction is important in a multi-user application.

A Movie can exist once locally while different users independently decide whether to track it.

---

# TMDB Import

TMDB is currently the primary Movie metadata provider.

Movie import is available through the backend using the TMDB identifier.

The import endpoint is conceptually:

```text
POST /api/v1/movies/import/tmdb/{tmdb_id}
```

Import is idempotent.

Repeatedly importing the same provider Movie should resolve to the existing local Movie rather than creating duplicate SofaWatch Movies.

---

# Idempotency

Conceptually:

```text
import TMDB 123
-> local Movie 42

import TMDB 123 again
-> local Movie 42
```

This protects Search, Explore, preview, and Library workflows from accidentally creating duplicate media entities.

Provider mappings/constraints should enforce the invariant at the backend/database level where appropriate.

---

# Provider Independence

Although TMDB currently supplies Movie metadata, the domain should not become permanently TMDB-specific.

The intended direction is:

```text
SofaWatch Movie
    |
    +-> External identifier: TMDB
    +-> External identifier: IMDb
    +-> future providers
```

Flutter and core Movie business logic should operate on normalized SofaWatch models.

See [ADR-006: Provider Independence](../decisions/006-provider-independence.md).

---

# Search Integration

Global Search supports Movies.

The flow can be:

```text
Search
-> provider Movie result
-> preview
-> import if required
-> Library action / Movie Details
```

Search remains a global feature.

Movies must not introduce a second independent Search implementation.

See [Search](search.md).

---

# Explore Integration

Explore can expose:

- Trending Movies;
- Popular Movies;
- genre-filtered Movie discovery;
- Movie previews;
- Library actions.

Future Movie discovery can add richer recommendation sections without turning Movies into a duplicate Explore implementation.

See [Explore](explore.md).

---

# Library

Movies participate in the user-scoped Library.

A Library entry references either a Show or a Movie, never both.

Conceptually:

```text
LibraryEntry
    |
    +-> show_id
    OR
    +-> movie_id
```

The XOR invariant should remain enforced.

See [Library](library.md).

---

# Movie Library State

Movie Library state is separate from watched state.

For example:

```text
Movie in Watchlist
watched = false
```

and:

```text
Movie still in Library
watched = true
```

can both be valid depending on product behavior.

The frontend should not infer Library membership merely from the existence of a watch event.

---

# Movie Library Organization

The intended/full Movie Library presentation can organize content into concepts such as:

```text
Watchlist
Upcoming
Watched
```

These are presentation/business classifications over the user's Movie Library and Movie viewing state.

They should not become unnecessary duplicate persistence models unless a real product requirement demands it.

---

# Watchlist

The Movie watchlist represents Movies the user intends to watch.

It is different from:

- the Movie existing locally;
- the Movie having been watched;
- a personal rating;
- provider popularity/trending state.

Watchlist mutations are user-scoped.

---

# Upcoming Movies

The Movie Library may eventually expose upcoming/unreleased Movies separately.

This requires reliable release-date semantics and should use normalized Movie metadata.

It should not invent regional release dates or availability information that the provider does not supply reliably.

---

# Watched Movies

A Movie becomes watched through real viewing events.

The canonical history is not a single Boolean.

Conceptually:

```text
MovieWatchEvent
```

is the source from which effective watched state and rewatch information can be derived.

---

# Movie Watch Events

Every Movie viewing is represented as an individual event.

Example:

```text
Movie
    |
    +-> viewing A
    +-> viewing B
    +-> viewing C
```

This supports:

- first watches;
- rewatches;
- chronological History;
- Statistics;
- viewing timestamps;
- corrections.

---

# First Watch

The first Movie viewing creates the first `MovieWatchEvent`.

Conceptually:

```text
unwatched Movie
    |
    v
Mark Watched
    |
    v
MovieWatchEvent A
```

Afterward the Movie is effectively watched.

---

# Rewatch

Rewatch creates another `MovieWatchEvent`.

It does not overwrite the first viewing.

```text
first watch
-> event A

rewatch
-> event B

rewatch
-> event C
```

Statistics can therefore distinguish total Movie viewings from unique Movies watched.

---

# Movie Watched State

Conceptually:

```text
0 events
-> unwatched

1 event
-> watched once

N events
-> watched with N - 1 rewatches
```

Where the API exposes derived fields such as watch count/latest watched timestamp, those values remain backend truth.

---

# Watched At

The effective latest watched timestamp is the timestamp of the most recent remaining Movie viewing event.

Example:

```text
A = January
B = March
C = August

watched_at = August
```

If C is removed:

```text
watched_at = March
```

---

# Removing a Movie Viewing

Individual Movie viewing events can be removed for history correction.

Deleting one event should not erase unrelated viewings.

Example:

```text
A
B
C

delete B

remaining:
A
C
```

The backend recalculates effective Movie viewing state.

---

# Removing the Final Viewing

If the final `MovieWatchEvent` is removed:

```text
watch_count = 0
watched_at = null
watched = false
```

Library membership should not automatically disappear merely because viewing history was corrected.

---

# Mark Unwatched

Any Movie Unwatch behavior must remain compatible with event-based history.

If multiple legitimate viewings exist, a generic Unwatch operation should not silently destroy all historical events unless that destructive behavior is explicitly defined and confirmed.

Precise event deletion is preferable for historical correction.

---

# Movie Details

Movie Details is the primary local Movie inspection experience.

It can bring together:

- poster/backdrop;
- title;
- release year/date;
- runtime;
- overview;
- genres;
- Library/watchlist state;
- watched state;
- latest watched date;
- watch count;
- viewing history;
- personal rating;
- external metadata/ratings;
- related/discovery information where supported.

---

# Local Movie Details

Full Movie Details should operate on a local SofaWatch Movie.

Provider previews can remain lightweight before import.

Conceptually:

```text
provider preview
-> import
-> local Movie
-> Movie Details
```

This mirrors the internal-ID strategy used throughout SofaWatch.

---

# Metadata

Movie metadata can include normalized fields such as:

- title;
- original title;
- overview;
- poster;
- backdrop;
- release date;
- runtime;
- genres;
- provider identifiers;
- external rating metadata where intentionally exposed.

Exact availability depends on the normalized backend model.

---

# Library Action in Movie Details

Movie Details can allow Library/watchlist changes.

These mutations should use the Library feature contracts.

The Movie Details UI should not directly manipulate database/provider concepts.

---

# Mark Watched in Movie Details

Mark Watched creates a real Movie viewing event.

After success, relevant UI should reconcile:

- watched state;
- latest watched date;
- watch count;
- Movie history;
- global History;
- Statistics;
- Movie Library classifications where affected.

---

# Rewatch in Movie Details

A watched Movie can expose `Watched Again`.

The quick action should:

- create a new event;
- use the current time;
- preserve prior events;
- expose targeted loading;
- prevent double submission.

A separate historical-entry flow can support an explicit timestamp if the product provides one.

---

# Movie Viewing History

Movie Details can expose the Movie's individual viewing events.

Ordering:

```text
watched_at DESC
```

Each row is a real viewing.

This is separate from global History, which combines Movies and Episodes.

---

# Adaptive History Presentation

Where Movie viewing history uses modal presentation, the same adaptive strategy can apply:

```text
mobile
-> bottom sheet

desktop
-> dialog
```

Existing design tokens/breakpoints should be reused.

---

# Personal Rating

A SofaWatch personal rating belongs to the user.

It is not a TMDB/IMDb rating.

Conceptually:

```text
User
  |
  +-> personal rating for Movie
```

Personal ratings are user-scoped and should remain under SofaWatch control.

---

# External Ratings

External ratings are provider metadata.

Potential sources include:

```text
TMDB
IMDb
future providers
```

They must remain distinguishable from the user's personal rating.

Example presentation:

```text
Your rating: 9 / 10
TMDB: 8.2 / 10
IMDb: 8.7 / 10
```

The application should not silently average these into one unexplained score.

---

# IMDb

IMDb integration is under evaluation.

Before implementation, SofaWatch should determine:

- legitimate/stable data source;
- licensing and terms;
- IMDb ID mapping;
- rating availability;
- vote count availability;
- update frequency;
- caching;
- provider failure behavior.

Fragile scraping should not become a core dependency.

---

# External Identifier Mapping

The long-term model should support Movie mappings such as:

```text
internal Movie 42
    |
    +-> TMDB 123
    +-> IMDb tt1234567
```

This allows metadata and ratings from multiple providers without changing SofaWatch's internal identity.

---

# Rating Count

If an external provider supplies both rating and vote count, they should remain paired.

For example:

```text
IMDb
8.4 / 10
215,000 votes
```

A rating without its context can be misleading.

The API/domain model should preserve source identity.

---

# History Integration

Global History combines:

```text
EpisodeWatchEvent
MovieWatchEvent
```

into one chronological user history.

Movie rewatches remain separate entries.

See [History](history.md).

---

# Statistics Integration

Statistics count real Movie viewing events.

This allows:

```text
Movies watched
-> total Movie viewings

Unique Movies
-> distinct Movies with viewing events

Movie rewatches
-> total viewings - unique Movies
```

Movie duration can contribute to total viewing time where reliable runtime data exists.

See [Statistics](statistics.md).

---

# Home Integration

Movie activity can contribute to Home sections such as:

- weekly Movie count;
- watch time;
- Recent Activity.

Home should reuse Statistics/History application data rather than maintaining separate Movie counters.

See [Home](home.md).

---

# Profile Integration

Profile can expose:

- Movie Library preview;
- Movie History preview;
- Statistics;
- ratings-related navigation where implemented.

Full Movie Library and History remain dedicated feature experiences.

See [Profile](profile.md).

---

# User Scoping

Movie Library state, viewing history, and personal ratings are user-specific.

Example:

```text
User A
-> Movie 42 in Watchlist
-> watched twice
-> personal rating 9

User B
-> Movie 42 not in Library
-> unwatched
-> no rating
```

The local Movie entity can be shared while user state remains independent.

---

# Backend Responsibility

The backend owns:

- Movie import;
- provider mapping;
- internal Movie identity;
- user Library membership;
- viewing-event persistence;
- watched-state derivation;
- user scoping;
- personal rating persistence;
- normalized metadata;
- business classification rules.

---

# Frontend Responsibility

Flutter owns:

- Movie list/grid presentation;
- Movie Details presentation;
- adaptive layout;
- invoking Library mutations;
- invoking viewing mutations;
- loading/error/empty states;
- watch-history presentation;
- personal rating controls;
- responsive behavior.

Flutter should not recreate backend classification rules.

---

# Mutation Loading

Movie actions should use targeted loading where practical.

Examples:

```text
Add to Watchlist
Mark Watched
Watched Again
Delete viewing
Rate Movie
```

One action should not unnecessarily disable the entire Movie page.

---

# Duplicate Submission

`Watched Again` is non-idempotent by design.

Each successful request creates another viewing event.

The UI must prevent accidental rapid duplicate submissions while the request is in flight.

---

# Retry Safety

Read operations are generally safe to retry.

A Movie viewing-event creation request should not be blindly replayed after an ambiguous transport failure, because doing so can create an unintended duplicate viewing.

Client retry behavior must respect mutation semantics.

---

# Partial Failures

A successful Movie mutation and a failed secondary refresh are different outcomes.

Example:

```text
MovieWatchEvent created
-> success

Statistics refresh
-> failure
```

The Movie should remain shown as watched.

Statistics can independently expose failure/retry.

---

# Empty States

Valid Movie empty states include:

- empty Movie watchlist;
- no watched Movies;
- no Movie viewing history;
- no personal rating;
- no external rating from a provider;
- no recommendations.

These are not generic errors.

---

# Errors

Movies uses the common SofaWatch error architecture.

Possible failures include:

- network;
- timeout;
- authentication;
- validation;
- not found;
- conflict;
- provider failure;
- invalid response;
- server failure.

Raw Dio/provider/database errors should not be displayed directly.

See [API Errors](../api/errors.md).

---

# Release Dates

Movie release dates require care because theatrical/streaming/regional releases can differ.

SofaWatch should not imply a more precise availability model than the metadata actually provides.

Future Coming Soon/Upcoming Movie experiences should define which release-date source/type they use.

---

# Where to Watch

Where to Watch is a potential richer Movie Details capability.

If implemented, it should account for region and provider data semantics.

A provider's availability data should not be presented as universal availability.

---

# Recommendations

Potential Movie discovery sections include:

```text
Recommended
Because You Watched...
Coming Soon
Hidden Gems
More Like This
```

These should be driven by real discovery/recommendation rules.

They should not be hardcoded merely to populate the interface.

Explore remains the primary general discovery destination.

---

# Responsive Design

Movie presentation should adapt without forking domain/application logic.

Mobile can favor:

- compact grids/cards;
- stacked Movie Details;
- bottom-sheet history/actions;
- touch-friendly controls.

Desktop can favor:

- wider grids;
- constrained content width;
- richer Movie Details layout;
- dialogs;
- denser metadata.

---

# Accessibility

Final Movie validation should include:

- poster semantics where useful;
- accessible Library state;
- accessible watched state;
- accessible personal-rating controls;
- accessible Rewatch/delete actions;
- keyboard navigation on Web/Desktop;
- focus behavior;
- non-color-only status communication.

---

# Performance

Relevant considerations include:

- efficient poster grids;
- image caching;
- avoiding repeated provider imports;
- idempotent import;
- pagination/bounded Movie collections;
- minimizing unnecessary detail reloads;
- efficient History loading.

Optimization should follow profiling rather than speculation.

---

# Testing

Backend tests should cover:

```text
TMDB Movie import
idempotent import
internal Movie identity
provider mapping
Library add/remove
user isolation
first Movie watch
Movie rewatch
watch count
latest watched_at
event deletion
delete final event
Movie history ordering
personal rating isolation
Statistics integration
provider failure mapping
```

Frontend tests should cover:

```text
Movie search/preview integration
Movie Library state
Movie grids
Movie Details loading
Movie Details success
Movie Details failure
Library mutation
Mark Watched
Watched Again
duplicate-submit protection
viewing history
event deletion
personal rating
external rating presentation when available
responsive layout
partial failures
```

---

# Edge Cases

## Imported but Not in Library

```text
Movie exists locally
user has no Library entry
-> valid
```

## In Library but Unwatched

```text
Watchlist
0 viewing events
-> valid
```

## Watched Multiple Times

```text
3 MovieWatchEvents
-> watched
-> 3 total viewings
-> 2 rewatches
```

## Delete Latest Viewing

```text
A
B
C

delete C
-> B becomes latest
```

## Delete Final Viewing

```text
delete only event
-> Movie becomes unwatched
-> Library state remains independently defined
```

## Same Movie, Different Users

```text
one local Movie
different Library/history/rating state
```

## Duplicate Provider Import

```text
same TMDB Movie imported twice
-> same internal Movie
```

## Missing External Rating

```text
IMDb rating unavailable
-> show no IMDb rating
-> do not fabricate/fallback-label another source as IMDb
```

---

# Future Work

## Movie Discovery

```text
[ ] richer recommended Movies
[ ] Because You Watched...
[ ] Coming Soon
[ ] Hidden Gems
[ ] More Like This
[ ] validate against Explore to avoid duplication
```

---

## Movie Library Presentation

```text
[ ] final Watchlist presentation audit
[ ] final Upcoming Movies rules
[ ] final Watched classification
[ ] ordering audit
[ ] empty-state audit
```

---

## External Ratings

```text
[ ] evaluate legitimate IMDb source
[ ] add provider-independent external identifiers
[ ] define ExternalRatings domain model
[ ] include rating source
[ ] include vote count where available
[ ] define refresh/cache policy
[ ] keep personal rating separate
```

---

## Provider Architecture

```text
[ ] extend provider mappings
[ ] metadata precedence rules
[ ] fallback rules
[ ] secondary-provider failure behavior
[ ] avoid provider IDs in business logic
```

---

## Rich Movie Details

Potential future work:

```text
[ ] cast
[ ] Where to Watch
[ ] More Like This
[ ] richer release information
[ ] external links
```

Only implement when supported by real data and clear product rules.

---

## Final Validation

```text
[ ] mobile responsive audit
[ ] desktop responsive audit
[ ] ultrawide audit
[ ] accessibility audit
[ ] Movie history regression tests
[ ] rewatch regression tests
[ ] Library classification regression tests
[ ] integration tests
```

---

# Notes

> Importing a Movie and adding it to a Library are separate operations.

> Imported Movies use internal SofaWatch IDs.

> Movie Library state and Movie watched state are separate concepts.

> Every Movie viewing is a real `MovieWatchEvent`.

> Rewatch creates another event and preserves previous history.

> Personal SofaWatch ratings must remain separate from TMDB, IMDb, or other external ratings.

> IMDb should only be integrated through an appropriate legitimate and stable source.

> Movie recommendations should use real discovery logic rather than hardcoded editorial content.

> Release and availability metadata should never imply precision the provider does not actually supply.

---

# Related Documentation

- [Implementation Status](implementation-status.md)
- [Search](search.md)
- [Explore](explore.md)
- [Library](library.md)
- [Viewing Progress](viewing-progress.md)
- [History](history.md)
- [Statistics](statistics.md)
- [Home](home.md)
- [Profile](profile.md)
- [Architecture Overview](../architecture/overview.md)
- [Database Architecture](../architecture/database.md)
- [Data Flow](../architecture/data-flow.md)
- [Frontend Contract](../api/frontend-contract.md)
- [API Errors](../api/errors.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)
- [ADR-003: Internal Media IDs](../decisions/003-internal-media-ids.md)
- [ADR-006: Provider Independence](../decisions/006-provider-independence.md)
