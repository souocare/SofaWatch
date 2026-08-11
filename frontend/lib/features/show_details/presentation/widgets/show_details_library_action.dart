import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/application/cubit/library_cubit.dart';
import 'package:sofawatch/features/library/application/cubit/library_item_operation.dart';
import 'package:sofawatch/features/library/application/cubit/library_state.dart';
import 'package:sofawatch/features/library/domain/models/library_media_key.dart';
import 'package:sofawatch/features/library/domain/models/library_media_type.dart';
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
        if (operation.entry != null) {
          return FilledButton.tonalIcon(
            key: const ValueKey<String>('show-details-library-added'),
            onPressed: () {
              context.read<LibraryCubit>().removeFromLibrary(_key);
            },
            icon: const Icon(Icons.check_rounded),
            label: const Text('In Watchlist'),
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
