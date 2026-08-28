# Home

## Overview

Home is SofaWatch's personal viewing dashboard.

Its purpose is to provide a concise overview of the user's current viewing activity and the most relevant next actions without duplicating the full functionality of Shows, Movies, Explore, History, or Statistics.

The intended structure is:

```text
Header
Your Week
Continue Watching
Premiering Today
Upcoming
Missed Recently
Recent Activity
```

Home is primarily an aggregation and presentation feature.

Where another SofaWatch feature already owns the underlying business rule, Home should reuse that rule/data rather than implement a second version.

See:

- [Watch List](watch-list.md)
- [Upcoming](upcoming.md)
- [Statistics](statistics.md)
- [History](history.md)
- [Library](library.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)

---

## Status

**Implemented / Evolving**

Implemented or established:

- personal dashboard structure;
- greeting/header;
- current date;
- account/avatar entry point;
- Your Week;
- Episodes watched summary;
- Movies watched summary;
- watch-time summary;
- Continue Watching;
- Premiering Today;
- Upcoming;
- Missed Recently;
- Recent Activity;
- responsive dashboard foundation.

Deliberately deferred:

- Quick Actions;
- Home recommendations.

Remaining work is primarily final cross-feature consistency, coordinated refresh, responsive validation, and accessibility/performance auditing.

See [Implementation Status](implementation-status.md).

---

# Goals

Home should answer, at a glance:

```text
How much have I watched recently?
What should I continue?
What airs today?
What is coming next?
Did I miss anything recently?
What did I watch most recently?
```

It should remain fast to understand and should not become a second copy of every major SofaWatch feature.

---

# Non-Goals

Home is not:

- the full Watch List;
- the full Upcoming timeline;
- the full Statistics dashboard;
- the full History timeline;
- the Movie Library;
- Explore;
- global Search;
- an administration dashboard.

Each Home section should link or navigate naturally to the richer feature when more detail is required.

---

# Aggregation Principle

Home composes information owned elsewhere.

Conceptually:

```text
Statistics
     |
     +------> Your Week

Watch List
     |
     +------> Continue Watching

Upcoming
     |
     +------> Premiering Today
     +------> Upcoming
     +------> Missed Recently rules/data

History
     |
     +------> Recent Activity
```

The exact API/application implementation can optimize this composition, but business definitions should remain consistent.

---

# User Scoping

Every Home section is user-specific.

The authenticated user determines:

- viewing statistics;
- Library;
- Watch Next;
- Upcoming tracked Shows;
- missed Episodes;
- recent History.

Home should never mix state across users.

---

# Header

The Home header provides lightweight personal context.

It can include:

- greeting;
- current date;
- user display name where appropriate;
- avatar/profile entry point;
- account/settings access.

---

# Greeting

The greeting can adapt to the local time of day.

Conceptually:

```text
Good morning
Good afternoon
Good evening
```

This is presentation behavior.

It should not require backend business logic.

Future localization should translate the greeting and format it appropriately.

---

# Current Date

The header can display the current date using locale-aware formatting.

The frontend should avoid hardcoded English date formatting once localization is introduced.

The displayed current date and backend date-sensitive feature semantics should use clearly defined timezone assumptions.

---

# Account / Avatar

The avatar/profile action can provide access to account/profile functionality.

Administrative actions should not be placed in Home merely because the current user is an Administrator.

Those belong to Profile/administration surfaces.

---

# Your Week

Your Week is a compact viewing summary.

It should reuse Statistics rather than maintaining separate Home counters.

The intended compact metrics include:

```text
Episodes watched
Movies watched
Watch time
```

---

# Episodes Watched

Episodes watched represents actual Episode viewing events in the relevant weekly period.

Rewatches count again because they are real viewing activity.

Example:

```text
S01E01 first watch
S01E02 first watch
S01E01 rewatch

Episodes watched = 3
Unique Episodes = 2
```

Home normally needs only the compact `Episodes watched` metric.

Detailed unique/rewatch breakdown belongs to Statistics.

---

# Movies Watched

Movies watched similarly represents Movie viewing events.

Example:

```text
Movie A
Movie B
Movie A rewatch

Movies watched = 3
Unique Movies = 2
```

Home should display the concise total while Statistics owns deeper analysis.

---

# Watch Time

