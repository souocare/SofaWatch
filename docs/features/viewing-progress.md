# Viewing Progress

## Overview

SofaWatch tracks viewing state through real viewing events and derives progress from those events.

For TV content, progress is calculated at Episode, Season, and Show level. For Movies, viewing events provide the watched state and rewatch count used by History and Statistics.

The backend is the source of truth for viewing state and progress calculations.

See:

- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)
- [Library](library.md)
- [Watch List](watch-list.md)
- [History](history.md)

---

## Status

**Implemented / Validation**

Implemented:

- Episode watched state;
- Episode watch events;
- explicit watched timestamps where supported;
- rewatches;
- individual watch-event history;
- watch-event removal;
- derived `is_watched`;
- derived `watch_count`;
- derived latest `watched_at`;
- Season progress;
- Show progress;
- overall progress;
- aired progress;
- caught-up state;
- next Episode calculation;
- next upcoming Episode calculation;
- Movie watch events;
- Movie rewatches;
- History and Statistics integration.

Remaining work is primarily final cross-feature validation, Upcoming mutation behavior, and coordinated refresh behavior.

---

# Core Model

A viewing is an event.

For Episodes:

```text
Episode
    |
    +-- EpisodeWatchEvent A
    +-- EpisodeWatchEvent B
    +-- EpisodeWatchEvent C
```

For Movies:

```text
Movie
    |
    +-- MovieWatchEvent A
    +-- MovieWatchEvent B
```

This allows SofaWatch to represent rewatches without overwriting previous history.

---

# Episode Watched State

The backend exposes the effective Episode state through values such as:

```text
is_watched
watch_count
watched_at
```

These values are derived from the user's watch events.

Conceptually:

```text
no watch events
-> is_watched = false
-> watch_count = 0
-> watched_at = null

one watch event
-> is_watched = true
-> watch_count = 1
-> watched_at = event timestamp

three watch events
-> is_watched = true
-> watch_count = 3
-> watched_at = latest event timestamp
```

The frontend should consume these values rather than independently reconstructing persisted truth.

---

# First Watch

Marking an unwatched Episode as watched creates its first viewing event.

```text
Episode
-> Mark Watched
-> EpisodeWatchEvent
```

The event records when the viewing occurred.

Where the API supports an explicit viewing date/time, that timestamp can be supplied by the client for legitimate historical corrections or entry flows.

---

# Rewatch

A rewatch creates another viewing event.

It does not update or replace the first event.

```text
first watch
-> event A

Watched Again
-> event B

Watched Again
-> event C
```

Result:

```text
watch_count = 3
watched_at = timestamp(event C)
```

This behavior is important for:

- Watch History;
- Profile History;
- Statistics;
- rewatch counts;
- rewatch time;
- activity timelines.

---

# Removing a Viewing Event

Individual viewing events can be removed when correcting history.

Example:

```text
event A
event B
event C
```

Removing `event B` produces:

```text
event A
event C
```

The backend then recalculates effective Episode state.

It must not incorrectly remove the entire watched history.

---

## Removing the Latest Event

If the latest event is removed:

```text
event A = older
event B = latest
```

then:

```text
remove event B
-> watch_count = 1
-> watched_at = timestamp(event A)
-> is_watched = true
```

---

## Removing the Last Remaining Event

If the only remaining viewing is removed:

```text
remove final event
-> watch_count = 0
-> watched_at = null
-> is_watched = false
```

---

# Mark Unwatched

The meaning of an Unwatch action must remain consistent with event-based history.

An operation that removes viewing state must not silently destroy multiple historical viewings unless that destructive behavior is explicitly intended by the API/action.

Where the UI exposes individual History entries, correction through event-level deletion is preferred for precise history management.

---

# Overall Progress

Overall progress compares watched Episodes with all known regular Episodes.

Future Episodes are included in the total.

Example:

```text
known regular Episodes = 10
watched Episodes = 5

overall progress = 5 / 10 = 50%
```

At Show level, Season 0 / Specials is excluded.

