import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/core/state/remote_state.dart';
import 'package:sofawatch/features/search/domain/models/search_media_type_filter.dart';
import 'package:sofawatch/features/search/domain/models/search_result_page.dart';

class SearchState extends Equatable {
  const SearchState({
    this.query = '',
    this.mediaType = SearchMediaTypeFilter.all,
    this.results = const RemoteState<SearchResultPage>.initial(),
    this.isLoadingMore = false,
    this.paginationError,
  });

  static const int minimumQueryLength = 2;

  final String query;
  final SearchMediaTypeFilter mediaType;
  final RemoteState<SearchResultPage> results;
  final bool isLoadingMore;
  final AppException? paginationError;

  static String normalizeQuery(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String get normalizedQuery {
    return normalizeQuery(query);
  }

  bool get hasQuery {
    return normalizedQuery.isNotEmpty;
  }

  bool get hasSearchableQuery {
    return normalizedQuery.length >= minimumQueryLength;
  }

  bool get needsMoreCharacters {
    return hasQuery && !hasSearchableQuery;
  }

  int get remainingCharacters {
    if (!needsMoreCharacters) {
      return 0;
    }

    return minimumQueryLength - normalizedQuery.length;
  }

  bool get hasResults {
    return results.data?.results.isNotEmpty == true;
  }

  bool get hasNoResults {
    return results.isSuccess && results.data?.results.isEmpty == true;
  }

  bool get canLoadMore {
    return hasSearchableQuery &&
        !isLoadingMore &&
        results.data?.hasNextPage == true;
  }

  bool get hasPaginationError {
    return paginationError != null;
  }

  SearchState copyWith({
    String? query,
    SearchMediaTypeFilter? mediaType,
    RemoteState<SearchResultPage>? results,
    bool? isLoadingMore,
    AppException? paginationError,
    bool clearPaginationError = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      mediaType: mediaType ?? this.mediaType,
      results: results ?? this.results,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      paginationError: clearPaginationError
          ? null
          : paginationError ?? this.paginationError,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    query,
    mediaType,
    results,
    isLoadingMore,
    paginationError,
  ];
}