Watch time is derived from viewing activity and known runtimes.

It should use the same Statistics definition as the full Statistics feature.

Home must not independently calculate runtime totals using a slightly different rule.

---

# Rewatches in Your Week

Rewatches count toward:

- Episodes watched;
- Movies watched;
- watch time.

This matches the event-based viewing model.

A separate rewatch metric can remain in Statistics rather than increasing Home density unnecessarily.

---

# Your Week Period

The exact definition of "Your Week" should remain consistent with the Statistics/application contract.

If it represents a rolling seven-day period or a calendar week, that rule should be defined once and reused.

Home presentation should not silently use a different date window.

---

# Continue Watching

Continue Watching is the Home preview of normal continuation.

It reuses Watch Next semantics.

Conceptually:

```text
Watch Next
    |
    v
small Home subset
```

Home should not independently calculate the next Episode for every Show.

---

# Continue Watching Content

A compact card can expose:

- Show;
- poster/artwork;
- next Episode;
- `SxxExx`;
- Episode title;
- progress;
- Mark Watched where supported.

The number of rows/cards should remain intentionally small.

The full collection belongs to Shows → Watch List.

---

# Continue Watching Eligibility

Eligibility must match Watch Next.

Therefore:

- caught-up Shows without an eligible Episode are absent;
- future Episodes are not Watch Next;
- Specials do not unexpectedly block normal progress;
- provider `Ended` does not automatically mean user `Completed`;
- dropped/completed behavior follows Watch List rules.

See [Watch List](watch-list.md).

---

# Continue Watching Mutation

If Home exposes Mark Watched:

```text
Mark Watched
-> create EpisodeWatchEvent
-> update progress
-> update next Episode
-> update Home sections
```

The mutation must use the same viewing infrastructure as Show Details and Watch List.

---

# Continue Watching Empty State

An empty Continue Watching section is valid.

It can mean:

- the user is caught up;
- no Shows have been started;
- no currently eligible Episode exists.

Home should not fabricate content merely to avoid an empty section.

---

# Premiering Today

Premiering Today highlights relevant Episodes with:

```text
air_date == today
```

This is distinct from Continue Watching.

A Show can be caught up yesterday and have a new Episode premiering today.

---

# Premiering Today Inclusion

The intended product behavior can include Shows in:

```text
Watching
Planning
```

Presentation should make the difference understandable.

A Planning Show premiering today is not the same user context as a Watching Show receiving its next Episode.

---

# Planning Presentation

When a Premiering Today item belongs to a Planning Show, the UI can use a visual distinction or label.

The distinction should be semantic and accessible, not color-only.

---

# Air Date, Not Invented Air Time

Premiering Today is based on the Episode's known `air_date`.

SofaWatch should not show a fabricated broadcast time.

If reliable air-time support is added later through a real provider, timezone semantics must be defined first.

See [Upcoming](upcoming.md).

---

# Upcoming

The Home Upcoming section is a compact future preview.

It starts tomorrow.

This intentionally avoids duplicating Premiering Today.

Conceptually:

```text
Premiering Today
-> today

Home Upcoming
-> tomorrow onward
```

---

# Upcoming Range

The initial Home design uses approximately the next seven days.

The full Shows → Upcoming feature can expose a much broader bidirectional timeline.

Home should remain a preview rather than recreating that entire timeline.

---

# Upcoming Content

A compact item can expose:

- Show;
- Episode;
- date;
- `SxxExx`;
- title;
- tracking context.

Items should be ordered chronologically.

---

# Upcoming and Planning

Planning Shows can be useful in Home Upcoming when product rules include them.

This allows the user to see an upcoming premiere before they have started watching.

The same backend inclusion rules should be shared with the appropriate Upcoming query/contract.

---

# Missed Recently

Missed Recently identifies recent Episodes that are likely to need attention.

Its intended rules are more specific than simply "past Upcoming."

---

# Missed Recently Window

The current intended period is:

```text
last 14 days
```

Today is excluded.

Conceptually:

```text
today - 14 days
through
yesterday
```

Boundary semantics should be explicit and deterministic.

---

# Missed Recently Eligibility

The intended rules are:

- regular Episode;
- Show is Watching;
- Episode has aired;
- Episode is unwatched;
- Episode aired within the recent window;
- Today excluded.

