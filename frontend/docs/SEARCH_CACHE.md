# Search Cache

SofaWatch uses a bounded in-memory cache for search result pages.

## Purpose

The cache avoids short-term duplicate search requests while keeping the
implementation deliberately small and replaceable.

Search caching is independent from Flutter's image cache.

## Strategy

Cache entries are identified by:

- normalized search term
- media type filter
- language
- page

Results are cached per page instead of caching the aggregated result built by
the SearchBloc.

## Defaults

- TTL: 5 minutes
- Maximum entries: 100
- Eviction strategy: Least Recently Used (LRU)
- Storage: memory only
- Failed requests are not cached
- Concurrent identical requests are deduplicated

A cache hit updates the LRU position of an entry but does not extend its TTL.

## Scope

The cache is intentionally non-persistent.

It does not currently implement:

- disk persistence
- background refresh
- stale-while-revalidate
- prefetching
- cache analytics
- adaptive TTL
- provider-specific caching

These optimizations should only be introduced when real usage data shows a
clear benefit.

## Future review

The current TTL and maximum size are conservative defaults.

Once SofaWatch has enough real-world usage, search request patterns should be
measured and these values reviewed.

The cache should also be cleared whenever the active SofaWatch server changes,
so search results from one server are never reused after switching to another.