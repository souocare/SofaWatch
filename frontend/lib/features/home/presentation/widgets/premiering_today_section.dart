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
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/shows/domain/models/upcoming_item.dart';

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
            _PremieringTodayCarousel(
              items: state.premieringToday,
              updatingEpisodeId: state.updatingEpisodeId,
              updatingEpisodeSource: state.updatingEpisodeSource,
            ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Material(
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
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _EpisodeArtwork(
                imageUrl: item.episode.stillUrl ?? item.backdropUrl,
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
                    '${_formatEpisodeCode(item.episode.code)} • '
                    '${item.episode.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (isPlanning) ...<Widget>[
                    const SizedBox(height: AppSpacing.sm),
                    const _PlanningBadge(),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _WatchedAction(item: item, isUpdating: isUpdating),
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
      icon: const Icon(Icons.circle_outlined),
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

class _PremieringTodayCarousel extends StatefulWidget {
  const _PremieringTodayCarousel({
    required this.items,
    required this.updatingEpisodeId,
    required this.updatingEpisodeSource,
  });

  final List<UpcomingItem> items;
  final String? updatingEpisodeId;
  final HomeWatchSource? updatingEpisodeSource;

  @override
  State<_PremieringTodayCarousel> createState() =>
      _PremieringTodayCarouselState();
}

class _PremieringTodayCarouselState extends State<_PremieringTodayCarousel> {
  static const double _mobileViewportFraction = 0.86;
  static const double _artworkAspectRatio = 16 / 9;

  /*
   * Planning cards contain an additional badge below the Episode metadata,
   * so the carousel must reserve enough vertical space for the tallest card.
   */
  static const double _standardMetadataHeight = 64;
  static const double _planningMetadataHeight = 96;

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(viewportFraction: _mobileViewportFraction);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double cardWidth = constraints.maxWidth * _mobileViewportFraction;

        final double artworkHeight = cardWidth / _artworkAspectRatio;

        final bool hasPlanningItem = widget.items.any(
          (UpcomingItem item) => item.libraryStatus == LibraryStatus.planning,
        );

        final double metadataHeight = hasPlanningItem
            ? _planningMetadataHeight
            : _standardMetadataHeight;

        final double carouselHeight =
            artworkHeight + AppSpacing.sm + metadataHeight;

        return SizedBox(
          height: carouselHeight,
          child: PageView.builder(
            key: const ValueKey<String>('home-premiering-today-carousel'),
            controller: _pageController,
            padEnds: false,
            physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
            itemCount: widget.items.length,
            itemBuilder: (BuildContext context, int index) {
              final UpcomingItem item = widget.items[index];

              return Padding(
                padding: EdgeInsets.only(
                  right: index < widget.items.length - 1
                      ? AppSpacing.md
                      : AppSpacing.none,
                ),
                child: _PremieringTodayCard(
                  item: item,
                  isUpdating:
                      widget.updatingEpisodeSource ==
                          HomeWatchSource.premieringToday &&
                      widget.updatingEpisodeId == item.episode.id,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

String _formatEpisodeCode(String value) {
  return value.replaceFirstMapped(
    RegExp(r'^(S\d+)(E\d+)$'),
    (Match match) => '${match.group(1)} ${match.group(2)}',
  );
}
