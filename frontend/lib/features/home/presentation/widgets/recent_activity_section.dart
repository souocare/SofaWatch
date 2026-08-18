import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/features/home/application/cubit/home_cubit.dart';
import 'package:sofawatch/features/home/application/cubit/home_state.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_item.dart';
import 'package:sofawatch/features/home/presentation/widgets/home_empty_state.dart';

class RecentActivitySection extends StatelessWidget {
  const RecentActivitySection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (HomeState previous, HomeState current) {
        return previous.recentActivity != current.recentActivity ||
            previous.isLoadingRecentActivity !=
                current.isLoadingRecentActivity ||
            previous.recentActivityError != current.recentActivityError;
      },
      builder: (BuildContext context, HomeState state) {
        if (state.isLoadingRecentActivity && state.recentActivity.isEmpty) {
          return const _RecentActivityLoading();
        }

        if (state.recentActivityError != null && state.recentActivity.isEmpty) {
          return const _RecentActivityFailure();
        }

        if (state.recentActivity.isEmpty) {
          return const HomeEmptyState(
            emptyStateKey: 'home-recent-activity-empty',
            title: 'Recent Activity',
            message: 'Nothing watched recently.',
            icon: Icons.history_rounded,
          );
        }

        return Column(
          key: const ValueKey<String>('home-recent-activity'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Recent Activity',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.md),
            for (
              int index = 0;
              index < state.recentActivity.length;
              index++
            ) ...<Widget>[
              _RecentActivityCard(item: state.recentActivity[index]),
              if (index < state.recentActivity.length - 1)
                const SizedBox(height: AppSpacing.sm),
            ],
          ],
        );
      },
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.item});

  final WatchHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final String watchedAt = _formatWatchedAt(context, item.episode.watchedAt);

    return Material(
      color: AppColors.surfaceHigh,
      borderRadius: AppRadius.borderLarge,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey<String>('home-recent-activity-${item.eventId}'),
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
              _RecentActivityArtwork(
                imageUrl:
                    item.episode.stillUrl ?? item.backdropUrl ?? item.posterUrl,
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
                        if (item.episode.watchCount > 1) ...<Widget>[
                          const SizedBox(width: AppSpacing.sm),
                          const _RewatchBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${item.episode.code} • ${item.episode.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      watchedAt,
                      key: ValueKey<String>(
                        'home-recent-activity-watched-at-${item.eventId}',
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivityArtwork extends StatelessWidget {
  const _RecentActivityArtwork({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.borderMedium,
      child: SizedBox(
        width: 88,
        height: 54,
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

class _RewatchBadge extends StatelessWidget {
  const _RewatchBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('home-recent-activity-rewatch'),
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
        'Rewatch',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RecentActivityLoading extends StatelessWidget {
  const _RecentActivityLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      key: ValueKey<String>('home-recent-activity-loading'),
      height: 96,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _RecentActivityFailure extends StatelessWidget {
  const _RecentActivityFailure();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('home-recent-activity-failure'),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          const Expanded(child: Text('Could not load recent activity.')),
          TextButton(
            key: const ValueKey<String>('home-recent-activity-retry'),
            onPressed: () {
              context.read<HomeCubit>().retryRecentActivity();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

String _formatWatchedAt(BuildContext context, DateTime watchedAt) {
  final DateTime local = watchedAt.toLocal();

  final String date = MaterialLocalizations.of(context).formatMediumDate(local);

  final String time = TimeOfDay.fromDateTime(local).format(context);

  return 'Watched $date • $time';
}
