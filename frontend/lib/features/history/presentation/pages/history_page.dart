import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/core/errors/app_error_message_mapper.dart';
import 'package:sofawatch/core/widgets/server_network_image.dart';
import 'package:sofawatch/features/history/application/cubit/history_cubit.dart';
import 'package:sofawatch/features/history/application/cubit/history_state.dart';
import 'package:sofawatch/features/history/domain/models/history_episode_item.dart';
import 'package:sofawatch/features/history/domain/models/history_item.dart';
import 'package:sofawatch/features/history/domain/models/history_movie_item.dart';
import 'package:sofawatch/features/history/domain/models/history_media_type.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({this.mediaType = HistoryMediaType.all, super.key});

  final HistoryMediaType mediaType;

  String get _pageTitle {
    return switch (mediaType) {
      HistoryMediaType.all => 'History',
      HistoryMediaType.episodes => 'Episode History',
      HistoryMediaType.movies => 'Movie History',
    };
  }

  String get _contentTitle {
    return switch (mediaType) {
      HistoryMediaType.all => 'Your viewing history',
      HistoryMediaType.episodes => 'Your episode history',
      HistoryMediaType.movies => 'Your movie history',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey<String>('history-page'),
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          _pageTitle,
          key: const ValueKey<String>('history-page-title'),
        ),
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<HistoryCubit, HistoryState>(
          builder: (BuildContext context, HistoryState state) {
            if (state.isLoading && !state.hasLoaded && state.items.isEmpty) {
              return const _HistoryLoading();
            }

            if (state.error != null && state.items.isEmpty) {
              return _HistoryFailure(
                message: AppErrorMessageMapper.map(state.error!),
                onRetry: context.read<HistoryCubit>().retry,
              );
            }

            if (state.isEmpty) {
              return _HistoryEmpty(mediaType: mediaType);
            }

            return _HistoryContent(state: state, title: _contentTitle);
          },
        ),
      ),
    );
  }
}

class _HistoryContent extends StatelessWidget {
  const _HistoryContent({required this.state, required this.title});

