import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/history/domain/models/history_item.dart';

final class HistoryState extends Equatable {
  const HistoryState({
    this.items = const <HistoryItem>[],
    this.nextCursor,
    this.hasMore = false,
    this.hasLoaded = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.paginationError,
  });

  final List<HistoryItem> items;

  final String? nextCursor;

  final bool hasMore;

  /// Whether the first History request has successfully completed.
  final bool hasLoaded;

  /// Initial/reload operation.
  final bool isLoading;

  /// Cursor pagination operation.
  final bool isLoadingMore;

  /// Fatal initial loading failure.
  final AppException? error;

  /// Non-fatal pagination failure.
  ///
  /// Existing History remains visible.
  final AppException? paginationError;

  bool get isEmpty {
    return hasLoaded && items.isEmpty;
  }

  bool get canLoadMore {
    return hasLoaded &&
        hasMore &&
        nextCursor != null &&
        !isLoading &&
        !isLoadingMore;
  }

  HistoryState copyWith({
    List<HistoryItem>? items,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? hasMore,
    bool? hasLoaded,
    bool? isLoading,
    bool? isLoadingMore,
    AppException? error,
    bool clearError = false,
    AppException? paginationError,
    bool clearPaginationError = false,
  }) {
    return HistoryState(
      items: items ?? this.items,
      nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      paginationError: clearPaginationError
          ? null
          : paginationError ?? this.paginationError,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    items,
    nextCursor,
    hasMore,
    hasLoaded,
    isLoading,
    isLoadingMore,
    error,
    paginationError,
  ];
}
