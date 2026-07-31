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

## Automatic synchronization

A background job checks locally stored series every eight hours.

Automatic synchronization follows the normal refresh policy.

Ended and canceled series are not refreshed automatically.

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

A local TV series can be manually refreshed through the API.

Manual refreshes bypass the automatic refresh policy.

This allows ended or canceled series to be refreshed explicitly when needed.

## Failure handling

Metadata refreshes are transactional at show level.

A failed show synchronization is rolled back without preventing the background job from attempting the remaining shows.

If one or more shows fail, the overall background job run is marked as failed.

The structured synchronization result is still preserved for failed runs, so the execution history can report how many shows were checked, refreshed, skipped, and failed before completion.