import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/app/theme/tokens/app_breakpoints.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';
import 'package:sofawatch/features/explore/application/cubit/explore_cubit.dart';
import 'package:sofawatch/features/explore/application/cubit/explore_state.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_collection.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending.dart';
import 'package:sofawatch/features/explore/presentation/widgets/explore_header.dart';
import 'package:sofawatch/features/explore/presentation/widgets/explore_horizontal_section.dart';
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
            state.popularShows.isInitial &&
            state.popularMovies.isInitial;

        final bool isLoading =
            state.today.isLoading ||
            state.week.isLoading ||
            state.popularShows.isLoading ||
            state.popularMovies.isLoading;

        if (isInitial || isLoading) {
          return const ExploreTrendingLoading();
        }

        final bool hasFailure =
            state.today.isFailure ||
            state.week.isFailure ||
            state.popularShows.isFailure ||
            state.popularMovies.isFailure;

        if (hasFailure) {
          return const SizedBox(
            key: ValueKey<String>('explore-trending-failure'),
          );
        }

        final ExploreTrending? today = state.today.data;

        final ExploreTrending? week = state.week.data;

        final ExploreMediaCollection? popularShows = state.popularShows.data;

        final ExploreMediaCollection? popularMovies = state.popularMovies.data;

        final bool todayIsEmpty = today == null || today.isEmpty;

        final bool weekIsEmpty = week == null || week.isEmpty;

        final bool popularShowsIsEmpty =
            popularShows == null || popularShows.isEmpty;

        final bool popularMoviesIsEmpty =
            popularMovies == null || popularMovies.isEmpty;

        if (todayIsEmpty &&
            weekIsEmpty &&
            popularShowsIsEmpty &&
            popularMoviesIsEmpty) {
          return const SizedBox(
            key: ValueKey<String>('explore-trending-empty'),
          );
        }

        return Column(
          key: const ValueKey<String>('explore-trending-content'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (!todayIsEmpty)
              ExploreHorizontalSection(
                title: 'Trending Today',
                items: today.items,
              ),

            if (!todayIsEmpty &&
                (!weekIsEmpty || !popularShowsIsEmpty || !popularMoviesIsEmpty))
              const SizedBox(height: AppSpacing.xxxl),

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
            ],

            if (!weekIsEmpty && (!popularShowsIsEmpty || !popularMoviesIsEmpty))
              const SizedBox(height: AppSpacing.xxxl),

            if (!popularShowsIsEmpty)
              ExploreHorizontalSection(
                title: 'Popular TV Shows',
                items: popularShows.items,
              ),

            if (!popularShowsIsEmpty && !popularMoviesIsEmpty)
              const SizedBox(height: AppSpacing.xxxl),

            if (!popularMoviesIsEmpty)
              ExploreHorizontalSection(
                title: 'Popular Movies',
                items: popularMovies.items,
              ),
          ],
        );
      },
    );
  }
}
