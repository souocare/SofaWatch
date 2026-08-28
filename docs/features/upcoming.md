# Upcoming

## Overview

Upcoming is SofaWatch's temporal TV Episode timeline.

Its purpose is to answer:

```text
What Episodes are airing today?
What airs tomorrow?
What is coming during the next days?
What aired recently?
What happened further back in the timeline?
```

Upcoming is based on real Episode air dates and the user's tracked TV Shows.

It is distinct from Watch Next:

```text
Upcoming
-> when Episodes air

Watch Next
-> what the user can continue watching now
```

See:

- [Watch List](watch-list.md)
- [Viewing Progress](viewing-progress.md)
- [Library](library.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)

---

## Status

**Implemented / Partial**

Implemented:

- temporal Episode timeline;
- Today;
- Tomorrow;
- next seven days;
- later future dates;
- past navigation;
- historical ranges;
- already-aired Episodes;
- chronological ordering;
- bidirectional timeline behavior;
- tracked-Show filtering;
- watched-state presentation;
- responsive foundation.

Known remaining work:

- finalize Mark Watched for applicable historical/aired Episodes where still pending;
- immediately reconcile progress and Watch Next after that mutation;
- block Mark Watched before an Episode airs;
- add/complete corresponding regression tests;
- final coordinated refresh;
- final responsive validation.

See [Implementation Status](implementation-status.md).

---

# Goals

Upcoming is designed to:

- provide a chronological view of tracked Episode releases;
- distinguish Today and Tomorrow clearly;
- expose the near future without limiting navigation to seven days;
- allow historical exploration;
- preserve already loaded temporal context;
- reflect watched state;
- integrate with Library tracking state;
- avoid inventing missing provider metadata;
- remain useful on both mobile and desktop.

---

# Non-Goals

Upcoming is not:

- Watch Next;
- a global TV release calendar for every Show in TMDB;
- a replacement for Explore;
- a persisted duplicate of Episode metadata;
- an air-time guessing system;
- a scheduler that assumes every known Episode is relevant to the user.

---

# Source Data

Upcoming derives its timeline from:

- authenticated user;
- Library;
- Show tracking state;
- Seasons;
- Episodes;
- Episode air dates;
- watched state;
- watch events where needed.

Conceptually:

```text
User Library
     +
Tracked Shows
     +
Episode metadata
     |
     v
Upcoming rules
     |
     v
Chronological timeline
```

---

# User Scoping

Upcoming is user-specific.

Two users tracking different Shows should receive different timelines.

Even for the same Show, tracking state can affect whether it is relevant.

The backend determines the user from authentication rather than trusting arbitrary client-supplied ownership.

---

# Timeline Model

Upcoming should be understood as a timeline rather than a single static "next seven days" list.

Conceptually:

```text
Past
  |
  v
Yesterday
  |
  v
Today
  |
  v
Tomorrow
  |
  v
Next 7 Days
  |
  v
Later Future
```

The user can move backward and forward through time as supported by the current UI/data-loading model.

---

# Today

Today contains relevant Episodes with:

```text
air_date == today
```

Today is based on date semantics, not an invented provider air time.

An Episode airing today can still be unwatched or watched depending on the user's history.

---

# Tomorrow

Tomorrow contains relevant Episodes with:

```text
air_date == today + 1 day
```

It should be visually understandable as a distinct near-future grouping where the UI uses named date sections.

---

# Next Seven Days

The normal near-future experience can expose Episodes across the next seven days.

Home also has a smaller Upcoming use case, but the Shows Upcoming experience is the fuller temporal timeline.

The feature should not assume that seven days is the maximum range that can ever be explored.

---

# Later Future Dates

Known Episodes beyond the initial near-future range can be loaded/displayed when the timeline moves forward.

This is useful when provider metadata already contains later air dates.

The UI should not need to preload an unbounded future range.

---

# Past Navigation

Upcoming supports navigating into historical ranges.

This allows the user to answer questions such as:

```text
What aired last week?
Which tracked Episodes did I miss?
Was this Episode already watched?
```

Past navigation should use the same underlying Episode metadata rather than maintaining a separate historical-calendar persistence model.

---

# Historical Ranges

Historical data can be loaded incrementally.

