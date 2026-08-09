import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/app/theme/tokens/app_breakpoints.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';
import 'package:sofawatch/features/explore/application/cubit/explore_cubit.dart';
import 'package:sofawatch/features/explore/application/cubit/explore_state.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending.dart';
import 'package:sofawatch/features/explore/presentation/widgets/explore_header.dart';
import 'package:sofawatch/features/explore/presentation/widgets/explore_horizontal_section.dart';
import 'package:sofawatch/features/explore/presentation/widgets/explore_trending_loading.dart';

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const ExploreHeader(),
                  const SizedBox(height: AppSpacing.xxxl),
                  const _ExploreContent(),
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
        if (state.trending.isInitial || state.trending.isLoading) {
          return const ExploreTrendingLoading();
        }

        if (state.trending.isFailure) {
          return const SizedBox(
            key: ValueKey<String>('explore-trending-failure'),
          );
        }

        final ExploreTrending? trending = state.trending.data;

        if (trending == null || trending.isEmpty) {
          return const SizedBox(
            key: ValueKey<String>('explore-trending-empty'),
          );
        }

        return Column(
          key: const ValueKey<String>('explore-trending-content'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ExploreHorizontalSection(
              title: 'Trending Shows',
              items: trending.shows,
            ),
            if (trending.shows.isNotEmpty && trending.movies.isNotEmpty)
              const SizedBox(height: AppSpacing.xxxl),
            ExploreHorizontalSection(
              title: 'Trending Movies',
              items: trending.movies,
            ),
          ],
        );
      },
    );
  }
}
