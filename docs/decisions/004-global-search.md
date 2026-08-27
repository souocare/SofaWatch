# ADR-004: One Global Search Experience

- Status: Accepted
- Date: 2026-08-27

## Context

SofaWatch includes several ways of finding and navigating media:

- global Search;
- Explore/discovery;
- Home recommendations and contextual sections;
- Shows;
- Movies;
- Library;
- provider-backed previews.

Search and discovery overlap visually because both can display TV Shows and Movies, but they solve different user problems.

Search answers an explicit intent:

```text
"I know roughly what I am looking for."
```

Examples:

```text
Breaking Bad
Dune
The Office
```

Explore answers a discovery intent:

```text
"I want to find something interesting to watch."
```

Examples:

```text
Trending today
Popular TV Shows
Popular Movies
Genre discovery
Future personalized recommendations
```

Without a deliberate architectural decision, SofaWatch could easily develop several independent Search implementations:

```text
global Search
Explore Search
Shows Search
Movies Search
mobile Search
desktop Search
```

That would duplicate:

- query behavior;
- filters;
- pagination;
- provider requests;
- error handling;
- caching;
- preview behavior;
- state management;
- tests.

It would also make Search behavior inconsistent between platforms and entry points.

---

## Decision

SofaWatch has **one global Search feature**.

Search is a product capability, not a page-specific implementation.

The same Search domain/application behavior should be reused across Web and mobile wherever practical.

Platform-specific presentation may differ:

```text
Mobile
-> Dual-Pill Search experience

Web / Desktop
-> top navigation + Search modal
```

but both represent the same global Search capability.

Explore remains a separate **discovery** feature and must not implement a second independent Search system.

---

## Search vs Explore

The distinction is:

```text
Search
------
explicit user query
find known or partially known media

Explore
-------
browse/discover
find media without requiring a specific query
```

Both may use the same metadata provider and may reuse presentation components.

That does not make them the same feature.

---

## Global Means Application-Wide

Search should be reachable as an application-level capability rather than being owned by one tab.

Conceptually:

```text
Home ──────┐
Shows ─────┤
Movies ────┼──> Global Search
Explore ───┤
Profile ───┘
```

A user should not need to navigate to Explore simply to search for a known title.

---

## Supported Media

Global Search currently supports:

```text
All
TV Shows
Movies
```

People are not part of the SofaWatch Search result experience.

Provider results are normalized into a common media-oriented contract before reaching the main client behavior.

---

## Provider Boundary

Search may currently be backed by TMDB, but the Search feature should not be conceptually defined as:

```text
TMDB Search UI
```

The intended flow is:

```text
User query
    |
    v
Global Search
    |
    v
SofaWatch backend
    |
    v
provider integration
    |
    v
normalized media results
```

Future provider changes should not require a second Search UI architecture.

---

## Search Results Before Import

A Search result does not need to be a persisted SofaWatch media entity.

Conceptually:

```text
Search Result
-------------
provider identity
media type
preview metadata
```

If the user performs an action requiring local persisted state:

```text
Add to Library
Open/import local media
```

the backend resolves/imports the provider media into a SofaWatch entity.

This follows [ADR-003](003-internal-media-ids.md).

---

## Shared Application Behavior

The Search application layer should own behavior such as:

- query normalization;
- minimum query handling;
- debounce;
- media filters;
- pagination;
- stale/out-of-order response protection;
- initial loading;
- preserving previous results where appropriate;
- pagination loading;
- pagination retry;
- provider/network error handling;
- result state.

This behavior should not be independently reimplemented for mobile and desktop.

---

## Presentation May Differ

Shared Search behavior does not require identical UI.

### Mobile

Mobile integrates Search into the application's Dual-Pill navigation experience.

Presentation can optimize for:

- touch;
- smaller screens;
- sheets;
- compact controls;
- safe areas;
- mobile keyboard behavior.

### Web / Desktop

