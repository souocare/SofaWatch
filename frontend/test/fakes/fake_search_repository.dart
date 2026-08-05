import 'package:sofawatch/features/search/domain/models/search_query.dart';
import 'package:sofawatch/features/search/domain/models/search_result_page.dart';
import 'package:sofawatch/features/search/domain/repositories/search_repository.dart';

final class FakeSearchRepository implements SearchRepository {
  FakeSearchRepository({SearchResultPage? result, Object? error})
    : _result = result ?? _emptyResult,
      _error = error;

  static const SearchResultPage _emptyResult = SearchResultPage(
    page: 1,
    results: [],
    totalPages: 0,
    totalResults: 0,
  );

  SearchResultPage _result;
  Object? _error;

  SearchQuery? lastQuery;
  int searchCallCount = 0;

  void setResult(SearchResultPage result) {
    _result = result;
    _error = null;
  }

  void setError(Object error) {
    _error = error;
  }

  @override
  Future<SearchResultPage> search(SearchQuery query) async {
    searchCallCount++;
    lastQuery = query;

    final Object? error = _error;

    if (error != null) {
      throw error;
    }

    return _result;
  }
}
