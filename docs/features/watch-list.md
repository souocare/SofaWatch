# Watch List

## Overview

Watch List is the primary TV-oriented workflow for deciding what the user can or should continue watching.

It is not a persisted list of duplicated recommendations. Its collections are derived from the user's Library, Episode metadata, and viewing history.

The Watch List contains four main sections:

```text
Watch Next
Haven't Watched in a While
Haven't Started
Watch History
```

The backend is the source of truth for inclusion rules, viewing progress, and ordering where those rules represent application business logic.

See:

- [Viewing Progress](viewing-progress.md)
- [Library](library.md)
- [Upcoming](upcoming.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)

---

## Status

**Implemented / Validation**

The core Watch List experience is implemented.

Implemented:

- Watch Next;
- Haven't Watched in a While;
- Haven't Started;
- Watch History;
- Episode progress;
- Mark Watched;
- Rewatch / Watched Again;
- real watch-event history;
- interaction with Library state;
- caught-up handling;
- independent collection behavior;
- responsive presentation foundation.

Remaining work is primarily final rule/ordering validation, edge-case coverage, coordinated refresh, and responsive validation.

See [Implementation Status](implementation-status.md).

---

# Goals

Watch List is designed to answer four different questions:

```text
Watch Next
-> What Episode should I continue with?

Haven't Watched in a While
-> Which started Shows have I neglected?

Haven't Started
-> Which tracked Shows have I not begun?

Watch History
-> What have I actually watched recently?
```

These collections should remain semantically distinct.

---

# Source Data

Watch List is derived from authoritative SofaWatch data including:

- authenticated user;
- Library entries;
- Show tracking state;
- Seasons;
- Episodes;
- Episode air dates;
- Episode watch events;
- watched state;
- latest watched timestamp;
- caught-up state.

Conceptually:

```text
Library
   +
Episode metadata
   +
Viewing events
   |
   v
Watch List rules
   |
   +-> Watch Next
   +-> Haven't Watched in a While
   +-> Haven't Started
   +-> Watch History
```

---

# User Scoping

Every Watch List collection is user-specific.

The same Show can produce different results for different users.

Example:

```text
User A
-> Show X: S02E04 next

User B
-> Show X: not started

User C
-> Show X: caught up
```

The backend determines the user from authentication.

---

# Watch Next

Watch Next contains actively tracked Shows for which there is a currently eligible next Episode to watch.

A typical row can show:

- Show;
- poster/artwork;
- next Episode;
- season/episode number;
- Episode title;
- air date;
- progress;
- Mark Watched.

Example:

```text
Severance
S02E03 — Who Is Alive?
Progress: 12 / 18
[Mark Watched]
```

---

## Watch Next Eligibility

A Show should only appear when it satisfies the current Watch Next business rules.

Conceptually, the Show must:

- be relevant to active tracking;
- have viewing/progress state compatible with Watch Next;
- have an eligible next Episode;
- not be caught up with no currently watchable Episode;
- not be excluded by another mutually exclusive Watch List classification.

The exact rule belongs to backend business logic.

---

## Eligible Next Episode

The next Episode is the earliest regular Episode that:

- has a known air date;
- has already aired;
- is unwatched by the current user.

Ordering follows regular Episode order:

```text
season number
then
episode number
```

Specials are excluded from normal next-Episode progression.

Future Episodes are not returned as Watch Next.

Episodes with unknown air dates are not assumed to have aired.

See [Viewing Progress](viewing-progress.md).

---

## Caught-Up Shows

A caught-up Show with no currently watchable Episode does not belong in Watch Next.

Example:

```text
aired Episodes = 10
watched aired Episodes = 10
future Episode = S02E11

Watch Next
-> no row for the Show yet
```

When S02E11 becomes eligible:

```text
Watch Next
-> Show can return
```

This is dynamic behavior and should not require manually changing the Show's Library status.

---

## Ended Shows

A provider status of `Ended` does not automatically exclude a Show from Watch Next.

Example:

```text
Show status = Ended
Episodes = 30
watched = 20

next eligible Episode exists
-> Show can remain in Watch Next
```

`Ended` describes the content lifecycle.

`Completed` describes the user's tracking state.

These must not be conflated.

---

## No Known Next Episode

If SofaWatch cannot identify an eligible next Episode:

```text
next_episode = null
```

the application must not invent one.

Depending on the rest of the user's progress, the Show may be caught up or may require another appropriate state, but Watch Next should not fabricate content.

---

# Mark Watched from Watch Next

Watch Next provides a fast path for normal Episode progression.

Conceptually:

```text
S01E04 = next
     |
     v
Mark Watched
     |
     v
create EpisodeWatchEvent
     |
     v
recalculate progress
     |
     v
S01E05 may become next
```

After success, the UI should reconcile the affected row immediately.

---

## Mutation Effects