Desktop/Web can use:

- top navigation entry point;
- modal/dialog Search;
- wider result layouts;
- keyboard-friendly interactions.

The UI adapts.

The Search feature semantics remain shared.

---

## Search State

Search state belongs to the Search feature.

Conceptually it may contain:

```text
query
filter
results
pagination
loading state
pagination loading state
error state
```

Other features should not maintain competing copies of Search state without a specific reason.

---

## SearchBloc

Search has enough asynchronous behavior to justify centralized event/state orchestration.

The Search application state handles concerns such as:

```text
query changed
filter changed
search requested
next page requested
retry requested
late response received
```

The exact implementation can evolve, but the responsibility remains inside the Search feature.

---

## Debounce

Search input is debounced to avoid issuing a provider/API request for every keystroke.

Conceptually:

```text
user types
    |
    v
short debounce
    |
    v
normalized query
    |
    v
Search request
```

Debounce is application behavior and should not be separately tuned by several competing Search implementations unless platform evidence justifies it.

---

## Query Normalization

Search should normalize query input consistently.

Examples may include:

- trimming surrounding whitespace;
- handling empty input;
- applying minimum-query rules.

The backend/provider may perform additional normalization.

The goal is deterministic behavior, not aggressive rewriting of what the user typed.

---

## Empty Query

An empty Search query is not equivalent to:

```text
zero matching results
```

It is an initial Search state.

The UI should show orientation rather than an incorrect "No results" message.

Explore is the appropriate place for browse-without-query discovery.

---

## Filters

Changing Search media filter changes the Search result context.

Example:

```text
All
-> Movies
```

should reset incompatible pagination state and search using the same normalized query under the new filter.

Filters belong to Search state.

---

## Pagination

Search uses provider/page-oriented pagination where appropriate.

Pagination should:

- preserve existing results;
- show a separate load-more state;
- prevent duplicate page requests;
- ignore stale page responses;
- expose pagination Retry independently from initial Retry.

See [API Pagination](../api/pagination.md).

---

## Stale Response Protection

Search requests may complete out of order.

Example:

```text
query A requested

query B requested

query B returns

query A returns later
```

The final UI must remain on query B.

The older response is stale and must not overwrite current state.

This applies to both initial Search and pagination.

---

## Search Cache

Search currently uses a deliberately small backend in-memory cache.

The strategy is:

```text
LRU
TTL = 5 minutes
maximum = 100 entries
```

Cache identity considers relevant request context such as:

```text
query
filter
language
page
```

The cache is intentionally:

- bounded;
- temporary;
- in-memory;
- easy to remove.

SofaWatch does not currently require:

- persistent Search cache;
- stale-while-revalidate;
- aggressive prefetch;
- dedicated Search analytics.

These should only be introduced if real usage demonstrates a benefit.

---

## Search Preview

Opening a media preview from Search should preserve Search context.

Conceptually:

```text
Search
query + filter + results + scroll
        |
        v
Preview
        |
        v
Close
        |
        v
same Search context
```

A preview should not unnecessarily reset:

- query;
- filter;
- loaded pages;
- result list;
- scroll position.

---

## Responsive Preview

Preview presentation may adapt by breakpoint.

Conceptually:

```text
narrow screen
-> bottom sheet

wide screen
-> dialog/modal
```

This is presentation behavior.

The underlying media preview and Search context remain shared.

---

## Library Actions from Search

Search results may expose Library actions.

However:

```text
SearchBloc
```

must not become the owner of Library business logic.

The separation is:

```text
Search
-> discovers media

Library
-> owns Library mutation behavior
```

A Search result can trigger a Library operation through the appropriate repository/application boundary.

This follows [ADR-002](002-backend-source-of-truth.md).

---

## Search State After Library Mutation

A known future improvement is synchronizing Search rows after Library mutations without repeating the entire Search unnecessarily.

The desired behavior is to preserve:

- query;
- filter;
- pagination;
- scroll;
- already loaded results.

This optimization is intentionally deferred until implemented cleanly.

It does not justify moving Library ownership into Search.

---

## Explore

Explore is explicitly not a Search container.

Explore may include:

- Trending;
- Popular Shows;
- Popular Movies;
- genre filters;
- future recommendations;
- Hidden Gems;
- Coming Soon;
- editorial/personal discovery.

These are browse/discovery flows.

---

## Explore Filters Are Not Search Filters

A genre filter such as:

```text
Popular Movies
Genre = Science Fiction
```

does not turn Explore into Search.

Explore filters refine discovery collections.

Search filters refine an explicit text query.

They may reuse common UI components while remaining separate application concerns.

---

## Explore State

Explore should preserve its own context:

- selected filters;
- vertical scroll;
- horizontal section scroll;
- loaded discovery data;
- preview context.

Opening global Search from Explore should not destroy Explore state.

Likewise, closing Search should return the user to the previous application context where practical.

---

## Home

Home may display content that helps the user choose what to watch, but it should not own Search.

A Search entry point on Home invokes the global Search feature.

Home sections such as:

```text
Continue Watching
Upcoming
Recent Activity
```

remain Home/dashboard concerns.

---

## Shows and Movies

Shows and Movies may have their own:

- Library views;
- Watch List;
- Upcoming;
- status filters.

These should not become independent title Search engines unless a future requirement clearly distinguishes local filtering from global media Search.

A local Library filter is not necessarily the same feature as provider-backed global Search.

---

## Navigation

Search should behave as an overlay/global interaction where appropriate rather than forcing a permanent navigation switch to a dedicated discovery tab.

The exact navigation implementation can evolve with the Flutter shell.

Important invariant:

```text
opening Search should not unnecessarily destroy the user's current context
```

---

## Deep Links

A future deep-link strategy may support opening Search with an initial query.

If implemented, it should initialize the same global Search feature rather than create a separate Search page with different behavior.

---

## Keyboard Interaction

Desktop Search may support richer keyboard behavior such as:

- focusing Search quickly;
- Escape to close;
- keyboard navigation;
- Enter to select.

These are presentation/input enhancements.

They should operate on the same Search state and result model.

---

## Error Handling

Search errors follow the common frontend/backend error architecture.

Examples include:

- network unavailable;
- timeout;
- provider failure;
- invalid response;
- authentication failure where applicable.

Search should display safe user-facing messages and preserve previous usable results where appropriate.

See [API Errors](../api/errors.md).

---

## Provider Errors

The UI should not expose raw provider implementation details.

For example, a raw TMDB exception should be normalized through the backend/API error contract and frontend exception mapping.

Search is a SofaWatch feature even when TMDB supplies the underlying metadata.

---

## Loading States

Search distinguishes several states.

### Initial

No query has been submitted.

### Initial Loading

A valid query is loading and no current results exist.

### Refresh/New Query Loading

A new Search context may preserve previous data temporarily where the intended UX calls for it.

### Pagination Loading

Existing results remain visible while another page loads.

These states should not be collapsed into one destructive spinner.

---

## Empty Results

No matches for a valid query should display a Search-specific empty state.

The UI can:

- show the query;
- suggest changing terms;
- suggest changing the media filter.

It should not silently redirect to Explore or invent recommendations as if they were Search results.

---

## Search Result Identity

Search results should preserve enough identity to distinguish:

```text
TV Show
Movie
provider
provider ID
```

before import.

Do not deduplicate results solely by title.

Two different media can share a title.

---

## Consequences

### Positive

#### Consistent Search

Users get one Search behavior throughout SofaWatch.

#### Less Duplication

Query handling, pagination, errors, caching, and tests are not rebuilt per tab/platform.

#### Clear Product Model

Search and discovery remain conceptually distinct.

#### Easier Provider Evolution

The Search UI is not directly tied to one provider implementation.

