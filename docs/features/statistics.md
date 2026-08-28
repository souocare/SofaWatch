# Statistics

## Overview

Statistics is SofaWatch's dedicated analytics feature for understanding a user's viewing activity, habits, content preferences, and Library evolution.

Statistics is an independent feature.

Home and Profile may reuse compact Statistics data, but they should not own or duplicate Statistics business logic.

The feature is built around actual SofaWatch user data:

```text
EpisodeWatchEvent
MovieWatchEvent
Library
Shows / Seasons / Episodes
Movies
Genres
```

Rewatches are real viewing events and therefore contribute to activity and watch-time metrics unless a specific metric is explicitly defined as unique-only.

See:

- [Viewing Progress](viewing-progress.md)
- [History](history.md)
- [Library](library.md)
- [Home](home.md)
- [Movies](movies.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)

---

## Status

**Implemented / Evolving**

The Statistics feature currently covers or has established support for:

- Viewing Overview;
- total watch time;
- rewatch time;
- Episode viewing totals;
- unique Episode totals;
- Episode rewatch totals;
- Movie viewing totals;
- unique Movie totals;
- Movie rewatch totals;
- Shows vs Movies watch-time split;
- Activity Over Time;
- configurable time periods;
- adaptive activity buckets;
- watch-time activity;
- Episode/Movie activity;
- activity heatmap;
- Watching Habits;
- current streak;
- longest streak;
- biggest marathon by time;
- longest binge by Episode count;
- average active-day watch time;
- most active weekday;
- Content Insights;
- most watched Shows;
- most rewatched Shows;
- most rewatched Episodes;
- most rewatched Movies;
- top Show genres;
- top Movie genres;
- Library Statistics;
- Shows added;
- Movies added;
- Shows completed;
- compact summary reuse by Home/Profile.

Future work includes backlog analytics, future watch-time estimation, catch-up speed, backlog trend analysis, additional long-term insights, and final visualization/responsive/accessibility validation.

See [Implementation Status](implementation-status.md).

---

# Goals

Statistics should help answer questions such as:

```text
How much have I watched?
How much of that was rewatching?
How active have I been recently?
When do I watch most?
What do I watch most?
Which Shows, Movies, Episodes, and genres dominate my activity?
How is my Library changing?
How large is my backlog?
Am I catching up or falling further behind?
```

Statistics should remain explainable.

A metric should have a clear definition rather than being an opaque score.

---

# Principles

Statistics follows several core rules:

1. Backend is the source of truth for metric definitions.
2. Viewing events are the canonical basis for viewing activity.
3. Rewatches count as real activity.
4. Unique-content metrics are explicitly separate from total-viewing metrics.
5. Missing runtime must not be silently invented.
6. User data is strictly user-scoped.
7. Home/Profile reuse Statistics rather than recalculating it.
8. Time windows and bucket boundaries must be deterministic.
9. Derived insights should remain explainable.
10. Visualization must not change the meaning of the underlying data.

---

# Data Sources

Statistics can derive information from several persisted domains.

Conceptually:

```text
EpisodeWatchEvent ──┐
                    ├──> Viewing Statistics
MovieWatchEvent ────┘

Shows / Episodes ──────> Runtime / content context
Movies ────────────────> Runtime / content context
Genres ────────────────> Genre insights
Library ───────────────> Library statistics / backlog
```

Statistics should consume normalized SofaWatch entities and relationships rather than provider-specific response structures.

---

# User Scoping

All personal Statistics are scoped to the authenticated user.

Example:

```text
User A
-> 500 Episode viewings
-> 80 Movie viewings

User B
-> 20 Episode viewings
-> 4 Movie viewings
```

The same local Show or Movie can contribute differently to each user's Statistics because viewing events and Library membership are user-specific.

---

# Viewing Events as Source Data

Every real viewing is represented by an event.

For TV:

```text
EpisodeWatchEvent
```

For Movies:

```text
MovieWatchEvent
```

This event model allows Statistics to distinguish:

```text
total viewings
unique content
rewatches
activity dates
watch time
```

