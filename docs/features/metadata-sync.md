# Metadata Synchronization

## Overview

Metadata Synchronization keeps SofaWatch's locally persisted media metadata aligned with external metadata providers while preserving SofaWatch-owned application state.

SofaWatch does not treat an external provider as its runtime database.

Instead:

```text
External Metadata Provider
          |
          v
Provider Client / Schemas
          |
          v
Application Service
          |
          v
SofaWatch Local Database
          |
          v
Web / iOS / Android
```

Clients consume SofaWatch's normalized local domain data. They do not independently synchronize media with TMDB.

TMDB is currently the primary metadata provider. TVDB is planned, and the architecture is intended to remain provider-independent.

Metadata synchronization currently covers TV metadata including:

- Shows;
- Genres;
- Networks;
- Seasons;
- Episodes.

The system supports periodic automatic synchronization, normal manual execution, explicit forced metadata refresh, and per-Show manual refresh through the Background Jobs and metadata synchronization infrastructure.

See:

- [Background Jobs](background-jobs.md)
- [Show Details](show-details.md)
- [Upcoming](upcoming.md)
- [Search](search.md)
- [Server Administration](server-administration.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)
- [ADR-003: Internal Media IDs](../decisions/003-internal-media-ids.md)
- [ADR-006: Provider Independence](../decisions/006-provider-independence.md)

---

## Status

**Implemented / Evolving**

Implemented:

- TMDB as the current primary TV metadata provider;
- import of TV Shows into the local database;
- Show metadata synchronization;
- Genre synchronization;
- Network synchronization;
- Season synchronization;
- Episode synchronization;
- updates to existing local entities;
- creation of newly discovered Seasons/Episodes;
- preservation of local-only media paths/overrides during refresh;
- non-destructive handling of Seasons/Episodes missing from a provider response;
- manual Show metadata refresh;
- periodic automatic metadata synchronization;
- persistent metadata-sync background job;
- eight-hour synchronization schedule;
- refresh-policy-aware automatic synchronization;
- manual Background Job execution using the same normal refresh semantics as scheduled execution;
- explicit forced Metadata Sync execution;
- forced execution support through an optional Background Job force handler;
- rejection of forced execution for jobs that do not support it;
- forced Show metadata refresh ignoring normal freshness rules;
- forced Season metadata refresh;
- forced Episode metadata refresh through the canonical Season/Episode synchronization service;
- recovery of metadata that became available after the original import or previous synchronization;
- recovery of previously missing Episode artwork when TMDB later provides a still;
- automatic exclusion of ended and canceled Shows;
- manual refresh for ended/canceled Shows;
- per-Show transaction boundaries;
- failure isolation between Shows;
- `checked`, `refreshed`, `skipped`, and `failed` execution metrics;
- persisted structured execution results;
- deep-refresh execution metrics for forced synchronization;
- administrator `Run now` and `Force refresh` controls in Profile;
- explicit confirmation before forced metadata refresh;
- frontend busy-state protection against duplicate manual execution;
- failed job runs retaining their structured synchronization result.

Planned/evolving:

- TVDB integration;
- provider-independent external identifier expansion;
- provider precedence/fallback rules;
- richer metadata conflict/precedence rules;
- Movie metadata synchronization strategy where periodic refresh is useful;
- richer administrator synchronization history and diagnostics UI;
- worker/provider diagnostics;
- rate-limit/backoff hardening where needed;
- metadata language integration;
- additional automated tests as provider support expands.

The current implementation refreshes locally stored metadata from TMDB while preserving local-only media paths. Seasons and Episodes that disappear from a TMDB response are not automatically deleted. Automatic synchronization runs every eight hours and respects the normal refresh policy. A normal manual `Run now` execution uses the same semantics, while an explicit `Force refresh` bypasses metadata freshness and performs a deeper Show → Season → Episode refresh.

---

# Goals

Metadata Synchronization should:

- keep locally stored metadata reasonably current;
- avoid unnecessary provider requests;
- preserve SofaWatch-owned state;
- update existing entities instead of duplicating them;
- discover newly added Seasons and Episodes;
- tolerate provider failures;
- isolate failures between Shows;
- remain observable through Background Jobs;
- support explicit manual refresh;
- remain adaptable to multiple metadata providers.
- distinguish normal synchronization from explicit forced synchronization;
- allow administrators to recover stale or previously unavailable provider metadata;
- reuse the canonical Season/Episode synchronization path for deep refreshes;

---

# Non-Goals

Metadata Synchronization is not:

- synchronization of viewing History;
- synchronization of user Library status;
- synchronization of ratings entered by SofaWatch users;
- a reason to overwrite local application state;
- a direct client-to-TMDB workflow;
- a full mirror of every provider field;
- a destructive reconciliation process where provider omissions automatically delete local entities.