The currently loaded past range should be preserved during relevant state changes and refreshes where possible.

Conceptually:

```text
initial range
-> today + near future

scroll/navigate backward
-> load older range

continue backward
-> extend existing timeline
```

Previously loaded data should not disappear merely because another range is requested.

---

# Bidirectional Timeline

Upcoming can require loading in both directions:

```text
older dates <- current range -> newer dates
```

This differs from conventional one-direction pagination.

State should therefore preserve:

- oldest loaded boundary;
- newest loaded boundary;
- existing Episode groups;
- scroll/navigation context;
- loading state for the requested direction.

---

# Chronological Ordering

Upcoming Episodes are ordered chronologically by known air date.

Within the same date, deterministic secondary ordering should be used where necessary.

The application should not rely on unstable provider response order.

If precise air times are unavailable, ordering within a day must not pretend that one Episode airs before another based on fabricated times.

---

# Air Date

`air_date` is the authoritative temporal field currently used by Upcoming.

Examples:

```text
air_date < today
-> historical/aired

air_date == today
-> Today

air_date > today
-> future
```

Episodes without a known air date require separate handling.

---

# Air Time

SofaWatch must not invent Episode air times.

Current metadata does not necessarily provide sufficiently reliable air-time information for individual Episodes.

Therefore a card can truthfully say:

```text
Today
```

without pretending:

```text
Today at 21:00
```

unless a future provider supplies a real, trustworthy value.

---

## Future Air-Time Support

If TVDB or another provider later supplies useful air-time metadata, implementation should first define:

- source precedence;
- timezone;
- original network timezone;
- user timezone conversion;
- daylight-saving behavior;
- missing-time fallback;
- conflict handling between providers.

Only then should Upcoming become time-aware.

---

# Episodes Without Air Dates

An Episode with:

```text
air_date = null
```

cannot be placed truthfully on the dated timeline.

SofaWatch should not infer its date from Episode numbering or neighboring Episodes.

Such Episodes remain valid metadata and can appear elsewhere where appropriate.

A later metadata sync may make them eligible for Upcoming.

---

# Tracked Show Inclusion

Upcoming is not a global provider calendar.

It uses the user's tracked Shows.

Relevant Library states can include active or intentionally followed content according to the product rules.

The exact inclusion matrix belongs to backend business logic.

---

# Watching Shows

Watching Shows are naturally relevant to Upcoming.

Their future Episodes help the user understand what is coming next even when they are currently caught up.

Example:

```text
Show = Watching
user = caught up
next Episode airs Friday

Watch Next
-> no current Episode

Upcoming
-> Friday Episode visible
```

---

# Planning Shows

Planning Shows can be relevant to Upcoming.

This is useful when the user wants to track a Show before starting it or before it premieres.

Presentation can distinguish Planning from Watching where useful.

Home's Premiering Today experience may also use this distinction.

---

# Completed Shows

A user-completed Show generally should not behave like actively tracked future content unless the business rule intentionally reactivates it when new Episodes appear.

This is distinct from a provider Show being `Ended`.

Any automatic state transition should be explicit and backend-owned.

---

# Dropped Shows

Dropped Shows should normally be excluded from active Upcoming tracking.

Historical viewing events remain valid.

Dropping a Show must not erase its past watch history.

---

# Ended Shows

A provider lifecycle status of `Ended` does not itself define user Library state.

Normally an Ended Show should not receive future Episodes, but provider metadata can be imperfect or later corrected.

Upcoming should operate on actual Episode air-date data plus tracking rules rather than blindly assuming provider lifecycle status is sufficient.

---

# Specials

Specials require deliberate treatment.

Season 0 is excluded from normal Watch Next/progress progression, but that does not necessarily mean every Special must be invisible from every calendar context.

The exact Upcoming inclusion rule for Specials should remain consistent with current backend behavior and product intent.

It should not be independently guessed by Flutter.

---

# Episode Presentation

An Upcoming Episode entry can present:

- Show title;
- poster/artwork;
- season and Episode number;
- Episode title;
- air date/date group;
- Library/tracking context where useful;
- watched state;
- Mark Watched where eligible.

Missing metadata should degrade gracefully.

---

# Watched State