without relying on lossy Boolean watched flags.

---

# Rewatch Semantics

A rewatch is not metadata attached to the first viewing.

It is another viewing event.

Example:

```text
Episode A
-> event 1
-> event 2
-> event 3
```

Statistics interprets this as:

```text
Episode viewings = 3
Unique Episodes = 1
Episode rewatches = 2
```

The same principle applies to Movies.

---

# Viewing Overview

Viewing Overview provides the high-level totals for the user.

Core metrics include:

```text
Total watch time
Rewatch time
Episodes watched
Unique Episodes
Episode rewatches
Movies watched
Unique Movies
Movie rewatches
Shows vs Movies time split
```

These metrics should remain internally consistent.

---

# Total Watch Time

Total watch time represents estimated/known time spent viewing tracked Episodes and Movies.

Conceptually:

```text
sum(runtime for every viewing event with usable runtime)
```

Rewatches contribute again.

Example:

```text
Episode runtime = 45 min
watched 3 times

contribution = 135 min
```

---

# Runtime Accuracy

SofaWatch should use persisted/normalized runtime metadata where available.

It should not invent runtime for content with unknown duration merely to make totals look complete.

If runtime is missing, the product should either:

- exclude that unknown duration from time-based metrics; or
- explicitly model an estimation policy.

Any estimation policy must be documented and consistent.

---

# Rewatch Time

Rewatch time is the portion of total viewing time attributable to repeated viewings beyond the first viewing of the same content.

Conceptually:

```text
first viewing
-> normal watch time

second and later viewings
-> rewatch time
```

For content watched three times:

```text
total viewing runtime contribution = runtime * 3
rewatch runtime contribution = runtime * 2
```

---

# Episodes Watched

`Episodes watched` represents Episode viewing events.

It is not a unique count.

Example:

```text
Episode A watched twice
Episode B watched once

Episodes watched = 3
```

---

# Unique Episodes

`Unique Episodes` represents distinct Episodes with at least one viewing event.

Using the previous example:

```text
Unique Episodes = 2
```

---

# Episode Rewatches

Conceptually:

```text
Episode rewatches
=
Episode viewings - Unique Episodes
```

assuming each unique Episode has at least one first viewing.

This can also be calculated directly from grouped event counts.

---

# Movies Watched

`Movies watched` represents Movie viewing events.

Example:

```text
Movie A watched twice
Movie B watched once

Movies watched = 3
```

---

# Unique Movies

`Unique Movies` represents distinct Movies with at least one viewing event.

Using the previous example:

```text
Unique Movies = 2
```

---

# Movie Rewatches

Conceptually:

```text
Movie rewatches
=
Movie viewings - Unique Movies
```

or the equivalent grouped-event calculation.

---

# Shows vs Movies Time Split

Viewing time can be divided into:

```text
TV Shows
Movies
```

The split should use the same watch-time calculation as Total Watch Time.

Conceptually:

```text
show_time + movie_time = known total watch time
```

subject to the same missing-runtime policy.

---

# Percentage Presentation

If percentages are shown, rounding must not create misleading results.

The underlying duration values remain authoritative.

Presentation may round percentages while ensuring the labels remain understandable.

---

# Activity Over Time

Activity Over Time shows how viewing behavior changes across a selected period.

Supported periods include:

```text
7D
14D
30D
90D
1Y
All
```

The selected period determines the data range and appropriate bucket strategy.

---

# Period Semantics

Each period should have an explicit boundary definition.

For example:

```text
7D
-> today plus previous six local calendar days
```

or another chosen rule.

The backend/application contract should define this consistently.

The frontend should not independently reinterpret date boundaries.

---

# All-Time

`All` covers the user's available viewing history.

The starting boundary can be based on the earliest relevant viewing event.

An empty user should produce a valid empty dataset rather than an invalid date range.

---

# Adaptive Buckets

A seven-day chart and a multi-year chart should not necessarily use the same bucket size.

Conceptually:

```text
short period
-> daily buckets

medium period
-> daily or weekly buckets

long period
-> weekly or monthly buckets

all-time
-> adaptive based on history span
```

The exact thresholds should be centralized rather than duplicated in Flutter chart widgets.

---

# Watch-Time Chart

Activity can visualize watch time over the selected period.

Each bucket aggregates viewing duration for events within that bucket.

Rewatches contribute normally.

Missing runtime follows the standard runtime policy.

---

# Episode / Movie Activity

Activity Over Time can also expose viewing counts.

Possible series include:

```text
Episodes
Movies
```

These represent viewing events, not unique content, unless explicitly labeled otherwise.

---

# Activity Heatmap

An activity heatmap can provide a calendar-style view of viewing activity.

Potential intensity can be based on:

- watch time;
- viewing count.

The chosen measure should be explicit.

The heatmap should not mix definitions across cells.

---

# Empty Activity Period

A period with no viewing events is valid.

The chart should render an understandable empty/zero state rather than treating it as an API error.

---

# Watching Habits

Watching Habits derives behavioral patterns from viewing history.

Current/planned metrics include:

```text
Current streak
Longest streak
Biggest marathon by time
Longest binge by Episode count
Average active-day watch time
Most active weekday
```

Each metric requires a deterministic definition.

---

# Active Day

An active day is a local calendar day containing at least one relevant viewing event.

Conceptually:

```text
0 events
-> inactive

1+ events
-> active
```

Timezone handling matters because an event near midnight can belong to different calendar days in different timezones.

---

# Current Streak

Current streak measures consecutive active viewing days according to the chosen streak rule.

A typical definition is:

```text
consecutive local calendar days with at least one viewing
```

Whether a streak remains current when today has no viewing but yesterday did should be explicitly defined in the backend contract.

This rule should not be guessed separately by the frontend.

---

# Longest Streak

Longest streak is the maximum historical sequence of consecutive active days.

Example:

```text
Mon active
Tue active
Wed active
Thu inactive

longest candidate = 3 days
```

---

# Biggest Marathon by Time

Biggest marathon identifies the strongest continuous/defined viewing session by total duration.

A marathon requires an explicit session-gap definition if viewings are grouped into sessions.

For example, a future/implemented rule may define a new session when the gap between viewings exceeds a threshold.

Whatever threshold is used should be centralized and documented.

---

# Longest Binge by Episode Count

Longest binge focuses on Episode count rather than duration.

This is distinct from biggest marathon by time.

Example:

```text
Session A
-> 8 short Episodes
-> 160 min

Session B
-> 4 long Episodes
-> 240 min
```

Then:

```text
longest binge by Episode count = Session A
biggest marathon by time = Session B
```

depending on the session definition.

---

# Average Active-Day Watch Time

This metric answers:

```text
On days when I watch something, how much do I watch on average?
```

Conceptually:

```text
known watch time on active days
/
number of active days
```

It should not divide by every calendar day in the selected history unless the metric is explicitly renamed.

---

# Most Active Weekday

Viewing events can be grouped by local weekday.

Possible measurement bases include:

- viewing count;
- watch time.

The chosen definition should remain stable and be reflected in the UI label or supporting text.

---

# Content Insights

Content Insights identifies what dominates the user's viewing behavior.

Current/planned insights include:

```text
Most watched Shows
Most rewatched Shows
Most rewatched Episodes
Most rewatched Movies
Top Show genres
Top Movie genres
```

---

# Most Watched Shows

Most watched Shows should have an explicit ranking basis.

Possible/currently appropriate basis:

```text
total Episode viewing events belonging to the Show
```

This naturally includes rewatches.

If another metric such as watch time is used, it should be named accordingly.

---

# Most Rewatched Shows

Most rewatched Shows should rank Shows by repeat Episode viewings rather than simply total Episode viewings.

Conceptually:

```text
sum(max(episode_watch_count - 1, 0))
per Show
```

This distinguishes a Show with many unique Episodes from a Show the user repeatedly rewatches.

---

# Most Rewatched Episodes

Episodes can be ranked by:

