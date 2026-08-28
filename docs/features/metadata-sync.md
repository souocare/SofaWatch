# Metadata Synchronization

SofaWatch keeps locally stored TV metadata synchronized with TMDB.

## Imported metadata

Synchronization currently covers:

- TV series;
- genres;
- networks;
- seasons;
- episodes.

## Update strategy

Synchronization updates existing local entities and creates newly discovered entities.

Local-only media paths are preserved during metadata refreshes.

Seasons and episodes that disappear from a TMDB response are not automatically deleted from the local database.

SofaWatch supports two metadata synchronization strategies:

- normal synchronization, which respects the automatic refresh policy and metadata freshness;
- forced synchronization, which explicitly requests fresh metadata for locally stored shows, seasons, and episodes.

## Automatic synchronization

A background job checks locally stored series every eight hours.

Automatic synchronization follows the normal refresh policy.

Ended and canceled series are not refreshed automatically.

Recent metadata that does not yet require refreshing is also skipped.

### Synchronization outcomes

Each automatic synchronization records four counters:

- `checked` — all locally stored TV series evaluated by the job;
- `refreshed` — series whose metadata was actually refreshed;
- `skipped` — series that did not require an automatic refresh, including recent metadata and series excluded by the automatic refresh policy;
- `failed` — series whose synchronization raised an error.

The following invariant should hold:

```text
checked = refreshed + skipped + failed
```

Ended and canceled series are evaluated by the synchronization job but are skipped by the automatic refresh policy.

Execution metrics are returned by the job and persisted with the corresponding background job run.

## Manual synchronization

Metadata synchronization can also be started manually.

### Run now

Running the metadata synchronization background job manually without force uses the same normal synchronization strategy as the scheduled job.

The job therefore continues to respect metadata freshness and the normal automatic refresh policy.

This provides a way to execute the scheduled synchronization immediately without changing its refresh semantics.

### Force refresh

The metadata synchronization background job supports an explicit forced execution mode.

A force refresh ignores the normal metadata freshness rules and performs a deep refresh of locally stored TV metadata.

For each locally stored show, SofaWatch:

1. refreshes the show metadata from TMDB;
2. refreshes the locally known season metadata;
3. synchronizes every local season through the canonical season and episode synchronization service;
4. requests fresh episode metadata even when local episode data already exists.

This allows SofaWatch to recover metadata that became available after the original import or a previous synchronization, including previously missing episode artwork.

Forced synchronization may make significantly more requests to external metadata providers and may take longer than a normal synchronization.

The Profile background jobs interface therefore exposes force refresh as a separate action and requires explicit confirmation before starting it.

Background jobs that do not define a forced execution handler reject forced execution instead of silently falling back to their normal handler.

## Individual show refresh

A local TV series can also be manually refreshed through the API.

An explicit show refresh bypasses the automatic show refresh policy.

This allows ended or canceled series to be refreshed explicitly when needed.

Deep episode synchronization remains the responsibility of the canonical season and episode synchronization service rather than being duplicated inside the show import service.

## Failure handling

Metadata refreshes are transactional at show level where applicable.

A failed show synchronization is rolled back without preventing the background job from attempting the remaining shows.

If one or more shows fail, the overall background job run is marked as failed.

The structured synchronization result is still preserved for failed runs, allowing the execution history to report the work completed before the failure.

Forced synchronization additionally records deep-refresh metrics such as synchronized seasons and refreshed episodes.