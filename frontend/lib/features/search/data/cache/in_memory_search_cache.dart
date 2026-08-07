import 'dart:collection';

import 'package:sofawatch/features/search/data/cache/search_cache.dart';
import 'package:sofawatch/features/search/data/cache/search_cache_key.dart';
import 'package:sofawatch/features/search/domain/models/search_result_page.dart';

typedef SearchCacheClock = DateTime Function();

final class InMemorySearchCache implements SearchCache {
  InMemorySearchCache({
    this.ttl = const Duration(minutes: 5),
    this.maxEntries = 100,
    SearchCacheClock? clock,
  }) : _clock = clock ?? DateTime.now {
    if (ttl <= Duration.zero) {
      throw ArgumentError.value(ttl, 'ttl', 'TTL must be greater than zero.');
    }

    if (maxEntries <= 0) {
      throw ArgumentError.value(
        maxEntries,
        'maxEntries',
        'Maximum entries must be greater than zero.',
      );
    }
  }

  final Duration ttl;
  final int maxEntries;
  final SearchCacheClock _clock;

  final LinkedHashMap<SearchCacheKey, _SearchCacheEntry> _entries =
      LinkedHashMap<SearchCacheKey, _SearchCacheEntry>();

  @override
  int get length => _entries.length;

  @override
  SearchResultPage? get(SearchCacheKey key) {
    final _SearchCacheEntry? entry = _entries.remove(key);

    if (entry == null) {
      return null;
    }

    if (_isExpired(entry)) {
      return null;
    }

    _entries[key] = entry;

    return entry.value;
  }

  @override
  void put(SearchCacheKey key, SearchResultPage value) {
    removeExpired();

    _entries.remove(key);

    while (_entries.length >= maxEntries) {
      _entries.remove(_entries.keys.first);
    }

    _entries[key] = _SearchCacheEntry(
      value: value,
      expiresAt: _clock().add(ttl),
    );
  }

  @override
  void removeExpired() {
    final DateTime now = _clock();

    final List<SearchCacheKey> expiredKeys = _entries.entries
        .where(
          (MapEntry<SearchCacheKey, _SearchCacheEntry> entry) =>
              !now.isBefore(entry.value.expiresAt),
        )
        .map((MapEntry<SearchCacheKey, _SearchCacheEntry> entry) => entry.key)
        .toList(growable: false);

    for (final SearchCacheKey key in expiredKeys) {
      _entries.remove(key);
    }
  }

  @override
  void clear() {
    _entries.clear();
  }

  bool _isExpired(_SearchCacheEntry entry) {
    return !_clock().isBefore(entry.expiresAt);
  }
}

final class _SearchCacheEntry {
  const _SearchCacheEntry({required this.value, required this.expiresAt});

  final SearchResultPage value;
  final DateTime expiresAt;
}