```text
watch_count - 1
```

or equivalent event grouping.

Useful presentation can include:

- Show;
- `SxxExx`;
- Episode title;
- total viewings;
- rewatch count.

---

# Most Rewatched Movies

Movies can be ranked similarly:

```text
MovieWatchEvent count - 1
```

Presentation should distinguish:

```text
3 viewings
2 rewatches
```

if both values are exposed.

---

# Genre Insights

Genre statistics should use SofaWatch's normalized Genre relationships.

They should not directly depend on raw provider genre IDs.

See the provider-independence architecture and Genre mapping strategy.

---

# Top Show Genres

Show genre insights can be weighted according to an explicit rule.

Possible definitions include:

- number of watched Shows in the genre;
- Episode viewing events associated with Shows in the genre;
- watch time associated with the genre.

The chosen rule must be defined once.

A Show with multiple genres also requires a clear attribution rule.

---

# Top Movie Genres

Movie genre insights follow the same principle.

If a Movie belongs to multiple genres, SofaWatch should deliberately decide whether:

- each genre receives full credit;
- viewing time/count is fractionally attributed;
- another strategy is used.

Avoid hidden weighting rules.

---

# Genre Mapping Independence

Genre analytics should use internal Genre entities.

Conceptually:

```text
TMDB TV genre ID ───┐
TMDB Movie genre ID ├──> SofaWatch Genre
future provider ID ─┘
```

This prevents Statistics from becoming tied to TMDB's taxonomy identifiers.

---

# Library Statistics

Library Statistics describe tracked content rather than viewing events alone.

Current metrics include:

```text
Shows added
Movies added
Shows completed
```

Future metrics can expand into backlog analysis.

---

# Shows Added

Shows Added represents user Library additions according to the relevant time scope.

It should use Library entry data, not Show creation/import date.

A Show can exist locally before a specific user adds it.

---

# Movies Added

Movies Added similarly represents user Library additions.

It is separate from Movie import date.

---

# Shows Completed

Shows Completed should reflect user tracking state/business rules.

Provider `Ended` is not equivalent to user `Completed`.

Therefore Statistics must not count every ended Show as completed automatically.

---

# Home Integration

Home's `Your Week` uses compact Statistics data.

Typical metrics:

```text
Episodes watched
Movies watched
Watch time
```

Home should reuse Statistics definitions.

See [Home](home.md).

---

# Profile Integration

Profile can show a Statistics preview and navigate to the full Statistics experience.

Profile should not independently recalculate viewing totals.

See [Profile](profile.md).

---

# History Relationship

History and Statistics share the same underlying viewing events but answer different questions.

```text
History
-> what did I watch, and when?

Statistics
-> what patterns and totals emerge from those events?
```

Correcting/deleting a History event must therefore affect Statistics.

See [History](history.md).

---

# Viewing Mutation Reconciliation

When a new viewing event is created:

```text
History changes
Statistics changes
Home summary may change
```

When an event is deleted:

```text
History changes
Statistics must recalculate accordingly
```

Statistics should not maintain an independent irreversible counter that becomes inconsistent with editable History.

---

# Backlog

Backlog analytics are planned.

The basic TV backlog concept is:

```text
aired regular Episodes
-
watched regular Episodes
=
unwatched aired Episodes
```

subject to Library/status inclusion rules.

Movies can have a separate planned/watchlist backlog concept.

---

# TV Backlog

Potential metrics include:

```text
Unwatched aired Episodes
Estimated backlog watch time
Shows with backlog
Oldest unwatched Episode
```

Specials should follow the same progress/backlog policy used elsewhere and should not unexpectedly distort regular Episode backlog.

---

# Movie Backlog

A Movie backlog can represent Movies the user plans to watch and has not yet watched.

The exact Library classification should be reused rather than reconstructed inside Statistics.

---

# Future Watch Time

Future/backlog watch time can estimate how much known content remains.

For TV:

```text
sum(runtime of eligible unwatched aired Episodes)
```

For Movies:

```text
sum(runtime of eligible planned unwatched Movies)
```

Unknown runtimes must remain unknown rather than being fabricated.

---

# Catch-Up Speed

Catch-up speed is a future metric intended to compare consumption with backlog growth.

Conceptually, over a defined period:

```text
Episodes becoming available
vs
backlog Episodes watched
```

This requires careful treatment of:

- newly aired Episodes;
- newly added Shows;
- historical imports;
- status changes;
- rewatches;
- deleted events.

Rewatches should not falsely count as backlog reduction.

---

# Backlog Trend

A future trend can classify backlog as:

```text
growing
stable
shrinking
```

This should be based on a transparent time-series rule rather than a vague score.

---

# Historical Imports

Imported historical watch events must participate in Statistics according to their actual `watched_at` timestamps.

They should not all appear as activity on the import date.

This is especially important for Activity Over Time, streaks, and long-term insights.

---

# Import Corrections

If imported events are later corrected or removed, Statistics should reflect the corrected event history.

This reinforces why Statistics should be derived from canonical persisted data.

---

# Timezone

Timezone handling is critical for:

- daily buckets;
- streaks;
- weekdays;
- heatmaps;
- weekly periods;
- date-range boundaries.

A timestamp stored consistently by the backend still needs a defined user/application timezone when converted into calendar-day analytics.

The project should avoid accidental UTC/local mixtures.

---

# Deterministic Time

Date-sensitive Statistics tests should not depend on the real wall clock.

Use controlled clock/today injection where needed.

This is especially important for:

- 7D/14D/30D windows;
- current streak;
- current week;
- heatmaps;
- backlog trends.

---

# Localization

Future localization should cover:

- period labels;
- metric labels;
- date formatting;
- weekday names;
- durations;
- numbers;
- pluralization;
- chart axis labels;
- empty/error states.

Initial planned languages are English and Portuguese.

---

# Duration Formatting

Large watch-time values should be presented readably.

Examples:

```text
2h 35m
124h
5d 4h
```

The exact presentation can vary by context.

Underlying calculations should use a stable duration unit rather than formatted strings.

---

# Number Formatting

Large values should use locale-aware formatting when localization is implemented.

For example:

```text
1,250
```

versus locale-specific alternatives.

Domain/API values remain numeric.

---

# Backend Responsibility

The backend owns or should own:

- metric definitions;
- event aggregation;
- user scoping;
- time-range filtering;
- bucket calculation where business semantics are involved;
- streak calculation;
- content ranking;
- Library statistics;
- backlog rules;
- catch-up calculations;
- normalized numeric results.

This prevents Web/mobile clients from disagreeing about the same statistic.

---

# Frontend Responsibility

Flutter owns:

- metric presentation;
- cards;
- charts;
- period selection;
- responsive layouts;
- loading/error/empty states;
- navigation;
- accessible visualization;
- formatting based on normalized values.

Flutter should not independently reimplement core aggregation rules.

---

# Domain Models

Statistics domain models should expose meaningful normalized values rather than JSON/provider concepts.

Conceptually:

```text
StatisticsSummary
ViewingOverview
ActivitySeries
ActivityBucket
WatchingHabits
ContentInsights
LibraryStatistics
```

Exact names should follow the current codebase rather than introducing duplicate models solely to match documentation.

---

# API Design

Statistics endpoints should return enough semantic information that the frontend does not need to infer bucket meaning.

For chart data, useful normalized concepts can include:

```text
bucket start/end
label context
watch time
Episode count
Movie count
```

The backend contract should avoid presentation-specific pixel/layout concerns.

---

# Independent Sections

Statistics contains several logical sections that may have different data requirements.

A failure in one advanced insight should not necessarily make the entire feature unusable if the architecture supports independent requests.

For example:

```text
Viewing Overview
-> success

Activity
-> success

Content Insights
-> failure
```

The successful data should remain useful.

---

# Loading States

Possible loading scopes include:

```text
initial Statistics load
period change
Activity chart refresh
Content Insights
Library Statistics
```

