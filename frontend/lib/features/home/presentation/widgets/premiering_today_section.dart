import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/features/home/application/cubit/home_cubit.dart';
import 'package:sofawatch/features/home/application/cubit/home_state.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/shows/domain/models/upcoming_item.dart';
import 'package:sofawatch/features/home/application/models/home_watch_source.dart';
import 'package:sofawatch/features/home/presentation/widgets/home_empty_state.dart';
import 'package:sofawatch/core/widgets/section_failure_card.dart';

class PremieringTodaySection extends StatelessWidget {
  const PremieringTodaySection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (HomeState previous, HomeState current) {
        return previous.premieringToday != current.premieringToday ||
            previous.isLoadingPremieringToday !=
                current.isLoadingPremieringToday ||
            previous.premieringTodayError != current.premieringTodayError ||
            previous.updatingEpisodeId != current.updatingEpisodeId ||
            previous.updatingEpisodeSource != current.updatingEpisodeSource;
      },
      builder: (BuildContext context, HomeState state) {
        if (state.isLoadingPremieringToday && state.premieringToday.isEmpty) {
          return const _PremieringTodayLoading();
        }

        final error = state.premieringTodayError;

        if (error != null && state.premieringToday.isEmpty) {
          return SectionFailureCard(
            failureKey: 'home-premiering-today-failure',
            error: error,
            onRetry: context.read<HomeCubit>().retryPremieringToday,
          );
        }

        if (state.premieringToday.isEmpty) {
          return const HomeEmptyState(
            emptyStateKey: 'home-premiering-today-empty',
            title: 'Premiering Today',
            message: 'Nothing from your library is premiering today.',
            icon: Icons.today_outlined,
          );
        }

        return Column(
          key: const ValueKey<String>('home-premiering-today'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Premiering Today',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.md),
            for (
              int index = 0;
              index < state.premieringToday.length;
              index++
            ) ...<Widget>[
              _PremieringTodayCard(
                item: state.premieringToday[index],
                isUpdating:
                    state.updatingEpisodeSource ==
                        HomeWatchSource.premieringToday &&
                    state.updatingEpisodeId ==
                        state.premieringToday[index].episode.id,
              ),
              if (index < state.premieringToday.length - 1)
                const SizedBox(height: AppSpacing.md),
            ],
          ],
        );
      },
    );
  }
}

class _PremieringTodayCard extends StatelessWidget {
  const _PremieringTodayCard({required this.item, required this.isUpdating});

  final UpcomingItem item;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    final bool isPlanning = item.libraryStatus == LibraryStatus.planning;

    return Material(
      color: AppColors.surfaceHigh,
      borderRadius: AppRadius.borderLarge,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey<String>('home-premiering-today-${item.episode.id}'),
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
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            item.showTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (isPlanning) ...<Widget>[
                          const SizedBox(width: AppSpacing.sm),
                          const _PlanningBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${item.episode.code} • ${item.episode.title}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (isPlanning) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'You haven’t started this show yet',
                        key: ValueKey<String>(
                          'home-premiering-today-not-started-'
                          '${item.episode.id}',
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _WatchedAction(item: item, isUpdating: isUpdating),
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
              : Image.network(
                  imageUrl!,
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
  const _WatchedAction({required this.item, required this.isUpdating});

  final UpcomingItem item;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    if (isUpdating) {
      return const SizedBox(
        key: ValueKey<String>('home-premiering-today-watched-progress'),
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

    if (item.episode.isWatched) {
      return IconButton(
        key: ValueKey<String>(
          'home-premiering-today-watched-${item.episode.id}',
        ),
        tooltip: 'Watched',
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        onPressed: null,
        icon: const Icon(
          Icons.check_circle_rounded,
          color: AppColors.primarySoft,
        ),
      );
    }

    return IconButton(
      key: ValueKey<String>(
        'home-premiering-today-mark-watched-${item.episode.id}',
      ),
      tooltip: 'Mark as watched',
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      onPressed: () {
        context.read<HomeCubit>().markPremieringTodayEpisodeWatched(
          episodeId: item.episode.id,
        );
      },
      icon: const Icon(Icons.check_circle_outline_rounded),
    );
  }
}

class _PlanningBadge extends StatelessWidget {
  const _PlanningBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('home-premiering-today-planning-badge'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderFull,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Text(
        'Not started',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PremieringTodayLoading extends StatelessWidget {
  const _PremieringTodayLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      key: ValueKey<String>('home-premiering-today-loading'),
      height: 96,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _PremieringTodayFailure extends StatelessWidget {
  const _PremieringTodayFailure();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('home-premiering-today-failure'),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          const Expanded(child: Text('Could not load today’s premieres.')),
          TextButton(
            key: const ValueKey<String>('home-premiering-today-retry'),
            onPressed: () {
              context.read<HomeCubit>().retryPremieringToday();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