User-owned state and provider-owned metadata are separate concerns.

---

# Source of Truth

SofaWatch's backend/database is the application source of truth.

External providers are authoritative only for the external metadata fields SofaWatch chooses to consume.

Conceptually:

```text
TMDB
-> metadata source

SofaWatch
-> application source of truth
```

This distinction matters because SofaWatch also owns information that TMDB does not:

```text
Library membership
tracking status
watch events
ratings
local overrides
user preferences
internal IDs
```

See [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md).

---

# Metadata vs User State

Synchronization must not conflate metadata with user state.

Example:

```text
TMDB refresh
-> title changes
-> overview changes
-> new Episode appears

but must not:
-> mark Episode watched
-> remove user History
-> change Library status
```

---

# Current Provider

TMDB is currently SofaWatch's primary external metadata provider. 

It is used for TV metadata such as:

```text
Show
Season
Episode
Genre
Network
```

Other TMDB-backed functionality such as Search and Discovery uses the provider through its own application flows.

---

# Provider Isolation

External integrations are isolated behind provider components rather than accessed directly by API routes or persistence code. The backend architecture separates provider clients/schemas from application services and local persistence.

Conceptually:

```text
TMDB API
   |
   v
TMDB Client
   |
   v
TMDB Schemas
   |
   v
Application Service
   |
   v
Repositories
```

This allows provider-specific HTTP/JSON behavior to remain outside the SofaWatch domain.

---

# Provider Independence

TMDB should not become the permanent identity model for SofaWatch.

SofaWatch entities use internal IDs.

Provider IDs are external identifiers.

```text
Show
├── SofaWatch internal ID
└── external IDs
    ├── TMDB
    ├── TVDB      future
    └── IMDb      where applicable
```

See:

- [ADR-003: Internal Media IDs](../decisions/003-internal-media-ids.md)
- [ADR-006: Provider Independence](../decisions/006-provider-independence.md)

---

# Import vs Refresh

Initial media import and metadata refresh are related but distinct operations.

## Import

```text
provider media
-> create SofaWatch entity
-> persist provider identifiers
-> persist metadata
-> create related local entities
```

## Refresh

```text
existing SofaWatch entity
-> fetch current provider metadata
-> update provider-owned fields
-> preserve SofaWatch-owned state
```

Both should reuse shared synchronization logic where appropriate.

## Forced Refresh

```text
existing SofaWatch entities
-> explicitly request current provider metadata
-> ignore normal freshness eligibility
-> refresh Show metadata
-> refresh Seasons
-> refresh Episodes
-> preserve SofaWatch-owned state

---

# TV Show Import

When a TV Show is imported from TMDB:

```text
TMDB Show
    |
    v
Show import service
    |
    +-> Show
    +-> Genres
    +-> Networks
    +-> Seasons
    +-> Episodes
```

The imported Show receives a SofaWatch internal ID.

Subsequent application relationships should use that internal ID.

---

# Idempotent Import

Importing the same provider Show again should reuse/update the existing SofaWatch entity rather than create a duplicate.

Conceptually:

```text
TMDB ID already mapped
-> reuse internal Show
```

Provider identity constraints/repository behavior should enforce this at the backend.

---

# Synchronization Scope

Current TV synchronization covers:

```text
TV Show
├── core Show metadata
├── Genres
├── Networks
├── Seasons
└── Episodes
```

The repository documentation confirms these current synchronization areas.

---

# Show Metadata

Show synchronization can update provider-owned fields such as the current normalized Show metadata supported by the domain.

Examples may include:

```text
title/name
overview
status
first air date
poster/backdrop provider data
provider identifiers
```

The exact field set should follow the current models/provider schemas rather than this document becoming a duplicate schema definition.

---

# Genres

Genres are synchronized from provider metadata.

Genre relationships should reuse existing normalized Genre entities where appropriate rather than creating duplicate local Genres on every refresh.

---

# Networks

Networks are synchronized similarly.

Provider identity/matching should keep network records stable across repeated refreshes.

---

# Seasons

Synchronization updates existing Seasons and creates newly discovered Seasons.

Conceptually:

```text
provider Season already known
-> update metadata

provider Season new
-> create local Season
```

---

# Episodes

Episodes follow the same principle:

```text
provider Episode already known
-> update metadata

