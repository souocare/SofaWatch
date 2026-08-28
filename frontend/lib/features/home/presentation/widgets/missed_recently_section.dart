import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/core/widgets/section_failure_card.dart';
import 'package:sofawatch/core/widgets/server_network_image.dart';
import 'package:sofawatch/features/home/application/cubit/home_cubit.dart';
import 'package:sofawatch/features/home/application/cubit/home_state.dart';
import 'package:sofawatch/features/home/application/models/home_watch_source.dart';
import 'package:sofawatch/features/home/presentation/widgets/home_empty_state.dart';
import 'package:sofawatch/features/shows/domain/models/upcoming_item.dart';

class MissedRecentlySection extends StatelessWidget {
  const MissedRecentlySection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (HomeState previous, HomeState current) {
        return previous.missedRecently != current.missedRecently ||
            previous.isLoadingMissedRecently !=
                current.isLoadingMissedRecently ||
            previous.missedRecentlyError != current.missedRecentlyError ||
            previous.updatingEpisodeId != current.updatingEpisodeId ||
            previous.updatingEpisodeSource != current.updatingEpisodeSource;
      },
      builder: (BuildContext context, HomeState state) {
        if (state.isLoadingMissedRecently && state.missedRecently.isEmpty) {
          return const _MissedRecentlyLoading();
        }

        final error = state.missedRecentlyError;

        if (error != null && state.missedRecently.isEmpty) {
          return SectionFailureCard(
            failureKey: 'home-missed-recently-failure',
            error: error,
            onRetry: context.read<HomeCubit>().retryMissedRecently,
          );
        }

        if (state.missedRecently.isEmpty) {
          return const HomeEmptyState(
            emptyStateKey: 'home-missed-recently-empty',
            title: 'Missed Recently',
            subtitle: 'Episodes from the last 14 days',
            message: 'You’re all caught up.',
            icon: Icons.check_circle_outline_rounded,
          );
        }

        return Column(
          key: const ValueKey<String>('home-missed-recently'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Missed Recently',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Episodes from the last 14 days you haven’t watched yet.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            for (
              int index = 0;
              index < state.missedRecently.length;
              index++
            ) ...<Widget>[
              _MissedRecentlyCard(
                item: state.missedRecently[index],
                isUpdating:
                    state.updatingEpisodeSource ==
                        HomeWatchSource.missedRecently &&
                    state.updatingEpisodeId ==
                        state.missedRecently[index].episode.id,
              ),
              if (index < state.missedRecently.length - 1)
                const SizedBox(height: AppSpacing.md),
            ],
          ],
        );
      },
    );
  }
}

class _MissedRecentlyCard extends StatelessWidget {
  const _MissedRecentlyCard({required this.item, required this.isUpdating});

  final UpcomingItem item;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceHigh,
      borderRadius: AppRadius.borderLarge,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey<String>('home-missed-recently-${item.episode.id}'),
        onTap: () {
          context.pushNamed(
            AppRoute.episodeDetails.name,
            pathParameters: <String, String>{'episodeId': item.episode.id},
          );
        },
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: <Widget>[
              _EpisodeArtwork(
                imageUrl: item.episode.stillUrl ?? item.backdropUrl,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.showTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${item.episode.code} • ${item.episode.title}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _formatAirDate(item.episode.airDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _WatchedAction(
                episodeId: item.episode.id,
                isUpdating: isUpdating,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EpisodeArtwork extends StatelessWidget {
  const _EpisodeArtwork({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.borderMedium,
      child: SizedBox(
        width: 104,
        height: 64,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: AppColors.surface),
          child: imageUrl == null
              ? const Center(
                  child: Icon(Icons.tv_outlined, color: AppColors.textMuted),
                )
              : ServerNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                      ) {
                        return const Center(
                          child: Icon(
                            Icons.tv_outlined,
                            color: AppColors.textMuted,
                          ),
                        );
                      },
                ),
        ),
      ),
    );
  }
}

class _WatchedAction extends StatelessWidget {
  const _WatchedAction({required this.episodeId, required this.isUpdating});

  final String episodeId;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    if (isUpdating) {
      return const SizedBox(
        key: ValueKey<String>('home-missed-recently-watched-progress'),
        width: 48,
        height: 48,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return IconButton(
      key: ValueKey<String>('home-missed-recently-mark-watched-$episodeId'),
      tooltip: 'Mark as watched',
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      onPressed: () {
        context.read<HomeCubit>().markEpisodeWatched(
          episodeId: episodeId,
          source: HomeWatchSource.missedRecently,
        );
      },
      icon: const Icon(Icons.check_circle_outline_rounded),
    );
  }
}

class _MissedRecentlyLoading extends StatelessWidget {
  const _MissedRecentlyLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      key: ValueKey<String>('home-missed-recently-loading'),
      height: 96,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

String _formatAirDate(DateTime value) {
  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[value.month - 1]} ${value.day}';
}
