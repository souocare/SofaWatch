import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/app/theme/tokens/app_breakpoints.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/features/shows/application/cubit/shows_cubit.dart';
import 'package:sofawatch/features/shows/application/cubit/shows_state.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_show.dart';

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

class _WatchListTab extends StatelessWidget {
  const _WatchListTab({required this.watchNext, required this.watchNextError});

  final List<WatchNextShow> watchNext;
  final Object? watchNextError;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isDesktop = constraints.maxWidth >= AppBreakpoints.tablet;

        return ListView(
          key: const ValueKey<String>('shows-watch-list'),
          padding: EdgeInsets.fromLTRB(
            isDesktop ? AppSpacing.xxxl : AppSpacing.xl,
            AppSpacing.sm,
            isDesktop ? AppSpacing.xxxl : AppSpacing.xl,
            AppSpacing.section,
          ),
          children: <Widget>[
            _WatchNextSection(
              items: watchNext,
              hasError: watchNextError != null,
              onRetry: context.read<ShowsCubit>().retryWatchNext,
              isDesktop: isDesktop,
            ),

            /*
             * Future Watch List blocks:
             *
             * - Haven't Watched in a While
             * - Haven't Started
             * - Watch History
             */
          ],
        );
      },
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