---

# Aired Progress

Aired progress considers only Episodes that are currently available according to their known air date.

An Episode is considered aired when:

```text
air_date != null
and
air_date <= today
```

Episodes without a known air date are not treated as aired.

Example:

```text
known Episodes = 10
aired Episodes = 5
watched aired Episodes = 5

overall progress = 5 / 10 = 50%
aired progress   = 5 / 5  = 100%
caught_up        = true
```

This distinction allows a Show to be fully caught up even when future Episodes are already known.

---

# Season Progress

Season progress can expose:

- watched Episode count;
- total Episode count;
- overall progress percentage;
- aired Episode count;
- watched aired Episode count;
- aired progress percentage;
- caught-up state.

Season-level progress can also be requested for Season 0 where needed.

Unlike Show-level regular progress, Season 0 can therefore have its own independently useful progress information.

---

# Show Progress

Show progress is calculated across regular Seasons.

Season 0 / Specials is excluded from:

- overall Show progress;
- aired Show progress;
- Show caught-up state;
- next-to-watch calculation;
- next-upcoming calculation.

This prevents Specials from unexpectedly blocking normal series progress.

---

# Dynamic Aggregates

Progress aggregates are calculated dynamically rather than persisted as duplicated aggregate truth.

Conceptually:

```text
Watch Events
     |
     v
Episode watched state
     |
     v
Season / Show progress
```

This reduces the risk of aggregate fields becoming inconsistent with actual viewing history.

---

# Caught-Up State

A Show or Season is caught up when:

```text
aired_episodes > 0
and
watched_aired_episodes == aired_episodes
```

Caught-up state is derived dynamically.

A Show can therefore be:

```text
overall progress < 100%
caught_up = true
```

when all aired Episodes are watched but future Episodes are already known.

---

## Caught Up Is Not Completed

`caught_up` and `Completed` are different concepts.

```text
caught_up
-> progress condition

Completed
-> user Library/tracking state
```

Similarly:

```text
Ended
-> provider Show lifecycle
```

is another separate concept.

These states must not be collapsed into one Boolean.

---

# Next Episode to Watch

The next Episode to watch is the earliest regular Episode that:

- has a known air date;
- has already aired;
- has not been watched by the current user.

Ordering follows:

```text
season number
then
episode number
```

Excluded:

- future Episodes;
- Episodes without a known air date;
- Specials.

When every currently aired regular Episode has been watched:

```text
next_episode = null
```

---

# Next Upcoming Episode

The next upcoming Episode is the earliest known regular Episode with:

```text
air_date > today
```

It is independent of the user's watched state.

This deliberately separates two questions:

```text
What can I watch now?
What airs next?
```

For a caught-up Show:

```text
next_episode = null
next_upcoming = next future Episode
```

---

# Future Episodes

Future Episodes contribute to overall progress when they are already known, but they do not contribute to aired progress.

They must not become the normal `next_episode` before they air.

This is also why Upcoming and Watch Next are distinct features.

---

# Episodes Without Air Dates

Episodes without a known air date:

- can exist as metadata;
- are not considered aired;
- are not returned as the next Episode to watch;
- should not be assigned an invented date.

If provider data later supplies a valid air date, normal calculations can include the Episode.

---

# Air Time

SofaWatch currently relies on air dates for progress eligibility.

A precise Episode air time must not be invented.

If a future provider supplies sufficiently reliable air-time data, eligibility rules can be revisited explicitly.

---

# Specials

Season 0 / Specials are intentionally excluded from normal Show progress and next-Episode calculations.

This avoids optional/special content blocking the user's regular-series progression.

Season-specific views can still expose progress for Season 0 where useful.

---

# Watch Next

Watch Next consumes backend-derived progress.

Conceptually:

```text
Library Show
    +
Viewing Progress
    +
Episode eligibility
    |
    v
Watch Next
```

A caught-up Show with no currently watchable Episode should not appear in Watch Next.

When a new Episode airs, the Show can become eligible again.

