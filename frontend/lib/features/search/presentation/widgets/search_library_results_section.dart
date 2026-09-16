import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/application/cubit/library_cubit.dart';
import 'package:sofawatch/features/library/application/cubit/library_item_operation.dart';
import 'package:sofawatch/features/library/application/cubit/library_state.dart';
import 'package:sofawatch/features/library/domain/models/library_media_key.dart';
import 'package:sofawatch/features/library/domain/models/library_media_type.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/library/presentation/mappers/library_failure_message_mapper.dart';
import 'package:sofawatch/features/search/domain/entities/search_result.dart';
import 'package:sofawatch/features/search/presentation/widgets/search_results_section.dart';

class SearchLibraryResultsSection extends StatefulWidget {
  const SearchLibraryResultsSection({
    required this.results,
    required this.onResultPressed,
    required this.scrollable,
    this.compact = false,
    this.onLoadMore,
    this.isLoadingMore = false,
    this.paginationError,
    this.onPaginationRetry,
    super.key,
  });

  final List<SearchResult> results;
  final ValueChanged<SearchResult> onResultPressed;

  final bool scrollable;
  final bool compact;

  final VoidCallback? onLoadMore;
  final bool isLoadingMore;

  final AppException? paginationError;
  final VoidCallback? onPaginationRetry;

  @override
  State<SearchLibraryResultsSection> createState() {
    return _SearchLibraryResultsSectionState();
  }
}

class _SearchLibraryResultsSectionState
    extends State<SearchLibraryResultsSection> {
  final Set<LibraryMediaKey> _notifiedFailures = <LibraryMediaKey>{};
  final Set<LibraryMediaKey> _markingWatched = <LibraryMediaKey>{};

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LibraryCubit, LibraryState>(
      listener: _handleLibraryState,
      builder: (BuildContext context, LibraryState libraryState) {
        return SearchResultsSection(
          results: widget.results,
          onResultPressed: widget.onResultPressed,
          scrollable: widget.scrollable,
          compact: widget.compact,
          onLoadMore: widget.onLoadMore,
          isLoadingMore: widget.isLoadingMore,
          paginationError: widget.paginationError,
          onPaginationRetry: widget.onPaginationRetry,
          onResultActionPressed: (SearchResult result) {
            context.read<LibraryCubit>().addToLibrary(_keyFor(result));
          },
          onResultWatchedPressed: (SearchResult result) {
            _markMovieWatched(context, result);
          },
          isActionAvailable: (SearchResult result) {
            final LibraryMediaKey key = _keyFor(result);
            final LibraryItemOperation operation = _operationFor(
              libraryState,
              result,
            );

            return !_markingWatched.contains(key) &&
                !operation.isRemoving &&
                !operation.isUpdating;
          },
          isActionLoading: (SearchResult result) {
            final LibraryMediaKey key = _keyFor(result);

            return _operationFor(libraryState, result).isAdding &&
                !_markingWatched.contains(key);
          },
          isActionAdded: (SearchResult result) {
            final LibraryItemOperation operation = _operationFor(
              libraryState,
              result,
            );

            if (result.isMovie && _isMovieWatched(libraryState, result)) {
              return true;
            }

            if (operation.entry != null || operation.isAdded) {
              return true;
            }

            return result.inLibrary;
          },
          isWatchedActionAvailable: (SearchResult result) {
            if (!result.isMovie) {
              return false;
            }

            final LibraryMediaKey key = _keyFor(result);
            final LibraryItemOperation operation = _operationFor(
              libraryState,
              result,
            );

            return !_markingWatched.contains(key) &&
                !operation.isAdding &&
                !operation.isRemoving &&
                !operation.isUpdating &&
                !_isMovieWatched(libraryState, result);
          },
          isWatchedActionLoading: (SearchResult result) {
            return _markingWatched.contains(_keyFor(result));
          },
          isWatched: (SearchResult result) {
            return _isMovieWatched(libraryState, result);
          },
        );
      },
    );
  }

  Future<void> _markMovieWatched(
    BuildContext context,
    SearchResult result,
  ) async {
    if (!result.isMovie) {
      return;
    }

    final LibraryMediaKey key = _keyFor(result);

    if (_markingWatched.contains(key)) {
      return;
    }

    setState(() {
      _markingWatched.add(key);
    });

    try {
      await context.read<LibraryCubit>().markMovieWatched(key);
    } finally {
      if (mounted) {
        setState(() {
          _markingWatched.remove(key);
        });
      }
    }
  }

  bool _isMovieWatched(LibraryState state, SearchResult result) {
    if (!result.isMovie) {
      return false;
    }

    final LibraryItemOperation operation = _operationFor(state, result);

    final LibraryStatus? currentStatus = operation.entry?.status;

    if (currentStatus != null) {
      return currentStatus == LibraryStatus.completed;
    }

    return result.isWatchedMovie;
  }

  void _handleLibraryState(BuildContext context, LibraryState state) {
    for (final MapEntry<LibraryMediaKey, LibraryItemOperation> entry
        in state.operations.entries) {
      final LibraryMediaKey key = entry.key;
      final LibraryItemOperation operation = entry.value;

      if (!operation.hasFailed) {
        _notifiedFailures.remove(key);
        continue;
      }

      if (!_notifiedFailures.add(key)) {
        continue;
      }

      final AppException? error = operation.error;

      if (error == null) {
        continue;
      }

      _showFailure(context, key: key, error: error);
    }
  }

  void _showFailure(
    BuildContext context, {
    required LibraryMediaKey key,
    required AppException error,
  }) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      SnackBar(
        key: ValueKey<String>(
          'library-operation-failure-'
          '${key.mediaType.name}-${key.tmdbId}',
        ),
        content: Text(
          LibraryFailureMessageMapper.messageFor(
            error,
            mediaType: key.mediaType,
          ),
        ),
        action: error.canRetry
            ? SnackBarAction(
                label: 'Retry',
                onPressed: () {
                  context.read<LibraryCubit>().retry(key);
                },
              )
            : null,
      ),
    );
  }

  LibraryItemOperation _operationFor(LibraryState state, SearchResult result) {
    return state.operationFor(_keyFor(result));
  }

  LibraryMediaKey _keyFor(SearchResult result) {
    return LibraryMediaKey(
      mediaType: result.isShow ? LibraryMediaType.show : LibraryMediaType.movie,
      tmdbId: result.tmdbId,
    );
  }
}
