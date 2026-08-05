import 'package:sofawatch/features/search/domain/models/search_query.dart';
import 'package:sofawatch/features/search/domain/models/search_result_page.dart';

abstract interface class SearchRepository {
  Future<SearchResultPage> search(SearchQuery query);
}