provider Episode new
-> create local Episode
```

Episode synchronization is owned by the canonical Season/Episode synchronization service.

Normal synchronization may reuse already persisted Episode metadata according to its refresh semantics.

Forced metadata synchronization explicitly invokes Episode synchronization with forced refresh enabled for each local Season.

This distinction prevents Show import logic from duplicating Episode synchronization responsibilities.

This is important for Upcoming and Watch Next because newly announced Episodes must become local domain entities.

---

# Internal Relationships

Once synchronized, application relationships use local IDs:

```text
Show.id
Season.id
Episode.id
```

rather than requiring the Flutter client to operate on TMDB IDs.

---

# Non-Destructive Provider Omissions

A Season or Episode missing from a later TMDB response is **not automatically deleted** from SofaWatch. This is part of the current synchronization strategy.

Conceptually:

```text
local Episode exists
+
provider response omits Episode
!=
DELETE local Episode
```

---

# Why Missing Does Not Mean Delete

Provider responses can change temporarily or contain incomplete/adjusted data.

Automatic deletion could destroy relationships with:

- Watch Events;
- viewing progress;
- History;
- Library-derived state;
- future local overrides.

Therefore provider omission is not sufficient evidence for destructive deletion.

---

# Future Reconciliation

If SofaWatch later needs to represent removed/provider-invalid media, prefer explicit reconciliation state over blind deletion.

Potential concepts might include:

```text
provider_missing
inactive
superseded
```

Only introduce such state when there is a real product requirement.

---

# Local Overrides

Provider refresh must preserve SofaWatch-owned local overrides.

The current implementation explicitly preserves local-only media paths during metadata refresh.

Conceptually:

```text
provider poster URL changes
+
local artwork path exists

-> do not destroy the local-only path
```

---

# Ownership of Fields

A useful conceptual distinction is:

```text
Provider-owned fields
-> may be refreshed from provider

SofaWatch-owned fields
-> preserved

User-owned fields
-> preserved
```

This should become more explicit as additional providers and local customization are added.

---

# Metadata Precedence

With only TMDB, precedence is relatively simple.

With future TVDB and other sources, SofaWatch needs explicit field-level or source-level precedence rules.

Example future policy:

```text
title        -> preferred provider
episode data -> preferred TV provider
rating       -> external ratings source
local art    -> local override wins
```

Do not implement implicit "last provider response wins" behavior across all fields.

---

# Automatic Synchronization

Automatic synchronization is handled by the persistent Background Jobs system.

The current metadata-sync job runs on an eight-hour schedule.

Conceptually:

```text
every 8 hours
      |
      v
metadata_sync job
      |
      v
evaluate local Shows
      |
      v
refresh policy
```

---

# Manual Background Job Execution

The Metadata Sync Background Job can be started manually from Server Administration/Profile.

There are two distinct execution modes:

```text
Run now
-> execute normal metadata synchronization immediately
-> respect normal refresh/freshness policy

Force refresh
-> execute forced metadata synchronization
-> bypass normal metadata freshness
-> deeply refresh locally stored Shows, Seasons, and Episodes
```

Run now does not imply forced synchronization.

This distinction keeps normal manual execution predictable and prevents an administrator action from unexpectedly generating a large number of external provider requests.

---

# Forced Metadata Synchronization
Forced Metadata Sync is an explicit deep-refresh mode of the `metadata_sync` Background Job.
For each locally stored Show, the forced job performs:

```text
Show
 |
 +-> refresh Show metadata
 |
 +-> load locally persisted Seasons
       |
       +-> force Season/Episode synchronization
             |
             +-> refresh existing Episodes
             +-> create newly discovered Episodes
             +-> refresh Episode still metadata
```

Normal metadata freshness rules do not prevent this operation.

The forced path still preserves normal validation, provider identity rules, transaction safety, and SofaWatch-owned state.

Forced synchronization is deliberately more expensive than normal synchronization and may make significantly more provider requests.




---

# Job Schedule vs Refresh Policy

The eight-hour job cadence does **not** mean every Show is refreshed every eight hours.

These are separate decisions:

```text
Schedule
-> when the job evaluates Shows

Refresh policy
-> whether each Show needs a provider refresh
```

This reduces unnecessary provider traffic and database writes.

---

# Recovering Previously Missing Metadata

Provider metadata can legitimately be incomplete when media is first imported.
For example:

```text
Episode imported
-> TMDB still_path = null
-> local Episode remains valid
```

If TMDB later publishes artwork, normal synchronization may continue using the existing local Episode metadata until a refresh is required.

A forced metadata refresh can explicitly request current Episode metadata and backfill the newly available provider field.

Example:

```text
before force:
tmdb_still_path = null

TMDB later publishes Episode still

