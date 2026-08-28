# Explore

## Overview

Explore is SofaWatch's discovery experience.

Its purpose is to help users browse TV shows and movies when they do not already have a specific title in mind.

Conceptually:

```text
Search
-> "I know what I want to find"

Explore
-> "Show me something interesting"
```

Explore and Search may reuse media cards, previews, Library actions, and provider-backed metadata, but they remain different product capabilities.

SofaWatch must not introduce a second independent global Search implementation inside Explore.

See:

- [Search](search.md)
- [ADR-004: One Global Search Experience](../decisions/004-global-search.md)
- [ADR-006: Provider-Independent Domain Architecture](../decisions/006-provider-independence.md)

---

## Status

**Implemented / Extensible**

The core Explore architecture and discovery experience are implemented or prepared around:

- Trending content;
- Popular TV Shows;
- Popular Movies;
- media-type filters;
- genre filters;
- reusable discovery cards;
- Library actions;
- media previews;
- loading states;
- error states;
- responsive Web/mobile presentation;
- context preservation.

More personalized and editorial discovery remains deliberately deferred.

See [Implementation Status](implementation-status.md) for the project-wide status.

---

# Goals

Explore is designed to:

- provide useful browsing without requiring a query;
- surface TV Shows and Movies from provider-backed discovery collections;
- support multiple independent discovery sections;
- keep filters local to the section they affect;
- reuse common media presentation where appropriate;
- integrate with Library actions without owning Library business logic;
- preserve discovery context when opening previews;
- adapt cleanly between mobile and desktop;
- evolve toward richer recommendations without hardcoding fake personalization.

---

# Non-Goals

Explore is not intended to become:

- a second global Search;
- a replacement for Shows or Movies Library screens;
- a replacement for Home;
- a collection of hardcoded editorial lists;
- a place for provider-specific business logic in Flutter;
- an excuse to duplicate recommendation logic across multiple screens.

---

# High-Level Flow

```text
Explore page
     |
     v
Explore application state
     |
     v
Explore repository
     |
     v
SofaWatch API
     |
     v
Discovery service / provider integration
     |
     v
TMDB
     |
     v
Normalized discovery results
     |
     v
Explore sections
```

Flutter consumes SofaWatch API contracts.

It does not call TMDB directly.

---

# Discovery Sources

TMDB is currently the provider behind the implemented discovery capabilities.

Current discovery concepts include:

```text
Trending
Popular TV
Popular Movies
Genre-based discovery
```

TMDB is the current implementation source, not the architectural identity of Explore.

Future providers may complement discovery without requiring the client feature to become provider-specific.

See [ADR-006](../decisions/006-provider-independence.md).

---

# Trending

Trending provides time-based discovery.

The intended/current concepts include:

```text
Today
This Week
```

Weekly Trending can support media filtering such as:

```text
All
TV Shows
Movies
```

The exact provider request used to obtain these collections belongs to the backend/provider integration.

---

## Trending Today

Trending Today focuses on content currently receiving attention.

It can contain both TV Shows and Movies where the selected discovery mode permits them.

The UI should make media type understandable without forcing the user to infer it from the title or poster.

---

## Trending This Week

Trending This Week broadens the discovery window.

Where media filters are available, changing between:

```text
All
TV Shows
Movies
```

changes only the relevant Trending collection state.

Other independent Explore sections should not unnecessarily reload or lose their state.

---

# Popular TV Shows

Popular TV Shows is an independent discovery section.

It can support a TV-specific genre filter.

Conceptually:

```text
Popular TV
genre = All
```

can become:

```text
Popular TV
genre = Drama
```

without changing the Movie genre filter.

---

# Popular Movies

Popular Movies is a separate discovery section.

Its genre selection is independent from Popular TV.

Example:

```text
Popular TV
genre = Comedy

Popular Movies
genre = Science Fiction
```

is a valid state.

The filters should not share one accidental global `selectedGenre` value.

---

# Genre Filters

Genres are represented through SofaWatch/provider mapping rules rather than assuming that all provider genre identifiers are globally interchangeable.

Conceptually:

```text
SofaWatch discovery intent
        |
        v
genre/provider mapping
        |
        v
provider request
```

TV and Movie provider taxonomies may use different external identifiers even when the visible genre name is similar.

See [ADR-006](../decisions/006-provider-independence.md).

---

## Filter Ownership

Each filter should affect only the collection it belongs to unless the product explicitly defines a shared filter.

For example:

```text
Trending media filter
-> Trending

Popular TV genre
-> Popular TV

Popular Movie genre
-> Popular Movies
```

This keeps Explore state predictable and prevents one interaction from unexpectedly resetting unrelated content.

---

# Discovery Media Card

Explore uses a reusable media presentation concept such as `DiscoveryMediaCard`.

