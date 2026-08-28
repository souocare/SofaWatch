# Search

## Overview

Search is SofaWatch's global media search experience for finding TV shows and movies.

It is intentionally separate from Explore:

```text
Search
-> explicit intent
-> find a title the user is looking for

Explore
-> discovery intent
-> browse content without requiring a query
```

SofaWatch has one global Search capability shared across the application. Mobile and Web/Desktop adapt its presentation to their respective form factors rather than implementing independent search systems.

The architectural decision behind this is documented in [ADR-004: One Global Search Experience](../decisions/004-global-search.md).

---

## Status

**Implemented**

The core Search feature is implemented across backend and Flutter clients.

Known future work is primarily around state reconciliation after Library mutations and possible future provider evolution rather than basic Search functionality.

See [Implementation Status](implementation-status.md) for the project-wide implementation checklist.

---

## Goals

Search is designed to:

- provide one consistent search experience throughout SofaWatch;
- search TV shows and movies through the backend;
- keep external provider behavior out of Flutter;
- support responsive Web and mobile presentation;
- handle asynchronous search safely;
- preserve useful context while navigating previews;
- support pagination without destroying existing results;
- integrate with Library actions without making Search responsible for Library business logic.

---

## Supported Media

Search currently supports:

```text
All
TV Shows
Movies
```

People are not exposed as first-class Search results.

If an external provider returns unsupported media types, the backend filters or normalizes them before exposing the SofaWatch Search contract.

---

## High-Level Flow

```text
User enters query
      |
      v
Flutter Search
      |
      v
SearchBloc
      |
      v
SearchRepository
      |
      v
SofaWatch API
      |
      v
Search service / provider integration
      |
      v
TMDB
      |
      v
Normalized Search results
      |
      v
Flutter Search state
```

The Flutter client does not call TMDB directly.

---

# Backend

## Responsibility

The backend is responsible for:

- communicating with the metadata provider;
- normalizing provider results;
- filtering unsupported media types;
- mapping provider failures to SofaWatch errors;
- pagination metadata;
- language-aware provider requests where supported;
- bounded Search caching.

Provider-specific behavior remains behind backend integration boundaries.

See:

- [Backend Architecture](../architecture/backend.md)
- [Data Flow](../architecture/data-flow.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)
- [ADR-006: Provider-Independent Domain Architecture](../decisions/006-provider-independence.md)

---

## Provider

TMDB is currently the Search provider.

This is an implementation detail of the current backend integration rather than the identity of the feature.

Conceptually:

```text
SofaWatch Search
      |
      v
provider integration
      |
      v
TMDB
```

Future provider work may change or extend the provider strategy without requiring a separate client-side Search feature.

---

## Result Normalization

External results are normalized into a common media-oriented Search contract.

A result needs enough information for the client to identify and preview the provider resource, including concepts such as:

```text
media type
provider identity
title
release/air information
poster/backdrop metadata
overview
rating metadata where available
```

The exact API schema is defined by the backend contract rather than by raw TMDB response shapes.

---

## Unsupported Results

Search is focused on SofaWatch media.

Provider results such as People are filtered rather than exposed as if they were supported SofaWatch media.

This prevents the frontend from having to understand provider-specific mixed result types that the product does not support.

---

# Search Results and Local Media

A Search result does not necessarily correspond to an already persisted SofaWatch Show or Movie.

Before import:

```text
Search result
-> provider-backed identity
```

After import:

```text
SofaWatch Show / Movie
-> internal SofaWatch identity
-> provider mapping/identifier
```

This distinction is defined by [ADR-003: Internal SofaWatch Media Identifiers](../decisions/003-internal-media-ids.md).

---

## Import Boundary

A local mutation may require resolving/importing the provider result first.

Conceptually:

```text
Search result
      |
      v
Preview / Add to Library
      |
      v
Resolve or import local media
      |
      v
SofaWatch internal ID
      |
      v
Local mutation
```

Search itself should not treat the provider ID as the permanent SofaWatch entity ID.

---

# Frontend

## Architecture

Search follows the Flutter feature architecture:

```text
search/
├── presentation/
├── application/
├── domain/
└── data/
```

Responsibilities remain separated:

```text
presentation
-> widgets, dialogs/sheets, Search UI

application
-> SearchBloc and asynchronous orchestration

domain
-> Search entities and repository contracts

data
-> DTOs, mappers, API repository implementation
```

Domain code should not depend on Flutter, Dio, or raw JSON.

---

## SearchRepository

The domain repository defines the Search capability expected by the application layer.

The API repository implementation is responsible for:

- calling the SofaWatch backend;
- decoding API DTOs;
- mapping DTOs into domain models;
- translating transport/API failures into application exceptions.

SearchBloc should not contain Dio-specific request parsing.

---

## SearchBloc

SearchBloc coordinates the Search interaction.

Its responsibilities include behavior such as:

- query changes;
- query validation;
- debounce;
- filter changes;
- initial Search;
- pagination;
- retry;
- stale response protection;
- loading-state transitions.

It should not own unrelated feature business logic.

In particular:

```text
SearchBloc != LibraryBloc
```

Library mutations remain owned by the Library feature.

---

# Query Lifecycle

## Initial State

Before a valid query exists, Search is in an initial state.

The UI should provide orientation rather than displaying:

```text
No results
```

because no Search has actually occurred.

---

## Query Normalization

Input is normalized consistently before searching.

Relevant behavior includes:

- trimming unnecessary surrounding whitespace;
- recognizing an empty query;
- enforcing minimum-query behavior;
- preventing meaningless requests.

Normalization should remain predictable and should not aggressively rewrite user intent.

---

## Minimum Query

Queries that do not meet the configured/implemented minimum requirement should not trigger normal Search requests.

The UI remains in an appropriate initial/input state.

This reduces unnecessary provider calls and avoids low-quality searches while the user is still typing.

---

# Debounce

Typing is debounced.

Conceptually:

```text
B
Br
Bre
Brea
Break
Breaking Bad
        |
        v
short debounce
        |
        v
Search request
```

This avoids making a backend/provider request for every individual keystroke.

Debounce belongs to shared Search behavior rather than being independently implemented by every presentation.

---

# Filters

Search supports media filtering:

```text
All
Shows
Movies
```

Changing the filter changes the Search context.

Example:

```text
query = "Dune"
filter = All

        |
        v

filter = Movies
```

Pagination state that belongs to the previous filter must not be reused incorrectly.

The query itself can remain.

---

# Pagination

Search supports pagination.

The important distinction is between:

```text
initial Search loading
```

and:

```text
loading another page
```

When another page is loading, existing results remain visible and usable.

---

## Pagination Flow

```text
Page 1
  |
  v
results displayed
  |
  v
user requests more
  |
  v
Page 2 loading
  |
  +--> existing results remain visible
  |
  v
Page 2 appended
```

Pagination must not replace Page 1 with a full-screen loading state.

---

## Pagination Retry

Pagination failure is recoverable independently.

Conceptually:

```text
Page 1 results
      |
      v
Page 2 fails
      |
      +--> Page 1 remains
      |
      v
Retry Page 2
```

A failed next page should not discard already loaded results.

See [API Pagination](../api/pagination.md).

---

# Stale Response Protection

Search requests are asynchronous and can complete out of order.

Example:

```text
request A -> "Dark"

request B -> "Dark Matter"

request B returns first
request A returns later
```

The late response from A must not overwrite the current results for B.

Search tracks enough request context to reject stale responses.

This behavior is important for:

- rapid typing;
- filter changes;
- retries;
- pagination;
- variable provider latency.

---

# Loading States

Search distinguishes different loading scenarios rather than using one generic destructive spinner.

## Initial Loading

A valid Search is loading and no relevant results are currently available.

The UI may use loading indicators or skeleton-style rows/cards.

---

## Loading While Preserving Results

When appropriate, previous useful results can remain visible while a new request is being resolved.

The UI should communicate that an update is occurring without unnecessarily destroying context.

---

## Pagination Loading

Pagination displays progress near the end of the current result collection while leaving existing results interactive.

