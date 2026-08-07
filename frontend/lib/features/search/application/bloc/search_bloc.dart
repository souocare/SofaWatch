import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/core/state/remote_state.dart';
import 'package:sofawatch/features/search/application/bloc/search_event.dart';
import 'package:sofawatch/features/search/application/bloc/search_state.dart';
import 'package:sofawatch/features/search/domain/models/search_media_type_filter.dart';
import 'package:sofawatch/features/search/domain/models/search_query.dart';
import 'package:sofawatch/features/search/domain/models/search_result_page.dart';
import 'package:sofawatch/features/search/domain/repositories/search_repository.dart';

final class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc(this._searchRepository) : super(const SearchState()) {
    on<SearchQueryChanged>(_onQueryChanged, transformer: restartable());

    on<SearchMediaTypeChanged>(_onMediaTypeChanged);
    on<SearchSubmitted>(_onSubmitted);
    on<SearchNextPageRequested>(_onNextPageRequested);
    on<SearchRetryRequested>(_onRetryRequested);
    on<SearchCleared>(_onCleared);
  }

  static const Duration queryDebounceDuration = Duration(milliseconds: 350);

  final SearchRepository _searchRepository;

  /// Identifies the currently valid search request.
  ///
  /// Whenever the query changes, the filter changes, Search is cleared or the
  /// BLoC is closed, the generation is incremented. Responses belonging to an
  /// older generation are ignored.
  int _searchGeneration = 0;

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    final String normalizedQuery = SearchState.normalizeQuery(event.query);

    // Immediately invalidates any request using the previous query.
    _searchGeneration++;

    if (normalizedQuery.isEmpty) {
      emit(SearchState(query: event.query, mediaType: state.mediaType));

      return;
    }

    if (normalizedQuery.length < SearchState.minimumQueryLength) {
      emit(SearchState(query: event.query, mediaType: state.mediaType));

      return;
    }

    // Keep the field/state synchronized immediately, before the debounce.
    emit(
      state.copyWith(
        query: event.query,
        isLoadingMore: false,
        clearPaginationError: true,
      ),
    );

    await Future<void>.delayed(queryDebounceDuration);

    if (emit.isDone) {
      return;
    }

    // A different event may have changed the current query during the delay.
    if (state.normalizedQuery != normalizedQuery) {
      return;
    }

    await _searchFirstPage(emit);
  }

  Future<void> _onMediaTypeChanged(
    SearchMediaTypeChanged event,
    Emitter<SearchState> emit,
  ) async {
    if (event.mediaType == state.mediaType) {
      return;
    }

    // Invalidates any request made with the previous filter.
    _searchGeneration++;

    emit(
      state.copyWith(
        mediaType: event.mediaType,
        isLoadingMore: false,
        clearPaginationError: true,
      ),
    );

    if (!state.hasSearchableQuery) {
      return;
    }

    await _searchFirstPage(emit);
  }

  Future<void> _onSubmitted(
    SearchSubmitted event,
    Emitter<SearchState> emit,
  ) async {
    if (!state.hasSearchableQuery) {
      _searchGeneration++;

      emit(SearchState(query: state.query, mediaType: state.mediaType));

      return;
    }

    // Submit is explicit and therefore bypasses the debounce.
    await _searchFirstPage(emit);
  }

  Future<void> _onNextPageRequested(
    SearchNextPageRequested event,
    Emitter<SearchState> emit,
  ) async {
    await _loadNextPage(emit);
  }

  Future<void> _onRetryRequested(
    SearchRetryRequested event,
    Emitter<SearchState> emit,
  ) async {
    if (!state.hasSearchableQuery) {
      return;
    }

    if (state.paginationError != null &&
        state.results.data?.hasNextPage == true) {
      await _loadNextPage(emit);

      return;
    }

    await _searchFirstPage(emit);
  }

  void _onCleared(SearchCleared event, Emitter<SearchState> emit) {
    _searchGeneration++;

    emit(const SearchState());
  }

  Future<void> _searchFirstPage(Emitter<SearchState> emit) async {
    final String normalizedQuery = state.normalizedQuery;

    if (normalizedQuery.length < SearchState.minimumQueryLength) {
      return;
    }

    final int generation = ++_searchGeneration;
    final SearchMediaTypeFilter mediaType = state.mediaType;

    emit(
      state.copyWith(
        results: const RemoteState<SearchResultPage>.loading(),
        isLoadingMore: false,
        clearPaginationError: true,
      ),
    );

    try {
      final SearchResultPage resultPage = await _searchRepository.search(
        SearchQuery(term: normalizedQuery, mediaType: mediaType),
      );

      if (emit.isDone || generation != _searchGeneration) {
        return;
      }

      emit(
        state.copyWith(
          results: RemoteState<SearchResultPage>.success(resultPage),
          isLoadingMore: false,
          clearPaginationError: true,
        ),
      );
    } on AppException catch (exception) {
      if (emit.isDone || generation != _searchGeneration) {
        return;
      }

      emit(
        state.copyWith(
          results: RemoteState<SearchResultPage>.failure(exception),
          isLoadingMore: false,
          clearPaginationError: true,
        ),
      );
    } on Object catch (error) {
      if (emit.isDone || generation != _searchGeneration) {
        return;
      }

      emit(
        state.copyWith(
          results: RemoteState<SearchResultPage>.failure(
            AppException.unknown(originalError: error),
          ),
          isLoadingMore: false,
          clearPaginationError: true,
        ),
      );
    }
  }

  Future<void> _loadNextPage(Emitter<SearchState> emit) async {
    final SearchResultPage? currentPage = state.results.data;

    if (!state.hasSearchableQuery ||
        state.isLoadingMore ||
        currentPage == null ||
        !currentPage.hasNextPage) {
      return;
    }

    final int? nextPage = currentPage.nextPage;

    if (nextPage == null) {
      return;
    }

    final int generation = _searchGeneration;
    final String normalizedQuery = state.normalizedQuery;
    final SearchMediaTypeFilter mediaType = state.mediaType;

    emit(state.copyWith(isLoadingMore: true, clearPaginationError: true));

    try {
      final SearchResultPage nextResultPage = await _searchRepository.search(
        SearchQuery(
          term: normalizedQuery,
          page: nextPage,
          mediaType: mediaType,
        ),
      );

      if (emit.isDone || generation != _searchGeneration) {
        return;
      }

      final SearchResultPage combinedPage = currentPage.append(nextResultPage);

      emit(
        state.copyWith(
          results: RemoteState<SearchResultPage>.success(combinedPage),
          isLoadingMore: false,
          clearPaginationError: true,
        ),
      );
    } on AppException catch (exception) {
      if (emit.isDone || generation != _searchGeneration) {
        return;
      }

      emit(state.copyWith(isLoadingMore: false, paginationError: exception));
    } on Object catch (error) {
      if (emit.isDone || generation != _searchGeneration) {
        return;
      }

      emit(
        state.copyWith(
          isLoadingMore: false,
          paginationError: AppException.unknown(originalError: error),
        ),
      );
    }
  }

  @override
  Future<void> close() {
    // Invalidates any repository response that completes after disposal.
    _searchGeneration++;

    return super.close();
  }
}
