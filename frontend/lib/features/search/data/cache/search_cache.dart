import 'package:sofawatch/features/search/data/cache/search_cache_key.dart';
import 'package:sofawatch/features/search/domain/models/search_result_page.dart';

abstract interface class SearchCache {
  SearchResultPage? get(SearchCacheKey key);

  void put(SearchCacheKey key, SearchResultPage value);

  void removeExpired();

  void clear();

  int get length;
}