Marking an Episode watched can affect:

- Episode watched state;
- watch count;
- latest watched timestamp;
- Season progress;
- Show progress;
- Watch Next;
- Haven't Watched in a While;
- Watch History;
- Home;
- Statistics.

The backend remains responsible for the resulting business state.

---

## Mutation Loading

The affected row/action should expose loading while the request is in flight.

Duplicate rapid submissions should be blocked.

The rest of the Watch List should remain usable where possible.

---

# Haven't Watched in a While

This collection highlights Shows that the user started but has not watched recently.

Its purpose is re-engagement.

It is different from Watch Next:

```text
Watch Next
-> normal continuation

Haven't Watched in a While
-> inactive continuation
```

---

## Inactivity

Inactivity is based on actual viewing history.

The backend can use the user's latest relevant watch activity together with the configured/current inactivity threshold.

Conceptually:

```text
started Show
+
eligible next Episode
+
last viewing older than threshold
-> Haven't Watched in a While
```

---

## Rewatch and Activity

A rewatch is a real viewing event.

Therefore, if inactivity rules use the latest relevant viewing event, a rewatch can update recent activity.

This behavior should remain explicit and tested rather than inferred differently by the client.

---

## Mutual Exclusivity

A Show should not appear simultaneously in:

```text
Watch Next
and
Haven't Watched in a While
```

when the product rule treats inactivity as a distinct Watch List classification.

The backend should decide the classification once.

The frontend should not independently filter duplicates after receiving contradictory collections.

---

## Ordering

Haven't Watched in a While should prioritize inactivity meaningfully.

A natural ordering is based on how long it has been since the last relevant viewing.

The exact ascending/descending representation should remain consistent with the UI intent.

For example, the most neglected Shows may appear first.

---

# Haven't Started

Haven't Started contains tracked Shows with no normal viewing progress.

Typical examples are Shows in Planning/Watchlist state that the user has not begun.

A row may show:

- Show;
- first eligible Episode;
- basic metadata;
- Start action.

---

## Eligibility

Conceptually:

```text
Show in Library
+
not started
+
appropriate tracking state
-> Haven't Started
```

A Show with actual Episode viewing history should not remain classified as Haven't Started.

---

## First Episode

Where available, the UI can expose the first eligible regular Episode.

It must not invent an Episode if metadata is incomplete.

Specials should not become the default starting point for normal series progression.

---

# Start Action

`Start` is a user-facing shortcut for beginning the Show.

If it marks the first eligible Episode as watched, it should use the same authoritative watch-event infrastructure as any other Mark Watched action.

It should not introduce a separate parallel progress model.

---

# Watch History

Watch History shows actual Episode viewing events.

It is not a list of Episodes with `is_watched = true`.

Example:

```text
S01E01 watched Jan 1
S01E02 watched Jan 2
S01E01 rewatched Jan 10
```

History contains three entries.

---

## Ordering

Watch History is ordered:

```text
watched_at DESC
```

The most recent viewing appears first.

Every rewatch remains an individual entry.

---

## History Row

A Watch History row can show:

- Show;
- season/episode number;
- Episode title;
- watched timestamp;
- watch-related actions where appropriate.

The timestamp belongs to the specific viewing event represented by that row.

---

# Watched Again / Rewatch

Watch History can expose `Watched Again`.

This creates a new viewing event using the current time.

Conceptually:

```text
existing history row
      |
      v
Watched Again
      |
      v
new EpisodeWatchEvent(now)
      |
      v
new history entry at top
```

The previous event remains intact.

---

## Rewatch UX

The action should:

- create a new event;
- use the current time;
- avoid an unnecessary date picker for the quick Rewatch action;
- expose per-row loading;
- block double submission;
- refresh affected progress;
- refresh Watch List collections as required.

The action can use a tooltip/accessible label such as:

```text
Watched again
```

---

# Removing History Events

Where correction actions are available, individual viewing events can be removed.

After removal, the backend recalculates:

```text
is_watched
watch_count
watched_at
```

Deleting one event must not automatically remove all other viewing events.

See [Viewing Progress](viewing-progress.md).

---

# Watch History vs Full History

Watch List's Watch History is a TV-focused working collection.

Profile's full History can combine:

```text
Episodes
Movies
```

with global chronological ordering.

The same underlying watch events should be reused rather than duplicated into separate history records.

See [History](history.md).

---

# Inclusion Rules

Watch List collection membership should be centralized enough to avoid contradictory rules across endpoints/features.

Important dimensions include:

- Library state;
- started/not started;
- caught-up state;
- next eligible Episode;
- inactivity;
- provider Show lifecycle;
- user completion state;
- dropped state;
- Episode air date.

The frontend should not independently recreate this matrix.

---

# Tracking States

Relevant TV tracking states currently include:

```text
Watching
Planning
Completed
Dropped
```