Planning Shows do not count as "missed."

---

# Why Planning Is Excluded

A user who has merely planned to watch a Show has not necessarily fallen behind.

Therefore:

```text
Planning + Episode aired
!= automatically missed
```

Missed Recently is intended to represent active Watching commitments.

---

# Missed Recently Ordering

Items should be ordered with the most recently missed Episodes first.

Conceptually:

```text
air_date DESC
```

with deterministic secondary ordering where necessary.

---

# Missed Recently vs Watch Next

The same Episode may be relevant to the user's continuation state, but Home sections answer different questions.

```text
Continue Watching
-> what should I continue with?

Missed Recently
-> what recent release did I fail to watch?
```

Presentation should avoid unnecessary duplicate visual noise where the final product rules decide overlap is undesirable.

Any deduplication rule should be explicit rather than ad hoc in widgets.

---

# Recent Activity

Recent Activity is a small Home preview of viewing History.

It uses real watch events.

Conceptually:

```text
EpisodeWatchEvent
MovieWatchEvent
       |
       v
combined History
       |
       v
small recent subset
```

---

# Recent Activity Ordering

Ordering is:

```text
watched_at DESC
```

The most recent actual viewing appears first.

---

# Rewatches in Recent Activity

A rewatch is a new viewing event.

Therefore it appears as a separate Recent Activity entry.

Example:

```text
Movie A watched Monday
Episode X watched Tuesday
Movie A rewatched Wednesday
```

Recent Activity shows the Wednesday Movie event separately.

---

# Episode Activity

Episode entries can display:

- Show title;
- `SxxExx`;
- Episode title;
- watched timestamp.

Selecting the item should navigate to the appropriate Episode/Show context according to the application's navigation design.

---

# Movie Activity

Movie entries can display:

- Movie title;
- watched timestamp.

Selecting the item should navigate to Movie Details.

---

# Recent Activity Limit

Home should request/display only a small number of recent entries.

The full timeline belongs to Profile → History.

Home should not implement History pagination or a large chronological archive.

---

# Empty Recent Activity

For a new user:

```text
no watch events
-> valid empty Recent Activity
```

The section can guide the user toward adding/tracking media rather than showing an error.

---

# Cross-Section Consistency

One viewing mutation can affect several Home sections at once.

Example:

```text
Mark Episode Watched
        |
        +-> Your Week
        +-> Continue Watching
        +-> Missed Recently
        +-> Recent Activity
```

Home orchestration should reconcile these sections without duplicating backend rules.

---

# Mutation Example

Suppose:

```text
Show A S01E04
-> appears in Continue Watching
-> also qualifies as Missed Recently
```

After Mark Watched:

```text
S01E04 watched
-> disappears from Missed Recently
-> Continue Watching may advance to S01E05
-> Your Week increments
-> Recent Activity gets new event
```

The backend/application layer should provide authoritative resulting state.

---

# Partial Failures

Home is composed of independent data sections.

A failure in one should not unnecessarily destroy the others.

Example:

```text
Your Week
-> success

Continue Watching
-> success

Upcoming
-> failure

Recent Activity
-> success
```

The successful sections should remain visible and usable.

---

# Independent Loading

Sections can have independent loading states.

This avoids making the entire dashboard wait for the slowest request.

Possible states per section include:

```text
initial
loading
success
empty
failure
refreshing
```

The exact state architecture should follow the current implementation.

---

# Initial Page Loading

The first Home load should avoid a visually chaotic sequence of large layout jumps.

Skeletons/placeholders can be used where they fit the current design system.

Independent requests can still resolve progressively.

---

# Refresh

A Home refresh can update the dashboard's underlying sections.

It should preserve previous successful data while refreshing where appropriate.

The user should not see the entire dashboard disappear into a blank spinner for a routine refresh.

---

# Coordinated Refresh

Because Home aggregates multiple domains, refresh orchestration should be deliberate.

Potentially affected sources include:

```text
Statistics
Watch Next
Upcoming
Missed Recently
History
```

The frontend should coordinate requests but should not recalculate their business rules.

---

# Refresh After Mutation

A local Home mutation should refresh only what is necessary for consistency.

For example:

```text
Mark Watched
-> affected Continue Watching
-> Your Week
-> Missed Recently
-> Recent Activity
```

Unrelated sections should not reload unnecessarily.

