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

## Manual synchronization

A local TV series can be manually refreshed through the API.

Manual refreshes bypass the automatic refresh policy.

This allows ended or canceled series to be refreshed explicitly when needed.

## Failure handling

Metadata refreshes are transactional at show level.

A failed show synchronization is rolled back without preventing the background job from attempting the remaining shows.