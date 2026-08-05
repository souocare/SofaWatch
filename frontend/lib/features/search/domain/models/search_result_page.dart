import 'package:equatable/equatable.dart';
import 'package:sofawatch/features/search/domain/entities/search_result.dart';

class SearchResultPage extends Equatable {
  const SearchResultPage({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  final int page;
  final List<SearchResult> results;
  final int totalPages;
  final int totalResults;

  bool get isEmpty {
    return results.isEmpty;
  }

  bool get isNotEmpty {
    return results.isNotEmpty;
  }

  bool get hasNextPage {
    return page < totalPages;
  }

  int? get nextPage {
    return hasNextPage ? page + 1 : null;
  }

  SearchResultPage append(SearchResultPage nextPageResult) {
    if (nextPageResult.page <= page) {
      return this;
    }

    return SearchResultPage(
      page: nextPageResult.page,
      results: List<SearchResult>.unmodifiable(<SearchResult>[
        ...results,
        ...nextPageResult.results,
      ]),
      totalPages: nextPageResult.totalPages,
      totalResults: nextPageResult.totalResults,
    );
  }

  @override
  List<Object?> get props => <Object?>[page, results, totalPages, totalResults];
}