---

# Retry

Retry should be section-specific when possible.

Example:

```text
Upcoming failed
-> Retry Upcoming
```

rather than:

```text
Upcoming failed
-> reload entire Home
```

unless a coordinated reload is necessary for correctness.

---

# Errors

Home uses the common SofaWatch error architecture.

Possible failures include:

- network;
- timeout;
- authentication;
- server error;
- invalid response;
- provider-dependent upstream failure.

Raw technical details should not be displayed directly.

See [API Errors](../api/errors.md).

---

# Backend Responsibility

The backend owns business definitions used by Home, including:

- viewing statistics;
- Watch Next eligibility;
- tracked Upcoming eligibility;
- Missed Recently rules;
- viewing History;
- user scoping.

Whether these are delivered through individual feature endpoints or a future optimized dashboard endpoint is an implementation choice.

---

# Frontend Responsibility

Flutter owns:

- dashboard composition;
- section layout;
- responsive presentation;
- loading/error/empty states;
- navigation;
- targeted mutations;
- refresh orchestration;
- preserving visual context.

Flutter should not recreate backend domain rules.

---

# Dedicated Dashboard Endpoint

A single aggregated Home endpoint is not required merely because Home combines several features.

Separate feature requests can be appropriate if they:

- preserve clean ownership;
- load independently;
- cache/reuse existing state;
- provide acceptable performance.

A dedicated dashboard endpoint should only be introduced if profiling/network behavior shows a real benefit or atomic dashboard consistency becomes a requirement.

Avoid premature aggregation abstractions.

---

# Navigation

Home should provide shortcuts into richer feature areas.

Examples:

```text
Continue Watching
-> Shows / Show Details

Upcoming
-> Shows → Upcoming

Recent Activity
-> History / media details

Your Week
-> Statistics
```

Navigation should preserve relevant destination context where practical.

---

# Search

Global Search remains outside Home's business structure.

Mobile can expose Search through the global Dual-Pill experience.

Desktop/Web uses the global navigation/search experience.

Home should not implement a separate Search field with independent behavior unless the product navigation design explicitly calls the global Search surface.

---

# Recommendations

Recommendations on Home are deliberately deferred.

Explore is the primary discovery destination.

If Home recommendations are added later, they should:

- use real recommendation logic;
- remain compact;
- avoid duplicating Explore;
- have a clear reason to be personally relevant.

---

# Quick Actions

Quick Actions are deliberately deferred.

Examples that might eventually be evaluated include:

- Mark something watched;
- open Search;
- add Movie;
- open History.

They should only be added if actual usage demonstrates that they reduce friction rather than adding dashboard clutter.

---

# Responsive Design

Home should adapt from mobile to desktop while sharing the same domain/application data.

Mobile can favor:

- vertically stacked sections;
- horizontal carousels where appropriate;
- compact metric cards;
- touch-friendly actions.

Desktop can favor:

- constrained dashboard width;
- multi-column metric presentation;
- denser content;
- balanced section widths.

---

# Mobile Validation

Final mobile validation should include:

- narrow widths;
- long Show/Movie titles;
- horizontal cards;
- metric cards;
- Mark Watched;
- loading states;
- error cards;
- safe areas;
- scrolling;
- interaction with the global navigation/Dual-Pill.

---

# Desktop Validation

Final desktop validation should include:

- maximum useful content width;
- ultrawide displays;
- card density;
- section hierarchy;
- hover/focus states;
- keyboard navigation;
- top navigation integration.

---

# Accessibility

Final Home validation should include:

- semantic section headings;
- accessible metric labels;
- accessible watched/progress state;
- keyboard-accessible actions;
- sensible focus order;
- non-color-only Planning/Watching distinctions;
- sufficient touch targets;
- readable loading/error states.

---

# Performance

Home is a high-frequency screen and should remain lightweight.

Potential considerations include:

- reuse already loaded application state;
- avoid duplicate requests;
- lazy rendering of off-screen sections where useful;
- image caching;
- targeted rebuilds;
- preserving previous data during refresh;
- avoiding unnecessary full-dashboard reloads.

Optimization should be based on profiling.

---

# Date and Time

Home contains several date-sensitive concepts:

- greeting;
- current date;
- Your Week;
- Today;
- Tomorrow;
- Missed Recently;
- watch-event timestamps.

