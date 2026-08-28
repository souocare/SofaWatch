# Show Details

## Overview

Show Details is the main TV Show inspection and interaction experience in SofaWatch.

It brings together:

- local Show metadata;
- Library state;
- viewing progress;
- Seasons;
- Episodes;
- Episode watched state;
- watch history;
- rewatches;
- metadata synchronization;
- related presentation information.

Show Details operates on SofaWatch's internal Show identity after import. External provider identifiers are metadata/mapping concerns rather than the primary identity used by the application.

See:

- [Library](library.md)
- [Viewing Progress](viewing-progress.md)
- [Watch List](watch-list.md)
- [Upcoming](upcoming.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)
- [ADR-003: Internal Media IDs](../decisions/003-internal-media-ids.md)
- [ADR-006: Provider Independence](../decisions/006-provider-independence.md)

---

## Status

**Implemented / Final Validation**

The core Show Details architecture and interaction model are implemented.

Implemented or established:

- Show metadata;
- poster/backdrop presentation;
- title and overview;
- genres;
- dates and additional information;
- Library state;
- Show progress;
- Seasons;
- expandable Season sections;
- lazy Episode synchronization by Season;
- independent Season loading/error state;
- Episode rows;
- Episode watched state;
- watched timestamps;
- watch counts;
- Mark Watched;
- Mark Unwatched/correction flows;
- Episode watch history;
- individual watch-event deletion;
- Rewatch / Watched Again;
- Season and Show progress reconciliation;
- batch/progress infrastructure for Season summaries.

Remaining work is primarily final Seasons/Episodes validation, coordinated refresh behavior, responsive validation, and any provider-backed metadata enhancements added later.

See [Implementation Status](implementation-status.md).

---

# Goals

Show Details should allow the user to:

- understand what a Show is;
- see whether it is in their Library;
- understand current viewing progress;
- inspect Seasons and Episodes;
- continue normal viewing;
- correct viewing history;
- record rewatches;
- inspect Episode-level history;
- access useful metadata without overwhelming the primary tracking workflow.

The page should remain usable even when one subsection fails.

---

# Identity

Once imported, a Show uses its internal SofaWatch ID.

Conceptually:

```text
TMDB result
    |
    v
import
    |
    v
SofaWatch Show
id = internal ID
    |
    +-> external TMDB mapping
    +-> future TVDB mapping
    +-> future IMDb mapping
```

Show Details should therefore be addressed through the local entity rather than treating a TMDB ID as the application's primary identity.

---

# Local vs Preview Details

Search and Explore can display provider-backed previews before media is imported.

Full Show Details is the local SofaWatch experience.

Conceptually:

```text
Search / Explore
-> provider preview
-> import if needed
-> local Show
-> Show Details
```

This distinction avoids making core tracking depend directly on a live provider response every time the page opens.

---

# Metadata

Show Details can expose local metadata such as:

- title;
- original title where available;
- overview;
- poster;
- backdrop;
- genres;
- first air date;
- status;
- networks or related metadata where supported;
- Season information.

The exact fields should follow the normalized SofaWatch model.

---

# Provider Independence

TMDB is currently the primary metadata provider.

Show Details should consume normalized local data rather than embedding TMDB-specific business rules into Flutter.

Future provider architecture may add:

```text
TMDB
TVDB
IMDb / external ratings source
```

without changing the internal Show identity.

Provider-specific fields should remain behind mappings/adapters where practical.

---

# Header / Hero Area

The top of Show Details can contain:

- backdrop;
- poster;
- Show title;
- year/date context;
- genres;
- status;
- overview;
- progress;
- Library/tracking actions.

Presentation should adapt between mobile and desktop without changing domain/application behavior.

---

# Library State

Show Details can expose whether the Show is tracked and its current Library status.

Relevant states include:

```text
Watching
Planning
Completed
Dropped
```

`Paused` remains deliberately deferred.

Library mutations should use the Library feature/repository rather than being implemented as provider mutations.

See [Library](library.md).

---

# Provider Status vs User Status

Provider Show lifecycle and user tracking state are separate concepts.

Examples:

```text
provider status = Ended
user status = Watching
```

is valid when the user still has Episodes to watch.

Likewise:

```text
provider status = Returning Series
user status = Completed
```

may represent an explicit user decision until product rules say otherwise.

Show Details should not silently collapse these states.

---

# Progress

Show Details presents backend-derived viewing progress.

This can include:

