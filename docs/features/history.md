# History

## Overview

History is SofaWatch's canonical user-facing timeline of viewing activity.

It combines real Episode and Movie viewing events into a chronological history while preserving every individual viewing, including rewatches.

Conceptually:

```text
EpisodeWatchEvent ──┐
                    ├──> Combined History
MovieWatchEvent ────┘
```

History answers:

```text
What did I watch?
When did I watch it?
How many separate times did I watch it?
```

It is distinct from watched state, Library membership, and Statistics.

See:

- [Viewing Progress](viewing-progress.md)
- [Show Details](show-details.md)
- [Movies](movies.md)
- [Statistics](statistics.md)
- [Profile](profile.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)

---

## Status

**Implemented / Evolving**

Implemented or established:

- Episode viewing history;
- Movie viewing history;
- event-based watch history;
- rewatches as individual entries;
- chronological ordering;
- combined Episode/Movie History;
- Profile History preview;
- Watch List Episode history;
- Episode-specific watch history;
- Movie-specific viewing history;
- deletion/correction of individual Episode viewing events;
- viewing-state recalculation after event deletion;
- History integration with Statistics;
- navigation from History to associated media;
- user-scoped History;
- full combined History page;
- Episode-only full History;
- Movie-only full History;
- backend `media_type` filtering for full History;
- cursor pagination scoped to the selected History media type;
- Profile `See All` navigation into Episode and Movie History;
- media-specific History titles and empty states.

The full History experience supports:

```text
All
Episodes
Movies
```

The combined History remains the default timeline, while Episode-only and Movie-only History are server-filtered views of the same canonical viewing events.

All full-History views use cursor-based pagination/load-more rather than loading an unlimited lifetime history.

Remaining work is primarily final full-History UX validation, pagination/large-history validation, Movie/Episode correction consistency, responsive/accessibility validation, and import/export integration audits.

See [Implementation Status](implementation-status.md).

---

# Goals

History should allow the user to:

- inspect recent viewing activity;
- browse older activity;
- distinguish Episodes from Movies;
- see rewatches as real separate viewings;
- navigate back to the watched content;
- correct erroneous viewing entries;
- understand the timestamp of each viewing;
- maintain a trustworthy personal viewing record.

---

# Canonical Event Model

History is built from viewing events rather than snapshots.

For Episodes:

```text
EpisodeWatchEvent
```

For Movies:

```text
MovieWatchEvent
```

Each event represents one viewing.

This is the foundation for:

- History;
- rewatches;
- watched state;
- latest watched timestamp;
- watch count;
- Statistics;
- Home Recent Activity.

---

# Event Identity

Each viewing event has its own identity.

Conceptually:

```text
EpisodeWatchEvent
id
user_id
episode_id
watched_at
```

and:

```text
MovieWatchEvent
id
user_id
movie_id
watched_at
```

Exact schema fields should follow the current implementation.

The important invariant is that separate viewings are separate persisted records.

---

# First Watch

A first viewing creates one event.

```text
Episode A
-> event 1
```

or:

```text
Movie A
-> event 1
```

History shows that event at its actual `watched_at` position.

---

# Rewatch

A rewatch creates another event.

```text
Episode A
-> event 1
-> event 2
```

History displays both.

The second event does not replace the first.

The same applies to Movies.

---

# Why Rewatches Are Separate

Keeping every viewing provides:

- accurate chronological History;
- correct total-viewing counts;
- rewatch statistics;
- correct watch time;
- correction of individual mistakes;
- preservation of historical behavior.

A single mutable `last_watched_at` field would lose this information.

---

# Effective Watched State

History events also determine effective watched state.

Conceptually:

```text
0 events
-> unwatched

1+ events
-> watched
```

Derived values can include:

```text
watch_count
watched_at
is_watched
```

The backend remains the source of truth.

---

# Latest Watched Timestamp

For content with multiple viewing events:

```text
watched_at
=
maximum remaining event timestamp
```

Example:

```text
January
March
August

latest watched_at = August
```

If August is deleted:

```text
latest watched_at = March
```

---

