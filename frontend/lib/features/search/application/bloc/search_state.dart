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

  final String query;
  final SearchMediaTypeFilter mediaType;

  final RemoteState<SearchResultPage> results;

  final bool isLoadingMore;
  final AppException? paginationError;

  String get normalizedQuery {
    return query.trim();
  }

  bool get hasQuery {
    return normalizedQuery.isNotEmpty;
  }

  bool get hasResults {
    return results.data?.results.isNotEmpty == true;
  }

  bool get hasNoResults {
    return results.isSuccess && results.data?.results.isEmpty == true;
  }

  bool get canLoadMore {
    return !isLoadingMore && results.data?.hasNextPage == true;
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
