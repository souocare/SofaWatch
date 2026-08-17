import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/application/cubit/library_cubit.dart';
import 'package:sofawatch/features/library/application/cubit/library_item_operation.dart';
import 'package:sofawatch/features/library/application/cubit/library_state.dart';
import 'package:sofawatch/features/library/domain/models/library_entry.dart';
import 'package:sofawatch/features/library/domain/models/library_media_key.dart';
import 'package:sofawatch/features/library/domain/models/library_media_type.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/library/presentation/mappers/library_failure_message_mapper.dart';

class ShowDetailsLibraryAction extends StatefulWidget {
  const ShowDetailsLibraryAction({required this.tmdbId, super.key});

  final int tmdbId;

  @override
  State<ShowDetailsLibraryAction> createState() {
    return _ShowDetailsLibraryActionState();
  }
}

class _ShowDetailsLibraryActionState extends State<ShowDetailsLibraryAction> {
  bool _failureNotified = false;

  LibraryMediaKey get _key {
    return LibraryMediaKey(
      mediaType: LibraryMediaType.show,
      tmdbId: widget.tmdbId,
    );
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
            key: ValueKey<String>('show-details-library-adding'),
            label: 'Adding…',
          );
        }

        if (operation.isRemoving) {
          return const _LoadingAction(
            key: ValueKey<String>('show-details-library-removing'),
            label: 'Removing…',
          );
        }

        /*
         * Removal failures preserve the LibraryEntry so the UI continues
         * to reflect that the Show is still in the user's Library.
         */
        final LibraryEntry? entry = operation.entry;

        if (entry != null) {
          return _ShowLibraryActions(
            entry: entry,
            isUpdating: operation.isUpdating,
            targetStatus: operation.targetStatus,
            onRemove: () {
              context.read<LibraryCubit>().removeFromLibrary(_key);
            },
            onStatusSelected: (LibraryStatus status) {
              context.read<LibraryCubit>().updateShowStatus(_key, status);
            },
          );
        }

        return FilledButton.icon(
          key: const ValueKey<String>('show-details-library-add'),
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
        key: const ValueKey<String>('show-details-library-failure'),
        content: Text(
          LibraryFailureMessageMapper.messageFor(
            error,
            mediaType: LibraryMediaType.show,
          ),
        ),
        action: error.canRetry
            ? SnackBarAction(
                label: 'Retry',
                onPressed: () {
                  final LibraryCubit cubit = context.read<LibraryCubit>();

                  if (operation.isStatusUpdateFailure) {
                    cubit.retryShowStatus(_key);
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

class _ShowLibraryActions extends StatelessWidget {
  const _ShowLibraryActions({
    required this.entry,
    required this.isUpdating,
    required this.targetStatus,
    required this.onRemove,
    required this.onStatusSelected,
  });

  final LibraryEntry entry;
  final bool isUpdating;
  final LibraryStatus? targetStatus;

  final VoidCallback onRemove;
  final ValueChanged<LibraryStatus> onStatusSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const ValueKey<String>('show-details-library-actions'),
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        FilledButton.tonalIcon(
          key: const ValueKey<String>('show-details-library-added'),
          onPressed: isUpdating ? null : onRemove,
          icon: const Icon(Icons.check_rounded),
          label: const Text('In Watchlist'),
        ),

        if (isUpdating)
          _StatusUpdatingAction(targetStatus: targetStatus)
        else
          _ShowStatusSelector(
            status: entry.status,
            onSelected: onStatusSelected,
          ),
      ],
    );
  }
}

class _ShowStatusSelector extends StatelessWidget {
  const _ShowStatusSelector({required this.status, required this.onSelected});

  final LibraryStatus status;
  final ValueChanged<LibraryStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<LibraryStatus>(
      key: const ValueKey<String>('show-details-library-status'),
      initialValue: status,
      tooltip: 'Change status',
      onSelected: onSelected,
      itemBuilder: (BuildContext context) {
        return LibraryStatus.values
            .map(
              (LibraryStatus status) => PopupMenuItem<LibraryStatus>(
                key: ValueKey<String>(
                  'show-details-library-status-${status.name}',
                ),
                value: status,
                child: Row(
                  children: <Widget>[
                    if (status == this.status) ...<Widget>[
                      const Icon(Icons.check_rounded, size: 18),
                      const SizedBox(width: 8),
                    ] else
                      const SizedBox(width: 26),
                    Text(_statusLabel(status)),
                  ],
                ),
              ),
            )
            .toList(growable: false);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _statusLabel(status),
                key: const ValueKey<String>(
                  'show-details-library-status-label',
                ),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusUpdatingAction extends StatelessWidget {
  const _StatusUpdatingAction({required this.targetStatus});

  final LibraryStatus? targetStatus;

  @override
  Widget build(BuildContext context) {
    final LibraryStatus? status = targetStatus;

    return FilledButton.tonalIcon(
      key: const ValueKey<String>('show-details-library-status-updating'),
      onPressed: null,
      icon: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      label: Text(
        status == null ? 'Updating…' : 'Updating to ${_statusLabel(status)}…',
      ),
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

String _statusLabel(LibraryStatus status) {
  return switch (status) {
    LibraryStatus.planning => 'Planning',
    LibraryStatus.watching => 'Watching',
    LibraryStatus.completed => 'Completed',
    LibraryStatus.paused => 'Paused',
    LibraryStatus.dropped => 'Dropped',
  };
}
