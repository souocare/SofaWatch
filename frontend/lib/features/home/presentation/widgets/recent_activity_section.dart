import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/core/widgets/section_failure_card.dart';
import 'package:sofawatch/core/widgets/server_network_image.dart';
import 'package:sofawatch/features/history/domain/models/history_episode_item.dart';
import 'package:sofawatch/features/history/domain/models/history_item.dart';
import 'package:sofawatch/features/history/domain/models/history_movie_item.dart';
import 'package:sofawatch/features/home/application/cubit/home_cubit.dart';
import 'package:sofawatch/features/home/application/cubit/home_state.dart';
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

        final error = state.recentActivityError;

        if (error != null && state.recentActivity.isEmpty) {
          return SectionFailureCard(
            failureKey: 'home-recent-activity-failure',
            error: error,
            onRetry: context.read<HomeCubit>().retryRecentActivity,
          );
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
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  key: const ValueKey<String>('home-recent-activity-see-all'),
                  onPressed: () {
                    context.goNamed(AppRoute.history.name);
                  },
                  child: const Text('See All'),
                ),
              ],
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

  final HistoryItem item;

  @override
  Widget build(BuildContext context) {
    return switch (item) {
      final HistoryEpisodeItem episodeItem => _RecentEpisodeActivityCard(
        item: episodeItem,
      ),
      final HistoryMovieItem movieItem => _RecentMovieActivityCard(
        item: movieItem,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _RecentEpisodeActivityCard extends StatelessWidget {
  const _RecentEpisodeActivityCard({required this.item});

  final HistoryEpisodeItem item;

  @override
  Widget build(BuildContext context) {
    final String watchedAt = _formatWatchedAt(context, item.watchedAt);

    return Material(
      color: AppColors.surfaceSubtle,
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              _RecentActivityArtwork(
                imageUrl:
                    item.episode.stillUrl ?? item.backdropUrl ?? item.posterUrl,
                fallbackIcon: Icons.tv_outlined,
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
                      '${_formatEpisodeCode(item.episode.code)} • '
                      '${item.episode.title}',
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
                size: 20,
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
  const _RecentActivityArtwork({
    required this.imageUrl,
    required this.fallbackIcon,
  });

  final String? imageUrl;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.borderMedium,
      child: SizedBox(
        width: 96,
        height: 54,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: AppColors.surface),
          child: imageUrl == null
              ? Center(child: Icon(fallbackIcon, color: AppColors.textMuted))
              : ServerNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                      ) {
                        return Center(
                          child: Icon(fallbackIcon, color: AppColors.textMuted),
                        );
                      },
                ),
        ),
      ),
    );
  }
}

class _RecentMovieActivityCard extends StatelessWidget {
  const _RecentMovieActivityCard({required this.item});

  final HistoryMovieItem item;

  @override
  Widget build(BuildContext context) {
    final String watchedAt = _formatWatchedAt(context, item.watchedAt);

    return Material(
      color: AppColors.surfaceSubtle,
      borderRadius: AppRadius.borderLarge,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey<String>('home-recent-activity-${item.eventId}'),
        onTap: () {
          context.pushNamed(
            AppRoute.movieDetails.name,
            pathParameters: <String, String>{'movieId': item.movieId},
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              _RecentActivityArtwork(
                imageUrl: item.backdropUrl ?? item.posterUrl,
                fallbackIcon: Icons.movie_outlined,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.movieTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Movie',
                      key: ValueKey<String>(
                        'home-recent-activity-movie-${item.eventId}',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
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
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
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

String _formatWatchedAt(BuildContext context, DateTime watchedAt) {
  final DateTime local = watchedAt.toLocal();

  final String date = MaterialLocalizations.of(context).formatMediumDate(local);

  final String time = TimeOfDay.fromDateTime(local).format(context);

  return 'Watched $date • $time';
}

String _formatEpisodeCode(String value) {
  return value.replaceFirstMapped(
    RegExp(r'^(S\d+)(E\d+)$'),
    (Match match) => '${match.group(1)} ${match.group(2)}',
  );
}