Historical and Today entries can reflect whether the user has already watched the Episode.

This state comes from backend viewing progress.

Upcoming should not maintain an independent watched flag.

See [Viewing Progress](viewing-progress.md).

---

# Historical Mark Watched

A known remaining interaction is allowing an applicable aired/historical Episode to be marked watched directly from Upcoming.

Conceptually:

```text
Historical Episode
      |
      v
Mark Watched
      |
      v
EpisodeWatchEvent
      |
      v
Upcoming row becomes watched
      |
      +-> progress refresh
      +-> Watch Next refresh
      +-> History refresh where loaded
```

This should use the normal viewing-event infrastructure.

---

# Blocking Future Mark Watched

An Episode that has not yet aired should not be markable as watched through the normal Upcoming quick action.

Conceptually:

```text
air_date > today
-> Mark Watched unavailable/blocked
```

This rule must be enforced by the backend where it represents a business invariant.

Disabling the button in Flutter alone is not sufficient protection.

---

# Today Eligibility

Because SofaWatch currently works with dates rather than precise air times:

```text
air_date == today
```

is the available date-level boundary.

If future product rules need to prevent marking an Episode watched until its actual broadcast time, reliable air-time metadata and timezone semantics are required first.

---

# Mutation Loading

Mark Watched should use row-level loading where possible.

While the request is in flight:

- prevent duplicate submission;
- keep unrelated timeline rows interactive;
- preserve scroll position;
- avoid replacing the whole Upcoming page with a loading screen.

---

# Mutation Success

After successful Mark Watched:

- update the affected Episode;
- refresh/reconcile progress;
- refresh/reconcile Watch Next;
- update History if relevant/loaded;
- preserve the user's current timeline position.

The user should not be returned to Today merely because they modified an Episode in a historical range.

---

# Partial Refresh Failure

A successful viewing mutation can be followed by a secondary refresh failure.

Example:

```text
Mark Watched
-> success

Watch Next refresh
-> failure
```

The UI should not report that Mark Watched failed.

Primary mutation state and secondary refresh state should remain distinguishable.

---

# Watch Next Relationship

Upcoming and Watch Next use related Episode metadata but have different eligibility.

Example:

```text
S02E04 aired yesterday and is unwatched
-> can influence Watch Next
-> appears historically in Upcoming

S02E05 airs next week
-> Upcoming
-> not Watch Next yet
```

See [Watch List](watch-list.md).

---

# Caught-Up Shows

Upcoming is especially useful for caught-up Shows.

Example:

```text
all aired Episodes watched
future Episode known

Watch Next
-> absent

Upcoming
-> future Episode visible
```

When the Episode airs, progress and Watch Next eligibility can change.

---

# Home Relationship

Home uses a smaller subset of Upcoming concepts.

Home's intended behavior includes:

```text
Premiering Today
-> today's relevant Episodes

Upcoming
-> begins tomorrow
-> initially next seven days
```

Home should not duplicate the full bidirectional timeline.

See [Home](home.md).

---

# Missed Recently Relationship

Home's Missed Recently is not simply the historical Upcoming timeline.

It has additional rules such as:

- recent time window;
- Watching only;
- unwatched;
- regular Episodes;
- exclude Today.

The backend/application layer should own those rules rather than having Home scrape Upcoming UI state.

---

# Show Details Relationship

Show Details can expose Episode air dates and watched state.

A viewing mutation from either Show Details or Upcoming should ultimately converge on the same backend state.

Cross-feature consistency should be achieved through reconciliation/refresh rather than separate progress models.

---

# Metadata Synchronization

Upcoming depends heavily on current Episode metadata.

Metadata Sync can affect the timeline when:

- new Episodes are discovered;
- air dates are added;
- air dates change;
- Episodes are removed/corrected by the provider;
- Season metadata changes.

See [Metadata Sync](metadata-sync.md).

---

# Provider Independence

TMDB is currently the main metadata source.

Upcoming should nevertheless operate on normalized SofaWatch Episode data.

Future TVDB integration may improve:

- Episode metadata;
- numbering;
- air dates;
- potentially air-time information.

Provider-specific IDs should not leak into Upcoming domain behavior.