---

# Empty Results

A valid Search that completes with no matches displays a specific empty state.

Useful information includes:

- the searched query;
- a suggestion to change the terms;
- a suggestion to change the media filter.

An empty Search result should not silently substitute unrelated Explore content.

---

# Errors

Search handles errors through SofaWatch's common error architecture.

Relevant categories include:

- network errors;
- timeout;
- provider failure;
- invalid response;
- authentication/API errors where applicable.

Raw implementation details should not be displayed to the user.

See [API Errors](../api/errors.md).

---

## Network Error

A network failure should:

- show a safe message;
- offer Retry;
- preserve existing usable results where appropriate.

---

## Timeout

Timeout is treated distinctly enough to provide meaningful user feedback while still using the common exception/error architecture.

Retry should be available.

---

## Provider Error

A TMDB/provider failure is normalized by the backend.

The frontend should not need to render raw TMDB error messages or status structures.

This keeps Search provider-independent.

---

## Invalid Response

Unexpected or invalid API data should fail safely.

Technical details belong in diagnostics/logging.

The user receives a safe generic error.

---

# Retry

Retry repeats the operation that failed.

For initial Search:

```text
Retry
-> repeat current Search
```

For pagination:

```text
Retry
-> repeat failed page request
```

Retry should preserve the current query/filter context.

---

# Search Cache

The backend uses a bounded in-memory LRU cache for Search.

Current strategy:

```text
TTL
-> 5 minutes

maximum entries
-> 100
```

The cache key considers relevant Search context, including:

- normalized query;
- media filter;
- language;
- page where applicable.

---

## Cache Goals

The cache exists to reduce repeated identical provider requests during normal interactive usage.

It is deliberately simple.

SofaWatch currently does not need:

- persistent Search caching;
- stale-while-revalidate;
- aggressive prefetch;
- a distributed cache;
- Search-specific analytics infrastructure.

The strategy should only become more complex if real usage demonstrates a need.

---

# Preview

Search results can open media previews.

Preview should preserve the Search context.

Expected behavior:

```text
Search
query = "Severance"
filter = Shows
loaded results
scroll position
      |
      v
open preview
      |
      v
close preview
      |
      v
return to same Search context
```

Opening a preview should not unnecessarily trigger a new Search.

---

## Responsive Preview

Presentation adapts by available width.

The established SofaWatch pattern is conceptually:

```text
narrow viewport
-> modal bottom sheet

wide viewport
-> dialog/modal
```

The exact breakpoint follows the shared design system rather than feature-specific magic numbers.

---

# Mobile Search

Mobile Search is integrated into the Dual-Pill experience.

This is a presentation choice.

It still uses the same Search domain/application capability as the rest of SofaWatch.

Mobile-specific concerns may include:

- keyboard behavior;
- safe areas;
- touch targets;
- compact filters;
- bottom-sheet previews;
- constrained result layouts.

---

# Web and Desktop Search

Web/Desktop exposes Search through the application-level navigation/modal experience.

Desktop presentation can take advantage of:

- larger modal width;
- denser result presentation;
- mouse interaction;
- keyboard interaction where supported.

It does not implement a separate Search engine.

---

# Context Preservation

Search is intended to behave as a global capability without unnecessarily destroying the context from which it was opened.

Conceptually:

```text
Shows
  |
  v
open Search
  |
  v
Search
  |
  v
close
  |
  v
Shows remains in its previous context
```

The same principle applies to Home, Movies, Explore, and Profile where relevant.

---

# Search and Library

Search can expose Library state/actions for results.

However, Library remains a separate feature.

The ownership rule is:

```text
Search
-> discovers media and presents Search state

Library
-> owns Library mutations and Library state
```

SearchBloc should not become responsible for persistence rules merely because a Search row contains an Add/Remove Library button.

---

## Known Deferred State Synchronization

A known future improvement is updating Search result rows after a Library mutation without repeating the Search.

The desired behavior is to preserve:

- query;
- filter;
- loaded pages;
- result ordering;
- scroll position.