after force:
tmdb_still_path = /provider/path.jpg
```

This was an important reason for introducing forced deep Episode refresh rather than making every Show Details request contact TMDB.

---

# Checked Shows

Each automatic run evaluates locally stored TV Shows.

Every evaluated Show contributes to:

```text
checked
```

The current invariant is:

```text
checked = refreshed + skipped + failed
```

This behavior is documented by the current implementation.

---

# Refreshed

A Show counts as:

```text
refreshed
```

when the automatic policy determines that a refresh is required and synchronization succeeds.

---

# Skipped

A Show counts as:

```text
skipped
```

when automatic synchronization intentionally does not refresh it.

Reasons include:

- metadata is still recent according to refresh policy;
- Show status excludes automatic refresh;
- another normal automatic-refresh rule determines refresh is unnecessary.

---

# Failed

A Show counts as:

```text
failed
```

when its synchronization attempt raises/fails.

Failure should not count as skipped.

---

# Metrics Invariant

For a completed evaluation set:

```text
checked
=
refreshed
+
skipped
+
failed
```

This invariant makes execution results understandable and testable.

---

# Structured Results

The metadata-sync job returns structured execution results containing these counters.

The Background Jobs system persists them with the corresponding execution history entry.

Example:

```text
checked:   48
refreshed: 12
skipped:   34
failed:     2
```

---

# Why Structured Results Matter

Structured metrics allow Server Administration to answer:

```text
Did the job run?
How many Shows needed work?
How many were skipped?
How many failed?
```

without parsing log messages.

See [Background Jobs](background-jobs.md).

---

# Refresh Policy

Automatic synchronization uses a backend refresh policy.

The policy determines whether a local Show should be refreshed at the current time.

It should remain centralized rather than duplicated in:

- worker code;
- API routes;
- Flutter;
- individual repositories.

---

# Fresh Metadata

If metadata was refreshed recently enough according to the policy:

```text
automatic sync
-> skipped
```

This avoids redundant provider calls.

---

# Active Shows

Active/ongoing Shows are the primary candidates for automatic metadata refresh because their:

- Episodes;
- Seasons;
- air dates;
- status;
- metadata

can continue changing.

Exact refresh intervals should remain defined by backend policy.

---

# Ended Shows

Ended Shows are evaluated by the automatic job but skipped by the automatic refresh policy.

Conceptually:

```text
Show.status = Ended
-> automatic refresh = no
```

---

# Canceled Shows

Canceled Shows are also excluded from automatic refresh.

```text
Show.status = Canceled
-> automatic refresh = no
```

---

# Why Ended/Canceled Are Skipped

These Shows are substantially less likely to receive meaningful metadata changes.

Skipping them reduces:

- provider API calls;
- worker execution time;
- database writes.

This is an optimization policy, not a permanent prohibition on refresh.

---

# Individual Show Refresh

A locally stored TV Show can also be refreshed individually through the API, independently of the Metadata Sync Background Job.

Manual refresh bypasses the normal automatic refresh policy.

Conceptually:

```text
User/Admin explicit refresh
        |
        v
refresh existing Show
        |
        v
do not reject merely because
Show is Ended/Canceled/recently refreshed
```

---

# Individual Refresh of Ended Shows

Because manual refresh bypasses automatic eligibility:

```text
Ended Show
-> manual refresh allowed
```

This is useful if TMDB later corrects:

- Episode metadata;
- artwork;
- dates;
- overview;
- provider data.

---

# Individual Refresh of Canceled Shows

Canceled Shows follow the same principle.

Automatic refresh remains suppressed while explicit user intent can request current provider data.

---

# Force Semantics

Forced synchronization means bypassing normal metadata freshness/eligibility rules.

It does **not** mean bypassing application safety or consistency rules.

```text
Force refresh
-> ignore normal metadata freshness
-> explicitly request current provider metadata

but still:
-> validate provider responses
-> preserve internal identities
-> preserve SofaWatch-owned state
-> preserve transaction safety
-> enforce synchronization invariants
```
Force is therefore a refresh-policy override, not a general safety bypass.

---

# API Ownership

Manual synchronization is exposed through the backend API.

Flutter requests the operation.

Flutter does not perform TMDB synchronization itself.

Conceptually:

```text
Flutter
-> SofaWatch API
-> synchronization service
-> TMDB provider
-> repositories
```

---

# Transaction Boundary

Current metadata refreshes are transactional at the **Show level**.

Conceptually:

```text
Show A transaction
-> success
-> commit

Show B transaction
-> failure
-> rollback B

Show C transaction
-> success
-> commit
```

---

# Why Per-Show Transactions

A single transaction for the entire automatic job would create undesirable behavior:

```text
47 Shows synchronized successfully
1 Show fails
-> rollback everything
```

Per-Show transactions preserve valid successful work while isolating failures.

---

# Failure Isolation

A failed Show synchronization does not prevent the automatic job from attempting the remaining Shows.

This is essential for resilient batch behavior.

---

# Failed Run Semantics

The current behavior marks the overall Background Job run as failed when one or more Show synchronizations fail, while still preserving the structured synchronization result.

Example:

```text
checked:   30
refreshed: 10
skipped:   19
failed:     1

Job status:
failed

