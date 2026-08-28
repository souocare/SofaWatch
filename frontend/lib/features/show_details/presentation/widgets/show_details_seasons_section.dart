import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/core/widgets/server_network_image.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_episode_operation.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_season_operation.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_season_state.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_seasons_cubit.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_show_operation.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_show_operation_cubit.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_episode.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_episode_progress.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_episode_watch_event.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_season.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_season_progress.dart';

class ShowDetailsSeasonsSection extends StatelessWidget {
  const ShowDetailsSeasonsSection({required this.seasons, super.key});

  final List<ShowDetailsSeason> seasons;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<
      ShowDetailsShowOperationCubit,
      ShowDetailsShowOperation
    >(
      listenWhen:
          (
            ShowDetailsShowOperation previous,
            ShowDetailsShowOperation current,
          ) {
            return previous.status != current.status;
          },
      listener: (BuildContext context, ShowDetailsShowOperation operation) async {
        if (operation.isSuccess) {
          try {
            await context
                .read<ShowDetailsSeasonsCubit>()
                .refreshAfterShowWatched();

            if (!context.mounted) {
              return;
            }

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  key: ValueKey<String>(
                    'show-details-mark-all-watched-success',
                  ),
                  content: Text('All aired episodes were marked as watched.'),
                ),
              );
          } on AppException {
            if (!context.mounted) {
              return;
            }

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  key: ValueKey<String>(
                    'show-details-mark-all-refresh-failure',
                  ),
                  content: Text(
                    'Episodes were marked as watched, but the page could not be '
                    'refreshed.',
                  ),
                ),
              );
          } catch (_) {
            if (!context.mounted) {
              return;
            }

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  key: ValueKey<String>(
                    'show-details-mark-all-refresh-failure',
                  ),
                  content: Text(
                    'Episodes were marked as watched, but the page could not be '
                    'refreshed.',
                  ),
                ),
              );
          } finally {
            if (context.mounted) {
              context.read<ShowDetailsShowOperationCubit>().reset();
            }
          }

          return;
        }

        if (!operation.hasFailed) {
          return;
        }

        final AppException? error = operation.error;

        if (error == null) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              key: const ValueKey<String>(
                'show-details-mark-all-watched-failure',
              ),
              content: const Text('Could not mark all episodes as watched.'),
              action: error.canRetry
                  ? SnackBarAction(
                      label: 'Retry',
                      onPressed: () {
                        context
                            .read<ShowDetailsShowOperationCubit>()
                            .retryMarkShowWatched();
                      },
                    )
                  : null,
            ),
          );
      },
      builder: (BuildContext context, ShowDetailsShowOperation showOperation) {
        return BlocConsumer<
          ShowDetailsSeasonsCubit,
          Map<int, ShowDetailsSeasonState>
        >(
          listenWhen:
              (
                Map<int, ShowDetailsSeasonState> previous,
                Map<int, ShowDetailsSeasonState> current,
              ) {
                return _findNewSeasonFailure(previous, current) != null ||
                    _findNewEpisodeFailure(previous, current) != null;
              },
          listener:
              (BuildContext context, Map<int, ShowDetailsSeasonState> current) {
                final _SeasonFailureInfo? seasonFailure =
                    _findCurrentSeasonFailure(current);

                if (seasonFailure != null) {
                  _showSeasonOperationFailure(context, failure: seasonFailure);

                  return;
                }

                final _EpisodeFailure? episodeFailure =
                    _findCurrentEpisodeFailure(current);

                if (episodeFailure != null) {
                  _showEpisodeFailure(context, failure: episodeFailure);
                }
              },
          builder:
              (BuildContext context, Map<int, ShowDetailsSeasonState> state) {
                final bool hasEpisodesToMark = seasons.any((
                  ShowDetailsSeason season,
                ) {
                  if (season.seasonNumber <= 0) {
                    return false;
                  }

                  final ShowDetailsSeasonProgress? progress =
                      state[season.seasonNumber]?.progress;

                  return progress != null &&
                      progress.hasAiredEpisodes &&
                      !progress.caughtUp;
                });

                final ShowDetailsSeasonsCubit seasonsCubit = context
                    .read<ShowDetailsSeasonsCubit>();

                final bool hasOtherMutation =
                    seasonsCubit.hasMutationInProgress;

                final bool canMarkAll =
                    hasEpisodesToMark &&
                    !showOperation.isUpdating &&
                    !hasOtherMutation;

                return Column(
                  key: const ValueKey<String>('show-details-seasons-section'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Seasons',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),

                        if (hasEpisodesToMark || showOperation.isUpdating)
                          _MarkAllWatchedButton(
                            isUpdating: showOperation.isUpdating,
                            enabled: canMarkAll,
                          ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    Column(
                      children: <Widget>[
                        for (
                          int index = 0;
                          index < seasons.length;
                          index++
                        ) ...<Widget>[
                          _SeasonAccordion(
                            season: seasons[index],
                            state:
                                state[seasons[index].seasonNumber] ??
                                const ShowDetailsSeasonState(),
                          ),
                          if (index != seasons.length - 1)
                            const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                    ),
                  ],
                );
              },
        );
      },
    );
  }

  void _showSeasonOperationFailure(
    BuildContext context, {
    required _SeasonFailureInfo failure,
  }) {
    final AppException? error = failure.operation.error;

    if (error == null) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: ValueKey<String>(
            'show-details-season-mark-watched-failure-'
            '${failure.seasonNumber}',
          ),
          content: const Text('Could not mark this season as watched.'),
          action: error.canRetry
              ? SnackBarAction(
                  label: 'Retry',
                  onPressed: () {
                    context
                        .read<ShowDetailsSeasonsCubit>()
                        .retryMarkSeasonWatched(
                          seasonNumber: failure.seasonNumber,
                        );
                  },
                )
              : null,
        ),
      );
  }

  void _showEpisodeFailure(
    BuildContext context, {
    required _EpisodeFailure failure,
  }) {
    final AppException? error = failure.operation.error;

    if (error == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: ValueKey<String>(
          'show-details-episode-update-failure-${failure.episodeId}',
        ),
        content: const Text('Could not update this episode. Please try again.'),
        action: error.canRetry
            ? SnackBarAction(
                label: 'Retry',
                onPressed: () {
                  context.read<ShowDetailsSeasonsCubit>().retryEpisodeUpdate(
                    seasonNumber: failure.seasonNumber,
                    episodeId: failure.episodeId,
                  );
                },
              )
            : null,
      ),
    );
  }
}

