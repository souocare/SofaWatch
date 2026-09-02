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

        final error = state.continueWatchingError;

        if (error != null && state.continueWatching.isEmpty) {
          return SectionFailureCard(
            failureKey: 'home-continue-watching-failure',
            error: error,
            onRetry: context.read<HomeCubit>().retryContinueWatching,
          );
        }

        if (state.continueWatching.isEmpty) {
          return const HomeEmptyState(
            emptyStateKey: 'home-continue-watching-empty',
            title: 'Continue Watching',
            message: 'Nothing to continue right now.',
            icon: Icons.play_circle_outline_rounded,
          );
        }

        return Column(
          key: const ValueKey<String>('home-continue-watching'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Continue Watching',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  key: const ValueKey<String>('home-continue-watching-see-all'),
                  onPressed: () {
                    context.goNamed(AppRoute.shows.name);
                  },
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            _ContinueWatchingCarousel(
              items: state.continueWatching,
              updatingEpisodeId: state.updatingEpisodeId,
              updatingEpisodeSource: state.updatingEpisodeSource,
            ),
          ],
        );
      },
    );
  }
}

class _ContinueWatchingCarousel extends StatefulWidget {
  const _ContinueWatchingCarousel({
    required this.items,
    required this.updatingEpisodeId,
    required this.updatingEpisodeSource,
  });

  final List<WatchNextShow> items;
  final String? updatingEpisodeId;
  final HomeWatchSource? updatingEpisodeSource;

  @override
  State<_ContinueWatchingCarousel> createState() =>
      _ContinueWatchingCarouselState();
}

class _ContinueWatchingCarouselState extends State<_ContinueWatchingCarousel> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(viewportFraction: 0.86);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: PageView.builder(
        key: const ValueKey<String>('home-continue-watching-carousel'),
        controller: _pageController,
        padEnds: false,
        physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
        itemCount: widget.items.length,
        itemBuilder: (BuildContext context, int index) {
          final WatchNextShow item = widget.items[index];

          return Padding(
            padding: EdgeInsets.only(
              right: index < widget.items.length - 1
                  ? AppSpacing.md
                  : AppSpacing.none,
            ),
            child: _ContinueWatchingCard(
              item: item,
              isUpdating:
                  widget.updatingEpisodeSource ==
                      HomeWatchSource.continueWatching &&
                  widget.updatingEpisodeId == item.nextEpisode.id,
            ),
          );
        },
      ),
    );
  }
}

class _ContinueWatchingCard extends StatelessWidget {
  const _ContinueWatchingCard({required this.item, required this.isUpdating});

  final WatchNextShow item;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Material(
          color: AppColors.surfaceHigh,
          borderRadius: AppRadius.borderLarge,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey<String>(
              'home-continue-watching-${item.nextEpisode.id}',
            ),
            onTap: () {
              context.pushNamed(
                AppRoute.episodeDetails.name,
                pathParameters: <String, String>{
                  'episodeId': item.nextEpisode.id,
                },
              );
            },
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _EpisodeArtwork(
                    imageUrl: item.nextEpisode.stillUrl ?? item.backdropUrl,
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadius.borderFull,
                        child: LinearProgressIndicator(
                          value: item.progress.percentage / 100,
                          minHeight: 6,
                          backgroundColor: AppColors.progressTrack,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.progressValue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
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
                    '${_formatEpisodeCode(item.nextEpisode.code)} • '
                    '${item.nextEpisode.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (isUpdating)
              const SizedBox(
                key: ValueKey<String>('home-continue-watching-progress'),
                width: 40,
                height: 40,
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              IconButton(
                key: ValueKey<String>(
                  'home-continue-watching-mark-watched-'
                  '${item.nextEpisode.id}',
                ),
                tooltip: 'Mark as watched',
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: EdgeInsets.zero,
                onPressed: () {
                  context.read<HomeCubit>().markContinueWatchingEpisodeWatched(
                    episodeId: item.nextEpisode.id,
                  );
                },
                icon: const Icon(Icons.circle_outlined, size: 30),
              ),
          ],
        ),
      ],
    );
  }
}

class _EpisodeArtwork extends StatelessWidget {
  const _EpisodeArtwork({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.surface),
      child: imageUrl == null
          ? const Center(
              child: Icon(
                Icons.tv_outlined,
                size: 48,
                color: AppColors.textMuted,
              ),
            )
          : ServerNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.tv_outlined,
                        size: 48,
                        color: AppColors.textMuted,
                      ),
                    );
                  },
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

String _formatEpisodeCode(String value) {
  return value.replaceFirstMapped(
    RegExp(r'^(S\d+)(E\d+)$'),
    (Match match) => '${match.group(1)} ${match.group(2)}',
  );
}
