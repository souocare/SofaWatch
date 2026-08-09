import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/app/theme/tokens/app_breakpoints.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';
import 'package:sofawatch/features/explore/application/cubit/explore_cubit.dart';
import 'package:sofawatch/features/explore/application/cubit/explore_state.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_genre_options.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_collection.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending.dart';
import 'package:sofawatch/features/explore/presentation/widgets/explore_genre_filter.dart';
import 'package:sofawatch/features/explore/presentation/widgets/explore_header.dart';
import 'package:sofawatch/features/explore/presentation/widgets/explore_horizontal_section.dart';
import 'package:sofawatch/features/explore/presentation/widgets/explore_popular_section_loading.dart';
import 'package:sofawatch/features/explore/presentation/widgets/explore_trending_loading.dart';
import 'package:sofawatch/features/explore/presentation/widgets/explore_week_filter_bar.dart';

class ExploreView extends StatelessWidget {
  const ExploreView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isDesktop = constraints.maxWidth >= AppBreakpoints.tablet;

        return SingleChildScrollView(
          key: const ValueKey<String>('explore-scroll-view'),
          padding: EdgeInsets.only(
            left: isDesktop
                ? AppSpacing.desktopHorizontalPadding
                : AppSpacing.mobileHorizontalPadding,
            right: isDesktop
                ? AppSpacing.desktopHorizontalPadding
                : AppSpacing.mobileHorizontalPadding,
            top: AppSpacing.xxl,
            bottom: AppSpacing.section,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ExploreHeader(),
                  SizedBox(height: AppSpacing.xxxl),
                  _ExploreContent(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ExploreContent extends StatelessWidget {
  const _ExploreContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExploreCubit, ExploreState>(
      builder: (BuildContext context, ExploreState state) {
        final bool isInitial =
            state.today.isInitial &&
            state.week.isInitial &&
            state.genres.isInitial &&
            state.popularShows.isInitial &&
            state.popularMovies.isInitial;

        if (isInitial) {
          return const ExploreTrendingLoading();
        }

        final bool initialLoadInProgress =
            state.today.isLoading &&
            state.week.isLoading &&
            state.genres.isLoading &&
            state.popularShows.isLoading &&
            state.popularMovies.isLoading;

        if (initialLoadInProgress) {
          return const ExploreTrendingLoading();
        }

        final bool coreFailure =
            state.today.isFailure ||
            state.week.isFailure ||
            state.genres.isFailure;

        if (coreFailure) {
          final error =
              state.today.error ?? state.week.error ?? state.genres.error;

          return Column(
            key: const ValueKey<String>('explore-trending-failure'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Could not load Explore.',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                error?.message ??
                    'Something went wrong while loading discovery content.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.tonal(
                key: const ValueKey<String>('explore-retry'),
                onPressed: () {
                  context.read<ExploreCubit>().retry();
                },
                child: const Text('Retry'),
              ),
            ],
          );
        }

        final ExploreTrending? today = state.today.data;
        final ExploreTrending? week = state.week.data;

        final ExploreGenreOptions genres =
            state.genres.data ?? const ExploreGenreOptions();

        final bool todayIsEmpty = today == null || today.isEmpty;
        final bool weekIsEmpty = week == null || week.isEmpty;

        return Column(
          key: const ValueKey<String>('explore-trending-content'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (!todayIsEmpty)
              ExploreHorizontalSection(
                title: 'Trending Today',
                items: today.items,
              ),

            if (!todayIsEmpty) const SizedBox(height: AppSpacing.xxxl),

            if (!weekIsEmpty) ...<Widget>[
              Text(
                'Trending This Week',
                key: const ValueKey<String>('explore-week-title'),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.md),
              const ExploreWeekFilterBar(),
              const SizedBox(height: AppSpacing.lg),
              ExploreHorizontalSection(items: state.filteredWeekItems),
              const SizedBox(height: AppSpacing.xxxl),
            ],

            _PopularShowsSection(genres: genres, state: state),

            const SizedBox(height: AppSpacing.xxxl),

            _PopularMoviesSection(genres: genres, state: state),
          ],
        );
      },
    );
  }
}

class _PopularShowsSection extends StatelessWidget {
  const _PopularShowsSection({required this.genres, required this.state});

  final ExploreGenreOptions genres;
  final ExploreState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('explore-popular-shows-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Popular TV Shows',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),

        ExploreGenreFilter(
          keyPrefix: 'explore-popular-shows',
          genres: genres.shows,
          selectedGenreId: state.selectedShowGenreId,
          onChanged: (int? genreId) {
            context.read<ExploreCubit>().changeShowGenre(genreId);
          },
        ),

        const SizedBox(height: AppSpacing.lg),

        _PopularShowsContent(state: state),
      ],
    );
  }
}