class _MarkAllWatchedButton extends StatelessWidget {
  const _MarkAllWatchedButton({
    required this.isUpdating,
    required this.enabled,
  });

  final bool isUpdating;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (isUpdating) {
      return const SizedBox(
        key: ValueKey<String>('show-details-mark-all-watched-loading'),
        width: 40,
        height: 40,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return OutlinedButton.icon(
      key: const ValueKey<String>('show-details-mark-all-watched'),
      onPressed: enabled
          ? () {
              _handleMarkAllWatched(context);
            }
          : null,
      icon: const Icon(Icons.library_add_check_outlined),
      label: const Text('Mark all watched'),
    );
  }
}

Future<void> _handleMarkAllWatched(BuildContext context) async {
  final ShowDetailsSeasonsCubit seasonsCubit = context
      .read<ShowDetailsSeasonsCubit>();

  final ShowDetailsShowOperationCubit operationCubit = context
      .read<ShowDetailsShowOperationCubit>();

  if (operationCubit.state.isUpdating || seasonsCubit.hasMutationInProgress) {
    return;
  }

  final bool confirmed = await _confirmMarkAllWatched(context);

  if (!confirmed || !context.mounted) {
    return;
  }

  if (operationCubit.state.isUpdating || seasonsCubit.hasMutationInProgress) {
    return;
  }

  await operationCubit.markShowWatched();
}

Future<bool> _confirmMarkAllWatched(BuildContext context) async {
  final bool useBottomSheet =
      MediaQuery.sizeOf(context).width < AppBreakpoints.tablet;

  if (useBottomSheet) {
    final bool? result = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return const _MarkAllWatchedConfirmation();
      },
    );

    return result ?? false;
  }

  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: const _MarkAllWatchedConfirmation(),
        ),
      );
    },
  );

  return result ?? false;
}

class _MarkAllWatchedConfirmation extends StatelessWidget {
  const _MarkAllWatchedConfirmation();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Mark all episodes as watched?',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: AppSpacing.sm),

