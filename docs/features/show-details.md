# Show Details

## Overview

Show Details is the main TV Show inspection and interaction experience in SofaWatch.

It brings together:

- local Show metadata;
- Library state;
- viewing progress;
- Seasons;
- Episodes;
- Episode artwork;
- Episode watched state;
- watch history;
- rewatches;
- bulk watched actions;
- previous-unwatched Episode catch-up;
- navigation to Episode Details;
- metadata synchronization;
- related presentation information.

Show Details operates on SofaWatch's internal Show identity after import. External provider identifiers are metadata/mapping concerns rather than the primary identity used by the application.

See:

- [Library](library.md)
- [Viewing Progress](viewing-progress.md)
- [Watch List](watch-list.md)
- [Upcoming](upcoming.md)
- [Metadata Sync](metadata-sync.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)
- [ADR-003: Internal Media IDs](../decisions/003-internal-media-ids.md)
- [ADR-006: Provider Independence](../decisions/006-provider-independence.md)

---

## Status

**Implemented / Final Validation**

The core Show Details architecture and interaction model are implemented.

Implemented or established:

- Show metadata;
- protected poster/backdrop presentation;
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
- Episode still artwork;
- Episode-specific artwork semantics;
- Episode Details navigation;
- Episode watched state;
- watched timestamps;
- watch counts;
- Mark Watched;
- Mark Unwatched/correction flows;
- Episode watch history;
- individual watch-event deletion;
- Rewatch / Watched Again;
- Season bulk watched actions;
- Show bulk watched actions;
- previous-unwatched Episode catch-up;
- cross-feature viewing-state invalidation;
- Season and Show progress reconciliation;
- batch/progress infrastructure for Season summaries.

Remaining work is primarily final Seasons/Episodes validation, coordinated refresh behavior, responsive validation, and any provider-backed metadata enhancements added later.

See [Implementation Status](implementation-status.md).

---

# Goals

Show Details should allow the user to:

- inspect normalized local Show metadata;
- understand viewing progress;
- inspect Seasons and Episodes;
- open an Episode's dedicated details page;
- record and correct Episode viewing state;
- record rewatches without destroying previous History;
- inspect Episode viewing history;
- mark eligible Episodes watched in bulk;
- optionally catch up earlier unwatched Episodes when marking a later Episode watched;
- understand aired vs future progress;
- interact with Library state;
- use artwork that accurately represents the displayed media;
- preserve state while individual Seasons or mutations load/fail.

---

# Show Identity

Full Show Details operates on a local SofaWatch Show.

Conceptually:

```text
provider result
-> import
-> SofaWatch Show
-> internal Show ID
-> Show Details
```

Provider IDs remain external mappings.

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

Persisted Show poster/backdrop artwork is served through SofaWatch's protected image infrastructure and loaded by Flutter through the shared authenticated server-image component.

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

# Specials

Season 0 / Specials are distinct from regular progression.

Normal Show progress, catch-up behavior, and bulk watched operations should not let Specials distort the regular Episode progression model.

Specials can remain inspectable and individually watchable where appropriate.

---

# Seasons

Show Details exposes Season summaries and expandable Episode collections.

Each Season can contain:

- number/title;
- poster where available;
- Episode count;
- progress;
- aired progress;
- expanded/collapsed state;
- independent loading;
- independent failure/retry;
- bulk watched actions;
- Episode rows.

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

SofaWatch deliberately avoids requiring every Episode of every Season to be refreshed whenever Show Details is opened.

Once local Episodes exist, normal Season loading can reuse them according to the synchronization policy.

Advantages include:

- fewer provider requests;
- lower unnecessary storage/work;
- better perceived Show Details loading;
- ability to load only what the user inspects;
- avoiding provider traffic on every Show Details visit.

Explicit forced metadata synchronization is a separate operation and must not be conflated with ordinary Show Details loading.

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

A normal Show metadata refresh may update Show/Season information without necessarily forcing all Episode collections to be fetched.

The canonical Season/Episode synchronization service owns Episode metadata synchronization.

Forced Metadata Sync can explicitly perform a deep refresh:

```text
Show
-> Seasons
-> Episodes
```

