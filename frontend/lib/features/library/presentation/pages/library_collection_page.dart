import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/core/widgets/server_network_image.dart';
import 'package:sofawatch/features/library/application/cubit/library_collection_cubit.dart';
import 'package:sofawatch/features/library/application/cubit/library_collection_state.dart';
import 'package:sofawatch/features/movies/domain/models/library_movie.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';

class LibraryCollectionPage extends StatelessWidget {
  const LibraryCollectionPage({
    super.key,
    this.initialTab = LibraryCollectionTab.shows,
  });

  final LibraryCollectionTab initialTab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: LibraryCollectionTab.values.length,
      initialIndex: initialTab.index,
      child: Scaffold(
        key: const ValueKey<String>('library-collection-page'),
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: const Text('Library'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(
                key: ValueKey<String>('library-collection-shows-tab'),
                text: 'Shows',
              ),
              Tab(
                key: ValueKey<String>('library-collection-movies-tab'),
                text: 'Movies',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[_LibraryShowsView(), _LibraryMoviesView()],
        ),
      ),
    );
  }
}

enum LibraryCollectionTab { shows, movies }

class _LibraryShowsView extends StatelessWidget {
  const _LibraryShowsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCollectionCubit, LibraryCollectionState>(
      builder: (BuildContext context, LibraryCollectionState state) {
        if (state.isLoadingShows && state.shows.isEmpty) {
          return const _LibraryCollectionLoading(
            loadingKey: 'library-collection-shows-loading',
          );
        }

        final AppException? error = state.showsError;

        if (error != null && state.shows.isEmpty) {
          return _LibraryCollectionFailure(
            failureKey: 'library-collection-shows-failure',
            message: error.isTimeout
                ? 'Loading your Shows took too long.'
                : 'Could not load your Shows.',
            onRetry: context.read<LibraryCollectionCubit>().retryShows,
          );
        }

        if (state.shows.isEmpty) {
          return const _LibraryCollectionEmpty(
            emptyKey: 'library-collection-shows-empty',
            icon: Icons.tv_outlined,
            title: 'No Shows yet',
            message: 'Shows added to your Library will appear here.',
          );
        }

        return RefreshIndicator(
          onRefresh: context.read<LibraryCollectionCubit>().loadShows,
          child: CustomScrollView(
            key: const ValueKey<String>('library-collection-shows-scroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              if (state.watchingShows.isNotEmpty)
                _ShowSectionSliver(
                  title: 'Watching',
                  sectionKey: 'library-collection-shows-watching',
                  shows: state.watchingShows,
                ),

              if (state.upToDateShows.isNotEmpty)
                _ShowSectionSliver(
                  title: 'Up to Date',
                  sectionKey: 'library-collection-shows-up-to-date',
                  shows: state.upToDateShows,
                ),

              if (state.haventStartedShows.isNotEmpty)
                _ShowSectionSliver(
                  title: 'Haven’t Started',
                  sectionKey: 'library-collection-shows-havent-started',
                  shows: state.haventStartedShows,
                ),

              if (state.finishedShows.isNotEmpty)
                _ShowSectionSliver(
                  title: 'Finished',
                  sectionKey: 'library-collection-shows-finished',
                  shows: state.finishedShows,
                ),

              if (state.pausedShows.isNotEmpty)
                _ShowSectionSliver(
                  title: 'Paused',
                  sectionKey: 'library-collection-shows-paused',
                  shows: state.pausedShows,
                ),

              if (state.droppedShows.isNotEmpty)
                _ShowSectionSliver(
                  title: 'Dropped',
                  sectionKey: 'library-collection-shows-dropped',
                  shows: state.droppedShows,
                ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          ),
        );
      },
    );
  }
}

class _LibraryMoviesView extends StatelessWidget {
  const _LibraryMoviesView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCollectionCubit, LibraryCollectionState>(
      builder: (BuildContext context, LibraryCollectionState state) {
        if (state.isLoadingMovies && state.movies.isEmpty) {
          return const _LibraryCollectionLoading(
            loadingKey: 'library-collection-movies-loading',
          );
        }

        final AppException? error = state.moviesError;

        if (error != null && state.movies.isEmpty) {
          return _LibraryCollectionFailure(
            failureKey: 'library-collection-movies-failure',
            message: error.isTimeout
                ? 'Loading your Movies took too long.'
                : 'Could not load your Movies.',
            onRetry: context.read<LibraryCollectionCubit>().retryMovies,
          );
        }

        if (state.movies.isEmpty) {
          return const _LibraryCollectionEmpty(
            emptyKey: 'library-collection-movies-empty',
            icon: Icons.movie_outlined,
            title: 'No Movies yet',
            message: 'Movies added to your Library will appear here.',
          );
        }

        return RefreshIndicator(
          onRefresh: context.read<LibraryCollectionCubit>().loadMovies,
          child: CustomScrollView(
            key: const ValueKey<String>('library-collection-movies-scroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              if (state.watchlistMovies.isNotEmpty)
                _MovieSectionSliver(
                  title: 'Watchlist',
                  sectionKey: 'library-collection-movies-watchlist',
                  movies: state.watchlistMovies,
                ),

              if (state.upcomingMovies.isNotEmpty)
                _MovieSectionSliver(
                  title: 'Upcoming',
                  sectionKey: 'library-collection-movies-upcoming',
                  movies: state.upcomingMovies,
                ),

              if (state.watchedMovies.isNotEmpty)
                _MovieSectionSliver(
                  title: 'Watched',
                  sectionKey: 'library-collection-movies-watched',
                  movies: state.watchedMovies,
                ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          ),
        );
      },
    );
  }
}

class _ShowSectionSliver extends StatelessWidget {
  const _ShowSectionSliver({
    required this.title,
    required this.sectionKey,
    required this.shows,
  });

