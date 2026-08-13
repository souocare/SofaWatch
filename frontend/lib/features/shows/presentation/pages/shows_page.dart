import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/app/theme/tokens/app_breakpoints.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/features/shows/application/cubit/shows_cubit.dart';
import 'package:sofawatch/features/shows/application/cubit/shows_state.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';

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
                  return switch (state) {
                    ShowsInitial() || ShowsLoading() => const _ShowsLoading(),

                    ShowsSuccess(:final shows) => TabBarView(
                      key: const ValueKey<String>('shows-tab-view'),
                      controller: _tabController,
                      children: <Widget>[
                        _WatchListTab(shows: shows),
                        const _UpcomingTab(),
                      ],
                    ),

                    ShowsFailure(:final error) => _ShowsFailure(
                      message: error.isTimeout
                          ? 'Loading your shows took too long.'
                          : 'Could not load your shows.',
                      onRetry: context.read<ShowsCubit>().retry,
                    ),
                  };
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

class _ShowsContent extends StatelessWidget {
  const _ShowsContent({required this.shows, super.key});

  final List<LibraryShow> shows;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isDesktop = constraints.maxWidth >= AppBreakpoints.tablet;

        return ListView.separated(
          key: const ValueKey<String>('shows-list'),
          padding: EdgeInsets.fromLTRB(
            isDesktop ? AppSpacing.xxxl : AppSpacing.xl,
            AppSpacing.sm,
            isDesktop ? AppSpacing.xxxl : AppSpacing.xl,
            AppSpacing.section,
          ),
          itemCount: shows.length,
          separatorBuilder: (BuildContext context, int index) {
            return const SizedBox(height: AppSpacing.md);
          },
          itemBuilder: (BuildContext context, int index) {
            return _ShowRow(show: shows[index], isDesktop: isDesktop);
          },
        );
      },
    );
  }
}

class _ShowRow extends StatelessWidget {
  const _ShowRow({required this.show, required this.isDesktop});

  final LibraryShow show;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey<String>('shows-item-${show.tmdbId}'),
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
            children: <Widget>[
              _ShowPoster(url: show.posterUrl, width: isDesktop ? 72 : 56),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: _ShowInformation(show: show)),
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

class _ShowPoster extends StatelessWidget {
  const _ShowPoster({required this.url, required this.width});

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

class _ShowInformation extends StatelessWidget {
  const _ShowInformation({required this.show});

  final LibraryShow show;

  @override
  Widget build(BuildContext context) {
    final List<String> metadata = <String>[
      if (show.firstAirDate != null) show.firstAirDate!.year.toString(),
      _statusLabel(show.status),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          show.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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

  String _statusLabel(LibraryStatus status) {
    return switch (status) {
      LibraryStatus.planning => 'Watchlist',
      LibraryStatus.watching => 'Watching',
      LibraryStatus.completed => 'Finished',
      LibraryStatus.paused => 'Paused',
      LibraryStatus.dropped => 'Dropped',
    };
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

class _WatchListTab extends StatelessWidget {
  const _WatchListTab({required this.shows});

  final List<LibraryShow> shows;

  @override
  Widget build(BuildContext context) {
    if (shows.isEmpty) {
      return const _ShowsEmpty(
        key: ValueKey<String>('shows-watch-list-empty'),
        title: 'Nothing to watch yet',
        message: 'Shows you add to your Library will appear here.',
      );
    }

    return _ShowsContent(
      key: const ValueKey<String>('shows-watch-list'),
      shows: shows,
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