using forced Season/Episode synchronization.

This allows previously persisted Episodes to receive metadata that became available later without making Show Details contact the provider every time it is opened.

See [Metadata Sync](metadata-sync.md).

---

# Episode Rows

An Episode row can expose:

- Episode still;
- Episode number;
- title;
- air date;
- runtime where available;
- watched state;
- watched date;
- watch count;
- Mark Watched / correction actions;
- access to viewing history;
- navigation to Episode Details.

Long or missing titles should degrade gracefully.

---

# Episode Artwork

Episode rows can display the Episode's own still artwork when available.

Within Show Details, Episode artwork follows a strict semantic rule:

```text
Episode still available
-> display Episode still

Episode still unavailable
-> display Episode placeholder

do not:
-> substitute Show poster
-> substitute Show backdrop
```

This avoids presenting series-level artwork as if it belonged to a specific Episode.

The same principle applies to Episode-specific Show/Season/Episode contexts.

Generic cross-feature cards such as Home may use broader fallback behavior where the card represents viewing context rather than a dedicated Episode details surface.

---

# Protected Episode Artwork

Persisted Episode stills are exposed through SofaWatch's authenticated image infrastructure.

Conceptually:

```text
Episode.still_url
-> relative SofaWatch image endpoint
-> ServerNetworkImage
-> resolve server URL
-> attach Bearer authentication
-> protected Episode still
```

If a provider still exists but is not yet cached locally, the backend image pipeline can fetch/cache it on demand.

If no Episode still exists, Show Details uses the Episode placeholder rather than Show-level artwork.

---

# Episode Details Navigation

The main informational/content area of an Episode row navigates to Episode Details.

Conceptually:

```text
Episode artwork / number / title / information
-> Episode Details
```

Episode-specific action controls remain independent:

```text
watched/status/history action
-> perform action
-> do not navigate
```

This separation prevents accidental navigation while changing viewing state.

Navigation uses the local SofaWatch Episode identity.

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

Mark Watched records a real viewing event.

A successful operation must reconcile backend-derived state such as:

```text
watch_count
watched_at
progress
caught_up
next Episode
```

The frontend should consume the returned/refreshed backend state rather than independently inventing these values.

---

# Previous Unwatched Episode Catch-Up

When marking a later regular Episode watched, SofaWatch can detect earlier regular Episodes that have already aired but remain unwatched.

Example:

```text
S01E01 watched
S01E02 unwatched
S01E03 unwatched
S01E04 -> user marks watched
```

SofaWatch can offer:

```text
mark S01E02 + S01E03 watched as well?
```

The catch-up operation is explicit.

The user can decline it and still mark the selected Episode watched.

---

# Catch-Up Eligibility

Previous-unwatched catch-up applies only to eligible previous regular Episodes.

The current rules exclude:

- Specials / Season 0;
- future Episodes;
- Episodes with unknown air dates;
- Episodes already watched.

The feature does not infer rewatches.

An Episode with an existing viewing event is already watched for catch-up purposes and must not receive another event merely because it appears before the selected Episode.

---

# Catch-Up Semantics

The feature represents a convenience for recording likely missing first-watch history.

It does not assert that the user definitely watched the previous Episodes.

Therefore:

```text
suggest
-> user confirms
-> create eligible missing viewing state

or

suggest
-> user declines
-> selected Episode still proceeds normally
```

The UI should never silently create previous watch events without confirmation.

---

# Season Bulk Watched

A Season can expose a bulk action for marking eligible Episodes watched.

The operation should apply to eligible aired regular Episodes that are not already watched.

Conceptually:

```text
Season
-> eligible aired regular Episodes
-> exclude already watched
-> create missing viewing state
```

Bulk watched must not create duplicate watch events for Episodes already watched.

---

# Show Bulk Watched

Show Details can expose a Show-level bulk watched action.

The operation applies across eligible regular Seasons/Episodes.

Current eligibility excludes:

- Specials / Season 0;
- future Episodes;
- Episodes with unknown air dates;
- Episodes already watched.

The operation records missing watched state without inventing rewatches.

---

# Bulk Watched Safety