class _PopularShowsContent extends StatelessWidget {
  const _PopularShowsContent({required this.state});

  final ExploreState state;

  @override
  Widget build(BuildContext context) {
    if (state.popularShows.isLoading) {
      return const ExplorePopularSectionLoading(
        sectionKey: 'explore-popular-shows',
      );
    }

    if (state.popularShows.isFailure) {
      return _PopularSectionFailure(
        sectionKey: 'explore-popular-shows',
        message:
            state.popularShows.error?.message ??
            'Could not load popular TV shows.',
        onRetry: () {
          context.read<ExploreCubit>().retryPopularShows();
        },
      );
    }

    final ExploreMediaCollection? collection = state.popularShows.data;

    if (collection == null || collection.isEmpty) {
      return const _PopularSectionEmpty(
        sectionKey: 'explore-popular-shows',
        message: 'No TV shows found for this genre.',
      );
    }

    return ExploreHorizontalSection(items: collection.items);
  }
}

class _PopularMoviesSection extends StatelessWidget {
  const _PopularMoviesSection({required this.genres, required this.state});

  final ExploreGenreOptions genres;
  final ExploreState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('explore-popular-movies-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Popular Movies',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),

        ExploreGenreFilter(
          keyPrefix: 'explore-popular-movies',
          genres: genres.movies,
          selectedGenreId: state.selectedMovieGenreId,
          onChanged: (int? genreId) {
            context.read<ExploreCubit>().changeMovieGenre(genreId);
          },
        ),

        const SizedBox(height: AppSpacing.lg),

        _PopularMoviesContent(state: state),
      ],
    );
  }
}

class _PopularMoviesContent extends StatelessWidget {
  const _PopularMoviesContent({required this.state});

  final ExploreState state;

  @override
  Widget build(BuildContext context) {
    if (state.popularMovies.isLoading) {
      return const ExplorePopularSectionLoading(
        sectionKey: 'explore-popular-movies',
      );
    }

    if (state.popularMovies.isFailure) {
      return _PopularSectionFailure(
        sectionKey: 'explore-popular-movies',
        message:
            state.popularMovies.error?.message ??
            'Could not load popular Movies.',
        onRetry: () {
          context.read<ExploreCubit>().retryPopularMovies();
        },
      );
    }

    final ExploreMediaCollection? collection = state.popularMovies.data;

    if (collection == null || collection.isEmpty) {
      return const _PopularSectionEmpty(
        sectionKey: 'explore-popular-movies',
        message: 'No Movies found for this genre.',
      );
    }

    return ExploreHorizontalSection(items: collection.items);
  }
}

class _PopularSectionFailure extends StatelessWidget {
  const _PopularSectionFailure({
    required this.sectionKey,
    required this.message,
    required this.onRetry,
  });

  final String sectionKey;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey<String>('$sectionKey-failure'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.tonal(
          key: ValueKey<String>('$sectionKey-retry'),
          onPressed: onRetry,
          child: const Text('Retry'),
        ),
      ],
    );
  }
}

class _PopularSectionEmpty extends StatelessWidget {
  const _PopularSectionEmpty({required this.sectionKey, required this.message});

  final String sectionKey;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey<String>('$sectionKey-empty'),
      width: double.infinity,
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