- watched regular Episodes;
- total regular Episodes;
- aired Episodes;
- watched aired Episodes;
- overall progress;
- aired progress;
- caught-up state;
- next Episode;
- next upcoming Episode.

See [Viewing Progress](viewing-progress.md).

---

# Overall vs Aired Progress

These are intentionally different.

Example:

```text
10 known Episodes
5 aired
5 watched

overall progress = 50%
aired progress = 100%
caught_up = true
```

Show Details should present this distinction in a way that does not imply future Episodes are currently watchable.

---

# Caught Up

A caught-up Show has no unwatched currently aired regular Episode.

It can still:

- have future Episodes;
- have overall progress below 100%;
- remain in Watching state;
- appear in Upcoming.

Caught up is not equivalent to Completed.

---

# Seasons

Seasons are presented as expandable/accordion sections.

This allows the page to avoid rendering and synchronizing every Episode in every Season immediately.

Conceptually:

```text
Show Details
    |
    +-> Season 1
    +-> Season 2
    +-> Season 3
    +-> Specials
```

Each Season can maintain its own interaction state.

---

# Season Summaries

A collapsed Season can expose useful summary information without requiring every Episode row to be loaded first.

Possible summary data includes:

- Season number/name;
- Episode count;
- watched count;
- progress;
- aired progress;
- caught-up state.

The existing architecture includes batch/progress support for this purpose.

---

# Independent Season State

Season loading should be isolated.

Example:

```text
Season 1
-> loaded

Season 2
-> loading

Season 3
-> failed

Season 4
-> untouched
```

A failure in Season 3 should not make Seasons 1 and 2 unusable.

---

# Expanding a Season

Opening a Season can trigger Episode loading/synchronization when necessary.

Conceptually:

```text
expand Season
     |
     v
inspect local Episode state
     |
     v
sync Season when required
     |
     v
persist normalized Episodes
     |
     v
render Episode rows
```

The exact decision about whether synchronization is required belongs to backend metadata logic.

---

# Lazy Episode Synchronization

SofaWatch deliberately avoids requiring every Episode of every Season to be synchronized during the initial Show import.

Advantages include:

- faster imports;
- fewer provider requests;
- lower unnecessary storage/work;
- better perceived Show Details loading;
- ability to load only what the user inspects.

Once synchronized, local Episodes can be reused.

---

# Local Episode Persistence

Provider Episodes are normalized and persisted as SofaWatch Episode entities.

After persistence:

```text
provider Episode
-> normalized Episode
-> internal Episode ID
```

Viewing events reference local Episodes rather than provider-only identifiers.

---

# Metadata Refresh vs Episode Sync

General Show metadata refresh and Season Episode synchronization are related but not identical operations.

A metadata refresh may update Show/Season information without necessarily forcing all Episode collections to be fetched.

Opening or explicitly refreshing a Season can handle Season-specific Episode synchronization.

This separation should remain intentional.

---

# Episode Rows

An Episode row can expose:

- Episode number;
- title;
- air date;
- runtime where available;
- watched state;
- watched date;
- watch count;
- Mark Watched / correction actions;
- access to viewing history.

Long or missing titles should degrade gracefully.

---

# Episode Eligibility

An Episode's air date affects normal viewing actions.

Conceptually:

```text
air_date < today
-> aired

air_date == today
-> date-level aired/current according to current rules

air_date > today
-> future

air_date = null
-> unknown
```

SofaWatch must not invent an air date or precise air time.

---

# Mark Watched

Marking an unwatched Episode as watched creates an `EpisodeWatchEvent`.

Conceptually:

```text
Episode
   |
   v
Mark Watched
   |
   v
EpisodeWatchEvent
   |
   v
recalculate effective state
```

The backend remains the source of truth.

---

# Explicit Watched Date

Where the UI/API supports historical correction, Mark Watched can use an explicit legitimate viewing timestamp.

This should remain separate from the quick `Watched Again` action, which uses the current time.

Date/time inputs should ultimately follow the application's localization and timezone strategy.

---

# Watched State

The effective Episode state includes values such as:

```text
is_watched
watch_count
watched_at
```

These are derived from real watch events.

Flutter should not infer them by maintaining parallel local counters.

---

# Watch Count

Repeated viewings can be presented compactly.

Example:

```text
one viewing
-> watched indicator

multiple viewings
-> 2x / 3x / ...
```

Exact visual representation belongs to presentation.

The count itself is backend truth.

---

# Watched Date

The displayed watched date represents the latest effective viewing timestamp.