Bulk actions potentially mutate many Episodes and therefore require deliberate user interaction.

The backend remains responsible for eligibility and mutation correctness.

Flutter should not reconstruct the authoritative bulk eligibility rules from presentation data.

After success, affected Show/Season/Episode progress and cross-feature viewing state must reconcile.

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
- History;
- Statistics.

Show Details should reconcile the directly relevant state while shared features refresh through their normal application mechanisms.

---

# Cross-Feature Viewing-State Invalidation

Viewing mutations in Show Details can affect multiple independently loaded application surfaces.

Successful viewing-state mutations therefore notify the shared viewing-state change mechanism.

Consumers such as Home and History can then refresh their own data without tightly coupling Show Details to their Cubits.

Conceptually:

```text
Show Details mutation
        |
        v
backend success
        |
        v
ViewingStateChangeNotifier
        |
        +-> Home refresh
        +-> History refresh
        +-> History preview refresh
```

The notification represents successful canonical viewing-state change.

It should be emitted once for a successful mutation and not emitted for a failed mutation.

This avoids one feature directly orchestrating unrelated presentation layers.

---

# Watch Next Reconciliation

Marking an Episode watched can change the next eligible unwatched Episode.

Example:

```text
before:
next = S01E04

mark S01E04 watched

after:
next = S01E05
```

Watch Next should derive the new result from backend truth.

---

# Haven't Watched in a While Reconciliation

A new viewing can change recency-based classification.

A Show previously considered inactive may no longer belong in Haven't Watched in a While after a new Episode viewing.

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
- global History;
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
bulk mutation
catch-up mutation
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

Mark Watched, Rewatch, catch-up, bulk operations, and event deletion should use appropriately scoped loading.

A mutation on one Episode should not disable unrelated Episodes unless a broader consistency requirement makes it necessary.

---

# Duplicate Submission Protection

Non-idempotent watch-event creation must be protected from rapid duplicate taps/clicks.

This is particularly important for Rewatch because every successful request intentionally creates another event.

Bulk and catch-up actions must also prevent duplicate submission while their operation is in progress.

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
- Episode with no still artwork;
- no Episode watch history;
- no next Episode;
- no next upcoming Episode;
- no previous unwatched Episodes requiring catch-up.

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
- server failure;
- protected artwork failure.

Raw Dio, SQLAlchemy, or provider details should not be exposed directly.

See [API Errors](../api/errors.md).

---

# Metadata Sync

Show Details depends on persisted metadata that can be refreshed.

Metadata synchronization can update:

- Show metadata;
- Season metadata;
- Episode metadata;
- future Episode knowledge;
- air dates;
- status;
- images;
- related provider data.

Normal Show Details loading should not force provider refresh simply because local Episode metadata exists.

Normal Metadata Sync respects its refresh/freshness policy.

Explicit Force refresh is a separate administrator-driven operation that can deeply refresh:

```text
Show
-> Seasons
-> Episodes
```

This can recover metadata that became available after the original import, including previously missing Episode still artwork.

See [Metadata Sync](metadata-sync.md).

---

# Missing Episode Artwork Recovery

An Episode can legitimately have no provider still when first synchronized.

Example:

```text
Episode imported
tmdb_still_path = null
```

The Episode remains valid and Show Details displays its placeholder.

If the provider later publishes a still:

```text
Force Metadata Sync
-> force Season/Episode refresh
-> current provider Episode metadata
-> tmdb_still_path populated
```

A later protected image request can then cache and serve the artwork.

This recovery path is intentionally separate from opening Show Details so that normal navigation does not generate unnecessary provider requests.

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
- Episode artwork endpoints/cache;
- viewing mutations;
- catch-up eligibility;
- bulk watched eligibility;
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
- Episode Details navigation;
- authenticated protected-artwork loading;
- loading/error/empty states;
- invoking actions;
- catch-up confirmation/presentation;
- bulk-action presentation;
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

Cubits/state orchestrate page and mutation behavior.

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
- Episode stills/placeholders;
- Season accordion;
- Episode navigation;
- Episode actions;
- bulk actions;
- catch-up confirmation;
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
- Episode artwork;
- Episode navigation;
- Episode action alignment;
- bulk actions;
- catch-up confirmation;
- dialogs;
- keyboard/mouse behavior.