Timezone semantics should remain consistent across backend and frontend.

Tests for date-sensitive behavior should use deterministic clocks/today injection where appropriate.

---

# Localization

Future localization should cover:

- greeting;
- date formatting;
- Today/Tomorrow;
- relative watched timestamps;
- section names;
- metric labels;
- empty/error messages;
- pluralization.

English and Portuguese are the initial planned languages.

---

# Testing

Backend/application tests should cover the rules consumed by Home:

```text
weekly viewing metrics
rewatches counted
Watch Next eligibility
Today episodes
Planning vs Watching behavior
future Upcoming range
Missed Recently 14-day range
Today exclusion
Planning exclusion from missed
unwatched requirement
recent History ordering
user isolation
```

Frontend tests should cover:

```text
Home loading
section success
section empty
independent section failure
section Retry
Your Week metrics
Continue Watching
Premiering Today
Planning distinction
Upcoming starts tomorrow
Missed Recently
Recent Activity
Episode navigation
Movie navigation
Mark Watched
cross-section reconciliation
refresh
responsive layout
```

---

# Edge Cases

## New User

```text
no Library
no watch events
-> valid mostly-empty Home
```

The dashboard should remain welcoming and useful.

## Fully Caught Up

```text
Continue Watching empty
Upcoming may still contain future Episodes
```

## Rewatch

```text
rewatch
-> Your Week increments
-> Recent Activity gets new entry
```

## Planning Premiere Today

```text
Planning Show
Episode airs today
-> can appear in Premiering Today
-> should be visually distinguishable
```

## Planning Episode Aired Yesterday

```text
Planning Show
Episode aired yesterday
-> not Missed Recently
```

## Watching Episode Aired Yesterday and Unwatched

```text
Watching
regular Episode
unwatched
within 14 days
-> Missed Recently
```

## Episode Aired Today

```text
-> Premiering Today
-> excluded from Missed Recently
```

## Partial Network Failure

```text
Statistics fails
History succeeds
-> Recent Activity remains usable
```

---

# Future Work

## Coordinated Refresh

```text
[ ] audit Home refresh orchestration
[ ] preserve previous data while refreshing
[ ] avoid unnecessary section reloads
[ ] reconcile viewing mutations efficiently
[ ] validate cross-feature consistency
```

---

## Responsive Validation

```text
[ ] mobile final audit
[ ] desktop final audit
[ ] ultrawide audit
[ ] long-title audit
[ ] horizontal-scroll audit
[ ] accessibility audit
```

---

## Recommendations

Deliberately deferred:

```text
[ ] evaluate Home recommendations using real usage
[ ] define clear difference from Explore
[ ] use genuine personalized/discovery data
[ ] avoid duplicate sections
```

---

## Quick Actions

Deliberately deferred:

```text
[ ] evaluate actual user friction
[ ] define useful high-frequency actions
[ ] avoid adding dashboard clutter without evidence
```

---

## Deterministic Time

```text
[ ] ensure date-sensitive tests use controlled clock/today
[ ] audit timezone boundaries
[ ] integrate localized date formatting
```

---

# Notes

> Home is an aggregation/dashboard feature, not a second implementation of Statistics, Watch List, Upcoming, or History.

> Your Week should use the same definitions as Statistics.

> Continue Watching should use Watch Next semantics.

> Premiering Today contains Today; Home Upcoming begins tomorrow.

> Missed Recently is Watching-only, unwatched, regular Episodes from the recent window, excluding Today.

> Planning Shows do not count as missed.

> Rewatches count again in Your Week and Recent Activity.

> Quick Actions and Home recommendations remain deliberately deferred.

> A dedicated aggregated Home API should only be introduced when it solves a real performance or consistency problem.

---

# Related Documentation

- [Implementation Status](implementation-status.md)
- [Library](library.md)
- [Viewing Progress](viewing-progress.md)
- [Watch List](watch-list.md)
- [Upcoming](upcoming.md)
- [Movies](movies.md)
- [Statistics](statistics.md)
- [History](history.md)
- [Profile](profile.md)
- [Architecture Overview](../architecture/overview.md)
- [Data Flow](../architecture/data-flow.md)
- [Frontend Contract](../api/frontend-contract.md)
- [API Errors](../api/errors.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)