# Combined History

Full History combines Episode and Movie events.

Example:

```text
10:00  Episode
12:00  Movie
18:00  Episode rewatch
21:00  Movie rewatch
```

All entries participate in one global timeline.

---

# Ordering

Canonical History ordering is:

```text
watched_at DESC
```

Newest viewing first.

When multiple events have the same timestamp, the backend should use a deterministic secondary ordering, such as event identity, so pagination remains stable.

---

# History Types

The full History experience supports three views:

    All
    Episodes
    Movies

`All` is the default combined timeline.

`Episodes` and `Movies` reuse the same History domain/application
architecture while requesting server-filtered data. Filtering happens on
the backend before pagination so pages remain complete and cursor semantics
remain correct.

---

# All

`All` combines:

```text
EpisodeWatchEvent
+
MovieWatchEvent
```

into one chronological sequence.

This is the default comprehensive personal timeline.

---

# Episodes

`Episodes` filters History to Episode viewing events.

Each entry can include:

- Show title;
- Season/Episode number;
- Episode title;
- watched timestamp;
- rewatch context where useful.

---

# Movies

`Movies` filters History to Movie viewing events.

Each entry can include:

- Movie title;
- year where useful;
- watched timestamp;
- rewatch context where useful.

---

# Profile Preview

Profile can display a compact History preview.

Conceptually:

```text
Profile
-> recent Episodes
-> recent Movies
```

or another compact presentation consistent with the current UI.

This is not the full History timeline.

Selecting the History section can open the complete History experience.

---

# Home Recent Activity

Home also consumes a small recent subset of History.

Conceptually:

```text
Combined History
-> newest N events
-> Home Recent Activity
```

Home should not maintain a separate activity database or reimplement History ordering.

See [Home](home.md).

---

# Watch List History

Shows → Watch List contains an Episode-focused Watch History section.

It uses real Episode viewing events.

This is a TV-oriented projection of the same underlying viewing history.

It should remain consistent with global History.

See [Watch List](watch-list.md).

---

# Episode-Specific History

Show Details allows inspection of all viewing events for a particular Episode.

Conceptually:

```text
Episode
-> event C
-> event B
-> event A
```

ordered newest first.

This is a filtered projection of the same canonical Episode watch-event data.

See [Show Details](show-details.md).

---

# Movie-Specific History

Movie Details can similarly expose all `MovieWatchEvent` records for one Movie.

The events remain the same records used by global History and Statistics.

See [Movies](movies.md).

---

# History Entry Model

A normalized combined History item can conceptually contain:

```text
event identity
media type
watched_at
associated local media identity
display metadata
```

For Episodes, enough context should exist to identify:

```text
Show
Season
Episode
```

For Movies:

```text
Movie
```

The domain contract should remain independent of raw JSON and Flutter.

---

# Internal Media IDs

History references SofaWatch's internal entities.

It should not navigate using TMDB IDs as primary identities.

Conceptually:

```text
History event
-> internal Episode / Movie
-> local details experience
```

See [ADR-003: Internal Media IDs](../decisions/003-internal-media-ids.md).

---

# Navigation

History entries should navigate to their associated content.

Intended behavior:

```text
Episode
-> Episode Details / appropriate Show Details Episode context

Movie
-> Movie Details
```

Navigation should use internal SofaWatch IDs.

---

# Episode Navigation

When navigating from an Episode History row, the destination should provide enough context for the user to understand the specific Episode.

Depending on the final navigation architecture, this can be:

- dedicated Episode Details; or
- Show Details opened/focused on the relevant Season/Episode.

Avoid creating a redundant page solely because History needs a target if Show Details already provides the required experience.

---

# Movie Navigation

Movie History rows navigate to the local Movie Details experience.

The Movie should already have an internal SofaWatch identity because the viewing event references a local Movie.

---

# Event Deletion

History correction can remove an individual viewing event.

Conceptually:

```text
event A
event B
event C

delete event B

remaining:
event A
event C
```

Only the selected event is removed.

---

# Why Individual Deletion Matters