Structured result:
preserved
```

This makes partial failure visible without losing successful work.

---

# Partial Success

The database may therefore contain valid metadata updates from successful Shows even when the overall job status is failed.

This is intentional.

```text
job failed
!=
all synchronization work rolled back
```

---

# Error Detail

Provider/database exceptions should be logged with appropriate operational context.

Client-facing/admin-facing results should remain safe.

Do not expose:

- provider tokens;
- raw secrets;
- unnecessary stack traces.

See [Server Administration](server-administration.md).

---

# Provider Timeouts

External provider requests should use bounded timeouts.

A single stalled TMDB request should not block the worker indefinitely.

Timeout should become a Show synchronization failure and allow the batch to continue where possible.

---

# Provider Unavailability

If TMDB is temporarily unavailable:

```text
affected Show refreshes
-> fail

local metadata
-> remains available

future run/manual refresh
-> can recover
```

The local database allows SofaWatch to remain useful during provider outages.

---

# Invalid Provider Responses

Provider schemas should validate external responses before they reach persistence logic.

Invalid data should fail safely rather than corrupt normalized local entities.

---

# Rate Limits

Automatic synchronization should minimize provider load through:

- refresh-policy checks;
- ended/canceled exclusions;
- no unnecessary forced refresh;
- controlled execution.

If explicit rate-limit/backoff handling becomes necessary, it belongs in provider/application infrastructure.

---

# Retry

Automatic failures naturally receive another opportunity during a later scheduled synchronization if the Show remains eligible.

Manual refresh also provides an explicit retry path.

Avoid aggressive retry loops during a provider-wide outage.

Forced refresh also provides an explicit recovery path when locally persisted metadata is stale or incomplete but normal freshness rules would otherwise skip it.

---

# Background Job Integration

Metadata Synchronization is the first scheduled SofaWatch Background Job.

The Background Jobs system provides:

- registration;
- scheduling;
- persistent state;
- execution history;
- duration;
- failure information;
- next-run tracking;
- structured execution results;
- normal manual job execution;
- optional forced job execution;
- job-specific force handlers;
- rejection of unsupported forced execution.

The `metadata_sync` job registers both a normal handler and a forced handler.

Scheduled execution always uses the normal handler.

A manual request uses the forced handler only when `force=true` is explicitly requested.


```text
scheduler -> normal handler

Run now -> normal handler

Force refresh -> force handler
```


See [Background Jobs](background-jobs.md).

---

# Worker

The background worker runs separately from FastAPI.

Development command:

```bash
python -m app.jobs.worker
```

The current backend also supports manual execution of the registered metadata job with:

```bash
python -m app.jobs.run metadata_sync
```

as documented in the repository.

---

# API vs Worker Refresh

There are several synchronization entry points:

```text
Individual Show Refresh
-> API request
-> one explicit Show

Scheduled Metadata Sync
-> worker/background job
-> normal handler
-> evaluate local Shows according to refresh policy

Manual Run Now
-> API/background job
-> normal handler
-> same semantics as scheduled synchronization

Manual Force Refresh
-> API/background job
-> force handler
-> deep Show/Season/Episode refresh
```

They should converge on shared synchronization/business services where possible.

---

# Refresh and Viewing Progress

Metadata synchronization can change the Episode/Season graph.

Example:

```text
new Episode imported
```

can affect:

- total Episode count;
- aired progress;
- caught-up state;
- Watch Next;
- Upcoming.

The backend remains responsible for deriving these states from the updated canonical data.

---

# New Episodes

When a provider introduces a new Episode:

```text
metadata refresh
-> Episode created locally
-> future application queries can include it
```

If it has aired and is unwatched, it may affect Watch Next/progress.

If it has not aired, it may affect Upcoming.

---

# New Seasons

A newly announced Season can similarly become available after synchronization.

Show Details should consume the refreshed local model rather than querying TMDB independently.

---

# Air-Date Changes

Provider air dates can change.

A refresh can therefore alter:

- Upcoming ordering;
- whether an Episode is considered aired;
- next upcoming Episode;
- caught-up calculations.

Derived application state should be recalculated from canonical metadata rather than stored inconsistently in Flutter.

---

# Show Status Changes

Synchronization can change a Show from an active state to:

```text
Ended
Canceled
```

After that update, subsequent automatic runs apply the new refresh policy and normally skip it.

---

# Status Transition Example

```text
Run 1:
Show = Returning Series
-> refreshed
-> TMDB now reports Ended