A discovery card can present information including:

- poster;
- title;
- media type;
- year;
- provider rating where available;
- Library state/action.

Cards should remain presentation components rather than becoming owners of persistence/business rules.

---

## Media Type

When a collection can contain both Shows and Movies, media type should be clear.

This is particularly important for mixed Trending collections.

The client should use the normalized SofaWatch media type rather than infer type from provider-specific fields.

---

## Year

A discovery card may display a year derived from the relevant release/air date when available.

Missing dates should be handled gracefully.

The UI should not invent a year.

---

## Rating

Provider ratings shown in Explore are external metadata.

They are not the user's personal SofaWatch rating.

Future external-rating work may allow multiple sources to be displayed, but those values must remain source-aware.

See [ADR-006](../decisions/006-provider-independence.md).

---

# Library Actions

Explore can allow media to be added to or removed from the Library.

However:

```text
Explore
-> presents discovery state

Library
-> owns Library persistence and business rules
```

Explore application state should not become the source of truth for Library membership.

See:

- [Library](library.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)
- [ADR-003: Internal SofaWatch Media Identifiers](../decisions/003-internal-media-ids.md)

---

## Import Before Library Membership

A provider-backed discovery result may not yet exist locally.

The conceptual mutation flow is:

```text
Discovery result
      |
      v
resolve/import provider media
      |
      v
local SofaWatch Show/Movie
      |
      v
Library mutation
```

After import, local operations use SofaWatch internal media identity.

---

## Library Mutation Feedback

When a Library action is running, the UI should provide appropriate local feedback and prevent accidental duplicate submissions where necessary.

A failure should affect the relevant action/card without unnecessarily destroying the entire Explore page.

---

# Preview

Explore results can open media previews.

Preview is useful for evaluating a discovery result without immediately navigating away from the discovery context.

Conceptually:

```text
Explore
selected filters
scroll positions
loaded sections
      |
      v
open Preview
      |
      v
inspect media
      |
      v
close Preview
      |
      v
same Explore context
```

---

## Preview Content

A preview can contain enough information to make a useful decision, such as:

- poster/backdrop;
- title;
- overview;
- media type;
- date/year;
- genres;
- rating metadata;
- Library state/actions;
- navigation to full details where appropriate.

Preview should not duplicate the entire full Details page.

---

# Responsive Preview

SofaWatch uses adaptive presentation.

Conceptually:

```text
narrow viewport
-> modal bottom sheet

wide viewport
-> dialog/modal
```

The shared design system/breakpoints should determine the presentation rather than feature-specific hardcoded width checks.

---

# Context Preservation

Explore should preserve context when the user temporarily leaves a section interaction.

Relevant state includes:

- vertical page scroll;
- horizontal section scroll;
- Trending period;
- Trending media filter;
- TV genre filter;
- Movie genre filter;
- loaded discovery results;
- Preview return context.

Closing a Preview should not reset Explore to its initial state.

---

# Horizontal Collections

Where discovery sections use horizontal lists/carousels, each section may have independent horizontal position.

Example:

```text
Trending
scroll = position A

Popular TV
scroll = position B

Popular Movies
scroll = position C
```

Interactions with one section should not reset the others without a reason.

---

# Vertical Scroll

The overall Explore page should preserve vertical position while opening and closing temporary overlays such as Preview.

When navigating away from Explore and later returning, preservation depends on the application's navigation/state lifecycle, but unnecessary rebuild-driven resets should be avoided.

---

# Loading Strategy

Explore contains multiple independent data collections.

This means loading should not automatically be modeled as one global Boolean such as:

```text
isExploreLoading
```

if doing so prevents independent section behavior.

Conceptually:

```text
Trending
-> loading / success / failure

Popular TV
-> loading / success / failure

Popular Movies
-> loading / success / failure
```

This allows partial page usability.

---

# Initial Loading

During initial loading, each discovery section can show an appropriate loading representation.

Depending on the established UI pattern this may be:

- skeleton cards;
- compact progress indicators;
- section placeholders.

The layout should remain stable enough to avoid excessive visual jumping.

---

# Section Refresh

Refreshing one filtered collection should preserve unrelated successful collections where possible.

Example:

```text
Popular TV = loaded

user changes Movie genre

Popular Movies = loading
Popular TV = remains available
```

A Movie filter change should not blank the entire page.

---

# Errors

Explore should handle failures at the smallest useful scope.

Examples:

```text
Trending fails
-> Trending error + Retry

Popular TV succeeds
-> remains usable

Popular Movies succeeds
-> remains usable
```

This follows SofaWatch's broader principle that independent sections should be able to fail independently.

---

## Network Error

A network failure should show a safe application-level message and Retry.

Existing successful data should remain visible where appropriate.

---

## Timeout