See [Watch List](watch-list.md).

---

# Haven't Watched in a While

Inactivity is based on actual viewing history.

The latest relevant viewing timestamp can be used to determine how long the user has been inactive on a started Show.

Rewatches are real viewing activity and therefore can affect the latest activity timestamp according to the feature's backend rule.

---

# Haven't Started

A Library Show with no viewing progress can be classified as not started.

This is derived from Library state plus absence of relevant watch events rather than requiring duplicate persisted progress state.

---

# Upcoming

Upcoming is driven by Episode air dates, while viewing progress determines whether historical/aired Episodes have already been watched.

Known remaining work includes finalizing interactions that allow applicable historical Episodes to be marked watched and ensuring future Episodes cannot be marked watched prematurely.

See [Upcoming](upcoming.md).

---

# Show Details

Show Details displays progress and allows viewing mutations.

After a watch-event mutation, relevant data should be reconciled, including:

- Episode state;
- Season progress;
- Show progress;
- Watch History;
- Watch Next where affected.

Season sections can load independently.

---

# Episode Watch History

Each Episode can expose its own viewing history.

History is ordered:

```text
watched_at DESC
```

Each row represents one actual viewing event.

The UI can therefore distinguish:

```text
watched once
watched twice
watched three times
```

without losing the timestamps of earlier viewings.

---

# Watch Count Presentation

The UI can represent repeated viewings compactly.

For example:

```text
1 viewing
-> watched indicator

2 viewings
-> 2x

3 viewings
-> 3x
```

Exact visual presentation belongs to the design system/presentation layer.

The numeric value comes from backend state.

---

# Movie Viewing Progress

Movies do not have episodic progress.

Their viewing state is based on `MovieWatchEvent`.

Conceptually:

```text
0 events
-> unwatched

1 event
-> watched once

N events
-> watched + rewatches
```

Movie watch history uses the same event-oriented principle as Episode history.

---

# Movie Rewatch

Each Movie rewatch creates another `MovieWatchEvent`.

This allows Statistics to distinguish:

- total Movie viewings;
- unique Movies watched;
- Movie rewatches.

It also preserves each viewing in History.

---

# Statistics

Statistics consume viewing events as actual viewing activity.

Therefore rewatches count again.

Examples include:

- Episodes watched;
- unique Episodes;
- Episode rewatches;
- Movies watched;
- unique Movies;
- Movie rewatches;
- total watch time;
- rewatch time;
- streaks;
- activity over time.

Statistics should not infer rewatches from overwritten watched flags.

---

# History

Global History combines Episode and Movie viewing events.

Ordering:

```text
watched_at DESC
```

A rewatch appears as another entry because it is another real viewing.

See [History](history.md).

---

# User Scoping

Viewing state is user-specific.

Conceptually:

```text
User A
-> Episode 42 watched twice

User B
-> Episode 42 unwatched
```

These are independent states.

The authenticated backend user defines whose watch events and progress are read or mutated.

---

# Backend Responsibility

The backend owns:

- watch-event creation;
- watch-event deletion;
- user scoping;
- watched-state derivation;
- watch counts;
- latest watched timestamp;
- aired eligibility;
- progress calculations;
- caught-up calculation;
- next Episode calculation;
- next upcoming Episode calculation.

Flutter should not duplicate these business rules.

---

# Frontend Responsibility

Flutter is responsible for:

- presenting backend progress;
- initiating watch mutations;
- showing mutation loading;
- preventing duplicate submissions where appropriate;
- displaying safe errors;
- reconciling affected UI after success;
- preserving useful navigation/scroll context.

---

# Cross-Feature Reconciliation

One viewing mutation can affect several features.

Example:

```text
Mark Episode Watched
        |
        +-> Episode state
        +-> Season progress
        +-> Show progress
        +-> Watch Next
        +-> Haven't Watched in a While
        +-> Watch History
        +-> Home
        +-> Statistics
```

The frontend should coordinate refresh/reconciliation without reimplementing the backend's eligibility rules.