Run 2:
Show = Ended
-> evaluated
-> skipped automatically
```

Manual refresh remains available.

---

# Metadata and History

Watch Events must survive metadata refresh.

Example:

```text
Episode title changes
```

must not delete:

```text
EpisodeWatchEvent
```

The local Episode identity remains stable.

---

# Metadata and Library

Show Library membership/status must also survive metadata refresh.

Provider status such as:

```text
Ended
```

is metadata and is not the same thing as the user's SofaWatch Library status such as:

```text
Completed
Dropped
Watching
```

---

# Metadata and Ratings

User ratings are SofaWatch/user state.

External provider rating data, if added, must remain separate.

A metadata refresh must not overwrite a user's personal rating.

---

# Movies

SofaWatch supports Movies as application entities, but the current periodic metadata-sync documentation/implementation is focused on TV Shows.

Movie metadata refresh should be added to periodic synchronization only when there is a clear need and refresh policy.

Do not assume TV synchronization rules apply unchanged to Movies.

---

# Movie Refresh Considerations

Potential future Movie refresh fields include:

- release dates;
- artwork;
- overview;
- provider availability;
- external ratings.

Movie metadata generally changes differently from ongoing TV episode metadata, so it may deserve a different refresh cadence/policy.

---

# TVDB Integration

TVDB is planned as an additional metadata provider.

The goal is not simply:

```text
replace TMDB with TVDB
```

but:

```text
support multiple provider identities
+
define provider responsibilities
+
define precedence/fallback
```

---

# External Identifier Model

Future synchronization should be able to resolve a local Show through known external IDs.

Conceptually:

```text
SofaWatch Show
├── TMDB 123
├── TVDB 456
└── IMDb tt...
```

This supports provider interoperability without changing SofaWatch's internal ID.

---

# Provider Matching

When adding a second provider, cross-provider matching must be explicit.

Strong external-ID mappings are preferable to repeated title-only matching.

Avoid silently attaching metadata from an ambiguous title match.

---

# Provider Precedence

Before multiple providers write overlapping fields, define precedence.

Questions include:

```text
Which provider owns Episode ordering?
Which provider supplies artwork?
Which provider supplies overview?
What happens when providers disagree?
Does local override always win?
```

These rules should be documented and tested before multi-provider write synchronization is enabled.

---

# Provider Fallback

Fallback can be useful when the preferred provider lacks a field.

Conceptually:

```text
local override
-> preferred provider
-> fallback provider
-> existing local value
```

The exact rule may vary by field.

Avoid wiping an existing useful value merely because the current provider response is empty.

---

# Metadata Language

Future localization can connect metadata-provider language to user/server preferences.

This requires clear policy because changing provider language can update locally persisted:

- titles;
- overviews;
- other localized text.

UI language and metadata language do not necessarily need to be identical.

---

# Multi-User Behavior

Metadata entities are shared server-side media data.

User state remains user-scoped.

Conceptually:

```text
Shared:
Show
Season
Episode
Movie
provider metadata

