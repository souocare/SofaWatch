import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/search/data/cache/in_memory_search_cache.dart';
import 'package:sofawatch/features/search/data/cache/search_cache_key.dart';
import 'package:sofawatch/features/search/domain/models/search_media_type_filter.dart';
import 'package:sofawatch/features/search/domain/models/search_result_page.dart';

void main() {
  group('InMemorySearchCache', () {
    late DateTime now;

    setUp(() {
      now = DateTime.utc(2026, 8, 7, 12);
    });

    test('returns a cached value before its TTL expires', () {
      final InMemorySearchCache cache = InMemorySearchCache(
        ttl: const Duration(minutes: 5),
        clock: () => now,
      );

      const SearchCacheKey key = SearchCacheKey(
        term: 'severance',
        page: 1,
        mediaType: SearchMediaTypeFilter.all,
        language: null,
      );

      const SearchResultPage result = SearchResultPage(
        page: 1,
        results: [],
        totalPages: 1,
        totalResults: 0,
      );

      cache.put(key, result);

      expect(cache.get(key), result);
    });

    test('returns null when a cached value has expired', () {
      final InMemorySearchCache cache = InMemorySearchCache(
        ttl: const Duration(minutes: 5),
        clock: () => now,
      );

      const SearchCacheKey key = SearchCacheKey(
        term: 'severance',
        page: 1,
        mediaType: SearchMediaTypeFilter.all,
        language: null,
      );

      const SearchResultPage result = SearchResultPage(
        page: 1,
        results: [],
        totalPages: 1,
        totalResults: 0,
      );

      cache.put(key, result);

      now = now.add(const Duration(minutes: 5));

      expect(cache.get(key), isNull);
      expect(cache.length, 0);
    });

    test('clear removes all cached values', () {
      final InMemorySearchCache cache = InMemorySearchCache(clock: () => now);

      const SearchResultPage result = SearchResultPage(
        page: 1,
        results: [],
        totalPages: 1,
        totalResults: 0,
      );

      cache.put(
        const SearchCacheKey(
          term: 'severance',
          page: 1,
          mediaType: SearchMediaTypeFilter.all,
          language: null,
        ),
        result,
      );

      cache.put(
        const SearchCacheKey(
          term: 'silo',
          page: 1,
          mediaType: SearchMediaTypeFilter.all,
          language: null,
        ),
        result,
      );

      cache.clear();

      expect(cache.length, 0);
    });

    test('removeExpired removes only expired entries', () {
      final InMemorySearchCache cache = InMemorySearchCache(
        ttl: const Duration(minutes: 5),
        clock: () => now,
      );

      const SearchCacheKey firstKey = SearchCacheKey(
        term: 'severance',
        page: 1,
        mediaType: SearchMediaTypeFilter.all,
        language: null,
      );

      const SearchCacheKey secondKey = SearchCacheKey(
        term: 'silo',
        page: 1,
        mediaType: SearchMediaTypeFilter.all,
        language: null,
      );

      const SearchResultPage result = SearchResultPage(
        page: 1,
        results: [],
        totalPages: 1,
        totalResults: 0,
      );

      cache.put(firstKey, result);

      now = now.add(const Duration(minutes: 4));

      cache.put(secondKey, result);

      now = now.add(const Duration(minutes: 2));

      cache.removeExpired();

      expect(cache.get(firstKey), isNull);
      expect(cache.get(secondKey), result);
    });

    test('evicts the least recently used entry when full', () {
      final InMemorySearchCache cache = InMemorySearchCache(
        maxEntries: 2,
        clock: () => now,
      );

      const SearchCacheKey firstKey = SearchCacheKey(
        term: 'severance',
        page: 1,
        mediaType: SearchMediaTypeFilter.all,
        language: null,
      );

      const SearchCacheKey secondKey = SearchCacheKey(
        term: 'silo',
        page: 1,
        mediaType: SearchMediaTypeFilter.all,
        language: null,
      );

      const SearchCacheKey thirdKey = SearchCacheKey(
        term: 'foundation',
        page: 1,
        mediaType: SearchMediaTypeFilter.all,
        language: null,
      );

      const SearchResultPage result = SearchResultPage(
        page: 1,
        results: [],
        totalPages: 1,
        totalResults: 0,
      );

      cache.put(firstKey, result);
      cache.put(secondKey, result);

      expect(cache.get(firstKey), result);

      cache.put(thirdKey, result);

      expect(cache.get(firstKey), result);
      expect(cache.get(secondKey), isNull);
      expect(cache.get(thirdKey), result);
    });
  });
}
