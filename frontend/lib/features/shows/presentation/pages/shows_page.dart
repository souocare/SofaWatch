import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/app/theme/tokens/app_breakpoints.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/shows/application/cubit/shows_cubit.dart';
import 'package:sofawatch/features/shows/application/cubit/shows_state.dart';
import 'package:sofawatch/features/shows/domain/models/stale_watching_episode.dart';
import 'package:sofawatch/features/shows/domain/models/upcoming_item.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_episode.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_show.dart';
import 'package:sofawatch/features/shows/domain/models/stale_watching_show.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_item.dart';
import 'package:sofawatch/features/shows/domain/models/library_first_episode.dart';

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
            BlocBuilder<ShowsCubit, ShowsState>(
              buildWhen: (ShowsState previous, ShowsState current) {
                return previous.isRefreshing != current.isRefreshing;
              },
              builder: (BuildContext context, ShowsState state) {
                return _ShowsHeader(
                  tabController: _tabController,
                  isRefreshing: state.isRefreshing,
                  onRefresh: context.read<ShowsCubit>().refresh,
                );
              },
            ),
            Expanded(
              child: BlocConsumer<ShowsCubit, ShowsState>(
                listenWhen: (ShowsState previous, ShowsState current) {
                  final bool watchNextFailed =
                      previous.watchNextOperationError !=
                          current.watchNextOperationError &&
                      current.watchNextOperationError != null;

                  final bool watchHistoryFailed =
                      previous.watchHistoryOperationError !=
                          current.watchHistoryOperationError &&
                      current.watchHistoryOperationError != null;

                  final bool startShowFailed =
                      previous.startShowError != current.startShowError &&
                      current.startShowError != null;

                  final bool upcomingFailed =
                      previous.upcomingOperationError !=
                          current.upcomingOperationError &&
                      current.upcomingOperationError != null;

                  final bool refreshFailed =
                      previous.refreshError != current.refreshError &&
                      current.refreshError != null;

                  return refreshFailed ||
                      watchNextFailed ||
                      watchHistoryFailed ||
                      startShowFailed ||
                      upcomingFailed;
                },
                listener: (BuildContext context, ShowsState state) {
                  final AppException? refreshError = state.refreshError;

                  if (refreshError != null) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(
                            refreshError.isTimeout
                                ? 'Refreshing your shows took too long.'
                                : 'Could not refresh all show data.',
                          ),
                        ),
                      );

                    return;
                  }
                  final AppException? upcomingOperationError =
                      state.upcomingOperationError;

                  if (upcomingOperationError != null) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(
                            upcomingOperationError.isTimeout
                                ? 'Marking the episode as watched took too long.'
                                : 'Could not mark this episode as watched.',
                          ),
                        ),
                      );

                    return;
                  }
                  final AppException? startShowError = state.startShowError;

                  if (startShowError != null) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(
                            startShowError.isTimeout
                                ? 'Starting the show took too long.'
                                : 'Could not start this show.',
                          ),
                        ),
                      );

                    return;
                  }

                  final AppException? watchHistoryError =
                      state.watchHistoryOperationError;
                  if (watchHistoryError != null) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(
                            watchHistoryError.isTimeout
                                ? 'Updating Watch History took too long.'
                                : 'Could not update Watch History.',
                          ),
                        ),
                      );
                    return;
                  }

                  final AppException? watchNextError =
                      state.watchNextOperationError;

                  if (watchNextError == null) {
                    return;
                  }

                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(
                          watchNextError.isTimeout
                              ? 'Marking the episode as watched took too long.'
                              : 'Could not mark the episode as watched.',
                        ),
                      ),
                    );
                },
                builder: (BuildContext context, ShowsState state) {
                  if (state.isLoading &&
                      state.libraryShows.isEmpty &&
                      state.error == null) {
                    return const _ShowsLoading();
                  }

                  final AppException? error = state.error;

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
                        upToDate: state.upToDate,
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
                        updatingWatchNextEpisodeId:
                            state.updatingWatchNextEpisodeId,
                        startingShowId: state.startingShowId,
                        updatingWatchHistoryEventId:
                            state.updatingWatchHistoryEventId,
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
  const _ShowsHeader({
    required this.tabController,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final TabController tabController;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;

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
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Shows',
                  key: const ValueKey<String>('shows-page-title'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              if (isDesktop)
                _DesktopRefreshButton(
                  isRefreshing: isRefreshing,
                  onRefresh: onRefresh,
                )
              else
                _MobileRefreshButton(
                  isRefreshing: isRefreshing,
                  onRefresh: onRefresh,
                ),
            ],
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

class _DesktopRefreshButton extends StatelessWidget {
  const _DesktopRefreshButton({
    required this.isRefreshing,
    required this.onRefresh,
  });

  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      key: const ValueKey<String>('shows-refresh-desktop'),
      onPressed: isRefreshing
          ? null
          : () {
              onRefresh();
            },
      icon: isRefreshing
          ? const SizedBox(
              key: ValueKey<String>('shows-refresh-progress'),
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh_rounded),
      label: Text(isRefreshing ? 'Refreshing…' : 'Refresh'),
    );
  }
}

class _MobileRefreshButton extends StatelessWidget {
  const _MobileRefreshButton({
    required this.isRefreshing,
    required this.onRefresh,
  });

  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: isRefreshing
          ? const Center(
              key: ValueKey<String>('shows-refresh-mobile-progress'),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : IconButton(
              key: const ValueKey<String>('shows-refresh-mobile'),
              tooltip: 'Refresh',
              onPressed: () {
                onRefresh();
              },
              icon: const Icon(Icons.refresh_rounded),
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
    required this.upToDate,
    required this.isLoadingWatchHistory,
    required this.isLoadingMoreWatchHistory,
    required this.watchHistoryError,
    required this.updatingWatchNextEpisodeId,
    required this.startingShowId,
    required this.updatingWatchHistoryEventId,
  });

  final List<WatchNextShow> watchNext;
  final Object? watchNextError;
  final String? updatingWatchNextEpisodeId;

  final List<StaleWatchingShow> staleWatching;
  final Object? staleWatchingError;

  final List<LibraryShow> haventStarted;
  final List<LibraryShow> upToDate;

  final List<WatchHistoryItem> watchHistory;
  final bool hasLoadedWatchHistory;
  final bool hasMoreWatchHistory;
  final bool isLoadingWatchHistory;
  final bool isLoadingMoreWatchHistory;
  final Object? watchHistoryError;
  final String? startingShowId;
  final String? updatingWatchHistoryEventId;

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
              updatingEpisodeId: widget.updatingWatchNextEpisodeId,
              onRetry: context.read<ShowsCubit>().retryWatchNext,
              onMarkWatched: (String episodeId) {
                context.read<ShowsCubit>().markWatchNextEpisodeWatched(
                  episodeId: episodeId,
                );
              },
              isDesktop: isDesktop,
            ),

            const SizedBox(height: AppSpacing.section),

            if (widget.upToDate.isNotEmpty) ...<Widget>[
              _UpToDateSection(items: widget.upToDate, isDesktop: isDesktop),
              const SizedBox(height: AppSpacing.section),
            ],

            _HaventStartedSection(
              items: widget.haventStarted,
              startingShowId: widget.startingShowId,
              onStart: (String showId) {
                context.read<ShowsCubit>().startShow(showId: showId);
              },
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
              updatingEventId: widget.updatingWatchHistoryEventId,
              onRewatch:
                  ({required String eventId, required String episodeId}) {
                    context.read<ShowsCubit>().rewatchWatchHistoryEpisode(
                      eventId: eventId,
                      episodeId: episodeId,
                    );
                  },
              onMarkUnwatched:
                  ({required String eventId, required String episodeId}) {
                    context.read<ShowsCubit>().markWatchHistoryEpisodeUnwatched(
                      eventId: eventId,
                      episodeId: episodeId,
                    );
                  },
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
    final StaleWatchingEpisode lastWatched = item.lastWatched;
    final WatchNextEpisode nextEpisode = item.nextEpisode;

    final List<String> nextEpisodeMetadata = <String>[
      nextEpisode.code,
      if (nextEpisode.runtime != null) '${nextEpisode.runtime} min',
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

        /*
       * Last watched episode.
       */
        _EpisodeDetailsLink(
          episodeId: lastWatched.id,
          linkKey: ValueKey<String>(
            'shows-stale-watching-last-episode-details-${lastWatched.id}',
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${lastWatched.code} • '
                  '${_lastWatchedLabel(lastWatched.watchedAt)}',
                  key: ValueKey<String>(
                    'shows-stale-watching-last-${item.showTmdbId}',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  lastWatched.title,
                  key: ValueKey<String>(
                    'shows-stale-watching-last-title-${lastWatched.id}',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        /*
       * Next episode.
       */
        _EpisodeDetailsLink(
          episodeId: nextEpisode.id,
          linkKey: ValueKey<String>(
            'shows-stale-watching-next-episode-details-${nextEpisode.id}',
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Continue with ${nextEpisodeMetadata.join(' • ')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  nextEpisode.title,
                  key: ValueKey<String>(
                    'shows-stale-watching-next-title-${nextEpisode.id}',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
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
    required this.updatingEpisodeId,
    required this.onRetry,
    required this.onMarkWatched,
    required this.isDesktop,
  });

  final List<WatchNextShow> items;
  final bool hasError;
  final String? updatingEpisodeId;
  final VoidCallback onRetry;
  final ValueChanged<String> onMarkWatched;
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
      final WatchNextShow item = items[index];

      if (index > 0) {
        widgets.add(const SizedBox(height: AppSpacing.md));
      }

      widgets.add(
        _WatchNextRow(
          item: item,
          isDesktop: isDesktop,
          isMarkingWatched: updatingEpisodeId == item.nextEpisode.id,
          onMarkWatched: () {
            onMarkWatched(item.nextEpisode.id);
          },
        ),
      );
    }

    return widgets;
  }
}

class _WatchNextRow extends StatelessWidget {
  const _WatchNextRow({
    required this.item,
    required this.isDesktop,
    required this.isMarkingWatched,
    required this.onMarkWatched,
  });

  final WatchNextShow item;
  final bool isDesktop;
  final bool isMarkingWatched;
  final VoidCallback onMarkWatched;

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
              _WatchNextMarkWatchedButton(
                episodeId: episode.id,
                isLoading: isMarkingWatched,
                onPressed: onMarkWatched,
              ),
              const SizedBox(width: AppSpacing.xs),
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

class _WatchNextMarkWatchedButton extends StatelessWidget {
  const _WatchNextMarkWatchedButton({
    required this.episodeId,
    required this.isLoading,
    required this.onPressed,
  });

  final String episodeId;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isLoading
          ? 'Marking episode as watched'
          : 'Mark episode as watched',
      child: SizedBox(
        width: 40,
        height: 40,
        child: isLoading
            ? Center(
                key: ValueKey<String>(
                  'shows-watch-next-mark-watched-loading-$episodeId',
                ),
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                key: ValueKey<String>(
                  'shows-watch-next-mark-watched-$episodeId',
                ),
                onPressed: onPressed,
                tooltip: 'Mark as watched',
                icon: const Icon(
                  Icons.check_rounded,
                  color: AppColors.textSecondary,
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
    final progress = item.progress;

    final List<String> metadata = <String>[
      episode.code,
      if (episode.runtime != null) '${episode.runtime} min',
      if (episode.airDate != null)
        MaterialLocalizations.of(context).formatMediumDate(episode.airDate!),
    ];

    final double progressValue = progress.airedEpisodes > 0
        ? progress.percentage / 100
        : 0;

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
        _EpisodeDetailsLink(
          episodeId: episode.id,
          linkKey: ValueKey<String>(
            'shows-watch-next-episode-details-${episode.id}',
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  episode.title,
                  key: ValueKey<String>(
                    'shows-watch-next-episode-title-${episode.id}',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  metadata.join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            Expanded(
              child: ClipRRect(
                borderRadius: AppRadius.borderSmall,
                child: LinearProgressIndicator(
                  key: ValueKey<String>(
                    'shows-watch-next-progress-${item.showTmdbId}',
                  ),
                  value: progressValue,
                  minHeight: 4,
                  backgroundColor: AppColors.surfaceLow,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${progress.watchedEpisodes}/${progress.airedEpisodes}',
              key: ValueKey<String>(
                'shows-watch-next-progress-label-${item.showTmdbId}',
              ),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
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

typedef _WatchHistoryEpisodeAction =
    void Function({required String eventId, required String episodeId});

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
    required this.updatingEventId,
    required this.onRewatch,
    required this.onMarkUnwatched,
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
  final String? updatingEventId;
  final _WatchHistoryEpisodeAction onRewatch;
  final _WatchHistoryEpisodeAction onMarkUnwatched;

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

      final WatchHistoryItem item = items[index];

      widgets.add(
        _WatchHistoryRow(
          item: item,
          isUpdating: updatingEventId == item.eventId,
          onRewatch: () {
            onRewatch(eventId: item.eventId, episodeId: item.episode.id);
          },
          onMarkUnwatched: () {
            onMarkUnwatched(eventId: item.eventId, episodeId: item.episode.id);
          },
          isDesktop: isDesktop,
        ),
      );
    }

    return widgets;
  }
}

class _WatchHistoryRow extends StatelessWidget {
  const _WatchHistoryRow({
    required this.item,
    required this.isUpdating,
    required this.onRewatch,
    required this.onMarkUnwatched,
    required this.isDesktop,
  });

  final WatchHistoryItem item;
  final bool isUpdating;
  final VoidCallback onRewatch;
  final VoidCallback onMarkUnwatched;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey<String>('shows-watch-history-${item.eventId}'),
      color: AppColors.surfaceHigh,
      borderRadius: AppRadius.borderLarge,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isUpdating
            ? null
            : () {
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
              if (isUpdating)
                SizedBox(
                  key: ValueKey<String>(
                    'shows-watch-history-progress-${item.eventId}',
                  ),
                  width: 40,
                  height: 40,
                  child: const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else ...<Widget>[
                IconButton(
                  key: ValueKey<String>(
                    'shows-watch-history-rewatch-${item.eventId}',
                  ),
                  tooltip: 'Watched again',
                  onPressed: onRewatch,
                  icon: const Icon(
                    Icons.replay_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
                IconButton(
                  key: ValueKey<String>(
                    'shows-watch-history-unwatched-${item.eventId}',
                  ),
                  tooltip: 'Mark as unwatched',
                  onPressed: onMarkUnwatched,
                  icon: const Icon(
                    Icons.visibility_off_outlined,
                    color: AppColors.textSecondary,
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
          key: ValueKey<String>('shows-watch-history-title-${item.eventId}'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        _EpisodeDetailsLink(
          episodeId: episode.id,
          linkKey: ValueKey<String>(
            'shows-watch-history-episode-details-${episode.id}',
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Watched ${MaterialLocalizations.of(context).formatMediumDate(episode.watchedAt)}',
          key: ValueKey<String>('shows-watch-history-date-${item.eventId}'),
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
    return BlocBuilder<ShowsCubit, ShowsState>(
      buildWhen: (ShowsState previous, ShowsState current) {
        return previous.upcoming != current.upcoming ||
            previous.isLoadingUpcoming != current.isLoadingUpcoming ||
            previous.isLoadingEarlierUpcoming !=
                current.isLoadingEarlierUpcoming ||
            previous.upcomingError != current.upcomingError ||
            previous.earlierUpcomingError != current.earlierUpcomingError ||
            previous.updatingUpcomingEpisodeId !=
                current.updatingUpcomingEpisodeId ||
            previous.upcomingOperationError != current.upcomingOperationError;
      },
      builder: (BuildContext context, ShowsState state) {
        if (state.isLoadingUpcoming && state.upcoming.isEmpty) {
          return const Center(
            key: ValueKey<String>('shows-upcoming-loading'),
            child: CircularProgressIndicator(),
          );
        }

        final AppException? error = state.upcomingError;

        if (error != null && state.upcoming.isEmpty) {
          return Center(
            key: const ValueKey<String>('shows-upcoming-failure'),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Could not load upcoming episodes.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    key: const ValueKey<String>('shows-upcoming-retry'),
                    onPressed: context.read<ShowsCubit>().retryUpcoming,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state.upcoming.isEmpty) {
          return const _ShowsEmpty(
            key: ValueKey<String>('shows-upcoming-empty'),
            title: 'No upcoming episodes',
            message: 'Upcoming episodes from your shows will appear here.',
          );
        }

        final DateTime? referenceDate = state.upcomingReferenceDate;

        if (referenceDate == null) {
          return const SizedBox.shrink();
        }

        return _UpcomingTimeline(
          items: state.upcoming,
          today: referenceDate,
          isLoadingEarlier: state.isLoadingEarlierUpcoming,
          earlierError: state.earlierUpcomingError,
          updatingEpisodeId: state.updatingUpcomingEpisodeId,
          onLoadEarlier: context.read<ShowsCubit>().loadEarlierUpcoming,
          onRetryEarlier: context.read<ShowsCubit>().retryEarlierUpcoming,
          onMarkWatched: context.read<ShowsCubit>().markUpcomingEpisodeWatched,
        );
      },
    );
  }
}

class _UpcomingTimeline extends StatefulWidget {
  const _UpcomingTimeline({
    required this.items,
    required this.today,
    required this.isLoadingEarlier,
    required this.earlierError,
    required this.updatingEpisodeId,
    required this.onLoadEarlier,
    required this.onRetryEarlier,
    required this.onMarkWatched,
  });

  final List<UpcomingItem> items;
  final DateTime today;

  final bool isLoadingEarlier;
  final AppException? earlierError;

  final Future<void> Function() onLoadEarlier;
  final Future<void> Function() onRetryEarlier;

  final String? updatingEpisodeId;

  final Future<void> Function({required String episodeId}) onMarkWatched;

  @override
  State<_UpcomingTimeline> createState() {
    return _UpcomingTimelineState();
  }
}

class _UpcomingTimelineState extends State<_UpcomingTimeline> {
  static const double _loadEarlierThreshold = 120;
  static const double _rearmThreshold = 280;

  final ScrollController _scrollController = ScrollController();

  final GlobalKey _todayCenterKey = GlobalKey();

  bool _canTriggerLoadEarlier = true;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_handleScroll);
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

    /*
   * With Today used as the CustomScrollView center, historical content
   * exists before the zero scroll offset.
   *
   * extentBefore tells us how much already-loaded historical content
   * still exists above the current viewport.
   */
    final double distanceFromHistoricalStart = position.extentBefore;

    /*
   * Once the user has moved sufficiently away from the oldest loaded
   * content, allow another historical request later.
   */
    if (distanceFromHistoricalStart >= _rearmThreshold) {
      _canTriggerLoadEarlier = true;

      return;
    }

    if (!_canTriggerLoadEarlier ||
        distanceFromHistoricalStart > _loadEarlierThreshold ||
        widget.isLoadingEarlier) {
      return;
    }

    _canTriggerLoadEarlier = false;

    widget.onLoadEarlier();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime today = _dateOnly(widget.today);

    final List<UpcomingItem> pastItems = widget.items
        .where(
          (UpcomingItem item) =>
              _dateOnly(item.episode.airDate).isBefore(today),
        )
        .toList(growable: false);

    final List<UpcomingItem> todayItems = widget.items
        .where(
          (UpcomingItem item) =>
              _isSameDate(_dateOnly(item.episode.airDate), today),
        )
        .toList(growable: false);

    final List<UpcomingItem> futureItems = widget.items
        .where(
          (UpcomingItem item) => _dateOnly(item.episode.airDate).isAfter(today),
        )
        .toList(growable: false);

    final List<_UpcomingTimelineEntry> pastEntries =
        _buildUpcomingTimelineEntries(items: pastItems, today: today);

    final List<_UpcomingTimelineEntry> futureEntries =
        _buildUpcomingTimelineEntries(items: futureItems, today: today);

    final bool showEarlierStatus =
        widget.isLoadingEarlier || widget.earlierError != null;

    return CustomScrollView(
      key: const ValueKey<String>('shows-upcoming-timeline'),
      controller: _scrollController,
      center: _todayCenterKey,
      slivers: <Widget>[
        /*
       * Historical timeline.
       *
       * This sliver exists before Today and therefore grows towards
       * negative scroll offsets.
       */
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate(<Widget>[
              if (showEarlierStatus) ...<Widget>[
                _UpcomingEarlierStatus(
                  isLoading: widget.isLoadingEarlier,
                  error: widget.earlierError,
                  onRetry: widget.onRetryEarlier,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              ..._buildUpcomingEntryWidgets(
                entries: pastEntries,
                today: today,
                updatingEpisodeId: widget.updatingEpisodeId,
                onMarkWatched: widget.onMarkWatched,
              ),
            ]),
          ),
        ),

        /*
       * Today is the scroll anchor.
       *
       * CustomScrollView assigns zero scroll offset to this sliver,
       * so opening Upcoming naturally starts here.
       */
        SliverToBoxAdapter(
          key: _todayCenterKey,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: _UpcomingTodaySection(
              items: todayItems,
              today: today,
              updatingEpisodeId: widget.updatingEpisodeId,
              onMarkWatched: widget.onMarkWatched,
            ),
          ),
        ),

        /*
       * Tomorrow, the following seven days and Later.
       */
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              _buildUpcomingEntryWidgets(
                entries: futureEntries,
                today: today,
                updatingEpisodeId: widget.updatingEpisodeId,
                onMarkWatched: widget.onMarkWatched,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildUpcomingEntryWidgets({
    required List<_UpcomingTimelineEntry> entries,
    required DateTime today,
    required String? updatingEpisodeId,
    required Future<void> Function({required String episodeId}) onMarkWatched,
  }) {
    final List<Widget> widgets = <Widget>[];

    for (int index = 0; index < entries.length; index++) {
      final _UpcomingTimelineEntry entry = entries[index];

      if (index > 0) {
        widgets.add(const SizedBox(height: AppSpacing.sm));
      }

      widgets.add(switch (entry) {
        _UpcomingDateHeaderEntry(:final label, :final kind) =>
          _UpcomingDateHeader(label: label, kind: kind),
        _UpcomingEpisodeEntry(:final item) => _UpcomingEpisodeRow(
          item: item,
          today: today,
          isUpdating: updatingEpisodeId == item.episode.id,
          onMarkWatched: onMarkWatched,
        ),
      });
    }

    return widgets;
  }
}

sealed class _UpcomingTimelineEntry {
  const _UpcomingTimelineEntry();
}

class _UpcomingTodaySection extends StatelessWidget {
  const _UpcomingTodaySection({
    required this.items,
    required this.today,
    required this.updatingEpisodeId,
    required this.onMarkWatched,
  });

  final List<UpcomingItem> items;
  final DateTime today;
  final String? updatingEpisodeId;

  final Future<void> Function({required String episodeId}) onMarkWatched;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('shows-upcoming-today-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _UpcomingDateHeader(
          label: 'Today',
          kind: _UpcomingDateHeaderKind.today,
        ),
        if (items.isEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No episodes airing today.',
            key: const ValueKey<String>('shows-upcoming-today-empty'),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ] else
          for (final UpcomingItem item in items) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            _UpcomingEpisodeRow(
              item: item,
              today: today,
              isUpdating: updatingEpisodeId == item.episode.id,
              onMarkWatched: onMarkWatched,
            ),
          ],
      ],
    );
  }
}

final class _UpcomingDateHeaderEntry extends _UpcomingTimelineEntry {
  const _UpcomingDateHeaderEntry({required this.label, required this.kind});

  final String label;
  final _UpcomingDateHeaderKind kind;
}

final class _UpcomingEpisodeEntry extends _UpcomingTimelineEntry {
  const _UpcomingEpisodeEntry({required this.item});

  final UpcomingItem item;
}

enum _UpcomingDateHeaderKind { past, today, tomorrow, future, later }

List<_UpcomingTimelineEntry> _buildUpcomingTimelineEntries({
  required List<UpcomingItem> items,
  required DateTime today,
}) {
  if (items.isEmpty) {
    return const <_UpcomingTimelineEntry>[];
  }

  final List<UpcomingItem> sortedItems = List<UpcomingItem>.of(items)
    ..sort((UpcomingItem first, UpcomingItem second) {
      final int dateComparison = first.episode.airDate.compareTo(
        second.episode.airDate,
      );

      if (dateComparison != 0) {
        return dateComparison;
      }

      final int showComparison = first.showTitle.toLowerCase().compareTo(
        second.showTitle.toLowerCase(),
      );

      if (showComparison != 0) {
        return showComparison;
      }

      final int seasonComparison = first.episode.seasonNumber.compareTo(
        second.episode.seasonNumber,
      );

      if (seasonComparison != 0) {
        return seasonComparison;
      }

      return first.episode.episodeNumber.compareTo(
        second.episode.episodeNumber,
      );
    });

  final DateTime tomorrow = today.add(const Duration(days: 1));
  final DateTime finalDetailedFutureDate = today.add(const Duration(days: 7));

  final List<_UpcomingTimelineEntry> entries = <_UpcomingTimelineEntry>[];

  DateTime? currentDetailedDate;
  bool hasCreatedLaterHeader = false;

  for (final UpcomingItem item in sortedItems) {
    final DateTime airDate = _dateOnly(item.episode.airDate);

    final bool belongsToLater = airDate.isAfter(finalDetailedFutureDate);

    if (belongsToLater) {
      if (!hasCreatedLaterHeader) {
        entries.add(
          const _UpcomingDateHeaderEntry(
            label: 'Later',
            kind: _UpcomingDateHeaderKind.later,
          ),
        );

        hasCreatedLaterHeader = true;
      }

      entries.add(_UpcomingEpisodeEntry(item: item));

      continue;
    }

    if (currentDetailedDate == null ||
        !_isSameDate(currentDetailedDate, airDate)) {
      entries.add(
        _UpcomingDateHeaderEntry(
          label: _upcomingDateHeaderLabel(
            date: airDate,
            today: today,
            tomorrow: tomorrow,
          ),
          kind: _upcomingDateHeaderKind(
            date: airDate,
            today: today,
            tomorrow: tomorrow,
          ),
        ),
      );

      currentDetailedDate = airDate;
    }

    entries.add(_UpcomingEpisodeEntry(item: item));
  }

  return entries;
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

bool _isSameDate(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

String _upcomingDateHeaderLabel({
  required DateTime date,
  required DateTime today,
  required DateTime tomorrow,
}) {
  if (_isSameDate(date, today)) {
    return 'Today';
  }

  if (_isSameDate(date, tomorrow)) {
    return 'Tomorrow';
  }

  return _formatUpcomingDay(date);
}

_UpcomingDateHeaderKind _upcomingDateHeaderKind({
  required DateTime date,
  required DateTime today,
  required DateTime tomorrow,
}) {
  if (date.isBefore(today)) {
    return _UpcomingDateHeaderKind.past;
  }

  if (_isSameDate(date, today)) {
    return _UpcomingDateHeaderKind.today;
  }

  if (_isSameDate(date, tomorrow)) {
    return _UpcomingDateHeaderKind.tomorrow;
  }

  return _UpcomingDateHeaderKind.future;
}

String _formatUpcomingDay(DateTime date) {
  const List<String> weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

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

  final String weekday = weekdays[date.weekday - 1];
  final String month = months[date.month - 1];

  return '$weekday, $month ${date.day}';
}

String _formatUpcomingShortDate(DateTime date) {
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

  return '${months[date.month - 1]} ${date.day}';
}

class _UpcomingDateHeader extends StatelessWidget {
  const _UpcomingDateHeader({required this.label, required this.kind});

  final String label;
  final _UpcomingDateHeaderKind kind;

  @override
  Widget build(BuildContext context) {
    final bool isPrimary =
        kind == _UpcomingDateHeaderKind.today ||
        kind == _UpcomingDateHeaderKind.tomorrow;

    final bool isLater = kind == _UpcomingDateHeaderKind.later;

    return Padding(
      key: ValueKey<String>(
        'shows-upcoming-date-${label.toLowerCase().replaceAll(' ', '-')}',
      ),
      padding: EdgeInsets.only(
        top: isPrimary || isLater ? AppSpacing.lg : AppSpacing.md,
        bottom: AppSpacing.xs,
      ),
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: isPrimary
                ? Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
                : Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: kind == _UpcomingDateHeaderKind.past
                        ? AppColors.textSecondary
                        : null,
                  ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingEpisodeRow extends StatelessWidget {
  const _UpcomingEpisodeRow({
    required this.item,
    required this.today,
    required this.isUpdating,
    required this.onMarkWatched,
  });

  final UpcomingItem item;
  final DateTime today;
  final bool isUpdating;

  final Future<void> Function({required String episodeId}) onMarkWatched;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;

    final DateTime airDate = _dateOnly(item.episode.airDate);

    final bool canMarkWatched = !airDate.isAfter(today);

    return Card(
      key: ValueKey<String>('shows-upcoming-${item.episode.id}'),
      margin: EdgeInsets.zero,
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
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _WatchNextPoster(url: item.posterUrl, width: isDesktop ? 64 : 52),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _UpcomingEpisodeInformation(
                  item: item,
                  today: today,
                  airDate: airDate,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              _UpcomingMarkWatchedButton(
                episodeId: item.episode.id,
                canMarkWatched: canMarkWatched,
                isUpdating: isUpdating,
                onMarkWatched: onMarkWatched,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingMarkWatchedButton extends StatelessWidget {
  const _UpcomingMarkWatchedButton({
    required this.episodeId,
    required this.canMarkWatched,
    required this.isUpdating,
    required this.onMarkWatched,
  });

  final String episodeId;
  final bool canMarkWatched;
  final bool isUpdating;

  final Future<void> Function({required String episodeId}) onMarkWatched;

  @override
  Widget build(BuildContext context) {
    final String tooltip = canMarkWatched
        ? 'Mark episode as watched'
        : 'This episode has not aired yet';

    return Tooltip(
      message: tooltip,
      child: IconButton(
        key: ValueKey<String>('shows-upcoming-mark-watched-$episodeId'),
        tooltip: tooltip,
        onPressed: !canMarkWatched || isUpdating
            ? null
            : () {
                onMarkWatched(episodeId: episodeId);
              },
        icon: isUpdating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check_circle_outline_rounded),
      ),
    );
  }
}

class _UpcomingEpisodeInformation extends StatelessWidget {
  const _UpcomingEpisodeInformation({
    required this.item,
    required this.today,
    required this.airDate,
  });

  final UpcomingItem item;
  final DateTime today;
  final DateTime airDate;

  @override
  Widget build(BuildContext context) {
    final String temporalLabel = _upcomingTemporalLabel(
      airDate: airDate,
      today: today,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          item.showTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        _EpisodeDetailsLink(
          episodeId: item.episode.id,
          linkKey: ValueKey<String>(
            'shows-upcoming-episode-details-${item.episode.id}',
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Text(
              '${item.episode.code} · ${item.episode.title}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          temporalLabel,
          key: ValueKey<String>('shows-upcoming-temporal-${item.episode.id}'),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

String _upcomingTemporalLabel({
  required DateTime airDate,
  required DateTime today,
}) {
  final int dayDifference = airDate.difference(today).inDays;

  if (dayDifference < 0) {
    return 'Aired ${_formatUpcomingShortDate(airDate)}';
  }

  if (dayDifference == 0) {
    return 'Airs today';
  }

  if (dayDifference == 1) {
    return 'Airs tomorrow';
  }

  if (dayDifference <= 7) {
    return 'In $dayDifference days';
  }

  return _formatUpcomingShortDate(airDate);
}

class _UpcomingEarlierStatus extends StatelessWidget {
  const _UpcomingEarlierStatus({
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  final bool isLoading;
  final AppException? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        key: ValueKey<String>('shows-upcoming-loading-earlier'),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (error == null) {
      return const SizedBox.shrink();
    }

    return Center(
      key: const ValueKey<String>('shows-upcoming-earlier-failure'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: Text(
                'Could not load earlier episodes.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              key: const ValueKey<String>('shows-upcoming-earlier-retry'),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
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
  const _HaventStartedSection({
    required this.items,
    required this.startingShowId,
    required this.onStart,
    required this.isDesktop,
  });

  final List<LibraryShow> items;
  final String? startingShowId;
  final ValueChanged<String> onStart;
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

      final LibraryShow show = items[index];

      widgets.add(
        _HaventStartedRow(
          show: show,
          isStarting: startingShowId == show.showId,
          onStart: () => onStart(show.showId),
          isDesktop: isDesktop,
        ),
      );
    }

    return widgets;
  }
}

class _HaventStartedRow extends StatelessWidget {
  const _HaventStartedRow({
    required this.show,
    required this.isStarting,
    required this.onStart,
    required this.isDesktop,
  });

  final LibraryShow show;
  final bool isStarting;
  final VoidCallback onStart;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final bool canStart = show.firstAvailableEpisode != null;
    return Material(
      key: ValueKey<String>('shows-havent-started-${show.tmdbId}'),
      color: AppColors.surfaceHigh,
      borderRadius: AppRadius.borderLarge,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isStarting
            ? null
            : () {
                context.pushNamed(
                  AppRoute.showDetails.name,
                  pathParameters: <String, String>{
                    'showId': show.tmdbId.toString(),
                  },
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
              FilledButton.tonalIcon(
                key: ValueKey<String>(
                  'shows-havent-started-start-${show.tmdbId}',
                ),
                onPressed: isStarting || !canStart ? null : onStart,
                icon: isStarting
                    ? const SizedBox(
                        key: ValueKey<String>(
                          'shows-havent-started-start-progress',
                        ),
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(isStarting ? 'Starting…' : 'Start'),
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
    final LibraryFirstEpisode? firstEpisode = show.firstAvailableEpisode;

    final List<String> showMetadata = <String>[
      if (show.firstAirDate != null) show.firstAirDate!.year.toString(),
      if (show.voteAverage > 0) show.voteAverage.toStringAsFixed(1),
    ];

    final List<String> episodeMetadata = <String>[
      if (firstEpisode != null) firstEpisode.code,
      if (firstEpisode?.runtime != null) '${firstEpisode!.runtime} min',
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
        if (showMetadata.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            showMetadata.join(' • '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        if (firstEpisode != null)
          _EpisodeDetailsLink(
            episodeId: firstEpisode.id,
            linkKey: ValueKey<String>(
              'shows-havent-started-episode-details-${firstEpisode.id}',
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    episodeMetadata.join(' • '),
                    key: ValueKey<String>(
                      'shows-havent-started-episode-code-${show.tmdbId}',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    firstEpisode.title,
                    key: ValueKey<String>(
                      'shows-havent-started-episode-title-${show.tmdbId}',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Text(
            'No episode available yet',
            key: ValueKey<String>(
              'shows-havent-started-no-episode-${show.tmdbId}',
            ),
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

class _UpToDateSection extends StatelessWidget {
  const _UpToDateSection({required this.items, required this.isDesktop});

  final List<LibraryShow> items;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('shows-up-to-date-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Up to Date',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Shows where you have watched every episode released so far.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
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

      widgets.add(_UpToDateRow(show: items[index], isDesktop: isDesktop));
    }

    return widgets;
  }
}

class _UpToDateRow extends StatelessWidget {
  const _UpToDateRow({required this.show, required this.isDesktop});

  final LibraryShow show;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final double progressValue = show.progress.airedEpisodes > 0
        ? show.progress.percentage / 100
        : 0;

    return Material(
      key: ValueKey<String>('shows-up-to-date-${show.tmdbId}'),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      show.title,
                      key: ValueKey<String>(
                        'shows-up-to-date-title-${show.tmdbId}',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Up to Date',
                      key: ValueKey<String>(
                        'shows-up-to-date-label-${show.tmdbId}',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: AppRadius.borderSmall,
                      child: LinearProgressIndicator(
                        key: ValueKey<String>(
                          'shows-library-progress-${show.tmdbId}',
                        ),
                        value: progressValue,
                        minHeight: 4,
                        backgroundColor: AppColors.surfaceLow,
                      ),
                    ),
                  ],
                ),
              ),
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

class _EpisodeDetailsLink extends StatelessWidget {
  const _EpisodeDetailsLink({
    required this.episodeId,
    required this.linkKey,
    required this.child,
  });

  final String episodeId;
  final Key linkKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open episode details',
      child: InkWell(
        key: linkKey,
        borderRadius: AppRadius.borderSmall,
        onTap: () {
          context.pushNamed(
            AppRoute.episodeDetails.name,
            pathParameters: <String, String>{'episodeId': episodeId},
          );
        },
        child: child,
      ),
    );
  }
}