If a user accidentally records one extra rewatch, deleting all watched state would be incorrect.

Event-level deletion allows precise correction without destroying legitimate history.

---

# Delete Latest Event

Example:

```text
A = January
B = March
C = August
```

Delete C:

```text
watch_count: 3 -> 2
watched_at: August -> March
is_watched: true
```

---

# Delete Old Event

Delete B:

```text
A
C remain

watch_count: 3 -> 2
watched_at remains August
```

---

# Delete Final Event

If the only remaining event is deleted:

```text
watch_count -> 0
watched_at -> null
is_watched -> false
```

The backend recalculates this state.

---

# Library Independence

Deleting viewing history does not inherently mean removing media from the Library.

These are separate concepts.

Example:

```text
Movie remains in Watchlist/Library
all viewing events removed
-> Movie becomes unwatched
-> Library membership remains independently defined
```

The same separation applies to Shows.

---

# Confirmation

Destructive event deletion should use an appropriate confirmation interaction.

The confirmation should make clear that:

- one viewing entry will be removed;
- other viewings remain;
- watched/progress state may change as a result.

Avoid vague destructive labels.

---

# Deletion Loading

Deleting one event should expose targeted loading for that event/action.

The entire History timeline should not become unusable unnecessarily.

---

# Duplicate Delete Protection

While deletion is in flight, the same event should not be submitted for deletion repeatedly.

The client should block duplicate interaction until the result is known.

---

# Deletion Reconciliation

A successful event deletion can affect several features.

For Episode events:

```text
History
Episode state
Season progress
Show progress
Watch Next
Haven't Watched in a While
Home
Statistics
```

For Movie events:

```text
History
Movie watched state
Movie Library classification
Home
Statistics
```

The backend owns resulting business state.

---

# Partial Failures After Deletion

A successful deletion and a failed secondary refresh are separate outcomes.

Example:

```text
DELETE event
-> success

Statistics refresh
-> fails
```

History must not restore the deleted event merely because Statistics failed to refresh.

Statistics can expose its own retry/error state.

---

# Editing a Timestamp

If SofaWatch later supports editing an existing event timestamp directly, the preferred semantic options are:

```text
update event timestamp
```

or an explicit delete/recreate workflow with well-defined identity consequences.

It should not silently modify unrelated events.

Any timestamp editing feature should update History ordering and all date-based Statistics.

---

# Historical Mark Watched

When the user records a past viewing using an explicit historical date, the event belongs at that historical `watched_at` position.

Example:

```text
today = August
user records viewing from March

History position -> March
not August
```

Statistics must also attribute it to March.

---

# Importing History

Import/Export can create historical viewing events.

Imported events should preserve their original viewing timestamps where valid.

The import date itself should not replace `watched_at`.

See [Import / Export](import-export.md).

---

# Import Deduplication

History import requires explicit duplicate rules.

A repeated import should not blindly duplicate every historical event.

Deduplication may consider a stable exported event identity or a carefully defined combination of media/user/timestamp/source fields.

The exact strategy belongs to Import/Export and should be version-aware.

---

# Pagination

Full History can become large.

Pagination or Load More should be supported rather than loading an unlimited lifetime history in one response.

---

# Stable Pagination

Full History uses opaque cursor-based pagination.

The cursor preserves deterministic continuation across:

```text
    watched_at

    media type

    event identity
```

For filtered Episode or Movie History, the cursor is scoped to the selected media type and cannot be reused with an incompatible filter.

The frontend treats the cursor as opaque and returns it unchanged when requesting the next page.

---

# Load More

A Load More interaction should:

- preserve existing entries;
- append older entries;
- expose local pagination loading;
- keep the list interactive;
- expose pagination-specific Retry on failure.

It should not replace the already loaded timeline with a global spinner.

---

# Pagination Failure

Example:

```text
first 50 events
-> loaded

next page
-> fails
```

The first 50 events remain visible.

The user can retry loading older events.

---

# Filter Navigation

History currently exposes media-specific full views through navigation:

```text
    /history
    /history?type=episode
    /history?type=movie
```

