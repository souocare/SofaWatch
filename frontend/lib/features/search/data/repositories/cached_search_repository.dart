import 'package:sofawatch/features/search/data/cache/search_cache.dart';
import 'package:sofawatch/features/search/data/cache/search_cache_key.dart';
import 'package:sofawatch/features/search/domain/models/search_query.dart';
import 'package:sofawatch/features/search/domain/models/search_result_page.dart';
import 'package:sofawatch/features/search/domain/repositories/search_repository.dart';

final class CachedSearchRepository implements SearchRepository {
  CachedSearchRepository({required this._repository, required this._cache});

  final SearchRepository _repository;
  final SearchCache _cache;

  final Map<SearchCacheKey, Future<SearchResultPage>> _inFlightRequests =
      <SearchCacheKey, Future<SearchResultPage>>{};

  @override
  Future<SearchResultPage> search(SearchQuery query) {
    final SearchCacheKey key = SearchCacheKey.fromQuery(query);

    final SearchResultPage? cachedResult = _cache.get(key);

    if (cachedResult != null) {
      return Future<SearchResultPage>.value(cachedResult);
    }

    final Future<SearchResultPage>? existingRequest = _inFlightRequests[key];

    if (existingRequest != null) {
      return existingRequest;
    }

    final Future<SearchResultPage> request = _searchAndCache(
      key: key,
      query: query,
    );

    _inFlightRequests[key] = request;

    return request.whenComplete(() {
      if (identical(_inFlightRequests[key], request)) {
        _inFlightRequests.remove(key);
      }
    });
  }

  void clearCache() {
    _cache.clear();
  }

  Future<SearchResultPage> _searchAndCache({
    required SearchCacheKey key,
    required SearchQuery query,
  }) async {
    final SearchResultPage result = await _repository.search(query);

    _cache.put(key, result);

    return result;
  }
}