It can also act as an entry point to the Episode's full watch-event history.

A stable `ValueKey` should be used where the current implementation relies on keys for tests/state identification.

---

# Episode Watch History

Each Episode can expose all of its viewing events.

Example:

```text
Episode S01E03

12 Jan 2026
28 Feb 2026
10 Aug 2026
```

History is ordered:

```text
watched_at DESC
```

Every row represents one real viewing.

---

# Watch History Presentation

Episode history can use adaptive presentation:

```text
mobile / narrow
-> bottom sheet

desktop / wide
-> dialog
```

The application already follows an adaptive modal strategy in several places.

The breakpoint should use the existing design system rather than magic values scattered through widgets.

---

# Rewatch / Watched Again

`Watched Again` creates a new viewing event.

It does not replace the latest timestamp of the existing event.

Conceptually:

```text
event A
    |
Watched Again
    |
    v
event B
```

After success:

```text
watch_count += 1
watched_at = event B timestamp
```

and event A remains in history.

---

# Rewatch UX

The quick Rewatch action should:

- use the current time;
- not require a date picker;
- expose item-level loading;
- block double submission;
- preserve existing history;
- refresh affected Episode/Season/Show state.

An explicit historical-entry workflow can separately support a chosen timestamp if required.

---

# Removing a Watch Event

Individual history rows can be removed for corrections.

The backend recalculates effective Episode state after deletion.

Example:

```text
events:
A
B
C

delete C
-> B becomes latest watched_at
-> watch_count = 2
```

Deleting the final event makes the Episode unwatched.

---

# Mark Unwatched

Any Mark Unwatched interaction must remain compatible with event-based history.

It should not accidentally destroy multiple legitimate viewing events when the intended operation is only to correct one viewing.

Precise event-level deletion is preferred where the user is editing historical entries.

---

# Mutation Reconciliation

A successful Episode mutation can affect:

- Episode row;
- Season progress;
- Show progress;
- caught-up state;
- next Episode;
- Watch Next;
- Haven't Watched in a While;
- Watch History;
- Home;
- Statistics.

Show Details should reconcile the directly relevant state while shared features refresh through their normal application mechanisms.

---

# Season Progress Refresh

After an Episode mutation, the containing Season's progress should update.

This should not require collapsing/reopening the Season.

---

# Show Progress Refresh

Show-level progress should update after Episode state changes.

Examples include:

```text
49% -> 50%
not caught up -> caught up
next Episode changes
```

The UI should reflect backend results rather than trying to predict every rule itself.

---

# Watch Next Reconciliation

An Episode mutation can change Watch Next.

Example:

```text
S01E04 = current next
Mark Watched
-> S01E05 becomes next
```

or:

```text
final aired Episode watched
-> Show becomes caught up
-> Show leaves Watch Next
```

See [Watch List](watch-list.md).

---

# Upcoming Reconciliation

A historical Episode marked watched in Show Details should also appear watched when the user later sees it in Upcoming.

This is naturally achieved by shared backend viewing state rather than duplicated flags.

---

# History Reconciliation

A new viewing event should become visible in:

- Episode watch history;
- Watch List history;
- Profile History;
- Home Recent Activity where applicable.

These views consume the same event data.

---

# Partial Failures

A primary mutation and secondary refresh are separate outcomes.

Example:

```text
create watch event
-> success

refresh Watch Next
-> failure
```

The user should not be told that the watch event failed.

The successful local/Show Details state should remain usable while the failed secondary feature exposes its own error/retry behavior.

---

# Loading States

Show Details can have multiple simultaneous loading scopes:

```text
page loading
Library mutation
Season loading
Season retry
Episode mutation
History loading
History mutation
metadata refresh
```

Avoid replacing the entire page with a global spinner for every local operation.

---

# Initial Loading

Initial Show Details loading should establish enough local Show state to render the primary page.

Season Episode bodies do not all need to be loaded during initial page loading.

---

# Season Loading

Opening an unloaded Season should expose loading within that Season.

Other Seasons and header information remain interactive.

---

# Season Failure

If one Season fails:

- show a safe local error;
- offer Retry;
- preserve other Seasons;
- preserve the expanded/collapsed context where practical.

---

# Episode Mutation Loading

Mark Watched, Rewatch, and event deletion should use targeted loading.

A mutation on one Episode should not disable unrelated Episodes unless a broader consistency requirement makes it necessary.

---

# Duplicate Submission Protection