Previous chart data can remain visible during a period refresh when that produces a smoother and unambiguous experience.

---

# Period Changes

Changing:

```text
7D -> 30D
```

should not reset unrelated Statistics sections unnecessarily.

Only period-dependent data should refresh if the architecture separates those concerns.

---

# Stale Request Protection

Rapid period changes can create out-of-order responses.

Example:

```text
7D request
30D request
90D request
```

The UI must not allow a slower 7D response to overwrite the currently selected 90D data.

Use the established application-state patterns for stale-response protection where required.

---

# Empty States

Valid empty states include:

- no viewing history;
- no activity in selected period;
- no rewatches;
- no genre data;
- no completed Shows;
- empty Library;
- no backlog.

An empty result is not a server error.

---

# Errors

Statistics uses SofaWatch's common error model.

Possible failures include:

- network;
- timeout;
- authentication;
- invalid response;
- server error.

Provider outages should only affect Statistics when the requested calculation genuinely requires live provider data.

Most historical Statistics should be based on local persisted data.

See [API Errors](../api/errors.md).

---

# Provider Failure Independence

Statistics should generally remain available when TMDB is temporarily unavailable because viewing events and imported metadata are local.

Example:

```text
TMDB unavailable
-> historical watch counts should still work
-> local History should still work
-> locally calculable Statistics should still work
```

A future external-rating insight can fail independently without breaking core Statistics.

---

# Charts

Charts are presentation of normalized Statistics data.

They should:

- have readable labels;
- handle zero values;
- handle long ranges;
- avoid misleading scales;
- support responsive widths;
- remain understandable without relying only on color;
- expose accessible alternatives/semantics where possible.

---

# Responsive Design

Mobile and desktop share Statistics domain/application logic.

Presentation adapts.

Mobile can use:

- vertically stacked metric cards;
- horizontally scrollable period selectors;
- compact charts;
- collapsible/ranked lists.

Desktop can use:

- multi-column overview cards;
- wider charts;
- side-by-side insight panels;
- constrained maximum widths on ultrawide displays.

---

# Accessibility

Final Statistics validation should include:

- semantic metric labels and values;
- chart descriptions;
- keyboard-accessible period controls;
- non-color-only series distinction;
- readable contrast;
- sensible focus order;
- accessible ranking lists;
- duration values understandable by screen readers.

Charts should not be the only way important information is communicated.

---

# Performance

Statistics can become aggregation-heavy as viewing history grows.

Potential backend considerations include:

- efficient indexed event queries;
- aggregation in SQL where appropriate;
- avoiding N+1 relationships;
- bounded ranked results;
- efficient date filtering;
- measuring before adding caches.

Potential frontend considerations include:

- avoiding unnecessary chart rebuilds;
- reusing period-independent data;
- bounded list rendering;
- preserving previous results during refresh.

Do not add persistent Statistics caching without evidence that it is needed.

---

# Database Considerations

Useful query dimensions include:

```text
user_id
watched_at
episode_id
movie_id
show relationships
Library user ownership
```

Indexes should follow actual query patterns.

Statistics requirements should not lead to provider-specific denormalization unless profiling justifies it.

---

# Testing

Backend tests should cover at least:

```text
empty user
user isolation
total Episode viewings
unique Episodes
Episode rewatches
total Movie viewings
unique Movies
Movie rewatches
total watch time
rewatch time
Shows vs Movies split
missing runtime
period boundaries
adaptive buckets
activity ordering
current streak
longest streak
marathon definition
binge definition
average active-day watch time
weekday calculation
most watched Shows
most rewatched Shows
most rewatched Episodes
most rewatched Movies
genre insights
Shows added
Movies added
Shows completed
history-event deletion reconciliation
historical imported timestamps
timezone boundaries
```

Frontend tests should cover at least:

```text
initial loading
overview success
overview empty
failure
Retry
period selector
period loading
stale-response protection
activity chart data
zero-activity period
watching habits
content rankings
Library Statistics
duration formatting
responsive layout
partial section failures
Home summary reuse
```