This work was deliberately deferred rather than solved through an unsafe coupling between SearchBloc and Library logic.

It should be implemented only when the synchronization path can remain clean and testable.

---

# Search and Explore

Search and Explore may display similar media cards and can reuse shared presentation components.

Their application behavior remains different.

```text
Search
-> query-driven

Explore
-> collection/discovery-driven
```

Explore must not introduce a second global title Search implementation.

See [ADR-004](../decisions/004-global-search.md).

---

# Search and Home

Home may provide an entry point to Search.

Home does not own Search behavior.

Likewise, Home recommendations or dashboard sections are not Search results.

---

# Search and Shows / Movies

Shows and Movies may contain local filtering or category navigation.

That is not automatically the same as global provider-backed Search.

If local Library Search/filtering is added later, it should have clearly defined semantics rather than silently duplicating global Search.

---

# Provider Evolution

TMDB is currently the Search provider.

Future possibilities include:

- TVDB;
- provider fallback;
- provider aggregation;
- alternative external sources.

Adding another provider should occur behind backend/provider architecture.

The client Search feature should continue consuming a normalized SofaWatch contract.

See [ADR-006](../decisions/006-provider-independence.md).

---

# Language

Search provider requests can eventually respect the configured/user-selected language as localization work is completed.

The Search cache includes language where relevant so results from different language contexts do not incorrectly share entries.

Language behavior should be coordinated with the broader localization strategy rather than implemented as an isolated Search-only preference.

---

# Testing

Search tests should cover behavior rather than only widget rendering.

Important areas include:

```text
initial state
empty query
minimum query
debounce
successful Search
filters
pagination
pagination retry
empty results
network failure
timeout
provider error
invalid response
retry
stale responses
preview/context preservation
responsive presentation
```

Backend tests should cover:

- provider result normalization;
- unsupported media filtering;
- pagination contracts;
- cache behavior;
- provider errors;
- request validation.

Frontend tests should cover SearchBloc/application behavior and important presentation states.

---

# Future Work

## Search State Synchronization

Planned/deferred:

```text
[ ] update a Search row after Library mutation without repeating Search
[ ] preserve query
[ ] preserve filter
[ ] preserve pagination
[ ] preserve scroll
[ ] ensure reopened Search remains consistent
[ ] add corresponding regression tests
```

This is the main known Search-specific deferred work.

---

## Multi-Provider Search

If SofaWatch eventually searches several providers simultaneously, additional backend work may be required for:

- result matching;
- deduplication;
- ranking;
- provider precedence;
- partial provider failures.

This should be designed when there is a concrete multi-provider requirement.

---

## People Search

People are not currently part of the Search product.

If SofaWatch later introduces first-class Person/Cast pages, People Search can be reconsidered deliberately.

---

## Local Library Search

A future local-only Search/filter capability may be useful for large Libraries.

If added, it should be clearly distinguished from global provider Search.

---

# Notes

> Search is intentionally global. Explore is discovery and must not grow a second independent implementation of Search.

> Library mutations do not belong to SearchBloc. Search result synchronization should be solved through clean cross-feature reconciliation rather than moving Library business rules into Search.

> TMDB is the current provider, not the identity of the Search feature.

> Search caching is intentionally small, bounded, and in-memory. Do not expand it without evidence that additional complexity is useful.

---

# Related Documentation

- [Implementation Status](implementation-status.md)
- [Explore](explore.md)
- [Library](library.md)
- [Architecture Overview](../architecture/overview.md)
- [Backend Architecture](../architecture/backend.md)
- [Frontend Architecture](../architecture/frontend.md)
- [Data Flow](../architecture/data-flow.md)
- [API Overview](../api/overview.md)
- [Frontend API Contract](../api/frontend-contract.md)
- [API Pagination](../api/pagination.md)
- [API Errors](../api/errors.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)
- [ADR-003: Internal SofaWatch Media Identifiers](../decisions/003-internal-media-ids.md)
- [ADR-004: One Global Search Experience](../decisions/004-global-search.md)
- [ADR-006: Provider-Independent Domain Architecture](../decisions/006-provider-independence.md)