`Paused` remains deliberately deferred.

---

## Watching

Watching Shows can participate in:

- Watch Next;
- Haven't Watched in a While;
- Upcoming;
- Missed Recently.

Their exact collection depends on progress and activity.

---

## Planning

Planning Shows generally belong to not-started flows rather than normal Watch Next.

Planning can still be relevant to future Episode discovery/Upcoming presentation where the product explicitly supports it.

---

## Completed

Completed Shows should not behave as active normal Watch Next items.

This is user state, not provider lifecycle.

---

## Dropped

Dropped Shows should not appear as active continuation suggestions.

Their history remains valid.

Dropping a Show must not erase viewing events.

---

# Specials

Season 0 / Specials are excluded from normal Watch Next progression.

They should not block a Show from being caught up on regular Episodes.

Their watch events can still exist and remain visible in relevant History/details contexts.

---

# Future Episodes

Future Episodes do not become Watch Next until eligible.

They belong to Upcoming instead.

This separation keeps:

```text
Watch Next
-> available to watch

Upcoming
-> not yet aired
```

semantically correct.

---

# Unknown Air Dates

An Episode with no known air date is not assumed to be aired.

It should not become Watch Next merely because its season/episode number follows the last watched Episode.

Provider metadata should be refreshed rather than inventing eligibility.

---

# Air Time

Current progression uses air dates.

Precise air-time eligibility is deferred until a provider supplies sufficiently reliable values and timezone semantics are explicitly defined.

---

# Partial Failures

Watch List collections should fail independently where practical.

Example:

```text
Watch Next
-> success

Haven't Watched in a While
-> failure

Haven't Started
-> success

Watch History
-> success
```

The successful collections should remain usable.

A single failed collection should not unnecessarily replace the whole page with one error screen.

---

# Loading States

Each collection can have its own:

```text
initial
loading
success
empty
failure
```

Refresh can preserve previous successful data while showing subtle progress where appropriate.

Pagination/loading-more state should remain distinct from initial loading if a collection uses pagination.

---

# Empty States

Empty collections are normal.

Examples:

```text
Watch Next
-> You're caught up

Haven't Watched in a While
-> Nothing neglected

Haven't Started
-> No unstarted Shows

Watch History
-> No viewing history yet
```

Exact copy should follow the application's localization/content strategy.

An empty state is not an error.

---

# Retry

Retry should target the failed operation/collection.

Examples:

```text
Watch History failed
-> retry Watch History

Watch Next failed
-> retry Watch Next
```

Do not reload unrelated successful sections unless the architecture requires a coordinated refresh for correctness.

---

# Pagination

Collections that can grow significantly, especially Watch History, should support bounded loading/pagination where implemented.

Pagination loading should:

- preserve existing rows;
- show progress at the end;
- keep the list interactive;
- expose pagination-specific Retry if loading the next page fails.

---

# Refresh

A coordinated Shows refresh remains a known improvement area.

A full refresh may need to update:

- Library;
- Watch Next;
- Haven't Watched in a While;
- Haven't Started;
- progress / Up to Date;
- Upcoming;
- Watch History if loaded.

---

## Refresh Context Preservation

Refresh should preserve:

- selected Shows tab;
- previous data while refreshing where appropriate;
- Watch List scroll;
- Upcoming scroll;
- already loaded historical range.

Refresh should not feel like navigating to a new page.

---

# Shows Tab Preservation

Shows contains at least:

```text
Watch List
Upcoming
```

The selected tab should survive relevant state changes and temporary navigation where appropriate.

A mutation inside Watch List should not unexpectedly switch the user to Upcoming.

---

# Home Integration

Home reuses selected Watch List concepts rather than implementing separate business logic.

Examples:

```text
Continue Watching
-> Watch Next

Recent Activity
-> Watch History preview
```

Home should request/use the appropriate backend/application data rather than independently recomputing eligibility.

See [Home](home.md).

---

# Show Details Integration

Viewing mutations in Show Details can change Watch List membership.

Example:

```text
Show Details
-> Mark Episode Watched
-> Show becomes caught up
-> remove from Watch Next
```

Cross-feature reconciliation should maintain consistency without moving Watch List business rules into Show Details.

---

# Upcoming Integration

Upcoming and Watch List share Episode metadata but answer different questions.

```text
Watch List
-> what to watch now / resume

Upcoming
-> what airs when
```

Marking a historical Episode watched from Upcoming should update Watch Next/progress immediately once that interaction is finalized.

---

# Statistics Integration

Watch List actions create real watch events.

Statistics therefore naturally reflect:

- first watches;
- rewatches;
- viewing timestamps;
- watch time;
- streaks.

Watch List should not separately increment Statistics counters.

---

# Backend Architecture

The backend should own collection queries/rules through appropriate services and repositories.

Conceptually:

```text
API route
   |
   v
Watch List service
   |
   +-> Library repository
   +-> Episode/progress repository
   +-> Watch-event repository
   |
   v
Watch List response
```

The exact implementation should follow the current codebase rather than forcing an abstraction purely because it appears in this document.

---

# Frontend Architecture

Flutter should separate:

```text
presentation
-> sections, rows, actions, responsive layout

application
-> load/retry/mutation orchestration

domain
-> Watch List models/contracts

data
-> API DTOs/mapping/repositories
```

Business inclusion rules should not migrate into widgets.

---

# Responsive Design

Mobile validation should cover:

- all four sections;
- long Show/Episode titles;
- narrow widths;
- Mark Watched;
- Start;
- Watched Again;
- History actions;
- touch targets;
- safe areas.

Desktop validation should cover:

- maximum useful content width;
- ultrawide displays;
- row density;
- action alignment;
- readable metadata hierarchy.

---

# Accessibility

Final validation should include:

- semantic action labels;
- keyboard access on Web/Desktop;
- focus behavior;
- accessible progress descriptions;
- non-color-only status communication;
- sufficient touch targets.

---

# Testing

Backend tests should cover:

```text
Watch Next inclusion
Watch Next exclusion
caught-up exclusion
newly aired Episode returns Show
Ended + unwatched remains eligible
Completed exclusion
Dropped exclusion
Planning behavior
Specials exclusion
future Episode exclusion
unknown air-date behavior
Haven't Watched in a While inclusion
inactivity ordering
mutual exclusivity
Haven't Started inclusion
started Show exclusion
Watch History ordering
rewatch event creation
event removal
user isolation
```

Frontend tests should cover:

```text
initial loading
success
empty state
independent failures
Retry
Mark Watched
row loading
duplicate-submit protection
next Episode update
Start
Watched Again
History update
event deletion
pagination if applicable
tab preservation
responsive layouts
```

---

# Edge Cases

Important regression cases include:

## Caught Up

```text
all aired Episodes watched
future Episodes known
-> no Watch Next
```

## Newly Aired Episode

```text
previously caught up
new Episode airs
-> Show returns to Watch Next
```

## Ended but Incomplete

```text
provider = Ended
user has unwatched aired Episodes
-> can remain actionable
```

## No Known Next Episode

```text
metadata incomplete
-> do not invent Episode
```

## Rewatch

```text
Watched Again
-> new event
-> old event preserved
```

## Remove Latest Viewing

```text
latest event deleted
-> previous event becomes watched_at
```

## Remove Final Viewing

```text
last event deleted
-> Episode becomes unwatched
```

## Dropped Show

```text
history remains
active continuation disappears
```

---

# Future Work

## Inclusion and Ordering Audit

```text
[ ] final inclusion-rule audit
[ ] final ordering audit
[ ] caught-up regression coverage
[ ] Ended/Completed regression coverage
[ ] no-known-next-Episode regression coverage
[ ] confirm Watch Next / inactivity mutual exclusivity
```

---

## Upcoming Mutations

```text
[ ] Mark Watched for applicable historical Upcoming Episodes
[ ] update progress immediately
[ ] update Watch Next immediately
[ ] block Mark Watched for future Episodes
[ ] add regression tests
```

---

## Coordinated Refresh

```text
[ ] mobile refresh
[ ] desktop refresh
[ ] coordinated collection refresh
[ ] preserve selected tab
[ ] preserve Watch List scroll
[ ] preserve Upcoming scroll
[ ] preserve historical ranges
```

---

## Responsive Validation

```text
[ ] mobile Watch List audit
[ ] long-title audit
[ ] narrow-width actions
[ ] History action layout
[ ] desktop density
[ ] ultrawide maximum width
[ ] accessibility pass
```

---

# Notes

> Watch List collections are derived from Library, Episode metadata, and viewing events. They are not independent duplicated persistence models.

> A caught-up Show does not appear in Watch Next until another Episode becomes eligible.

> `Ended` does not mean `Completed`.

> Watch Next and Haven't Watched in a While should not duplicate the same Show when inactivity is treated as a separate classification.

> Rewatch creates another viewing event and preserves the original history.

> Specials, future Episodes, and Episodes without known air dates do not become normal Watch Next Episodes.

> The backend owns inclusion rules. Flutter owns presentation and orchestration.

---

# Related Documentation

- [Implementation Status](implementation-status.md)
- [Library](library.md)
- [Viewing Progress](viewing-progress.md)
- [Upcoming](upcoming.md)
- [Show Details](show-details.md)
- [History](history.md)
- [Home](home.md)
- [Statistics](statistics.md)
- [Architecture Overview](../architecture/overview.md)
- [Database Architecture](../architecture/database.md)
- [Data Flow](../architecture/data-flow.md)
- [API Errors](../api/errors.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)