Per-user:
Library
Watch Events
Ratings
preferences
```

This prevents SofaWatch from storing duplicate metadata copies for every user.

---

# Synchronization Triggered by Search/Import

Search can discover provider media that is not yet local.

When a user imports/adds that media, the backend creates the local normalized entity.

Periodic synchronization then keeps that local media current.

See [Search](search.md).

---

# Synchronization Triggered by Show Details

Show Details should normally display locally persisted metadata.

If the product later introduces stale-on-view refresh behavior, it should call a backend synchronization operation according to backend policy rather than having Flutter fetch provider data directly.

---

# Server Health

TMDB health is exposed separately through Server Administration.

A health check answers:

```text
Is TMDB configured/reachable?
```

Metadata synchronization answers:

```text
Should this media be updated, and can it be synchronized?
```

Do not conflate the two operations.

---

# Configuration

Provider credentials are backend configuration.

Flutter must never receive the TMDB token merely to perform synchronization.

Server Administration can expose:

```text
configured: true/false
```

without exposing the credential itself.

---

# Logging

Useful synchronization logs can include:

```text
Show internal ID
provider identifier
refresh decision
execution ID
duration
safe failure category
```

Avoid logging provider tokens or unnecessarily large raw provider responses.

---

# Observability

Administrators should be able to understand:

```text
when metadata sync last ran
whether it succeeded
how many Shows were checked
how many refreshed
how many skipped
how many failed
when it will run again
```

This information belongs primarily to Background Jobs/Server Administration.

---

# Manual Refresh UX

A manual refresh action should:

```text
disable duplicate submission while running
show progress/loading
show safe failure
refresh local Show Details after success
```

The exact Flutter interaction belongs to the consuming feature.

---

# Forced Refresh UX

The administrator-facing Metadata Sync controls distinguish normal execution from forced execution.

Conceptually:

```text
[ Run now ] [ Force refresh ] [ Info ]
```

Force refresh:
* is available only for jobs that support forced execution;
* explains that it ignores normal metadata freshness;
* warns that substantially more provider requests may be made;
* requires explicit confirmation;
* prevents duplicate submission while the job is being started/running.

This keeps the expensive operation deliberate rather than making it the default manual action.


---

# Coordinated Refresh

After successful metadata refresh, affected frontend state may need reconciliation.

Potential consumers include:

- Show Details;
- Upcoming;
- Watch Next;
- Home;
- Library previews.

Avoid hard-coding one giant global reload if targeted refresh/invalidation can preserve UX.

---

# Cache Invalidation

If frontend/backend caches are introduced around metadata, successful synchronization must invalidate or update affected entries.

Stale cached metadata should not indefinitely hide a successful refresh.

---

# Performance

Metadata synchronization should minimize unnecessary work.

Important strategies include:

- evaluate refresh policy before provider fetch;
- skip ended/canceled Shows automatically;
- reuse existing local entities;
- avoid duplicate provider requests within one synchronization;
- use deliberate transaction boundaries;
- avoid unbounded parallel writes to SQLite.

---

# SQLite Considerations

FastAPI and the worker can both access SQLite.

Synchronization should avoid long unnecessary write transactions.

Per-Show transaction boundaries help limit failure scope and lock duration.

See [Database Architecture](../architecture/database.md).

---

# Concurrency

Automatic and manual synchronization can theoretically target the same Show at similar times.

The backend should define/protect appropriate concurrency semantics.

Goals:

```text
no duplicate entity creation
no corrupted relationships
no local override loss
predictable final metadata
```

If explicit locking/claiming becomes necessary, keep it backend-owned.

---

# Idempotency

Repeating a successful synchronization should not create duplicate:

- Shows;
- Seasons;
- Episodes;
- Genres;
- Networks.

Updates should converge on the same normalized local entities.

---

# Testing

Current/future backend tests should cover at least:

```text
Show import
existing Show reuse
Show metadata update
Genre synchronization
Network synchronization
Season creation
Season update
Episode creation
Episode update
local media path preservation
missing provider Season not deleted
missing provider Episode not deleted
manual refresh
manual refresh bypasses policy
automatic refresh policy
fresh metadata skipped
Ended Show skipped automatically
Canceled Show skipped automatically
Ended Show manually refreshable
Canceled Show manually refreshable
per-Show transaction rollback
one Show failure does not stop remaining Shows
checked counter
refreshed counter
skipped counter
failed counter
checked = refreshed + skipped + failed
failed job preserves structured result
provider timeout
invalid provider response
normal manual Background Job execution
normal manual execution respects freshness
forced Background Job execution
forced execution selects force handler
unsupported force rejected
unsupported force does not persist Running state
forced Show refresh
forced Season refresh
forced Episode refresh
all local Seasons participate in deep refresh
previously missing Episode still can be refreshed
force does not replace normal scheduled execution
```

The backend repository states that tests cover metadata synchronization/background jobs and mock external provider calls where appropriate rather than depending on live TMDB responses.

---

# Future Provider Tests

TVDB/multi-provider work should add tests for:

```text
external-ID mapping
cross-provider matching
ambiguous match rejection
provider precedence
provider fallback
local override precedence
missing preferred-provider field
provider disagreement
provider unavailable
metadata language
```

---

# Integration Tests

High-value integration scenarios include:

```text
import Show
-> persist Seasons/Episodes
-> mark Episode watched
-> synchronize changed provider metadata
-> Watch Event remains intact
```

and:

```text
active Show
-> sync introduces new Episode
-> progress/Upcoming reflects new Episode
```

---

# Failure Tests

Explicitly verify:

```text
Show A succeeds
Show B fails
Show C succeeds
```

Expected:

```text
A committed
B rolled back
C committed