Non-idempotent watch-event creation must be protected from rapid duplicate taps/clicks.

This is particularly important for Rewatch because every successful request intentionally creates another event.

---

# Retry Safety

Reads and synchronization operations can generally be retried according to their contracts.

Non-idempotent viewing-event creation should not be blindly auto-replayed after an ambiguous network failure.

Otherwise the client could accidentally create two viewings.

---

# Empty States

Valid empty states include:

- no Seasons known;
- Season with no Episodes;
- no Episode watch history;
- no next Episode;
- no next upcoming Episode.

These should not be represented as generic errors.

---

# Errors

Show Details uses the common application error model.

Possible failures include:

- network;
- timeout;
- unauthorized;
- not found;
- provider error;
- validation error;
- conflict;
- invalid response;
- server failure.

Raw Dio, SQLAlchemy, or provider details should not be exposed directly.

See [API Errors](../api/errors.md).

---

# Metadata Sync

Show Details depends on persisted metadata that can be refreshed.

Metadata synchronization can update:

- Show metadata;
- Season metadata;
- future Episode knowledge;
- air dates;
- status;
- images;
- related provider data.

Manual refresh behavior should remain distinct from automatic background refresh policy where appropriate.

See [Metadata Sync](metadata-sync.md).

---

# Ended / Canceled Shows

Provider status normalization remains a known cross-cutting improvement.

Variants such as:

```text
Ended
Canceled
Cancelled
```

should eventually be normalized centrally enough that business rules do not repeatedly compare arbitrary strings.

This does not require turning the database field into a rigid enum if that would reduce provider resilience.

---

# External Ratings

Personal SofaWatch ratings and external provider ratings are separate concepts.

Future Show Details may present:

```text
SofaWatch personal rating
TMDB rating
IMDb rating
TVDB/other rating
```

without merging them into one unexplained score.

Any IMDb integration should use a legitimate and stable source rather than fragile scraping.

---

# More Like This

Related/recommended Shows are a reasonable future Show Details section.

They should use real provider/discovery data.

Do not hardcode editorial recommendations merely to fill the UI.

---

# Cast / Where to Watch

Show Details product direction includes richer metadata such as:

- cast;
- Where to Watch;
- related media.

These should only be documented as implemented when the corresponding backend/provider/frontend flow genuinely exists.

Provider availability and regional semantics should be explicit.

---

# Backend Responsibility

The backend owns:

- Show identity;
- persisted metadata;
- Library state;
- Episode persistence;
- Episode synchronization rules;
- viewing mutations;
- watch-event history;
- progress calculations;
- caught-up calculation;
- next Episode;
- next upcoming Episode;
- user scoping.

---

# Frontend Responsibility

Flutter owns:

- adaptive layout;
- Season accordion;
- row presentation;
- loading/error/empty states;
- invoking actions;
- mutation feedback;
- adaptive history modal;
- preserving local presentation context.

It should not duplicate backend business rules.

---

# Frontend Structure

The existing Show Details feature follows the project architecture:

```text
presentation/
application/
domain/
data/
```

Domain models include Show Details concepts such as Episodes, Seasons, progress, and watch events.

Repositories abstract API access.

Cubit/state orchestrates page and mutation behavior.

Widgets should remain focused and reusable rather than turning the entire page into one large build method.

---

# Design System

Show Details should use existing tokens such as:

```text
AppColors
AppTypography
AppSpacing
AppRadius
AppDurations
AppBreakpoints
```

Avoid introducing arbitrary spacing/radius/breakpoint values when a suitable token already exists.

---

# Responsive Strategy

Mobile and desktop should share domain/application behavior.

Presentation adapts.

Examples:

```text
Mobile
-> compact hero
-> stacked metadata
-> touch-friendly Season rows
-> bottom-sheet history

Desktop
-> wider hero
-> constrained content width
-> denser metadata
-> dialog history
```

Do not fork the entire feature into unrelated mobile and desktop implementations.

---

# Mobile Validation

Final mobile validation should include:

- narrow widths;
- long Show title;
- long overview;
- long Episode titles;
- Season accordion;
- Episode actions;
- history bottom sheet;
- safe areas;
- mutation loading;
- scroll preservation.

---

# Desktop Validation

Final desktop validation should include:

- sensible maximum width;
- ultrawide displays;
- metadata hierarchy;
- Season row density;
- Episode action alignment;
- dialogs;
- keyboard/mouse behavior.

---

# Accessibility

Final validation should include:

- semantic watched state;
- semantic progress;
- accessible accordion controls;
- accessible Mark Watched/Rewatch/Delete labels;
- keyboard navigation;
- focus behavior;
- sufficient target sizes;
- non-color-only state communication.

---

# Performance

Important performance characteristics include:

- lazy Season Episode loading;
- avoiding unnecessary provider calls;
- reusing persisted Episodes;
- avoiding rebuilding unrelated Seasons during local mutations;
- bounded History loading where applicable;
- efficient image rendering/caching.

Optimization should remain evidence-driven.

---

# Testing

Backend tests should cover:

```text
Show Details retrieval
user-scoped Library state
Season summaries
Episode sync
idempotent/local persistence behavior
progress
caught_up
next Episode
next upcoming
Specials behavior
future Episodes
unknown air dates
Mark Watched
Rewatch
watch_count
watched_at
event deletion
delete final event
user isolation
provider failures
```

Frontend tests should cover:

```text
initial loading
success
page failure
Library state
progress
Season collapsed state
Season expansion
Season loading
Season failure
Season Retry
Episode rows
Mark Watched
mutation loading
duplicate-submit protection
Rewatch
history open
history loading
history empty
history failure
event deletion
Season progress refresh
Show progress refresh
responsive presentation
```

---

# Known Final Validation

The roadmap still contains a general:

```text
16.15.8
Test remaining Seasons & Episodes functionality
```

Before considering Show Details fully finalized, this should include a regression pass across the existing Season/Episode interactions rather than creating new functionality simply to satisfy the checklist.

---

# Season Details Page

A separate Season Details page remains optional.

It should only be introduced if it solves a real navigation or information-density problem.

The existing expandable Season architecture is sufficient unless actual usage demonstrates otherwise.

---

# Future Work

## Final Seasons / Episodes Validation

```text
[ ] audit all Season loading states
[ ] audit Season Retry
[ ] audit Episode mutations
[ ] audit progress reconciliation
[ ] audit watch history
[ ] audit Rewatch
[ ] audit event deletion
[ ] audit future Episode behavior
[ ] audit unknown air-date behavior
[ ] complete missing regression tests
```

---

## Coordinated Refresh

```text
[ ] coordinate Show Details with Shows refresh
[ ] refresh progress without losing expanded Season context
[ ] preserve scroll
[ ] preserve loaded Seasons
[ ] reconcile Watch Next
[ ] reconcile Upcoming where relevant
```

---

## Provider Enhancements

```text
[ ] TVDB integration
[ ] provider identifier mappings
[ ] metadata precedence
[ ] metadata fallback
[ ] aliases
[ ] improved Episode metadata
[ ] evaluate reliable air-time data
[ ] external ratings
```

---

## Rich Metadata

Potential future additions:

```text
[ ] cast
[ ] Where to Watch
[ ] More Like This
[ ] external ratings
[ ] richer network/provider metadata
```

Only implement these with real provider/data support.

---

## Responsive / Accessibility

```text
[ ] mobile final audit
[ ] desktop final audit
[ ] ultrawide audit
[ ] keyboard navigation audit
[ ] semantics audit
[ ] focus audit
```

---

# Notes

> Full Show Details operates on SofaWatch's internal Show identity.

> Provider IDs are external identifiers, not primary domain IDs.

> Seasons load independently and should fail independently.

> Episode synchronization is lazy by Season rather than forcing every Episode during Show import.

> Viewing history is event-based.

> Rewatch creates another event and never overwrites the previous viewing.

> `caught_up`, user `Completed`, and provider `Ended` are separate concepts.

> Specials do not block normal regular-Episode progress.

> Missing Episode dates or times must never be invented.

> A separate Season Details page is optional, not a required architectural layer.

---

# Related Documentation

- [Implementation Status](implementation-status.md)
- [Library](library.md)
- [Viewing Progress](viewing-progress.md)
- [Watch List](watch-list.md)
- [Upcoming](upcoming.md)
- [History](history.md)
- [Statistics](statistics.md)
- [Metadata Sync](metadata-sync.md)
- [Architecture Overview](../architecture/overview.md)
- [Database Architecture](../architecture/database.md)
- [Data Flow](../architecture/data-flow.md)
- [Frontend Contract](../api/frontend-contract.md)
- [API Errors](../api/errors.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)
- [ADR-003: Internal Media IDs](../decisions/003-internal-media-ids.md)
- [ADR-006: Provider Independence](../decisions/006-provider-independence.md)
