import 'package:bloc/bloc.dart';
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
    on<SearchQueryChanged>(_onQueryChanged);
    on<SearchMediaTypeChanged>(_onMediaTypeChanged);
    on<SearchSubmitted>(_onSubmitted);
    on<SearchNextPageRequested>(_onNextPageRequested);
    on<SearchRetryRequested>(_onRetryRequested);
    on<SearchCleared>(_onCleared);
  }

  final SearchRepository _searchRepository;

  /// Identifies the most recent first-page request.
  ///
  /// If an older request finishes after a newer one, its result is ignored.
  int _searchGeneration = 0;

  void _onQueryChanged(SearchQueryChanged event, Emitter<SearchState> emit) {
    final String query = event.query;

    if (query.trim().isEmpty) {
      _searchGeneration++;

      emit(SearchState(query: query, mediaType: state.mediaType));

      return;
    }

    emit(state.copyWith(query: query, clearPaginationError: true));
  }

  Future<void> _onMediaTypeChanged(
    SearchMediaTypeChanged event,
    Emitter<SearchState> emit,
  ) async {
    if (event.mediaType == state.mediaType) {
      return;
    }

    emit(
      state.copyWith(mediaType: event.mediaType, clearPaginationError: true),
    );

    if (!state.hasQuery) {
      return;
    }

    await _searchFirstPage(emit);
  }

  Future<void> _onSubmitted(
    SearchSubmitted event,
    Emitter<SearchState> emit,
  ) async {
    if (!state.hasQuery) {
      _searchGeneration++;

      emit(SearchState(query: state.query, mediaType: state.mediaType));

      return;
    }

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
    if (!state.hasQuery) {
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

    if (normalizedQuery.isEmpty) {
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

    if (!state.hasQuery ||
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
}