#### Better Context Preservation

Search can behave as a global overlay while preserving the current application location.

#### Shared Web/Mobile Logic

Flutter platforms can share domain/application behavior while adapting presentation.

---

### Trade-offs

#### Global State Coordination

A global Search experience must coordinate carefully with navigation and overlays.

#### Platform-Specific UI Complexity

Mobile and desktop presentations differ while sharing behavior.

#### Cross-Feature Mutations

Library actions from Search require clean boundaries and state reconciliation.

#### Search vs Local Filtering

Developers must distinguish provider-backed Search from local filtering inside Library or other screens.

---

## Alternatives Considered

### Search Only Inside Explore

Rejected because Search is a global user intent and should not require navigating to discovery first.

---

### Separate Search for Shows and Movies

Example:

```text
Shows Search
Movies Search
```

Rejected because it duplicates infrastructure and makes mixed-media Search awkward.

The global filter already supports:

```text
All
Shows
Movies
```

---

### Independent Mobile and Desktop Search

Rejected because platform presentation differences do not justify duplicating domain/application behavior.

---

### Search Inside Every Main Tab

Rejected because it would create competing Search state, inconsistent behavior, and duplicated tests.

---

### Merge Search and Explore

Rejected because explicit query and browse/discovery are different user intents.

Combining them would make both features harder to reason about.

---

## Revisit When

This decision should be reconsidered only if product requirements reveal genuinely different Search domains.

Examples might include:

### Local Library Search

A future feature may need fast local text filtering over only the user's Library.

That can exist as a distinct local filtering/search capability if its semantics are clearly different from global provider-backed Search.

It should not silently duplicate global Search.

### People Search

If SofaWatch eventually introduces first-class People/Cast pages and People Search, the global Search contract may need expansion.

### Multi-Provider Search Strategy

If several providers participate simultaneously in Search, backend aggregation and ranking may need a new architectural decision.

The existence of additional providers alone does not invalidate one global Search.

---

## Implementation Constraints

Code written under this decision should follow these rules:

```text
[ ] SofaWatch has one global media Search feature
[ ] Search remains available independently of Explore
[ ] Explore remains discovery-oriented
[ ] Web and mobile share Search domain/application behavior where practical
[ ] platform-specific presentation may differ
[ ] Search supports All / Shows / Movies
[ ] People are not currently returned as first-class Search results
[ ] Search state owns query/filter/pagination behavior
[ ] stale responses cannot replace current results
[ ] pagination preserves already loaded results
[ ] SearchBloc does not own Library business rules
[ ] provider details remain behind backend/provider boundaries
[ ] Search context is preserved through previews where practical
[ ] Search cache remains bounded and simple unless evidence justifies expansion
[ ] new tab-specific Search implementations require an explicit distinct use case
```

---

## Relationship to Other Decisions

### Backend as Source of Truth

[ADR-002](002-backend-source-of-truth.md) means Search uses the backend/provider integration rather than moving provider/business rules directly into Flutter.

### Internal Media IDs

[ADR-003](003-internal-media-ids.md) distinguishes provider-backed Search result identity from persisted SofaWatch media identity after import.

### Authentication

[ADR-005](005-authentication-model.md) defines authenticated API access independently of Search presentation.

### Provider Independence

[ADR-006](006-provider-independence.md) ensures global Search does not become permanently coupled to TMDB.

---

## Related Documentation

- [Documentation Index](../README.md)
- [Architecture Overview](../architecture/overview.md)
- [Frontend Architecture](../architecture/frontend.md)
- [Backend Architecture](../architecture/backend.md)
- [Data Flow](../architecture/data-flow.md)
- [API Overview](../api/overview.md)
- [Frontend API Contract](../api/frontend-contract.md)
- [API Pagination](../api/pagination.md)
- [API Errors](../api/errors.md)
- [Show Search](../features/show-search.md)
- [Implementation Status](../features/implementation-status.md)