See [ADR-006: Provider-Independent Domain Architecture](../decisions/006-provider-independence.md).

---

# Backend Responsibility

The backend owns business rules such as:

- user scoping;
- tracked-Show inclusion;
- date-range queries;
- Episode eligibility;
- watched state;
- future/aired validation;
- deterministic ordering;
- mutation validation.

Flutter should not reproduce these rules independently.

---

# Frontend Responsibility

Flutter owns:

- timeline presentation;
- date headers;
- loading indicators;
- directional loading UI;
- scroll/navigation context;
- responsive layout;
- invoking mutations;
- mutation feedback;
- safe error presentation.

---

# State Architecture

Upcoming state may need to represent more than:

```text
loading / loaded / error
```

because data can be extended in either direction.

Conceptually useful state includes:

```text
loaded date range
Episode groups
loading older
loading newer
refreshing
directional error
selected/current temporal context
```

The exact implementation should follow the current codebase rather than being rewritten only to match this conceptual model.

---

# Initial Loading

Initial loading should establish the normal timeline around the current date.

The UI can use:

- skeleton rows/cards;
- timeline placeholders;
- a compact loading indicator.

It should avoid showing an empty-state message before the initial request has completed.

---

# Loading Older Dates

When loading historical data:

- preserve current rows;
- show progress at the historical boundary;
- keep the timeline usable;
- append/prepend data without duplicates;
- preserve the user's visual position.

---

# Loading Newer Dates

When extending forward:

- preserve already loaded data;
- show progress at the future boundary;
- merge deterministically;
- avoid resetting the user to Today.

---

# Directional Errors

A failure loading older data should not remove the current timeline.

Example:

```text
current range = loaded
load older = failure

-> current range remains visible
-> Retry older available
```

The same applies to forward extension.

---

# Refresh

Refresh should update the relevant loaded temporal context.

A known future improvement is coordinated Shows refresh across:

- Library;
- Watch Next;
- inactivity collections;
- progress;
- Upcoming;
- Watch History.

---

## Refresh Preservation

Refresh should preserve:

- selected Shows tab;
- current timeline context;
- vertical scroll;
- historical ranges already loaded;
- previous data while refreshing where appropriate.

A refresh should not unnecessarily collapse the timeline back to the initial seven-day range.

---

# Empty States

A date/range with no Episodes is valid.

Examples:

```text
Nothing airing today
No tracked Episodes tomorrow
No Episodes in this period
```

This is different from:

```text
network failure
provider failure
invalid response
```

The UI should communicate the distinction.

---

# Errors

Upcoming uses the common SofaWatch error architecture.

Relevant failures include:

- network error;
- timeout;
- authentication failure;
- server error;
- provider error;
- invalid response.

Raw Dio or provider exception details should not be exposed to the user.

See [API Errors](../api/errors.md).

---

# Retry

Retry should preserve the failed temporal request.

Example:

```text
load 1-7 August
-> failure

Retry
-> retry 1-7 August
```

It should not silently replace that operation with the default current-week request.

---

# Date Boundaries

Date calculations should be deterministic and explicit.

Backend and frontend must avoid subtle disagreement around:

- current date;
- timezone boundaries;
- inclusive/exclusive range endpoints.

As localization/timezone work evolves, the API contract should make temporal semantics clear.

---

# Localization

Future localization should affect:

- Today/Tomorrow labels;
- weekday names;
- month names;
- date formatting;
- relative date labels;
- locale-aware ordering where appropriate.

Provider language and user-interface locale are related but distinct concerns.

---

# Responsive Design

Mobile validation should cover:

- narrow timeline cards;
- long Show titles;
- long Episode titles;
- date headers;
- Mark Watched actions;
- directional loading;
- safe areas;
- preserved scroll.

Desktop validation should cover:

- useful maximum width;
- timeline density;
- action alignment;
- ultrawide displays;
- keyboard/mouse interactions.

---

# Accessibility

Final Upcoming validation should include:

- semantic date headers;
- accessible Episode descriptions;
- accessible watched state;
- accessible Mark Watched actions;
- keyboard navigation on Web/Desktop;
- focus behavior after mutations;
- non-color-only state communication.

---

# Performance

A bidirectional timeline can accumulate many rows.