Provider/backend timeout should be mapped through the common error architecture.

The user should not see raw Dio/TMDB exception details.

---

## Provider Failure

TMDB/provider failures are normalized by the backend.

Explore should not contain presentation branches based directly on raw TMDB error structures.

---

## Invalid Response

Malformed or unexpected API responses should fail safely.

Technical details belong in logs/diagnostics.

---

# Retry

Retry should repeat the failed collection request using its current context.

Example:

```text
Popular Movies
genre = Horror
request fails

Retry
-> retry Popular Movies / Horror
```

Retry should not silently reset the genre to `All`.

---

# Empty Collections

A valid discovery request can return no results.

This is not the same as an error.

The UI should display an appropriate section-level empty state rather than a technical failure.

For filtered sections, it can suggest changing the selected filter where useful.

---

# Explore and Search

Explore must not add a text field that independently reimplements global title Search simply because users may want to find something while browsing.

Instead:

```text
Explore
-> can expose the normal global Search entry point

Global Search
-> handles title queries
```

This keeps Search behavior consistent across Home, Shows, Movies, Explore, and Profile.

See [Search](search.md).

---

# Explore and Home

Home and Explore have different roles.

```text
Home
-> personal dashboard
-> "what matters to me now?"

Explore
-> discovery
-> "what else could I watch?"
```

Discovery collections should not be copied wholesale into Home.

If Home later shows recommendations, they should be intentionally selected for the dashboard use case.

---

# Explore and Shows

Shows is primarily concerned with the user's TV tracking state.

Explore can discover Shows that are not yet in the user's Library.

The two features can share cards or navigation primitives but should not duplicate application logic.

---

# Explore and Movies

Movies can contain Movie-specific Library/watchlist experiences.

Explore can surface new Movies through Trending/Popular/discovery collections.

Movie discovery logic that is generally useful for browsing should normally remain in Explore rather than being independently rebuilt in multiple places.

---

# State Architecture

Explore state should reflect independently changing collections.

A useful conceptual model is:

```text
Explore
├── Trending state
├── Popular TV state
└── Popular Movies state
```

Each can carry relevant information such as:

```text
loading
data
error
selected filter
```

The exact Cubit/BLoC decomposition should follow the current code and should not be changed merely to mirror this documentation.

---

# Cubits / Application State

Explore application components are responsible for orchestration such as:

- initial collection loading;
- changing Trending period;
- changing media filter;
- changing TV genre;
- changing Movie genre;
- Retry;
- preserving current successful data during relevant refreshes.

They should not own:

- raw Dio parsing;
- provider authentication;
- Library persistence rules;
- navigation-specific widget behavior.

---

# Repository Boundary

The domain repository describes the discovery operations required by Explore.

The data implementation handles:

- SofaWatch API requests;
- DTO parsing;
- domain mapping;
- transport/API error translation.

This keeps application logic independent from Dio and raw JSON.

---

# Backend Responsibility

The backend owns provider integration.

Responsibilities include:

- building provider discovery requests;
- mapping media types;
- mapping genres;
- normalizing provider responses;
- filtering unsupported content;
- provider error handling;
- timeout behavior;
- language behavior where supported.

Flutter should not reproduce these rules.

---

# Provider Independence

Explore should be able to evolve beyond TMDB.

Future possibilities include:

- TVDB complementary metadata;
- alternative recommendation sources;
- multiple external ratings;
- SofaWatch-generated personalized ranking.

Provider-independent boundaries make this possible.

The UI should render SofaWatch discovery models rather than raw provider response objects.

---

# Personal Discovery

Personalized discovery is a future direction.

Potential sections include:

```text
Top Shows For You
Top Movies For You
Because You Watched...
Hidden Gems
```

These should only be implemented when SofaWatch has a meaningful ranking/recommendation rule.

---

## Avoid Fake Personalization

A section titled:

```text
For You
```

should actually use user-specific information.

Simply renaming:

```text
TMDB Popular
```

to:

```text
Recommended For You
```

would be misleading.

Until personalized ranking exists, provider-backed collections should be labeled according to what they really represent.

---

# Because You Watched

A future `Because You Watched...` feature may use signals such as:

- watched media;
- personal ratings;
- genres;
- related/recommended provider metadata;
- Library state.

The exact ranking model is not yet defined.

It should avoid repeatedly recommending media already present in the Library when that does not make sense.

---

# Hidden Gems

`Hidden Gems` remains exploratory.

A meaningful implementation needs an explicit rule.

Possible future signals might include combinations of:

- rating;
- vote count;
- popularity;
- release age;
- Library/user preferences.

No arbitrary thresholds should be introduced merely to populate the section.

---

# Coming Soon

A future Coming Soon discovery section could surface unreleased Movies or upcoming Shows/Seasons where provider data supports it.

