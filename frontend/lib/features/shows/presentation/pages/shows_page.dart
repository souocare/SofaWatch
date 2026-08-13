import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/app/theme/tokens/app_breakpoints.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/features/shows/application/cubit/shows_cubit.dart';
import 'package:sofawatch/features/shows/application/cubit/shows_state.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_show.dart';
import 'package:sofawatch/features/shows/domain/models/stale_watching_show.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_item.dart';

class ShowsPage extends StatefulWidget {
  const ShowsPage({super.key});

  @override
  State<ShowsPage> createState() {
    return _ShowsPageState();
  }
}

class _ShowsPageState extends State<ShowsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _ShowsHeader(tabController: _tabController),
            Expanded(
              child: BlocBuilder<ShowsCubit, ShowsState>(
                builder: (BuildContext context, ShowsState state) {
                  if (state.isLoading &&
                      state.libraryShows.isEmpty &&
                      state.error == null) {
                    return const _ShowsLoading();
                  }

                  final error = state.error;

                  if (error != null) {
                    return _ShowsFailure(
                      message: error.isTimeout
                          ? 'Loading your shows took too long.'
                          : 'Could not load your shows.',
                      onRetry: context.read<ShowsCubit>().retry,
                    );
                  }

                  return TabBarView(
                    key: const ValueKey<String>('shows-tab-view'),
                    controller: _tabController,
                    children: <Widget>[
                      _WatchListTab(
                        watchNext: state.watchNext,
                        watchNextError: state.watchNextError,
                        staleWatching: state.staleWatching,
                        staleWatchingError: state.staleWatchingError,
                        haventStarted: state.haventStarted,
                        watchHistory: state.watchHistory,
                        hasLoadedWatchHistory: state.hasLoadedWatchHistory,
                        hasMoreWatchHistory: state.hasMoreWatchHistory,
                        isLoadingWatchHistory: state.isLoadingWatchHistory,
                        isLoadingMoreWatchHistory:
                            state.isLoadingMoreWatchHistory,
                        watchHistoryError: state.watchHistoryError,
                      ),
                      const _UpcomingTab(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShowsHeader extends StatelessWidget {
  const _ShowsHeader({required this.tabController});

  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Shows',
            key: const ValueKey<String>('shows-page-title'),
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.lg),
          TabBar(
            key: const ValueKey<String>('shows-tabs'),
            controller: tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            tabs: const <Widget>[
              Tab(
                key: ValueKey<String>('shows-tab-watch-list'),
                text: 'Watch List',
              ),
              Tab(
                key: ValueKey<String>('shows-tab-upcoming'),
                text: 'Upcoming',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WatchListTab extends StatefulWidget {
  const _WatchListTab({
    required this.watchNext,
    required this.watchNextError,
    required this.staleWatching,
    required this.staleWatchingError,
    required this.haventStarted,
    required this.watchHistory,
    required this.hasLoadedWatchHistory,
    required this.hasMoreWatchHistory,
    required this.isLoadingWatchHistory,
    required this.isLoadingMoreWatchHistory,
    required this.watchHistoryError,
  });

  final List<WatchNextShow> watchNext;
  final Object? watchNextError;

  final List<StaleWatchingShow> staleWatching;
  final Object? staleWatchingError;

  final List<LibraryShow> haventStarted;

  final List<WatchHistoryItem> watchHistory;
  final bool hasLoadedWatchHistory;
  final bool hasMoreWatchHistory;
  final bool isLoadingWatchHistory;
  final bool isLoadingMoreWatchHistory;
  final Object? watchHistoryError;

  @override
  State<_WatchListTab> createState() => _WatchListTabState();
}

class _WatchListTabState extends State<_WatchListTab> {
  static const double _loadMoreThreshold = 240;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();

    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final ScrollPosition position = _scrollController.position;

    if (position.extentAfter > _loadMoreThreshold) {
      return;
    }

    final ShowsCubit cubit = context.read<ShowsCubit>();
    final ShowsState state = cubit.state;

    if (state.watchHistoryError != null) {
      return;
    }

    if (!state.hasLoadedWatchHistory) {
      cubit.loadWatchHistory();

      return;
    }

    if (state.hasMoreWatchHistory) {
      cubit.loadMoreWatchHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isDesktop = constraints.maxWidth >= AppBreakpoints.tablet;

        final Set<int> staleTmdbIds = widget.staleWatching
            .map((StaleWatchingShow item) => item.showTmdbId)
            .toSet();

        final List<WatchNextShow> visibleWatchNext = widget.watchNext
            .where(
              (WatchNextShow item) => !staleTmdbIds.contains(item.showTmdbId),
            )
            .toList(growable: false);

        return ListView(
          key: const ValueKey<String>('shows-watch-list'),
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(
            isDesktop ? AppSpacing.xxxl : AppSpacing.xl,
            AppSpacing.sm,
            isDesktop ? AppSpacing.xxxl : AppSpacing.xl,
            AppSpacing.section,
          ),
          children: <Widget>[
            _WatchNextSection(
              items: visibleWatchNext,
              hasError: widget.watchNextError != null,
              onRetry: context.read<ShowsCubit>().retryWatchNext,
              isDesktop: isDesktop,
            ),
            const SizedBox(height: AppSpacing.section),

            _HaventStartedSection(
              items: widget.haventStarted,
              isDesktop: isDesktop,
            ),
            const SizedBox(height: AppSpacing.section),

            _StaleWatchingSection(
              items: widget.staleWatching,
              hasError: widget.staleWatchingError != null,
              onRetry: context.read<ShowsCubit>().retryStaleWatching,
              isDesktop: isDesktop,
            ),
            const SizedBox(height: AppSpacing.section),

            _WatchHistorySection(
              items: widget.watchHistory,
              hasLoaded: widget.hasLoadedWatchHistory,
              hasMore: widget.hasMoreWatchHistory,
              isLoading: widget.isLoadingWatchHistory,
              isLoadingMore: widget.isLoadingMoreWatchHistory,
              hasError: widget.watchHistoryError != null,
              onRetryInitial: context.read<ShowsCubit>().retryWatchHistory,
              onRetryMore: context.read<ShowsCubit>().loadMoreWatchHistory,
              isDesktop: isDesktop,
            ),
          ],
        );
      },
    );
  }
}

class _StaleWatchingSection extends StatelessWidget {
  const _StaleWatchingSection({
    required this.items,
    required this.hasError,
    required this.onRetry,
    required this.isDesktop,
  });

  final List<StaleWatchingShow> items;
  final bool hasError;
  final VoidCallback onRetry;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('shows-stale-watching-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          "Haven't Watched in a While",
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Shows you started but have not continued recently.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (hasError)
          _StaleWatchingFailure(onRetry: onRetry)
        else if (items.isEmpty)
          const _StaleWatchingEmpty()
        else
          ..._buildItems(),
      ],
    );
  }

  List<Widget> _buildItems() {
    final List<Widget> widgets = <Widget>[];

    for (int index = 0; index < items.length; index++) {
      if (index > 0) {
        widgets.add(const SizedBox(height: AppSpacing.md));
      }

      widgets.add(_StaleWatchingRow(item: items[index], isDesktop: isDesktop));
    }

    return widgets;
  }
}

class _StaleWatchingRow extends StatelessWidget {
  const _StaleWatchingRow({required this.item, required this.isDesktop});

  final StaleWatchingShow item;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey<String>('shows-stale-watching-${item.showTmdbId}'),
      color: AppColors.surfaceHigh,
      borderRadius: AppRadius.borderLarge,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.pushNamed(
            AppRoute.showDetails.name,
            pathParameters: <String, String>{
              'showId': item.showTmdbId.toString(),
            },
          );
        },
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _WatchNextPoster(url: item.posterUrl, width: isDesktop ? 72 : 56),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: _StaleWatchingInformation(item: item)),
              const SizedBox(width: AppSpacing.md),
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

class _StaleWatchingInformation extends StatelessWidget {
  const _StaleWatchingInformation({required this.item});

  final StaleWatchingShow item;

  @override
  Widget build(BuildContext context) {
    final episode = item.nextEpisode;

    final List<String> nextEpisodeMetadata = <String>[
      episode.code,
      if (episode.runtime != null) '${episode.runtime} min',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          item.showTitle,
          key: ValueKey<String>(
            'shows-stale-watching-title-${item.showTmdbId}',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _lastWatchedLabel(item.lastWatched.watchedAt),
          key: ValueKey<String>('shows-stale-watching-last-${item.showTmdbId}'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Continue with ${nextEpisodeMetadata.join(' • ')}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          episode.title,
          key: ValueKey<String>(
            'shows-stale-watching-next-title-${episode.id}',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  String _lastWatchedLabel(DateTime watchedAt) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(watchedAt);

    final int days = difference.inDays;

    if (days < 60) {
      return 'Last watched $days days ago';
    }

    if (days < 365) {
      final int months = days ~/ 30;

      return months == 1
          ? 'Last watched 1 month ago'
          : 'Last watched $months months ago';
    }

    final int years = days ~/ 365;

    return years == 1
        ? 'Last watched 1 year ago'
        : 'Last watched $years years ago';
  }
}

class _StaleWatchingEmpty extends StatelessWidget {
  const _StaleWatchingEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey<String>('shows-stale-watching-empty'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Text(
        'No forgotten shows right now.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _StaleWatchingFailure extends StatelessWidget {
  const _StaleWatchingFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey<String>('shows-stale-watching-failure'),
      decoration: const BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: <Widget>[
            const Icon(Icons.error_outline_rounded, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                "Could not load Haven't Watched in a While.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            TextButton(
              key: const ValueKey<String>('shows-stale-watching-retry'),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchNextSection extends StatelessWidget {
  const _WatchNextSection({
    required this.items,
    required this.hasError,
    required this.onRetry,
    required this.isDesktop,
  });

  final List<WatchNextShow> items;
  final bool hasError;
  final VoidCallback onRetry;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('shows-watch-next-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Watch Next',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (hasError)
          _WatchNextFailure(onRetry: onRetry)
        else if (items.isEmpty)
          const _WatchNextEmpty()
        else
          ..._buildItems(),
      ],
    );
  }

  List<Widget> _buildItems() {
    final List<Widget> widgets = <Widget>[];

    for (int index = 0; index < items.length; index++) {
      if (index > 0) {
        widgets.add(const SizedBox(height: AppSpacing.md));
      }

      widgets.add(_WatchNextRow(item: items[index], isDesktop: isDesktop));
    }

    return widgets;
  }
}

class _WatchNextRow extends StatelessWidget {
  const _WatchNextRow({required this.item, required this.isDesktop});

  final WatchNextShow item;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final episode = item.nextEpisode;

    return Material(
      key: ValueKey<String>('shows-watch-next-${item.showTmdbId}'),
      color: AppColors.surfaceHigh,
      borderRadius: AppRadius.borderLarge,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.pushNamed(
            AppRoute.showDetails.name,
            pathParameters: <String, String>{
              'showId': item.showTmdbId.toString(),
            },
          );
        },
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _WatchNextPoster(url: item.posterUrl, width: isDesktop ? 72 : 56),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: _WatchNextInformation(item: item)),
              const SizedBox(width: AppSpacing.md),
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

class _WatchNextInformation extends StatelessWidget {
  const _WatchNextInformation({required this.item});

  final WatchNextShow item;

  @override
  Widget build(BuildContext context) {
    final episode = item.nextEpisode;

    final List<String> metadata = <String>[
      episode.code,
      if (episode.runtime != null) '${episode.runtime} min',
      if (episode.airDate != null)
        MaterialLocalizations.of(context).formatMediumDate(episode.airDate!),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          item.showTitle,
          key: ValueKey<String>('shows-watch-next-title-${item.showTmdbId}'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          episode.title,
          key: ValueKey<String>('shows-watch-next-episode-title-${episode.id}'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          metadata.join(' • '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _WatchNextPoster extends StatelessWidget {
  const _WatchNextPoster({required this.url, required this.width});

  final String? url;
  final double width;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.borderMedium,
      child: SizedBox(
        width: width,
        child: AspectRatio(aspectRatio: 2 / 3, child: _buildImage()),
      ),
    );
  }

  Widget _buildImage() {
    final String? imageUrl = url;

    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return const ColoredBox(
        color: AppColors.surfaceLow,
        child: Center(
          child: Icon(Icons.tv_rounded, color: AppColors.textMuted),
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
            return const ColoredBox(
              color: AppColors.surfaceLow,
              child: Center(
                child: Icon(Icons.tv_rounded, color: AppColors.textMuted),
              ),
            );
          },
    );
  }
}

class _WatchNextEmpty extends StatelessWidget {
  const _WatchNextEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey<String>('shows-watch-next-empty'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Text(
        'You are all caught up.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _WatchNextFailure extends StatelessWidget {
  const _WatchNextFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey<String>('shows-watch-next-failure'),
      decoration: const BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: <Widget>[
            const Icon(Icons.error_outline_rounded, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Could not load Watch Next.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            TextButton(
              key: const ValueKey<String>('shows-watch-next-retry'),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchHistorySection extends StatelessWidget {
  const _WatchHistorySection({
    required this.items,
    required this.hasLoaded,
    required this.hasMore,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasError,
    required this.onRetryInitial,
    required this.onRetryMore,
    required this.isDesktop,
  });

  final List<WatchHistoryItem> items;

  final bool hasLoaded;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasError;

  final VoidCallback onRetryInitial;
  final VoidCallback onRetryMore;

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('shows-watch-history-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Watch History',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Episodes you have watched, from newest to oldest.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),

        if (!hasLoaded && isLoading)
          const _WatchHistoryLoading()
        else if (!hasLoaded && hasError)
          _WatchHistoryFailure(onRetry: onRetryInitial)
        else if (!hasLoaded)
          const _WatchHistoryNotLoaded()
        else if (items.isEmpty)
          const _WatchHistoryEmpty()
        else ...<Widget>[
          ..._buildItems(),
          const SizedBox(height: AppSpacing.lg),
          if (isLoadingMore)
            const _WatchHistoryLoadingMore()
          else if (hasError)
            _WatchHistoryLoadMoreFailure(onRetry: onRetryMore)
          else if (!hasMore)
            const _WatchHistoryEnd(),
        ],
      ],
    );
  }

  List<Widget> _buildItems() {
    final List<Widget> widgets = <Widget>[];

    for (int index = 0; index < items.length; index++) {
      if (index > 0) {
        widgets.add(const SizedBox(height: AppSpacing.md));
      }

      widgets.add(_WatchHistoryRow(item: items[index], isDesktop: isDesktop));
    }

    return widgets;
  }
}

class _WatchHistoryRow extends StatelessWidget {
  const _WatchHistoryRow({required this.item, required this.isDesktop});

  final WatchHistoryItem item;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final episode = item.episode;

    return Material(
      key: ValueKey<String>('shows-watch-history-${episode.id}'),
      color: AppColors.surfaceHigh,
      borderRadius: AppRadius.borderLarge,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.pushNamed(
            AppRoute.showDetails.name,
            pathParameters: <String, String>{
              'showId': item.showTmdbId.toString(),
            },
          );
        },
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _WatchNextPoster(url: item.posterUrl, width: isDesktop ? 72 : 56),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: _WatchHistoryInformation(item: item)),
              const SizedBox(width: AppSpacing.md),
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

class _WatchHistoryInformation extends StatelessWidget {
  const _WatchHistoryInformation({required this.item});

  final WatchHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final episode = item.episode;

    final List<String> metadata = <String>[
      episode.code,
      if (episode.runtime != null) '${episode.runtime} min',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          item.showTitle,
          key: ValueKey<String>('shows-watch-history-title-${episode.id}'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          episode.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          metadata.join(' • '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Watched ${MaterialLocalizations.of(context).formatMediumDate(episode.watchedAt)}',
          key: ValueKey<String>('shows-watch-history-date-${episode.id}'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _WatchHistoryNotLoaded extends StatelessWidget {
  const _WatchHistoryNotLoaded();

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey<String>('shows-watch-history-not-loaded'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Text(
        'Scroll down to load your Watch History.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _WatchHistoryLoading extends StatelessWidget {
  const _WatchHistoryLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: ValueKey<String>('shows-watch-history-loading'),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _WatchHistoryLoadingMore extends StatelessWidget {
  const _WatchHistoryLoadingMore();

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: ValueKey<String>('shows-watch-history-loading-more'),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _WatchHistoryEmpty extends StatelessWidget {
  const _WatchHistoryEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey<String>('shows-watch-history-empty'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Text(
        'No watched episodes yet.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _WatchHistoryFailure extends StatelessWidget {
  const _WatchHistoryFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _WatchHistoryErrorCard(
      cardKey: const ValueKey<String>('shows-watch-history-failure'),
      message: 'Could not load Watch History.',
      buttonKey: const ValueKey<String>('shows-watch-history-retry'),
      onRetry: onRetry,
    );
  }
}

class _WatchHistoryLoadMoreFailure extends StatelessWidget {
  const _WatchHistoryLoadMoreFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _WatchHistoryErrorCard(
      cardKey: const ValueKey<String>('shows-watch-history-load-more-failure'),
      message: 'Could not load older history.',
      buttonKey: const ValueKey<String>('shows-watch-history-load-more-retry'),
      onRetry: onRetry,
    );
  }
}

class _WatchHistoryErrorCard extends StatelessWidget {
  const _WatchHistoryErrorCard({
    required this.cardKey,
    required this.message,
    required this.buttonKey,
    required this.onRetry,
  });

  final Key cardKey;
  final String message;
  final Key buttonKey;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: cardKey,
      decoration: const BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: <Widget>[
            const Icon(Icons.error_outline_rounded, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            TextButton(
              key: buttonKey,
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchHistoryEnd extends StatelessWidget {
  const _WatchHistoryEnd();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey<String>('shows-watch-history-end'),
      child: Text(
        'That is your complete Watch History.',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
      ),
    );
  }
}

class _UpcomingTab extends StatelessWidget {
  const _UpcomingTab();

  @override
  Widget build(BuildContext context) {
    return const _ShowsEmpty(
      key: ValueKey<String>('shows-upcoming-empty'),
      title: 'No upcoming episodes',
      message: 'Upcoming episodes from your shows will appear here.',
    );
  }
}

class _ShowsLoading extends StatelessWidget {
  const _ShowsLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: ValueKey<String>('shows-loading'),
      child: CircularProgressIndicator(),
    );
  }
}

class _ShowsEmpty extends StatelessWidget {
  const _ShowsEmpty({required this.title, required this.message, super.key});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.cardPaddingLarge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.tv_off_rounded,
              size: 42,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShowsFailure extends StatelessWidget {
  const _ShowsFailure({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey<String>('shows-failure'),
      child: Padding(
        padding: AppSpacing.cardPaddingLarge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Please try again.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              key: const ValueKey<String>('shows-retry'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HaventStartedSection extends StatelessWidget {
  const _HaventStartedSection({required this.items, required this.isDesktop});

  final List<LibraryShow> items;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('shows-havent-started-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          "Haven't Started",
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Shows in your Watchlist that you have not started yet.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (items.isEmpty) const _HaventStartedEmpty() else ..._buildItems(),
      ],
    );
  }

  List<Widget> _buildItems() {
    final List<Widget> widgets = <Widget>[];

    for (int index = 0; index < items.length; index++) {
      if (index > 0) {
        widgets.add(const SizedBox(height: AppSpacing.md));
      }

      widgets.add(_HaventStartedRow(show: items[index], isDesktop: isDesktop));
    }

    return widgets;
  }
}

class _HaventStartedRow extends StatelessWidget {
  const _HaventStartedRow({required this.show, required this.isDesktop});

  final LibraryShow show;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey<String>('shows-havent-started-${show.tmdbId}'),
      color: AppColors.surfaceHigh,
      borderRadius: AppRadius.borderLarge,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.pushNamed(
            AppRoute.showDetails.name,
            pathParameters: <String, String>{'showId': show.tmdbId.toString()},
          );
        },
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _WatchNextPoster(url: show.posterUrl, width: isDesktop ? 72 : 56),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: _HaventStartedInformation(show: show)),
              const SizedBox(width: AppSpacing.md),
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

class _HaventStartedInformation extends StatelessWidget {
  const _HaventStartedInformation({required this.show});

  final LibraryShow show;

  @override
  Widget build(BuildContext context) {
    final List<String> metadata = <String>[
      if (show.firstAirDate != null) show.firstAirDate!.year.toString(),
      if (show.voteAverage > 0) show.voteAverage.toStringAsFixed(1),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          show.title,
          key: ValueKey<String>('shows-havent-started-title-${show.tmdbId}'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (metadata.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            metadata.join(' • '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Not started yet',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _HaventStartedEmpty extends StatelessWidget {
  const _HaventStartedEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey<String>('shows-havent-started-empty'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Text(
        'No unstarted shows in your Watchlist.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