---

# Partial Refresh Failures

A successful watch mutation and a failed secondary refresh are different outcomes.

Example:

```text
POST watch event = success
Watch Next refresh = failure
```

The UI should not incorrectly tell the user that marking the Episode watched failed.

Secondary state can expose its own retry/error behavior.

---

# Loading and Duplicate Submission

Watch mutations should expose item-level loading where possible.

For actions such as `Watched Again`, duplicate rapid submissions should be blocked while the request is in flight.

The rest of the page should remain usable unless a broader lock is genuinely necessary.

---

# Errors

Viewing mutations use the common SofaWatch error model.

Possible cases include:

- network failure;
- timeout;
- unauthorized;
- not found;
- validation error;
- conflict;
- server failure;
- invalid response.

Raw provider/database/Dio errors should not be shown directly to the user.

See [API Errors](../api/errors.md).

---

# Retry Safety

Read operations are generally safe to retry.

For watch-event creation, retry behavior should respect request semantics.

If the client cannot determine whether a non-idempotent creation request reached the server, blindly repeating it could create an unintended extra viewing event.

The API/client design should therefore avoid automatic unsafe replay of ambiguous mutations.

---

# Date and Time

Watch events use real timestamps.

Presentation should localize dates/times in the frontend according to the eventual localization strategy.

Backend persistence/API contracts should remain timezone-safe and unambiguous.

Date-sensitive tests should avoid depending on the real current date when deterministic clock injection is appropriate.

---

# Testing

Backend tests should cover:

```text
first watch
rewatch
watch_count
latest watched_at
event deletion
delete latest event
delete final event
user isolation
overall progress
aired progress
caught_up
Specials exclusion
future Episode exclusion
unknown air-date exclusion
next_episode
next_upcoming
Movie watch events
Movie rewatches
```

Frontend tests should cover:

```text
watched state
watch count presentation
Mark Watched
Watched Again
per-row mutation loading
duplicate-submit protection
history opening
event deletion
progress refresh
failure
Retry where safe
cross-feature refresh behavior
```

---

# Future Work

## Upcoming Interaction Validation

```text
[ ] allow applicable historical Episode Mark Watched where still pending
[ ] refresh progress immediately
[ ] refresh Watch Next immediately
[ ] block Mark Watched before emission
[ ] add corresponding regression tests
```

---

## Coordinated Refresh

```text
[ ] coordinate Shows refresh
[ ] preserve selected tab
[ ] preserve Watch List scroll
[ ] preserve Upcoming scroll
[ ] preserve historical ranges
[ ] keep previous data visible while refreshing where appropriate
```

---

## Air-Time Eligibility

```text
[ ] evaluate only when a real provider supplies reliable air times
[ ] define timezone semantics
[ ] update eligibility rules explicitly
[ ] never infer/fabricate missing times
```

---

## Deterministic Time Tests

```text
[ ] inject clock/today where useful
[ ] remove tests that become flaky as calendar dates advance
```

---

# Notes

> Viewing history is event-based. Rewatching never overwrites the previous viewing.

> `is_watched`, `watch_count`, and `watched_at` are backend-derived truth.

> Overall progress and aired progress intentionally answer different questions.

> A Show can be caught up while overall progress is below 100%.

> `caught_up`, `Completed`, and provider `Ended` status are separate concepts.

> Specials do not block normal Show progress.

> Future Episodes and Episodes without known air dates are not returned as the next Episode to watch.

> Air times must not be invented.

---

# Related Documentation

- [Implementation Status](implementation-status.md)
- [Library](library.md)
- [Watch List](watch-list.md)
- [Upcoming](upcoming.md)
- [Show Details](show-details.md)
- [Movies](movies.md)
- [History](history.md)
- [Statistics](statistics.md)
- [Home](home.md)
- [Architecture Overview](../architecture/overview.md)
- [Database Architecture](../architecture/database.md)
- [Data Flow](../architecture/data-flow.md)
- [API Errors](../api/errors.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)