It must remain distinct from the user's personal `Upcoming` Episode timeline.

Conceptually:

```text
Explore / Coming Soon
-> discover future media

Shows / Upcoming
-> Episodes relevant to the user's tracked Shows
```

---

# Recommendations

Provider-native recommendations may be useful as one signal.

Long-term SofaWatch recommendations may combine:

```text
provider recommendations
+
viewing history
+
personal ratings
+
genres
+
Library state
```

The recommendation architecture should be designed when this work becomes active rather than prematurely adding a generic recommendation engine.

---

# External Ratings

Future discovery cards may display ratings from multiple sources.

Example:

```text
TMDB  8.1
IMDb  8.6
```

if legitimate data sources are available.

These remain external ratings.

The user's personal SofaWatch rating is separate.

---

# Localization

Future localization should affect:

- section labels;
- filter labels;
- dates;
- number formatting;
- provider request language where supported;
- localized provider titles/overviews.

Provider language behavior should be coordinated through the backend.

---

# Accessibility

Final Explore validation should include:

- semantic labels for media cards;
- accessible Library actions;
- filter semantics;
- keyboard navigation on Web/Desktop;
- sensible focus behavior in Preview;
- adequate touch targets on mobile;
- readable text scaling;
- image fallback/semantics.

Accessibility work should be part of the final quality audit rather than treated as an afterthought.

---

# Performance

Explore can render several image-heavy collections.

Performance considerations include:

- avoiding unnecessary section rebuilds;
- appropriate image caching;
- preserving loaded data during filter interactions;
- avoiding duplicate provider requests;
- lazy rendering where appropriate;
- keeping horizontal lists efficient.

Optimization should be driven by actual profiling rather than speculative complexity.

---

# Testing

Explore tests should cover both independent section behavior and integrated presentation.

Important application behavior includes:

```text
initial loading
Trending success
Trending failure
Trending Retry
period change
media filter change
Popular TV success
TV genre change
Popular TV failure/retry
Popular Movies success
Movie genre change
Popular Movies failure/retry
independent section failures
empty collections
Library action feedback
Preview opening/closing
context preservation
responsive presentation
```

Backend tests should cover:

- discovery provider calls;
- media normalization;
- genre mapping;
- filter mapping;
- provider errors;
- timeouts;
- invalid responses;
- unsupported media filtering.

---

# Future Work

## Personalized Discovery

```text
[ ] define recommendation signals
[ ] define ranking rules
[ ] Top Shows For You
[ ] Top Movies For You
[ ] Because You Watched...
[ ] avoid misleading "For You" labels without personalization
```

---

## Editorial Discovery

```text
[ ] evaluate Hidden Gems
[ ] define a real Hidden Gems rule
[ ] evaluate Coming Soon
[ ] avoid hardcoded editorial collections
```

---

## Provider Evolution

```text
[ ] evaluate TVDB contribution to discovery
[ ] define multi-provider discovery behavior if needed
[ ] define deduplication/matching if multiple providers supply collections
[ ] define partial-provider-failure behavior
```

---

## External Ratings

```text
[ ] evaluate legitimate IMDb/external rating source
[ ] preserve rating source identity
[ ] decide discovery-card presentation
[ ] keep personal ratings separate
```

---

## Final Validation

```text
[ ] mobile responsive audit
[ ] desktop responsive audit
[ ] ultrawide behavior
[ ] scroll preservation audit
[ ] accessibility audit
[ ] performance profiling
[ ] final regression tests
```

---

# Notes

> Explore is discovery. Search remains the single global query-driven media Search feature.

> Trending and Popular are provider-backed discovery collections. They should not be presented as personalized recommendations unless personalization actually exists.

> TV and Movie genre filters are independent.

> A failure in one Explore section should not unnecessarily make successful sections unusable.

> Opening and closing Preview should preserve the user's discovery context.

> Library actions may be presented from Explore, but Library remains responsible for Library business rules.

> Advanced recommendation sections are intentionally deferred until SofaWatch has meaningful rules to power them.

---

# Related Documentation

- [Implementation Status](implementation-status.md)
- [Search](search.md)
- [Library](library.md)
- [Home](home.md)
- [Movies](movies.md)
- [Architecture Overview](../architecture/overview.md)
- [Backend Architecture](../architecture/backend.md)
- [Frontend Architecture](../architecture/frontend.md)
- [Data Flow](../architecture/data-flow.md)
- [API Overview](../api/overview.md)
- [API Errors](../api/errors.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)
- [ADR-003: Internal SofaWatch Media Identifiers](../decisions/003-internal-media-ids.md)
- [ADR-004: One Global Search Experience](../decisions/004-global-search.md)
- [ADR-006: Provider-Independent Domain Architecture](../decisions/006-provider-independence.md)