  final HistoryState state;
  final String title;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: context.read<HistoryCubit>().load,
      child: CustomScrollView(
        key: const ValueKey<String>('history-scroll-view'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: _HistoryContentBounds(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  _horizontalPadding(context),
                  AppSpacing.xl,
                  _horizontalPadding(context),
                  AppSpacing.md,
                ),
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: _HistoryContentBounds(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: _horizontalPadding(context),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: AppRadius.borderLarge,
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Column(
                    children: <Widget>[
                      for (
                        int index = 0;
                        index < state.items.length;
                        index++
                      ) ...<Widget>[
                        _HistoryRow(item: state.items[index]),

                        if (index < state.items.length - 1)
                          Divider(height: 1, color: AppColors.outlineVariant),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (state.paginationError != null)
            SliverToBoxAdapter(
              child: _HistoryContentBounds(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    _horizontalPadding(context),
                    AppSpacing.md,
                    _horizontalPadding(context),
                    0,
                  ),
                  child: _HistoryPaginationFailure(
                    message: AppErrorMessageMapper.map(state.paginationError!),
                    onRetry: context.read<HistoryCubit>().retryLoadMore,
                  ),
                ),
              ),
            ),

          if (state.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  key: ValueKey<String>('history-loading-more'),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (state.canLoadMore)
            SliverToBoxAdapter(
              child: _HistoryContentBounds(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    _horizontalPadding(context),
                    AppSpacing.lg,
                    _horizontalPadding(context),
                    0,
                  ),
                  child: Center(
                    child: FilledButton.tonalIcon(
                      key: const ValueKey<String>('history-load-more'),
                      onPressed: context.read<HistoryCubit>().loadMore,
                      icon: const Icon(Icons.expand_more_rounded),
                      label: const Text('Load more'),
                    ),
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.section)),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item});

  final HistoryItem item;

  @override
  Widget build(BuildContext context) {
    return switch (item) {
      HistoryEpisodeItem episodeItem => _EpisodeHistoryRow(item: episodeItem),
      HistoryMovieItem movieItem => _MovieHistoryRow(item: movieItem),
      _ => const SizedBox.shrink(),
    };
  }
}

class _EpisodeHistoryRow extends StatelessWidget {
  const _EpisodeHistoryRow({required this.item});

  final HistoryEpisodeItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey<String>('history-episode-${item.eventId}'),
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
            _HistoryArtwork(
              imageUrl: item.episode.stillUrl ?? item.posterUrl,
              icon: Icons.tv_outlined,
              width: 88,
              height: 56,
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    '${item.episode.code} · ${item.episode.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  _HistoryWatchedAt(watchedAt: item.watchedAt),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _MovieHistoryRow extends StatelessWidget {
  const _MovieHistoryRow({required this.item});

  final HistoryMovieItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey<String>('history-movie-${item.eventId}'),
      onTap: () {
        context.pushNamed(
          AppRoute.movieDetails.name,
          pathParameters: <String, String>{
            'movieId': item.movieTmdbId.toString(),
          },
        );
      },
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: <Widget>[
            _HistoryArtwork(
              imageUrl: item.posterUrl,
              icon: Icons.movie_outlined,
              width: 44,
              height: 66,
            ),

            const SizedBox(width: AppSpacing.md),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.movieTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  _HistoryWatchedAt(watchedAt: item.watchedAt),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _HistoryArtwork extends StatelessWidget {
  const _HistoryArtwork({
    required this.imageUrl,
    required this.icon,
    required this.width,
    required this.height,
  });

  final String? imageUrl;
  final IconData icon;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final String? normalizedUrl = imageUrl?.trim();

    return ClipRRect(
      borderRadius: AppRadius.borderMedium,
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: normalizedUrl == null || normalizedUrl.isEmpty
              ? Center(child: Icon(icon, size: 24, color: AppColors.textMuted))
              : ServerNetworkImage(
                  imageUrl: normalizedUrl,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                      ) {
                        return Center(
                          child: Icon(
                            icon,
                            size: 24,
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

class _HistoryWatchedAt extends StatelessWidget {
  const _HistoryWatchedAt({required this.watchedAt});

  final DateTime watchedAt;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(
          Icons.schedule_rounded,
          size: 14,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            _formatHistoryDate(watchedAt),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _HistoryContentBounds extends StatelessWidget {
  const _HistoryContentBounds({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: child,
      ),
    );
  }
}

class _HistoryLoading extends StatelessWidget {
  const _HistoryLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: ValueKey<String>('history-loading'),
      child: CircularProgressIndicator(),
    );
  }
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty({required this.mediaType});

  final HistoryMediaType mediaType;

  @override
  Widget build(BuildContext context) {
    final String title = switch (mediaType) {
      HistoryMediaType.all => 'No viewing history yet',
      HistoryMediaType.episodes => 'No episode history yet',
      HistoryMediaType.movies => 'No movie history yet',
    };

    final String message = switch (mediaType) {
      HistoryMediaType.all => 'Episodes and Movies you watch will appear here.',
      HistoryMediaType.episodes => 'Episodes you watch will appear here.',
      HistoryMediaType.movies => 'Movies you watch will appear here.',
    };

    return Center(
      key: const ValueKey<String>('history-empty'),
      child: Padding(
        padding: AppSpacing.cardPaddingLarge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.history_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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

class _HistoryFailure extends StatelessWidget {
  const _HistoryFailure({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey<String>('history-failure'),
      child: Padding(
        padding: AppSpacing.cardPaddingLarge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.tonalIcon(
              key: const ValueKey<String>('history-retry'),
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

class _HistoryPaginationFailure extends StatelessWidget {
  const _HistoryPaginationFailure({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('history-pagination-failure'),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.textSecondary,
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodySmall),
          ),

          const SizedBox(width: AppSpacing.sm),

          TextButton(
            key: const ValueKey<String>('history-pagination-retry'),
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

double _horizontalPadding(BuildContext context) {
  final double width = MediaQuery.sizeOf(context).width;

  return width >= AppBreakpoints.desktop
      ? AppSpacing.desktopHorizontalPadding
      : AppSpacing.mobileHorizontalPadding;
}

String _formatHistoryDate(DateTime value) {
  final DateTime local = value.toLocal();

  final String day = local.day.toString().padLeft(2, '0');
  final String month = local.month.toString().padLeft(2, '0');

  final String hour = local.hour.toString().padLeft(2, '0');
  final String minute = local.minute.toString().padLeft(2, '0');

  return '$day/$month/${local.year} · $hour:$minute';
}