  final String title;
  final String sectionKey;
  final List<LibraryShow> shows;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: _LibraryContentBounds(
        child: _LibrarySection(
          sectionKey: sectionKey,
          title: title,
          itemCount: shows.length,
          itemBuilder: (BuildContext context, int index) {
            return _LibraryShowCard(show: shows[index]);
          },
        ),
      ),
    );
  }
}

class _MovieSectionSliver extends StatelessWidget {
  const _MovieSectionSliver({
    required this.title,
    required this.sectionKey,
    required this.movies,
  });

  final String title;
  final String sectionKey;
  final List<LibraryMovie> movies;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: _LibraryContentBounds(
        child: _LibrarySection(
          sectionKey: sectionKey,
          title: title,
          itemCount: movies.length,
          itemBuilder: (BuildContext context, int index) {
            return _LibraryMovieCard(movie: movies[index]);
          },
        ),
      ),
    );
  }
}

class _LibraryContentBounds extends StatelessWidget {
  const _LibraryContentBounds({required this.child});

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

class _LibrarySection extends StatelessWidget {
  const _LibrarySection({
    required this.sectionKey,
    required this.title,
    required this.itemCount,
    required this.itemBuilder,
  });

  final String sectionKey;
  final String title;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;

    final bool isDesktop = screenWidth >= AppBreakpoints.desktop;

    return Padding(
      key: ValueKey<String>(sectionKey),
      padding: EdgeInsets.fromLTRB(
        isDesktop
            ? AppSpacing.desktopHorizontalPadding
            : AppSpacing.mobileHorizontalPadding,
        AppSpacing.xl,
        isDesktop
            ? AppSpacing.desktopHorizontalPadding
            : AppSpacing.mobileHorizontalPadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            key: ValueKey<String>('$sectionKey-title'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: AppSpacing.md),

          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int columns = _libraryGridColumns(constraints.maxWidth);

              return GridView.builder(
                key: ValueKey<String>('$sectionKey-grid'),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: itemCount,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.xl,
                  childAspectRatio: 0.56,
                ),
                itemBuilder: itemBuilder,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LibraryShowCard extends StatelessWidget {
  const _LibraryShowCard({required this.show});

  final LibraryShow show;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey<String>('library-collection-show-${show.showId}'),
      borderRadius: AppRadius.borderLarge,
      onTap: () {
        context.pushNamed(
          AppRoute.showDetails.name,
          pathParameters: <String, String>{'showId': show.tmdbId.toString()},
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: _ShowPosterWithProgress(show: show)),

          const SizedBox(height: AppSpacing.sm),

          Text(
            show.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ShowPosterWithProgress extends StatelessWidget {
  const _ShowPosterWithProgress({required this.show});

  final LibraryShow show;

  @override
  Widget build(BuildContext context) {
    final double progress = (show.progress.percentage / 100).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: AppRadius.borderLarge,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: show.posterUrl == null
                ? const _PosterPlaceholder(icon: Icons.tv_outlined)
                : ServerNetworkImage(
                    imageUrl: show.posterUrl!,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (
                          BuildContext context,
                          Object error,
                          StackTrace? stackTrace,
                        ) {
                          return const _PosterPlaceholder(
                            icon: Icons.tv_outlined,
                          );
                        },
                  ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LinearProgressIndicator(
              key: ValueKey<String>(
                'library-collection-show-progress-${show.showId}',
              ),
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.black.withValues(alpha: 0.38),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryMovieCard extends StatelessWidget {
  const _LibraryMovieCard({required this.movie});

  final LibraryMovie movie;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey<String>('library-collection-movie-${movie.movieId}'),
      borderRadius: AppRadius.borderLarge,
      onTap: () {
        context.pushNamed(
          AppRoute.movieDetails.name,
          pathParameters: <String, String>{'movieId': movie.tmdbId.toString()},
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: ClipRRect(
              borderRadius: AppRadius.borderLarge,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: SizedBox.expand(
                  child: movie.posterUrl == null
                      ? const _PosterPlaceholder(icon: Icons.movie_outlined)
                      : ServerNetworkImage(
                          imageUrl: movie.posterUrl!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (
                                BuildContext context,
                                Object error,
                                StackTrace? stackTrace,
                              ) {
                                return const _PosterPlaceholder(
                                  icon: Icons.movie_outlined,
                                );
                              },
                        ),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            movie.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(child: Icon(icon, size: 36, color: AppColors.textMuted));
  }
}

class _LibraryCollectionLoading extends StatelessWidget {
  const _LibraryCollectionLoading({required this.loadingKey});

  final String loadingKey;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: ValueKey<String>(loadingKey),
      child: const CircularProgressIndicator(),
    );
  }
}

class _LibraryCollectionFailure extends StatelessWidget {
  const _LibraryCollectionFailure({
    required this.failureKey,
    required this.message,
    required this.onRetry,
  });

  final String failureKey;
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: ValueKey<String>(failureKey),
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
              key: ValueKey<String>('$failureKey-retry'),
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

class _LibraryCollectionEmpty extends StatelessWidget {
  const _LibraryCollectionEmpty({
    required this.emptyKey,
    required this.icon,
    required this.title,
    required this.message,
  });

  final String emptyKey;
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: ValueKey<String>(emptyKey),
      child: Padding(
        padding: AppSpacing.cardPaddingLarge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 48, color: AppColors.textMuted),

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

int _libraryGridColumns(double width) {
  return switch (width) {
    >= 1200 => 7,
    >= 900 => 6,
    >= 700 => 5,
    >= 520 => 4,

    // Mobile: explicitly cap the grid at 3 posters per row.
    _ => 3,
  };
}
