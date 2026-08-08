import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/application/cubit/library_cubit.dart';
import 'package:sofawatch/features/library/application/cubit/library_item_operation.dart';
import 'package:sofawatch/features/library/application/cubit/library_state.dart';
import 'package:sofawatch/features/library/domain/models/library_media_key.dart';
import 'package:sofawatch/features/library/domain/models/library_media_type.dart';
import 'package:sofawatch/features/search/domain/entities/search_result.dart';
import 'package:sofawatch/features/search/presentation/widgets/search_results_section.dart';

class SearchLibraryResultsSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (BuildContext context, LibraryState libraryState) {
        return SearchResultsSection(
          results: results,
          onResultPressed: onResultPressed,
          scrollable: scrollable,
          compact: compact,
          onLoadMore: onLoadMore,
          isLoadingMore: isLoadingMore,
          paginationError: paginationError,
          onPaginationRetry: onPaginationRetry,
          onResultActionPressed: (SearchResult result) {
            context.read<LibraryCubit>().addToLibrary(_keyFor(result));
          },
          isActionAvailable: (SearchResult result) {
            return result.isShow;
          },
          isActionLoading: (SearchResult result) {
            if (!result.isShow) {
              return false;
            }

            return _operationFor(libraryState, result).isAdding;
          },
          isActionAdded: (SearchResult result) {
            if (!result.isShow) {
              return false;
            }

            if (result.inLibrary) {
              return true;
            }

            return _operationFor(libraryState, result).isAdded;
          },
        );
      },
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
