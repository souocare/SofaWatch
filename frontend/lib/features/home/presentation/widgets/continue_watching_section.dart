import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/features/home/application/cubit/home_cubit.dart';
import 'package:sofawatch/features/home/application/cubit/home_state.dart';
import 'package:sofawatch/features/home/application/models/home_watch_source.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_show.dart';

class ContinueWatchingSection extends StatelessWidget {
  const ContinueWatchingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (HomeState previous, HomeState current) {
        return previous.continueWatching != current.continueWatching ||
            previous.isLoadingContinueWatching !=
                current.isLoadingContinueWatching ||
            previous.continueWatchingError != current.continueWatchingError ||
            previous.updatingEpisodeId != current.updatingEpisodeId ||
            previous.updatingEpisodeSource != current.updatingEpisodeSource;
      },
      builder: (BuildContext context, HomeState state) {
        if (state.isLoadingContinueWatching && state.continueWatching.isEmpty) {
          return const _ContinueWatchingLoading();
        }

        if (state.continueWatchingError != null &&
            state.continueWatching.isEmpty) {
          return const _ContinueWatchingFailure();
        }

        if (state.continueWatching.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          key: const ValueKey<String>('home-continue-watching'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Continue Watching',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.md),

            for (
              int index = 0;
              index < state.continueWatching.length;
              index++
            ) ...<Widget>[
              _ContinueWatchingCard(
                item: state.continueWatching[index],
                isUpdating:
                    state.updatingEpisodeSource ==
                        HomeWatchSource.continueWatching &&
                    state.updatingEpisodeId ==
                        state.continueWatching[index].nextEpisode.id,
              ),
              if (index < state.continueWatching.length - 1)
                const SizedBox(height: AppSpacing.md),
            ],
          ],
        );
      },
    );
  }
}

class _ContinueWatchingCard extends StatelessWidget {
  const _ContinueWatchingCard({required this.item, required this.isUpdating});

  final WatchNextShow item;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceHigh,
      borderRadius: AppRadius.borderLarge,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey<String>('home-continue-watching-${item.nextEpisode.id}'),
        onTap: () {
          context.pushNamed(
            AppRoute.episodeDetails.name,
            pathParameters: <String, String>{'episodeId': item.nextEpisode.id},
          );
        },
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: <Widget>[
              _EpisodeArtwork(
                imageUrl: item.nextEpisode.stillUrl ?? item.backdropUrl,
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
                      '${item.nextEpisode.code} • '
                      '${item.nextEpisode.title}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    ClipRRect(
                      borderRadius: AppRadius.borderFull,
                      child: LinearProgressIndicator(
                        value: item.progress.percentage / 100,
                        minHeight: 4,
                        backgroundColor: AppColors.surface,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    Text(
                      '${item.progress.watchedEpisodes} of '
                      '${item.progress.airedEpisodes} episodes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              if (isUpdating)
                const SizedBox(
                  key: ValueKey<String>('home-continue-watching-progress'),
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  key: ValueKey<String>(
                    'home-continue-watching-mark-watched-'
                    '${item.nextEpisode.id}',
                  ),
                  tooltip: 'Mark as watched',
                  onPressed: () {
                    context
                        .read<HomeCubit>()
                        .markContinueWatchingEpisodeWatched(
                          episodeId: item.nextEpisode.id,
                        );
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded),
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

class _ContinueWatchingLoading extends StatelessWidget {
  const _ContinueWatchingLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      key: ValueKey<String>('home-continue-watching-loading'),
      height: 96,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ContinueWatchingFailure extends StatelessWidget {
  const _ContinueWatchingFailure();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('home-continue-watching-failure'),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          const Expanded(child: Text('Could not load Continue Watching.')),
          TextButton(
            key: const ValueKey<String>('home-continue-watching-retry'),
            onPressed: () {
              context.read<HomeCubit>().retryContinueWatching();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