---

# Accessibility

Final validation should include:

- semantic watched state;
- semantic progress;
- accessible accordion controls;
- accessible Episode navigation;
- accessible Mark Watched/Rewatch/Delete labels;
- accessible bulk watched actions;
- accessible catch-up confirmation;
- keyboard navigation;
- focus behavior;
- sufficient target sizes;
- non-color-only state communication.

---

# Performance

Important performance characteristics include:

- lazy/reused Season Episode loading;
- avoiding unnecessary provider calls;
- reusing persisted Episodes;
- protected image caching;
- avoiding rebuilding unrelated Seasons during local mutations;
- bounded History loading where applicable;
- efficient image rendering/caching.

Force Metadata Sync is intentionally allowed to perform more provider work, but it is an explicit administrator operation rather than normal Show Details behavior.

Optimization should remain evidence-driven.

---

# Testing

Backend tests should cover:

```text
Show Details retrieval
user-scoped Library state
Season summaries
Episode sync
forced Episode sync
idempotent/local persistence behavior
progress
caught_up
next Episode
next upcoming
Specials behavior
future Episodes
unknown air dates
Mark Watched
previous-unwatched catch-up detection
catch-up confirmation mutation behavior
catch-up excludes Specials
catch-up excludes future Episodes
catch-up excludes unknown air dates
catch-up does not infer rewatches
Season bulk watched
Show bulk watched
bulk excludes Specials
bulk excludes future Episodes
bulk excludes unknown air dates
bulk avoids duplicate watch events
Rewatch
watch_count
watched_at
event deletion
delete final event
Episode still resolution
missing Episode still
protected Episode still endpoint
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
Episode still
Episode still placeholder
Episode content opens Episode Details
Episode action does not navigate
Mark Watched
previous-unwatched catch-up prompt
catch-up decline
catch-up confirm
Season bulk watched
Show bulk watched
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
cross-feature viewing-state notification
responsive presentation
```

---

# Known Final Validation

The roadmap still contains a general Seasons/Episodes final-validation requirement.

Before considering Show Details fully finalized, this should include a regression pass across the existing Season/Episode interactions rather than creating new functionality simply to satisfy the checklist.

The regression pass should now include the recently completed:

```text
Episode Details navigation
Episode still artwork
bulk watched actions
previous-unwatched catch-up
protected artwork
cross-feature viewing-state refresh
```

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
[ ] audit Episode Details navigation
[ ] audit Episode artwork/placeholders
[ ] audit bulk watched actions
[ ] audit previous-unwatched catch-up
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
[ ] final cross-feature refresh audit
[ ] refresh progress without losing expanded Season context
[ ] preserve scroll
[ ] preserve loaded Seasons
[ ] reconcile Watch Next
[ ] reconcile Upcoming where relevant
```

The shared viewing-state change notifier already provides cross-feature invalidation for relevant successful viewing mutations; remaining work is final behavioral/regression validation rather than introducing direct Cubit-to-Cubit coupling.

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

> Existing local Episodes can be reused during normal Show Details loading; deep forced Episode refresh is an explicit Metadata Sync operation.

> Episode-specific Show Details presentation uses the Episode still or a placeholder and does not substitute the Show poster/backdrop.

> Persisted protected artwork is loaded through authenticated SofaWatch image requests.

> Episode row content can navigate to Episode Details while action controls remain independently interactive.

> Season and Show bulk watched operations only create missing eligible viewing state and do not infer rewatches.

> Previous-unwatched catch-up is explicitly confirmed by the user and excludes Specials, future Episodes, unknown air dates, and already watched Episodes.

> Viewing history is event-based.

> Rewatch creates another event and never overwrites the previous viewing.

> Successful viewing mutations can invalidate independent Home/History state through the shared viewing-state change mechanism.

> `caught_up`, user `Completed`, and provider `Ended` are separate concepts.

> Specials do not block normal regular-Episode progress.

> Missing Episode dates or times must never be invented.

> Missing provider artwork does not make an Episode invalid.

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