Profile History provides separate `See All` actions for Episode and Movie
history.

Each route owns correctly scoped History pagination state, preventing pages
or cursors from different media types from being mixed.

---

# Filter State

The selected History filter should be preserved when navigating into media details and back where practical.

This improves continuity in long histories.

---

# Scroll Preservation

Opening a History entry and returning should ideally preserve:

- selected filter;
- loaded pages;
- scroll position.

This is especially important for older History exploration.

---

# Refresh

Refreshing History should retrieve newer/corrected event state without unnecessarily discarding already useful context.

The exact strategy can depend on pagination implementation.

A refresh should not silently duplicate rows.

---

# New Events

If a new viewing is recorded while History is open, a refresh can place it according to `watched_at`.

For a current-time viewing, this is normally at the top.

For a historical viewing, it may belong deeper in the timeline.

---

# Empty History

A new user can have no viewing events.

This is a valid state.

The UI can explain that watched Episodes and Movies will appear here once activity is recorded.

---

# Empty Filter

The user may have:

```text
Episode history
but no Movie history
```

Therefore:

```text
All -> populated
Episodes -> populated
Movies -> empty
```

is valid.

---

# Loading States

History can have several loading scopes:

```text
initial load
filter load
refresh
load more
event deletion
```

These should not all collapse into one global loading state.

---

# Initial Loading

Initial History loading can use an appropriate progress indicator or skeleton consistent with the design system.

No false empty state should flash before the first request completes.

---

# Refreshing With Existing Data

When refreshing, existing entries can remain visible with subtle progress where appropriate.

This avoids unnecessary UI disruption.

---

# Errors

History uses the common SofaWatch application error model.

Possible failures include:

- network;
- timeout;
- authentication;
- not found during mutation;
- conflict;
- invalid response;
- server failure.

Raw database/Dio details should not be shown to the user.

See [API Errors](../api/errors.md).

---

# Event Not Found

An event can disappear between loading and deletion, for example due to another active session.

The backend should return the appropriate safe error/response.

The frontend can refresh/reconcile History rather than retaining a permanently stale row.

---

# Multi-Session Behavior

A user may have multiple active SofaWatch sessions.

Example:

```text
Web deletes event
Mobile still displays old event
```

The next refresh on Mobile should reconcile with backend truth.

No client should be treated as the authoritative History store.

---

# User Scoping

History endpoints must always scope events to the authenticated user.

Knowing another event ID must not allow access to or deletion of another user's viewing event.

This is enforced by the backend, not merely by hiding UI.

---

# Authorization

History is normal authenticated user data.

Administrative status does not grant a reason to casually expose another user's History through standard user endpoints.

Any future administrative data-access feature would require explicit product and privacy rules.

---

# Privacy

Viewing History is personal application data.

Logs and diagnostics should not unnecessarily reproduce full personal viewing history.

Exports intentionally contain user data and should be treated accordingly.

---

# Statistics Relationship

Statistics derives insights from the same viewing events.

Therefore:

```text
create event
-> History + Statistics change

delete event
-> History + Statistics change

change watched_at
-> History ordering + time-based Statistics change
```

Statistics should not maintain irreversible counters detached from History.

See [Statistics](statistics.md).

---

# Home Relationship

Home Recent Activity is a small projection of combined History.

Home weekly metrics also react to viewing-event changes.

Home should consume canonical application data rather than duplicate History rules.

See [Home](home.md).

---

# Watch List Relationship

Episode watch events feed Watch List History.

Removing an Episode event can also alter progress and Watch Next.

See [Watch List](watch-list.md).

---

# Show Details Relationship

Episode-specific History is accessible from Show Details.

Deleting an event there and deleting the same event from global History are semantically the same backend operation.

Both surfaces should reconcile to the same result.

See [Show Details](show-details.md).

---

# Movies Relationship

Movie-specific History follows the same event semantics.

A Movie rewatch should appear in:

- Movie Details history;
- global History;
- Home Recent Activity where within the preview;
- Statistics.

See [Movies](movies.md).

---

# Backend Responsibility

The backend owns:

- viewing-event persistence;
- event ownership;
- combined History queries;
- filtering;
- ordering;
- pagination semantics;
- event deletion;
- recalculation of effective watched state;
- user scoping;
- safe mutation errors.

---

# Frontend Responsibility

Flutter owns:

- History presentation;
- filter controls;
- list/timeline UI;
- loading/error/empty states;
- Load More;
- Retry;
- deletion confirmation;
- targeted mutation loading;
- navigation;
- scroll/filter preservation;
- responsive behavior.

Flutter should not infer or rewrite canonical watch-event history.

---

# Combined API Contract

A combined History response should normalize enough information for the client to render heterogeneous rows safely.

Conceptually:

```text
HistoryItem
├── type: episode | movie
├── eventId
├── watchedAt
└── media-specific normalized context
```

The domain layer should expose typed models rather than requiring presentation code to inspect arbitrary JSON structures.

---

# Type Safety

Episode and Movie History rows have shared properties but different media context.

The implementation should prefer explicit typed models/sealed concepts over loosely structured maps where practical.

Do not add abstraction purely for elegance if the existing typed domain model already solves the problem cleanly.

---

# Date and Time

History timestamps are central data.

The system should distinguish:

```text
stored timestamp
display timezone
localized formatting
```

The backend should store timestamps consistently.

The frontend can format them according to the user's locale/timezone strategy.

---

# Same-Day Presentation

The UI may group History by calendar day in the future/current design.

If so, grouping must use the same chosen display timezone.

A timestamp should not appear under different dates between grouping label and row formatting.

---

# Relative Time

Presentation may use labels such as:

```text
Today
Yesterday
```

where appropriate.

These are display concerns and must be localized later.

The underlying `watched_at` remains the source of ordering.

---

# Deterministic Testing

Tests involving:

- Today;
- Yesterday;
- relative dates;
- pagination boundaries;
- imported historical events

should use controlled time rather than the real current clock where relevant.

---

# Localization

Future localization should cover:

- `All`;
- `Episodes`;
- `Movies`;
- date group labels;
- relative timestamps;
- deletion confirmation;
- empty states;
- Load More;
- Retry;
- pluralization.

Initial planned languages are English and Portuguese.

---

# Responsive Design

History should share domain/application behavior across mobile and desktop.

Mobile can favor:

- compact timeline rows;
- touch-friendly filters;
- bottom-sheet confirmation/details where appropriate;
- progressive Load More.

Desktop can favor:

- constrained timeline width;
- denser rows;
- keyboard/mouse interaction;
- dialogs for destructive confirmation.

---

# Mobile Validation

Final mobile validation should include:

- narrow screens;
- long Show titles;
- long Episode titles;
- Movie titles;
- timestamps;
- filter switching;
- Load More;
- delete actions;
- confirmation UI;
- navigation and back;
- scroll preservation;
- safe areas.

---

# Desktop Validation

Final desktop validation should include:

- ultrawide screens;
- sensible maximum timeline width;
- hover/focus behavior;
- keyboard-accessible filters;
- row actions;
- confirmation dialogs;
- navigation/back preservation.

---

# Accessibility

Final History validation should include:

- semantic media type;
- readable Show/Episode/Movie labels;
- semantic watched timestamp;
- accessible delete labels;
- confirmation focus management;
- keyboard navigation;
- non-color-only distinctions;
- accessible loading/error states.

---

# Performance

History can grow indefinitely.

Important considerations include:

- indexed user/timestamp queries;
- bounded page size;
- avoiding N+1 media lookups;
- stable ordering;
- efficient combined Episode/Movie query strategy;
- incremental list rendering;
- avoiding unnecessary full refresh after one deletion.

Optimization should follow actual profiling.

---

# Database Considerations

History queries commonly depend on:

```text
user_id
watched_at
event id
episode_id
movie_id
```

Indexes should support actual ordering/filter patterns.

Combined History should avoid loading all Episode and Movie events into application memory merely to sort them when the database can perform the work efficiently.

---

# Testing

Backend tests should cover at least:

```text
empty History
Episode History
Movie History
combined History
watched_at DESC ordering
deterministic equal-timestamp ordering
All filter
Episodes filter
Movies filter
user isolation
rewatches as separate entries
delete middle event
delete latest event
delete final event
watched-state recalculation
pagination
pagination ordering
filter pagination
historical timestamps
imported History
unauthorized event deletion
event not found
```

Frontend tests should cover at least:

```text
initial loading
combined History
Episode rows
Movie rows
rewatch rows
All/Episodes/Movies filters
empty History
empty individual filter
failure
Retry
Load More
pagination failure
delete confirmation
delete loading
delete success
delete failure
navigation to Episode context
navigation to Movie Details
filter preservation
scroll/context preservation where supported
responsive layout
```

---

# Edge Cases

## Same Episode Watched Three Times

```text
event C
event B
event A

-> three History rows
```

## Same Movie Watched Twice

```text
event B
event A

-> two History rows
```

## Same Timestamp

Two events can theoretically share the same timestamp.

Use deterministic secondary ordering.

## Historical Event Added Today

```text
created today
watched_at = three months ago
```

History ordering follows `watched_at`, not database creation time.

## Delete Latest Rewatch

Previous event becomes the effective latest watched timestamp.

## Delete Only Event

Content becomes effectively unwatched while Library membership remains independent.

## No Movie Events

Movies filter is empty while Episode/All History can still be populated.

## Another Session Deletes Event

Refresh should remove stale local representation.

## Provider Offline

Local History should remain available because viewing events and imported media are persisted locally.

---

# Future Work

## Full History UX

```text
[ ] final All / Episodes / Movies UX audit
[ ] final pagination/load-more behavior
[ ] preserve filter when navigating back
[ ] preserve loaded pages where practical
[ ] preserve scroll position
```

---

## Corrections

```text
[ ] audit Episode event deletion across all surfaces
[ ] audit Movie event deletion across all surfaces
[ ] evaluate explicit timestamp editing only if needed
[ ] ensure correction updates Statistics
[ ] ensure correction updates progress/Watch Next
```

---

## Pagination

```text
[ ] validate large histories
[ ] verify deterministic equal-timestamp ordering
[ ] benchmark current pagination
[ ] consider cursor pagination only if needed
```

---

## Import / Export

```text
[ ] finalize History export contract
[ ] version exported event data
[ ] define robust import deduplication
[ ] preserve original watched_at
[ ] test repeated imports
[ ] test partial import failures
```

---

## Responsive / Accessibility

```text
[ ] mobile final audit
[ ] desktop final audit
[ ] ultrawide audit
[ ] keyboard navigation audit
[ ] screen-reader semantics audit
[ ] destructive-action focus audit
```

---

# Notes

> History is event-based, not a list of currently watched flags.

> Every rewatch remains an individual History entry.

> Combined History orders Episode and Movie viewing events by `watched_at DESC`.

> Deleting one event removes only that viewing.

> Deleting the latest event can change effective `watched_at`.

> Deleting the final event makes the content effectively unwatched.

> Library membership and History are separate concepts.

> Historical entries are ordered by their actual viewing timestamp, not when they were imported or created.

> History corrections must naturally propagate into Statistics and relevant progress state.

> Full History should scale through pagination/load-more rather than loading an unlimited lifetime timeline.

> History should remain usable when external metadata providers are temporarily unavailable.

---

# Related Documentation

- [Implementation Status](implementation-status.md)
- [Library](library.md)
- [Viewing Progress](viewing-progress.md)
- [Watch List](watch-list.md)
- [Show Details](show-details.md)
- [Movies](movies.md)
- [Home](home.md)
- [Statistics](statistics.md)
- [Profile](profile.md)
- [Import / Export](import-export.md)
- [Architecture Overview](../architecture/overview.md)
- [Database Architecture](../architecture/database.md)
- [Data Flow](../architecture/data-flow.md)
- [Frontend Contract](../api/frontend-contract.md)
- [API Errors](../api/errors.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)
- [ADR-003: Internal Media IDs](../decisions/003-internal-media-ids.md)