            Text(
              'All aired episodes that are not currently marked as watched '
              'will be marked as watched now.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),

            const SizedBox(height: AppSpacing.sm),

            Text(
              'Already watched episodes, future episodes, and Specials '
              'will not be changed.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),

            const SizedBox(height: AppSpacing.xl),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  key: const ValueKey<String>(
                    'show-details-mark-all-watched-cancel',
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Cancel'),
                ),

                const SizedBox(width: AppSpacing.sm),

                FilledButton.icon(
                  key: const ValueKey<String>(
                    'show-details-mark-all-watched-confirm',
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  icon: const Icon(Icons.library_add_check_outlined),
                  label: const Text('Mark all watched'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SeasonAccordion extends StatelessWidget {
  const _SeasonAccordion({required this.season, required this.state});

  final ShowDetailsSeason season;
  final ShowDetailsSeasonState state;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: ValueKey<String>('show-details-season-${season.seasonNumber}'),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.borderLarge,
        child: Column(
          children: <Widget>[
            _SeasonHeader(
              season: season,
              expanded: state.isExpanded,
              progress: state.progress,
              operation: state.operation,
              onPressed: () {
                context.read<ShowDetailsSeasonsCubit>().toggleSeason(
                  season.seasonNumber,
                );
              },
              onMarkWatched: () {
                context.read<ShowDetailsSeasonsCubit>().markSeasonWatched(
                  seasonNumber: season.seasonNumber,
                );
              },
            ),
            if (state.isExpanded)
              _ExpandedSeasonContent(season: season, state: state),
          ],
        ),
      ),
    );
  }
}

class _SeasonHeader extends StatelessWidget {
  const _SeasonHeader({
    required this.season,
    required this.expanded,
    required this.progress,
    required this.operation,
    required this.onPressed,
    required this.onMarkWatched,
  });

  final ShowDetailsSeason season;
  final bool expanded;
  final ShowDetailsSeasonProgress? progress;
  final ShowDetailsSeasonOperation operation;

  final VoidCallback onPressed;
  final VoidCallback onMarkWatched;

  @override
  Widget build(BuildContext context) {
    final ShowDetailsSeasonProgress? currentProgress = progress;

    final bool hasAiredEpisodes =
        currentProgress != null && currentProgress.hasAiredEpisodes;

    final bool isCaughtUp = currentProgress?.caughtUp ?? false;
    final bool isUpdating = operation.isUpdating;

    final bool canMarkSeasonWatched =
        hasAiredEpisodes && !isCaughtUp && !isUpdating;

    final String episodeLabel = hasAiredEpisodes
        ? '${currentProgress.watchedAiredEpisodes} of '
              '${currentProgress.airedEpisodes} aired episodes'
        : '${season.episodeCount} '
              '${season.episodeCount == 1 ? 'episode' : 'episodes'}';

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: <Widget>[
            Expanded(
              child: InkWell(
                key: ValueKey<String>(
                  'show-details-season-toggle-${season.seasonNumber}',
                ),
                borderRadius: AppRadius.borderMedium,
                onTap: onPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              season.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (isCaughtUp) ...<Widget>[
                            const SizedBox(width: AppSpacing.sm),
                            Icon(
                              Icons.check_circle_rounded,
                              key: ValueKey<String>(
                                'show-details-season-caught-up-'
                                '${season.seasonNumber}',
                              ),
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        episodeLabel,
                        key: ValueKey<String>(
                          'show-details-season-progress-label-'
                          '${season.seasonNumber}',
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (hasAiredEpisodes) ...<Widget>[
                        const SizedBox(height: AppSpacing.md),
                        ClipRRect(
                          borderRadius: AppRadius.borderFull,
                          child: LinearProgressIndicator(
                            key: ValueKey<String>(
                              'show-details-season-progress-'
                              '${season.seasonNumber}',
                            ),
                            value: currentProgress.airedProgressValue,
                            minHeight: 4,
                            backgroundColor: AppColors.surfaceLow,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            if (hasAiredEpisodes && !isCaughtUp)
              Tooltip(
                message: 'Mark aired episodes as watched',
                child: IconButton(
                  key: ValueKey<String>(
                    'show-details-season-mark-watched-${season.seasonNumber}',
                  ),
                  onPressed: canMarkSeasonWatched ? onMarkWatched : null,
                  icon: isUpdating
                      ? SizedBox(
                          key: ValueKey<String>(
                            'show-details-season-mark-watched-progress-'
                            '${season.seasonNumber}',
                          ),
                          width: 20,
                          height: 20,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.library_add_check_outlined),
                ),
              ),

            AnimatedRotation(
              duration: const Duration(milliseconds: 180),
              turns: expanded ? 0.5 : 0,
              child: IconButton(
                tooltip: expanded ? 'Collapse season' : 'Expand season',
                onPressed: onPressed,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandedSeasonContent extends StatelessWidget {
  const _ExpandedSeasonContent({required this.season, required this.state});

  final ShowDetailsSeason season;
  final ShowDetailsSeasonState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const _SeasonLoading();
    }

    if (state.hasError) {
      return _SeasonFailure(
        seasonNumber: season.seasonNumber,
        message:
            state.error?.message ??
            'Could not load the episodes for this season.',
      );
    }

    if (state.episodes.isEmpty) {
      return const _SeasonEmpty();
    }

    return _EpisodeList(
      seasonNumber: season.seasonNumber,
      episodes: state.episodes,
      episodeProgressById: state.episodeProgressById,
      episodeOperationsById: state.episodeOperationsById,
    );
  }
}

class _SeasonLoading extends StatelessWidget {
  const _SeasonLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      key: ValueKey<String>('show-details-season-loading'),
      padding: AppSpacing.cardPaddingLarge,
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _SeasonFailure extends StatelessWidget {
  const _SeasonFailure({required this.seasonNumber, required this.message});

  final int seasonNumber;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: ValueKey<String>('show-details-season-failure-$seasonNumber'),
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.tonalIcon(
            key: ValueKey<String>('show-details-season-retry-$seasonNumber'),
            onPressed: () {
              context.read<ShowDetailsSeasonsCubit>().retrySeason(seasonNumber);
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _SeasonEmpty extends StatelessWidget {
  const _SeasonEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey<String>('show-details-season-empty'),
      padding: AppSpacing.cardPadding,
      child: Text(
        'No episodes are available for this season.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _EpisodeList extends StatelessWidget {
  const _EpisodeList({
    required this.seasonNumber,
    required this.episodes,
    required this.episodeProgressById,
    required this.episodeOperationsById,
  });

  final int seasonNumber;
  final List<ShowDetailsEpisode> episodes;
  final Map<String, ShowDetailsEpisodeProgress> episodeProgressById;
  final Map<String, ShowDetailsEpisodeOperation> episodeOperationsById;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey<String>('show-details-season-episodes-$seasonNumber'),
      children: <Widget>[
        const Divider(height: 1),
        for (int index = 0; index < episodes.length; index++) ...<Widget>[
          _EpisodeRow(
            seasonNumber: seasonNumber,
            episode: episodes[index],
            progress: episodeProgressById[episodes[index].id],
            operation:
                episodeOperationsById[episodes[index].id] ??
                const ShowDetailsEpisodeOperation.idle(),
          ),
          if (index != episodes.length - 1)
            const Divider(
              height: 1,
              indent: AppSpacing.lg,
              endIndent: AppSpacing.lg,
            ),
        ],
      ],
    );
  }
}

class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({
    required this.seasonNumber,
    required this.episode,
    required this.progress,
    required this.operation,
  });

  final int seasonNumber;
  final ShowDetailsEpisode episode;
  final ShowDetailsEpisodeProgress? progress;
  final ShowDetailsEpisodeOperation operation;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isCompact = constraints.maxWidth < AppBreakpoints.tablet;

        final bool hasImage =
            !isCompact &&
            episode.stillUrl != null &&
            episode.stillUrl!.trim().isNotEmpty;

        return Padding(
          key: ValueKey<String>('show-details-episode-${episode.id}'),
          padding: isCompact
              ? const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                )
              : AppSpacing.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Open episode details',
                  child: InkWell(
                    key: ValueKey<String>(
                      'show-details-episode-link-${episode.id}',
                    ),
                    borderRadius: AppRadius.borderMedium,
                    onTap: () {
                      context.pushNamed(
                        AppRoute.episodeDetails.name,
                        pathParameters: <String, String>{
                          'episodeId': episode.id,
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          if (hasImage) ...<Widget>[
                            _EpisodeImage(url: episode.stillUrl!),
                            const SizedBox(width: AppSpacing.lg),
                          ],
                          Expanded(
                            child: _EpisodeInformation(
                              seasonNumber: seasonNumber,
                              episode: episode,
                              isCompact: isCompact,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _EpisodeStatusButton(
                seasonNumber: seasonNumber,
                episode: episode,
                progress: progress,
                operation: operation,
              ),
            ],
          ),
        );
      },
    );
  }
}

// class _WideEpisodeLayout extends StatelessWidget {
//   const _WideEpisodeLayout({
//     required this.seasonNumber,
//     required this.episode,
//     required this.progress,
//     required this.operation,
//   });

//   final int seasonNumber;
//   final ShowDetailsEpisode episode;
//   final ShowDetailsEpisodeProgress? progress;
//   final ShowDetailsEpisodeOperation operation;

//   @override
//   Widget build(BuildContext context) {
//     final bool hasImage =
//         episode.stillUrl != null && episode.stillUrl!.trim().isNotEmpty;

//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: <Widget>[
//         if (hasImage) ...<Widget>[
//           _EpisodeImage(url: episode.stillUrl!),
//           const SizedBox(width: AppSpacing.lg),
//         ],
//         Expanded(
//           child: _EpisodeInformation(
//             seasonNumber: seasonNumber,
//             episode: episode,
//           ),
//         ),
//         const SizedBox(width: AppSpacing.md),
//         _EpisodeStatusButton(
//           seasonNumber: seasonNumber,
//           episode: episode,
//           progress: progress,
//           operation: operation,
//         ),
//       ],
//     );
//   }
// }

// class _CompactEpisodeLayout extends StatelessWidget {
//   const _CompactEpisodeLayout({
//     required this.seasonNumber,
//     required this.episode,
//     required this.progress,
//     required this.operation,
//   });

//   final int seasonNumber;
//   final ShowDetailsEpisode episode;
//   final ShowDetailsEpisodeProgress? progress;
//   final ShowDetailsEpisodeOperation operation;

//   @override
//   Widget build(BuildContext context) {
//     final bool hasImage =
//         episode.stillUrl != null && episode.stillUrl!.trim().isNotEmpty;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: <Widget>[
//         if (hasImage) ...<Widget>[
//           _EpisodeImage(url: episode.stillUrl!, width: double.infinity),
//           const SizedBox(height: AppSpacing.md),
//         ],
//         _EpisodeInformation(seasonNumber: seasonNumber, episode: episode),
//         const SizedBox(height: AppSpacing.sm),
//         Align(
//           alignment: Alignment.centerRight,
//           child: _EpisodeStatusButton(
//             seasonNumber: seasonNumber,
//             episode: episode,
//             progress: progress,
//             operation: operation,
//           ),
//         ),
//       ],
//     );
//   }
// }

class _EpisodeImage extends StatelessWidget {
  const _EpisodeImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.borderMedium,
      child: SizedBox(
        width: 112,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: ServerNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            errorBuilder:
                (BuildContext context, Object error, StackTrace? stackTrace) {
                  return const SizedBox.shrink();
                },
          ),
        ),
      ),
    );
  }
}

class _EpisodeInformation extends StatelessWidget {
  const _EpisodeInformation({
    required this.seasonNumber,
    required this.episode,
    required this.isCompact,
  });

  final int seasonNumber;
  final ShowDetailsEpisode episode;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final String code = isCompact
        ? 'E${episode.episodeNumber.toString().padLeft(2, '0')}'
        : 'S${seasonNumber.toString().padLeft(2, '0')}'
              'E${episode.episodeNumber.toString().padLeft(2, '0')}';

    final bool isUpcoming = _isUpcomingEpisode(episode);

    final List<String> metadata = <String>[
      if (episode.runtime != null) '${episode.runtime} min',
      if (episode.airDate != null)
        MaterialLocalizations.of(context).formatMediumDate(episode.airDate!),
      if (isUpcoming) 'Upcoming',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '$code  ${episode.title}',
          key: ValueKey<String>('show-details-episode-title-${episode.id}'),
          maxLines: isCompact ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),

        if (metadata.isNotEmpty) ...<Widget>[
          SizedBox(height: isCompact ? 2 : AppSpacing.xs),
          Text(
            metadata.join(' • '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

class _EpisodeStatusButton extends StatelessWidget {
  const _EpisodeStatusButton({
    required this.seasonNumber,
    required this.episode,
    required this.progress,
    required this.operation,
  });

  final int seasonNumber;
  final ShowDetailsEpisode episode;
  final ShowDetailsEpisodeProgress? progress;
  final ShowDetailsEpisodeOperation operation;

  @override
  Widget build(BuildContext context) {
    final bool isWatched = progress?.isWatched ?? false;
    final bool isUpcoming = _isUpcomingEpisode(episode);

    if (operation.isUpdating) {
      return SizedBox(
        key: ValueKey<String>('show-details-episode-updating-${episode.id}'),
        width: 48,
        height: 48,
        child: const Padding(
          padding: EdgeInsets.all(13),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        if (isUpcoming)
          IconButton(
            key: ValueKey<String>('show-details-episode-watched-${episode.id}'),
            onPressed: null,
            tooltip: 'Not released yet',
            icon: const Icon(Icons.schedule_rounded),
          )
        else if (isWatched)
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              IconButton(
                key: ValueKey<String>(
                  'show-details-episode-watched-${episode.id}',
                ),
                onPressed: () {
                  _handleEpisodeUnwatch(
                    context,
                    seasonNumber: seasonNumber,
                    episode: episode,
                    watchCount: progress!.watchCount,
                  );
                },
                tooltip: 'Mark as not watched',
                icon: const Icon(Icons.check_circle_rounded),
              ),

              IconButton(
                key: ValueKey<String>(
                  'show-details-episode-rewatch-${episode.id}',
                ),
                onPressed: () {
                  context.read<ShowDetailsSeasonsCubit>().rewatchEpisode(
                    seasonNumber: seasonNumber,
                    episodeId: episode.id,
                  );
                },
                tooltip: 'Watched again',
                icon: const Icon(Icons.replay_rounded),
              ),

              if ((progress?.watchCount ?? 0) > 0)
                _EpisodeWatchCountButton(
                  seasonNumber: seasonNumber,
                  episode: episode,
                  watchCount: progress!.watchCount,
                ),
            ],
          )
        else
          IconButton(
            key: ValueKey<String>('show-details-episode-watched-${episode.id}'),
            onPressed: () {
              _handleEpisodeMarkWatched(
                context,
                seasonNumber: seasonNumber,
                episode: episode,
              );
            },
            tooltip: 'Mark as watched',
            icon: const Icon(Icons.radio_button_unchecked_rounded),
          ),

        if (isWatched && progress?.watchedAt != null)
          InkWell(
            key: ValueKey<String>(
              'show-details-episode-watched-date-${episode.id}',
            ),
            borderRadius: AppRadius.borderSmall,
            onTap: () {
              _showEpisodeWatchHistory(
                context,
                seasonNumber: seasonNumber,
                episode: episode,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              child: Text(
                MaterialLocalizations.of(
                  context,
                ).formatMediumDate(progress!.watchedAt!.toLocal()),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
            ),
          ),
      ],
    );
  }
}

enum _EpisodeMarkWatchedChoice { onlyThisEpisode, includePrevious }

Future<void> _handleEpisodeMarkWatched(
  BuildContext context, {
  required int seasonNumber,
  required ShowDetailsEpisode episode,
}) async {
  final ShowDetailsSeasonsCubit cubit = context.read<ShowDetailsSeasonsCubit>();

  /*
   * Do not start another action for the same Episode while an existing
   * mutation is still running.
   */
  final ShowDetailsSeasonState currentState =
      cubit.state[seasonNumber] ?? const ShowDetailsSeasonState();

  if (currentState.operationForEpisode(episode.id).isUpdating) {
    return;
  }

  int previousUnwatchedCount;

  try {
    previousUnwatchedCount = await cubit.getPreviousUnwatchedEpisodeCount(
      episodeId: episode.id,
    );
  } on AppException {
    if (!context.mounted) {
      return;
    }

    _showPreviousEpisodeCheckFailure(context);

    return;
  } catch (_) {
    if (!context.mounted) {
      return;
    }

    _showPreviousEpisodeCheckFailure(context);

    return;
  }

  if (!context.mounted) {
    return;
  }

  /*
   * Nothing earlier needs attention, so preserve the normal one-click
   * "Mark as watched" behavior.
   */
  if (previousUnwatchedCount == 0) {
    await cubit.markEpisodeWatched(
      seasonNumber: seasonNumber,
      episodeId: episode.id,
    );

    return;
  }

  final _EpisodeMarkWatchedChoice? choice = await _showEpisodeMarkWatchedChoice(
    context,
    previousUnwatchedCount: previousUnwatchedCount,
  );

  if (choice == null || !context.mounted) {
    return;
  }

  /*
   * State may have changed while the confirmation UI was open.
   *
   * Check again before starting the mutation so repeated taps cannot create
   * overlapping operations.
   */
  final ShowDetailsSeasonState latestState =
      cubit.state[seasonNumber] ?? const ShowDetailsSeasonState();

  if (latestState.operationForEpisode(episode.id).isUpdating) {
    return;
  }

  switch (choice) {
    case _EpisodeMarkWatchedChoice.onlyThisEpisode:
      await cubit.markEpisodeWatched(
        seasonNumber: seasonNumber,
        episodeId: episode.id,
      );

    case _EpisodeMarkWatchedChoice.includePrevious:
      await cubit.markEpisodeWatchedWithPrevious(
        seasonNumber: seasonNumber,
        episodeId: episode.id,
      );
  }
}

void _showPreviousEpisodeCheckFailure(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        key: ValueKey<String>('show-details-previous-unwatched-check-failure'),
        content: Text('Could not check previous episodes. Please try again.'),
      ),
    );
}

Future<_EpisodeMarkWatchedChoice?> _showEpisodeMarkWatchedChoice(
  BuildContext context, {
  required int previousUnwatchedCount,
}) async {
  final bool useBottomSheet =
      MediaQuery.sizeOf(context).width < AppBreakpoints.tablet;

  if (useBottomSheet) {
    return showModalBottomSheet<_EpisodeMarkWatchedChoice>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _EpisodeMarkWatchedOptions(
          previousUnwatchedCount: previousUnwatchedCount,
        );
      },
    );
  }

  return showDialog<_EpisodeMarkWatchedChoice>(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: _EpisodeMarkWatchedOptions(
            previousUnwatchedCount: previousUnwatchedCount,
          ),
        ),
      );
    },
  );
}

class _EpisodeMarkWatchedOptions extends StatelessWidget {
  const _EpisodeMarkWatchedOptions({required this.previousUnwatchedCount});

  final int previousUnwatchedCount;

  @override
  Widget build(BuildContext context) {
    final String episodeLabel = previousUnwatchedCount == 1
        ? '1 previous episode'
        : '$previousUnwatchedCount previous episodes';

    return SingleChildScrollView(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Previous episodes are unwatched',
              key: const ValueKey<String>(
                'show-details-previous-unwatched-title',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: AppSpacing.sm),

            Text(
              '$episodeLabel aired before this one and '
              '${previousUnwatchedCount == 1 ? 'is' : 'are'} '
              'still marked as unwatched.',
              key: const ValueKey<String>(
                'show-details-previous-unwatched-description',
              ),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),

            const SizedBox(height: AppSpacing.sm),

            Text(
              'Specials (Season 0) are not included. Only episodes that '
              'have already aired are considered.',
              key: const ValueKey<String>(
                'show-details-previous-unwatched-rules',
              ),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),

            const SizedBox(height: AppSpacing.lg),

            ListTile(
              key: const ValueKey<String>(
                'show-details-mark-only-this-episode',
              ),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline_rounded),
              title: const Text('Only this episode'),
              subtitle: const Text('Leave the previous episodes unchanged.'),
              onTap: () {
                Navigator.of(
                  context,
                ).pop(_EpisodeMarkWatchedChoice.onlyThisEpisode);
              },
            ),

            ListTile(
              key: const ValueKey<String>('show-details-mark-with-previous'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.done_all_rounded),
              title: Text(
                previousUnwatchedCount == 1
                    ? 'Include previous episode'
                    : 'Include previous episodes',
              ),
              subtitle: Text(
                previousUnwatchedCount == 1
                    ? 'Mark the previous episode and this episode as watched.'
                    : 'Mark all $previousUnwatchedCount previous episodes '
                          'and this episode as watched.',
              ),
              onTap: () {
                Navigator.of(
                  context,
                ).pop(_EpisodeMarkWatchedChoice.includePrevious);
              },
            ),

            const SizedBox(height: AppSpacing.sm),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const ValueKey<String>(
                  'show-details-mark-with-previous-cancel',
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _EpisodeUnwatchChoice { removeLatest, removeAll }

Future<void> _handleEpisodeUnwatch(
  BuildContext context, {
  required int seasonNumber,
  required ShowDetailsEpisode episode,
  required int watchCount,
}) async {
  final ShowDetailsSeasonsCubit cubit = context.read<ShowDetailsSeasonsCubit>();

  if (watchCount <= 1) {
    await cubit.removeAllEpisodeViewings(
      seasonNumber: seasonNumber,
      episodeId: episode.id,
    );

    return;
  }

  final _EpisodeUnwatchChoice? choice = await _showEpisodeUnwatchChoice(
    context,
    watchCount: watchCount,
  );

  if (choice == null) {
    return;
  }

  switch (choice) {
    case _EpisodeUnwatchChoice.removeLatest:
      await cubit.removeLatestEpisodeViewing(
        seasonNumber: seasonNumber,
        episodeId: episode.id,
      );

    case _EpisodeUnwatchChoice.removeAll:
      await cubit.removeAllEpisodeViewings(
        seasonNumber: seasonNumber,
        episodeId: episode.id,
      );
  }
}

Future<_EpisodeUnwatchChoice?> _showEpisodeUnwatchChoice(
  BuildContext context, {
  required int watchCount,
}) async {
  final bool useBottomSheet =
      MediaQuery.sizeOf(context).width < AppBreakpoints.tablet;

  if (useBottomSheet) {
    return showModalBottomSheet<_EpisodeUnwatchChoice>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _EpisodeUnwatchOptions(watchCount: watchCount);
      },
    );
  }

  return showDialog<_EpisodeUnwatchChoice>(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: _EpisodeUnwatchOptions(watchCount: watchCount),
        ),
      );
    },
  );
}

class _EpisodeUnwatchOptions extends StatelessWidget {
  const _EpisodeUnwatchOptions({required this.watchCount});

  final int watchCount;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Mark as not watched?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This episode has been watched $watchCount times. '
              'Choose which viewing history you want to remove.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              key: const ValueKey<String>('show-details-unwatch-remove-latest'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history_rounded),
              title: const Text('Remove latest viewing'),
              subtitle: const Text('Keep the previous viewing history.'),
              onTap: () {
                Navigator.of(context).pop(_EpisodeUnwatchChoice.removeLatest);
              },
            ),
            ListTile(
              key: const ValueKey<String>('show-details-unwatch-remove-all'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Remove all viewings'),
              subtitle: const Text(
                'Mark this episode as completely unwatched.',
              ),
              onTap: () {
                Navigator.of(context).pop(_EpisodeUnwatchChoice.removeAll);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const ValueKey<String>('show-details-unwatch-cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EpisodeWatchCountButton extends StatelessWidget {
  const _EpisodeWatchCountButton({
    required this.seasonNumber,
    required this.episode,
    required this.watchCount,
  });

  final int seasonNumber;
  final ShowDetailsEpisode episode;
  final int watchCount;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: watchCount == 1
          ? 'View watch history'
          : 'View watch history ($watchCount viewings)',
      child: InkWell(
        key: ValueKey<String>(
          'show-details-episode-watch-history-${episode.id}',
        ),
        borderRadius: AppRadius.borderMedium,
        onTap: () {
          _showEpisodeWatchHistory(
            context,
            seasonNumber: seasonNumber,
            episode: episode,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.history_rounded, size: 20),
              if (watchCount > 1) ...<Widget>[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '$watchCount×',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showEpisodeWatchHistory(
  BuildContext context, {
  required int seasonNumber,
  required ShowDetailsEpisode episode,
}) async {
  final ShowDetailsSeasonsCubit cubit = context.read<ShowDetailsSeasonsCubit>();

  final bool useBottomSheet =
      MediaQuery.sizeOf(context).width < AppBreakpoints.tablet;

  final Widget content = BlocProvider<ShowDetailsSeasonsCubit>.value(
    value: cubit,
    child: _EpisodeWatchHistoryContent(
      seasonNumber: seasonNumber,
      episode: episode,
    ),
  );

  if (useBottomSheet) {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return content;
      },
    );

    return;
  }

  await showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
          child: content,
        ),
      );
    },
  );
}

class _EpisodeWatchHistoryContent extends StatefulWidget {
  const _EpisodeWatchHistoryContent({
    required this.seasonNumber,
    required this.episode,
  });

  final int seasonNumber;
  final ShowDetailsEpisode episode;

  @override
  State<_EpisodeWatchHistoryContent> createState() =>
      _EpisodeWatchHistoryContentState();
}

class _EpisodeWatchHistoryContentState
    extends State<_EpisodeWatchHistoryContent> {
  List<ShowDetailsEpisodeWatchEvent>? _events;

  AppException? _error;

  String? _deletingEventId;

  @override
  void initState() {
    super.initState();

    _load();
  }

  Future<void> _load() async {
    setState(() {
      _events = null;
      _error = null;
    });

    try {
      final List<ShowDetailsEpisodeWatchEvent> events = await context
          .read<ShowDetailsSeasonsCubit>()
          .getEpisodeWatchEvents(episodeId: widget.episode.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _events = events;
      });
    } on AppException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = AppException.unknown(originalError: error);
      });
    }
  }

  Future<void> _delete(ShowDetailsEpisodeWatchEvent event) async {
    if (_deletingEventId != null) {
      return;
    }

    setState(() {
      _deletingEventId = event.id;
      _error = null;
    });

    try {
      final ShowDetailsSeasonsCubit cubit = context
          .read<ShowDetailsSeasonsCubit>();

      await cubit.deleteEpisodeWatchEvent(
        seasonNumber: widget.seasonNumber,
        episodeId: widget.episode.id,
        eventId: event.id,
      );

      final List<ShowDetailsEpisodeWatchEvent> events = await cubit
          .getEpisodeWatchEvents(episodeId: widget.episode.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _events = events;
        _deletingEventId = null;
      });
    } on AppException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error;
        _deletingEventId = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = AppException.unknown(originalError: error);

        _deletingEventId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<ShowDetailsEpisodeWatchEvent>? events = _events;

    return Padding(
      padding: AppSpacing.cardPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Watch history',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    Text(
                      widget.episode.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip: 'Close',
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          if (_error != null) ...<Widget>[
            _EpisodeWatchHistoryError(onRetry: _load),
          ] else if (events == null) ...<Widget>[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CircularProgressIndicator(),
              ),
            ),
          ] else if (events.isEmpty) ...<Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Text(
                  'No viewing history.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ] else ...<Widget>[
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: events.length,
                separatorBuilder: (BuildContext context, int index) {
                  return const Divider(height: 1);
                },
                itemBuilder: (BuildContext context, int index) {
                  final ShowDetailsEpisodeWatchEvent event = events[index];

                  return _EpisodeWatchHistoryRow(
                    event: event,
                    isDeleting: _deletingEventId == event.id,
                    onDelete: () {
                      _delete(event);
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EpisodeWatchHistoryRow extends StatelessWidget {
  const _EpisodeWatchHistoryRow({
    required this.event,
    required this.isDeleting,
    required this.onDelete,
  });

  final ShowDetailsEpisodeWatchEvent event;
  final bool isDeleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final DateTime localDate = event.watchedAt.toLocal();

    final String date = MaterialLocalizations.of(
      context,
    ).formatMediumDate(localDate);

    final String time = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(localDate));

    return ListTile(
      key: ValueKey<String>('episode-watch-event-${event.id}'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.play_circle_outline_rounded),
      title: Text(
        date,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        time,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
      ),
      trailing: isDeleting
          ? const SizedBox(
              width: 40,
              height: 40,
              child: Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : IconButton(
              key: ValueKey<String>('delete-episode-watch-event-${event.id}'),
              tooltip: 'Delete viewing',
              onPressed: () async {
                final bool confirmed = await _confirmEpisodeWatchEventDeletion(
                  context,
                );

                if (!confirmed) {
                  return;
                }

                onDelete();
              },
              icon: const Icon(Icons.delete_outline_rounded),
            ),
    );
  }
}

Future<bool> _confirmEpisodeWatchEventDeletion(BuildContext context) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Delete viewing?'),
        content: const Text(
          'This viewing will be removed from the episode history.',
        ),
        actions: <Widget>[
          TextButton(
            key: const ValueKey<String>('cancel-delete-episode-watch-event'),
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey<String>('confirm-delete-episode-watch-event'),
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );

  return confirmed ?? false;
}

class _EpisodeWatchHistoryError extends StatelessWidget {
  const _EpisodeWatchHistoryError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: <Widget>[
          Text(
            'Could not load viewing history.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: AppSpacing.md),

          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

_EpisodeFailure? _findNewEpisodeFailure(
  Map<int, ShowDetailsSeasonState> previous,
  Map<int, ShowDetailsSeasonState> current,
) {
  for (final MapEntry<int, ShowDetailsSeasonState> seasonEntry
      in current.entries) {
    final int seasonNumber = seasonEntry.key;
    final ShowDetailsSeasonState currentSeason = seasonEntry.value;

    final ShowDetailsSeasonState previousSeason =
        previous[seasonNumber] ?? const ShowDetailsSeasonState();

    for (final MapEntry<String, ShowDetailsEpisodeOperation> operationEntry
        in currentSeason.episodeOperationsById.entries) {
      final String episodeId = operationEntry.key;
      final ShowDetailsEpisodeOperation currentOperation = operationEntry.value;

      if (!currentOperation.hasFailed) {
        continue;
      }

      final ShowDetailsEpisodeOperation previousOperation = previousSeason
          .operationForEpisode(episodeId);

      if (previousOperation == currentOperation) {
        continue;
      }

      return _EpisodeFailure(
        seasonNumber: seasonNumber,
        episodeId: episodeId,
        operation: currentOperation,
      );
    }
  }

  return null;
}

_SeasonFailureInfo? _findNewSeasonFailure(
  Map<int, ShowDetailsSeasonState> previous,
  Map<int, ShowDetailsSeasonState> current,
) {
  for (final MapEntry<int, ShowDetailsSeasonState> entry in current.entries) {
    final int seasonNumber = entry.key;
    final ShowDetailsSeasonState currentSeason = entry.value;

    if (!currentSeason.operation.hasFailed) {
      continue;
    }

    final ShowDetailsSeasonState previousSeason =
        previous[seasonNumber] ?? const ShowDetailsSeasonState();

    if (previousSeason.operation == currentSeason.operation) {
      continue;
    }

    return _SeasonFailureInfo(
      seasonNumber: seasonNumber,
      operation: currentSeason.operation,
    );
  }

  return null;
}

_SeasonFailureInfo? _findCurrentSeasonFailure(
  Map<int, ShowDetailsSeasonState> state,
) {
  for (final MapEntry<int, ShowDetailsSeasonState> entry in state.entries) {
    if (!entry.value.operation.hasFailed) {
      continue;
    }

    return _SeasonFailureInfo(
      seasonNumber: entry.key,
      operation: entry.value.operation,
    );
  }

  return null;
}

final class _SeasonFailureInfo {
  const _SeasonFailureInfo({
    required this.seasonNumber,
    required this.operation,
  });

  final int seasonNumber;
  final ShowDetailsSeasonOperation operation;
}

_EpisodeFailure? _findCurrentEpisodeFailure(
  Map<int, ShowDetailsSeasonState> state,
) {
  for (final MapEntry<int, ShowDetailsSeasonState> seasonEntry
      in state.entries) {
    for (final MapEntry<String, ShowDetailsEpisodeOperation> operationEntry
        in seasonEntry.value.episodeOperationsById.entries) {
      if (!operationEntry.value.hasFailed) {
        continue;
      }

      return _EpisodeFailure(
        seasonNumber: seasonEntry.key,
        episodeId: operationEntry.key,
        operation: operationEntry.value,
      );
    }
  }

  return null;
}

final class _EpisodeFailure {
  const _EpisodeFailure({
    required this.seasonNumber,
    required this.episodeId,
    required this.operation,
  });

  final int seasonNumber;
  final String episodeId;
  final ShowDetailsEpisodeOperation operation;
}

bool _isUpcomingEpisode(ShowDetailsEpisode episode) {
  final DateTime? airDate = episode.airDate;

  if (airDate == null) {
    return false;
  }

  final DateTime now = DateTime.now();

  final DateTime today = DateTime(now.year, now.month, now.day);

  final DateTime episodeDate = DateTime(
    airDate.year,
    airDate.month,
    airDate.day,
  );

  return episodeDate.isAfter(today);
}