---

# Edge Cases

## No Viewing History

```text
0 Episode events
0 Movie events

Total watch time = 0
viewing counts = 0
rewatches = 0
```

Habit metrics should use a valid empty representation.

## One Episode Watched Three Times

```text
Episodes watched = 3
Unique Episodes = 1
Episode rewatches = 2
```

## One Movie Watched Twice

```text
Movies watched = 2
Unique Movies = 1
Movie rewatches = 1
```

## Missing Runtime

```text
viewing exists
runtime unknown

count metrics -> still count viewing
time metrics -> do not fabricate duration
```

## Delete a Rewatch Event

```text
3 viewings -> 2 viewings

total viewing count decreases
rewatch count decreases
watch time decreases if runtime known
```

## Delete the First Chronological Event

The remaining events still represent real viewings.

Statistics should derive totals from remaining canonical events rather than relying on a permanently marked "first watch" row.

## Same Content Across Users

Only the authenticated user's events contribute.

## Provider Offline

Locally derivable Statistics should remain available.

## No Activity in 7D but Historical Activity Exists

```text
7D -> zero/empty activity
All -> historical data
```

This is valid.

---

# Future Work

## Backlog Statistics

```text
[ ] unwatched aired Episodes
[ ] Shows with backlog
[ ] planned unwatched Movies
[ ] backlog watch-time estimate
[ ] oldest backlog content
```

---

## Catch-Up Analytics

```text
[ ] define catch-up speed
[ ] distinguish first watches from rewatches
[ ] measure new backlog vs consumed backlog
[ ] classify backlog growing/stable/shrinking
[ ] define useful time windows
[ ] handle Library additions correctly
```

---

## Long-Term Insights

Potential additions include:

```text
[ ] year-over-year viewing
[ ] monthly trends
[ ] annual summaries
[ ] genre evolution over time
[ ] completion trends
[ ] viewing-time trends
```

Only add metrics that provide understandable value.

---

## Visualization Audit

```text
[ ] mobile chart validation
[ ] desktop chart validation
[ ] ultrawide validation
[ ] zero-data states
[ ] large-history datasets
[ ] accessibility alternatives
[ ] locale-aware labels
```

---

## Performance Audit

```text
[ ] profile Statistics queries with large history
[ ] verify indexes
[ ] check N+1 behavior
[ ] benchmark All-time queries
[ ] evaluate caching only if measurements justify it
```

---

## Deterministic Time

```text
[ ] audit all period-boundary tests
[ ] inject clock/today where needed
[ ] test timezone transitions
[ ] test year/month boundaries
```

---

# Notes

> Statistics is an independent feature. Home and Profile consume it; they do not own its business logic.

> Total viewing counts include rewatches.

> Unique-content counts do not count the same content more than once.

> Rewatch counts represent viewings beyond the first remaining viewing of a content item.

> Rewatches contribute to watch time.

> Missing runtime must not be invented.

> History corrections must propagate naturally into Statistics.

> Provider `Ended` and user `Completed` are different concepts.

> Genre analytics should use internal Genre relationships rather than raw TMDB IDs.

> Backlog and catch-up analytics remain future work and require explicit, testable definitions.

> Statistics should remain mostly functional even when an external metadata provider is unavailable.

---

# Related Documentation

- [Implementation Status](implementation-status.md)
- [Viewing Progress](viewing-progress.md)
- [Watch List](watch-list.md)
- [Upcoming](upcoming.md)
- [Show Details](show-details.md)
- [Movies](movies.md)
- [Home](home.md)
- [History](history.md)
- [Library](library.md)
- [Profile](profile.md)
- [Architecture Overview](../architecture/overview.md)
- [Database Architecture](../architecture/database.md)
- [Data Flow](../architecture/data-flow.md)
- [Frontend Contract](../api/frontend-contract.md)
- [API Errors](../api/errors.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)
- [ADR-003: Internal Media IDs](../decisions/003-internal-media-ids.md)
- [ADR-006: Provider Independence](../decisions/006-provider-independence.md)
