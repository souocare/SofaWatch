import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/history/application/cubit/history_state.dart';
import 'package:sofawatch/features/history/domain/models/history_item.dart';
import 'package:sofawatch/features/history/domain/models/history_page.dart';
import 'package:sofawatch/features/history/domain/repositories/history_repository.dart';

final class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit({required this._repository}) : super(const HistoryState());

  final HistoryRepository _repository;

  static const int _pageSize = 30;

  Future<void> load() async {
    if (state.isLoading) {
      return;
    }

    /*
     * Initial/reload is authoritative.
     *
     * Unlike cursor pagination, it replaces the existing timeline with
     * the newest server-owned History page.
     */
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearPaginationError: true,
      ),
    );

    try {
      final HistoryPage page = await _repository.getHistory(limit: _pageSize);

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          items: page.items,
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          hasMore: page.hasMore,
          hasLoaded: true,
          isLoading: false,
          clearError: true,
          clearPaginationError: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(state.copyWith(isLoading: false, error: error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          isLoading: false,
          error: AppException.unknown(originalError: error),
        ),
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.canLoadMore) {
      return;
    }

    final String cursor = state.nextCursor!;

    emit(state.copyWith(isLoadingMore: true, clearPaginationError: true));

    try {
      final HistoryPage page = await _repository.getHistory(
        limit: _pageSize,
        cursor: cursor,
      );

      if (isClosed) {
        return;
      }

      /*
       * History events have stable event IDs.
       *
       * Cursor pagination should not overlap, but defensive de-duplication
       * protects the UI from accidental duplicate events without attempting
       * to reproduce the backend's ordering rules.
       */
      final Set<String> existingEventIds = state.items
          .map((HistoryItem item) => item.eventId)
          .toSet();

      final List<HistoryItem> newItems = page.items
          .where((HistoryItem item) => !existingEventIds.contains(item.eventId))
          .toList(growable: false);

      emit(
        state.copyWith(
          items: <HistoryItem>[...state.items, ...newItems],
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          hasMore: page.hasMore,
          isLoadingMore: false,
          clearPaginationError: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(state.copyWith(isLoadingMore: false, paginationError: error));
    } on Object catch (error) {
      if (isClosed) {
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

  Future<void> retry() {
    return load();
  }

  Future<void> retryLoadMore() {
    return loadMore();
  }
}