checked = 3
refreshed = 2
failed = 1
```

assuming all three required refresh and no skips.

---

# Edge Cases

## Provider Removes an Episode Temporarily

Local Episode remains.

## Provider Renames an Episode

Existing local Episode is updated while retaining its internal identity and Watch Events.

## New Episode Appears

It is created locally and becomes available to derived features.

## Show Becomes Ended

The refresh that discovers the new status succeeds; later automatic runs skip it.

## Ended Show Receives Provider Correction

Manual refresh can retrieve the correction.

## TMDB Is Down

Local metadata remains available; eligible synchronization attempts fail safely and can recover later.

## One Show Has Invalid Provider Data

Its transaction rolls back without discarding successful synchronization of other Shows.

## Worker Is Offline

Automatic synchronization does not occur until the Background Jobs worker resumes according to overdue-job policy.

## Manual and Automatic Refresh Coincide

Backend concurrency/idempotency must prevent duplicate/corrupt local entities.

## Provider Omits Local Season

Season is not automatically deleted.

## Local Artwork Override Exists

Provider refresh preserves the local-only path/override.


## Episode Artwork Was Missing During Import

The local Episode remains valid.

If the provider later supplies a still, forced Metadata Sync can refresh the Episode metadata and persist the newly available provider artwork path.

## Force Requested for Unsupported Job

The request is rejected rather than silently executing the normal handler.

The job must not be left in a Running state.

## Run Now vs Force Refresh

`Run now` uses normal synchronization semantics.

It must not unexpectedly behave as a forced deep refresh.


---

# Future Work

## TVDB

```text
[ ] TVDB provider client
[ ] TVDB provider schemas
[ ] external-ID persistence/mapping
[ ] Show matching
[ ] Season/Episode matching
[ ] provider health
[ ] provider tests
```

---

## Provider Strategy

```text
[ ] define provider precedence
[ ] define field ownership
[ ] define fallback rules
[ ] define conflict behavior
[ ] define local-override precedence
[ ] document empty/null provider semantics
```

---

## Movie Metadata

```text
[ ] decide whether Movies need scheduled refresh
[ ] define Movie refresh policy
[ ] define cadence
[ ] define terminal/stable Movie behavior
[ ] external ratings refresh if added
```

---

## Metadata Language

```text
[ ] metadata language preference
[ ] provider language propagation
[ ] localized field refresh behavior
[ ] language-change refresh strategy
```

---

## Administration UI

```text
[ ] last metadata-sync summary
[ ] execution history
[ ] checked/refreshed/skipped/failed presentation
[ ] safe failure detail
[x] manual job Run Now
[x] forced Metadata Sync action
[x] force-refresh explanation
[x] force-refresh confirmation
[ ] per-Show manual refresh UX audit
[ ] worker/provider health linkage
```

---

## Reliability

```text
[ ] concurrency audit
[ ] automatic/manual same-Show collision tests
[ ] provider timeout audit
[ ] rate-limit handling if required
[ ] bounded retry/backoff if required
[ ] SQLite contention tests
```

---

## Reconciliation

```text
[ ] evaluate provider-missing state if needed
[ ] avoid destructive deletion
[ ] preserve Watch Events
[ ] preserve Library state
[ ] preserve ratings
[ ] preserve local overrides
```

---

# Notes

> SofaWatch stores provider metadata locally; clients consume SofaWatch's backend rather than synchronizing directly with TMDB.

> TMDB is currently the primary metadata provider.

> TVDB is planned, but SofaWatch internal IDs remain canonical.

> Automatic metadata synchronization runs through the Background Jobs worker on an eight-hour schedule.

> The job schedule and the per-Show refresh policy are separate concepts.

> Ended and canceled Shows are evaluated but skipped automatically.

> Manual refresh bypasses automatic refresh eligibility, allowing ended/canceled Shows to be refreshed explicitly.

> Automatic synchronization records `checked`, `refreshed`, `skipped`, and `failed`.

> `checked = refreshed + skipped + failed`.

> Metadata refresh is transactional at Show level.

> One Show failure does not prevent the job from attempting remaining Shows.

> A run with one or more Show failures is currently marked failed, while its structured synchronization result is still preserved.

> Provider omissions do not automatically delete local Seasons or Episodes.

> Local-only media paths/overrides are preserved during refresh.

> Metadata synchronization must never overwrite user-owned viewing History, Library state, or personal ratings.

> Multi-provider synchronization requires explicit precedence and fallback rules before multiple providers write overlapping metadata.

> Manual `Run now` executes the normal Metadata Sync handler and continues to respect freshness rules.

> `Force refresh` is an explicit separate execution mode.

> Forced Metadata Sync deeply refreshes Show, Season, and Episode metadata.

> Episode deep refresh reuses the canonical Season/Episode synchronization service.

> Force can recover provider metadata that became available after the original import, including previously missing Episode still artwork.

> Forced execution bypasses refresh eligibility, not validation, transaction safety, or SofaWatch-owned-state protection.

> Background Jobs that do not support force reject forced execution explicitly.

---

# Related Documentation

- [Implementation Status](implementation-status.md)
- [Search](search.md)
- [Library](library.md)
- [Viewing Progress](viewing-progress.md)
- [Watch List](watch-list.md)
- [Upcoming](upcoming.md)
- [Show Details](show-details.md)
- [Movies](movies.md)
- [Home](home.md)
- [Background Jobs](background-jobs.md)
- [Server Administration](server-administration.md)
- [Import / Export](import-export.md)
- [Architecture Overview](../architecture/overview.md)
- [Backend Architecture](../architecture/backend.md)
- [Database Architecture](../architecture/database.md)
- [Background Jobs Architecture](../architecture/background-jobs.md)
- [Data Flow](../architecture/data-flow.md)
- [Frontend Contract](../api/frontend-contract.md)
- [API Errors](../api/errors.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)
- [ADR-003: Internal Media IDs](../decisions/003-internal-media-ids.md)
- [ADR-006: Provider Independence](../decisions/006-provider-independence.md)