Potential considerations include:

- lazy list rendering;
- bounded range loading;
- avoiding duplicate Episodes;
- efficient date grouping;
- minimizing unnecessary rebuilds;
- retaining useful state without loading an unbounded timeline.

Optimization should be based on real profiling.

---

# Testing

Backend tests should cover:

```text
Today
Tomorrow
future range
historical range
range boundaries
chronological ordering
tracked-user isolation
Watching inclusion
Planning behavior
Dropped exclusion
unknown air date
future Episode behavior
watched state
Mark Watched validation
future Mark Watched rejection
metadata changes
```

Frontend tests should cover:

```text
initial loading
Today grouping
Tomorrow grouping
future groups
historical navigation
load older
load newer
directional loading
directional failure
directional Retry
empty date/range
watched presentation
Mark Watched
future action blocked
mutation loading
progress reconciliation
Watch Next reconciliation
scroll preservation
tab preservation
responsive layout
```

---

# Edge Cases

## No Episodes Today

```text
Today
-> valid empty group/state
```

## Caught Up with Future Episode

```text
Watch Next = empty for Show
Upcoming = future Episode
```

## Episode Date Changes

```text
metadata sync changes air_date
-> Episode moves to correct timeline date
```

## Unknown Air Date Becomes Known

```text
air_date = null
-> not on dated timeline

metadata refresh

air_date = future date
-> becomes eligible
```

## Future Episode

```text
air_date > today
-> visible in Upcoming
-> normal Mark Watched blocked
```

## Historical Unwatched Episode

```text
air_date < today
unwatched
-> historical timeline
-> Mark Watched can be offered where implemented
```

## Rewatch

Upcoming's normal Mark Watched interaction should not accidentally create repeated viewing events simply because a row is already watched.

Rewatch should remain an explicit action where offered.

---

# Future Work

## Historical Episode Interaction

```text
[ ] finalize Mark Watched for eligible historical Episodes
[ ] update row immediately after success
[ ] refresh Show/Season progress
[ ] refresh Watch Next
[ ] update History where relevant
[ ] preserve historical scroll position
```

---

## Future Episode Protection

```text
[ ] ensure future Mark Watched is unavailable in UI
[ ] enforce the rule in backend
[ ] add backend regression tests
[ ] add frontend regression tests
```

---

## Coordinated Refresh

```text
[ ] mobile refresh
[ ] desktop refresh
[ ] coordinate with Library
[ ] coordinate with Watch Next
[ ] coordinate with progress
[ ] coordinate with History
[ ] preserve loaded historical range
[ ] preserve scroll/context
```

---

## Air Time

```text
[ ] evaluate future provider data
[ ] define timezone model
[ ] define provider precedence
[ ] define missing-time behavior
[ ] only implement with reliable real data
```

---

## Final Validation

```text
[ ] mobile responsive audit
[ ] desktop responsive audit
[ ] ultrawide audit
[ ] bidirectional loading audit
[ ] date-boundary tests
[ ] accessibility audit
[ ] performance profiling
```

---

# Notes

> Upcoming is a temporal Episode timeline, not Watch Next.

> The initial near-future range does not define the maximum timeline range.

> Historical ranges are first-class and should be preserved as the user navigates.

> Future Episodes must not become normal Watch Next items before they air.

> Future Mark Watched must be protected by backend rules, not only disabled in Flutter.

> SofaWatch currently knows Episode air dates, not necessarily reliable Episode air times.

> Missing dates and times must never be invented.

> Planning and Watching can both be relevant to Upcoming, but presentation/business rules may distinguish them.

> A mutation in a historical range should not throw the user back to Today.

---

# Related Documentation

- [Implementation Status](implementation-status.md)
- [Library](library.md)
- [Viewing Progress](viewing-progress.md)
- [Watch List](watch-list.md)
- [Show Details](show-details.md)
- [Home](home.md)
- [History](history.md)
- [Metadata Sync](metadata-sync.md)
- [Architecture Overview](../architecture/overview.md)
- [Data Flow](../architecture/data-flow.md)
- [API Errors](../api/errors.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)
- [ADR-006: Provider-Independent Domain Architecture](../decisions/006-provider-independence.md)
