import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/app/theme/tokens/app_colors.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/application/cubit/library_cubit.dart';
import 'package:sofawatch/features/library/application/cubit/library_item_operation.dart';
import 'package:sofawatch/features/library/application/cubit/library_state.dart';
import 'package:sofawatch/features/library/domain/models/library_entry.dart';
import 'package:sofawatch/features/library/domain/models/library_media_key.dart';
import 'package:sofawatch/features/library/domain/models/library_media_type.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/library/presentation/mappers/library_failure_message_mapper.dart';

class MovieDetailsLibraryAction extends StatefulWidget {
  const MovieDetailsLibraryAction({
    required this.tmdbId,
    this.movieId,
    this.isUpcoming = false,
    super.key,
  });

  final int tmdbId;
  final String? movieId;
  final bool isUpcoming;

  @override
  State<MovieDetailsLibraryAction> createState() {
    return _MovieDetailsLibraryActionState();
  }
}

class _MovieDetailsLibraryActionState extends State<MovieDetailsLibraryAction> {
  bool _failureNotified = false;

  LibraryMediaKey get _key {
    return LibraryMediaKey(
      mediaType: LibraryMediaType.movie,
      tmdbId: widget.tmdbId,
    );
  }

  @override
  void initState() {
    super.initState();

    final String? movieId = widget.movieId;

    if (movieId != null) {
      context.read<LibraryCubit>().loadLocalMovieState(
        key: _key,
        movieId: movieId,
      );
    }
  }

  @override
  void didUpdateWidget(covariant MovieDetailsLibraryAction oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.movieId == widget.movieId &&
        oldWidget.tmdbId == widget.tmdbId) {
      return;
    }

    _failureNotified = false;

    final String? movieId = widget.movieId;

    if (movieId != null) {
      context.read<LibraryCubit>().loadLocalMovieState(
        key: _key,
        movieId: movieId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LibraryCubit, LibraryState>(
      listenWhen: (LibraryState previous, LibraryState current) {
        return previous.operationFor(_key) != current.operationFor(_key);
      },
      listener: _handleLibraryState,
      builder: (BuildContext context, LibraryState state) {
        final LibraryItemOperation operation = state.operationFor(_key);

        if (operation.isAdding) {
          return const _LoadingAction(
            key: ValueKey<String>('movie-details-library-adding'),
            label: 'Adding…',
          );
        }

        if (operation.isRemoving) {
          return const _LoadingAction(
            key: ValueKey<String>('movie-details-library-removing'),
            label: 'Removing…',
          );
        }

        final LibraryEntry? entry = operation.entry;

        /*
         * A failed remove/status update deliberately preserves the entry.
         * The Movie must therefore continue to appear as being in the
         * Watchlist while Retry is offered through the SnackBar.
         */
        if (entry != null) {
          return _MovieLibraryActions(
            entry: entry,
            isUpdating: operation.isUpdating,
            targetStatus: operation.targetStatus,
            isUpcoming: widget.isUpcoming,
            onRemove: () {
              context.read<LibraryCubit>().removeFromLibrary(_key);
            },
            onMarkWatched: () {
              context.read<LibraryCubit>().markMovieWatched(_key);
            },
            onMarkUnwatched: () {
              context.read<LibraryCubit>().markMovieUnwatched(_key);
            },
          );
        }

        return FilledButton.icon(
          key: const ValueKey<String>('movie-details-library-add'),
          onPressed: () {
            context.read<LibraryCubit>().addToLibrary(_key);
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add to Watchlist'),
        );
      },
    );
  }

  void _handleLibraryState(BuildContext context, LibraryState state) {
    final LibraryItemOperation operation = state.operationFor(_key);

    if (!operation.hasFailed) {
      _failureNotified = false;
      return;
    }

    if (_failureNotified) {
      return;
    }

    final AppException? error = operation.error;

    if (error == null) {
      return;
    }

    _failureNotified = true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const ValueKey<String>('movie-details-library-failure'),
        content: Text(
          LibraryFailureMessageMapper.messageFor(
            error,
            mediaType: LibraryMediaType.movie,
          ),
        ),
        action: error.canRetry
            ? SnackBarAction(
                label: 'Retry',
                onPressed: () {
                  final LibraryCubit cubit = context.read<LibraryCubit>();

                  if (operation.isStatusUpdateFailure) {
                    cubit.retryMovieStatus(_key);
                    return;
                  }

                  if (operation.entry != null) {
                    cubit.retryRemove(_key);
                    return;
                  }

                  cubit.retry(_key);
                },
              )
            : null,
      ),
    );
  }
}

class _MovieLibraryActions extends StatelessWidget {
  const _MovieLibraryActions({
    required this.entry,
    required this.isUpdating,
    required this.targetStatus,
    required this.onRemove,
    required this.onMarkWatched,
    required this.onMarkUnwatched,
    required this.isUpcoming,
  });

  final LibraryEntry entry;
  final bool isUpdating;
  final LibraryStatus? targetStatus;
  final bool isUpcoming;

  final VoidCallback onRemove;
  final VoidCallback onMarkWatched;
  final VoidCallback onMarkUnwatched;

  @override
  Widget build(BuildContext context) {
    final bool isWatched = entry.status == LibraryStatus.completed;

    return Column(
      key: const ValueKey<String>('movie-details-library-actions'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            FilledButton.tonalIcon(
              key: const ValueKey<String>('movie-details-library-added'),
              onPressed: isUpdating ? null : onRemove,
              icon: const Icon(Icons.check_rounded),
              label: const Text('In Watchlist'),
            ),

            if (isUpdating)
              FilledButton.tonalIcon(
                key: const ValueKey<String>('movie-details-library-updating'),
                onPressed: null,
                icon: const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                label: Text(
                  targetStatus == LibraryStatus.completed
                      ? 'Marking as watched…'
                      : 'Marking as unwatched…',
                ),
              )
            else if (isWatched)
              FilledButton.tonalIcon(
                key: const ValueKey<String>('movie-details-mark-unwatched'),
                onPressed: onMarkUnwatched,
                icon: const Icon(Icons.visibility_off_outlined),
                label: const Text('Mark as unwatched'),
              )
            else if (!isUpcoming)
              FilledButton.icon(
                key: const ValueKey<String>('movie-details-mark-watched'),
                onPressed: onMarkWatched,
                icon: const Icon(Icons.visibility_rounded),
                label: const Text('Mark as watched'),
              ),
          ],
        ),

        if (isWatched && entry.completedAt != null) ...<Widget>[
          const SizedBox(height: 12),
          _WatchedDate(completedAt: entry.completedAt!),
        ],
      ],
    );
  }
}

class _LoadingAction extends StatelessWidget {
  const _LoadingAction({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: null,
      icon: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      label: Text(label),
    );
  }
}

class _WatchedDate extends StatelessWidget {
  const _WatchedDate({required this.completedAt});

  final DateTime completedAt;

  @override
  Widget build(BuildContext context) {
    final String formattedDate = MaterialLocalizations.of(
      context,
    ).formatMediumDate(completedAt.toLocal());

    return Row(
      key: const ValueKey<String>('movie-details-watched-date'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(
          Icons.check_circle_rounded,
          size: 18,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'Watched $formattedDate',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
