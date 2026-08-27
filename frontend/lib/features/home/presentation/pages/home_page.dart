import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/features/home/application/cubit/home_cubit.dart';
import 'package:sofawatch/features/home/application/cubit/home_state.dart';
import 'package:sofawatch/features/home/presentation/widgets/continue_watching_section.dart';
import 'package:sofawatch/features/home/presentation/widgets/home_header.dart';
import 'package:sofawatch/features/home/presentation/widgets/missed_recently_section.dart';
import 'package:sofawatch/features/home/presentation/widgets/premiering_today_section.dart';
import 'package:sofawatch/features/home/presentation/widgets/recent_activity_section.dart';
import 'package:sofawatch/features/home/presentation/widgets/upcoming_section.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_cubit.dart';
import 'package:sofawatch/features/statistics/presentation/widgets/weekly_statistics_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey<String>('home-page'),
      backgroundColor: AppColors.surface,
      body: const SafeArea(child: _HomeView()),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool useDesktopLayout =
            constraints.maxWidth >= AppBreakpoints.tablet;

        final Widget scrollView = SingleChildScrollView(
          key: const ValueKey<String>('home-scroll-view'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            useDesktopLayout
                ? AppSpacing.desktopHorizontalPadding
                : AppSpacing.mobileHorizontalPadding,
            AppSpacing.xxl,
            useDesktopLayout
                ? AppSpacing.desktopHorizontalPadding
                : AppSpacing.mobileHorizontalPadding,
            AppSpacing.section,
          ),
          child: Center(
            child: ConstrainedBox(
              key: const ValueKey<String>('home-content'),
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: _HomeContent(
                showRefreshAction: useDesktopLayout,
                onRefresh: () => _refreshHome(context),
              ),
            ),
          ),
        );

        if (useDesktopLayout) {
          return scrollView;
        }

        return RefreshIndicator(
          key: const ValueKey<String>('home-pull-to-refresh'),
          onRefresh: () => _refreshHome(context),
          child: scrollView,
        );
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.showRefreshAction,
    required this.onRefresh,
  });

  final bool showRefreshAction;

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeCubit, HomeState>(
      listenWhen: (HomeState previous, HomeState current) {
        final bool operationFailed =
            previous.watchOperationError != current.watchOperationError &&
            current.watchOperationError != null;

        final bool operationSucceeded =
            previous.updatingEpisodeId != null &&
            current.updatingEpisodeId == null &&
            current.watchOperationError == null;

        return operationFailed || operationSucceeded;
      },
      listener: (BuildContext context, HomeState state) {
        if (state.watchOperationError != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Could not mark this episode as watched.'),
              ),
            );

          return;
        }

        /*
   * The Episode mutation completed successfully.
   *
   * Weekly Statistics live in their own feature/Cubit, so Home merely
   * requests a silent refresh instead of coupling Statistics to HomeCubit.
   */
        context.read<StatisticsCubit>().refreshWeeklyStatistics();
      },
      child: Column(
        key: ValueKey<String>('home-sections'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          HomeHeader(
            showRefreshAction: showRefreshAction,
            onRefresh: () {
              unawaited(onRefresh());
            },
          ),

          SizedBox(height: AppSpacing.xxxl),

          WeeklyStatisticsSection(),

          SizedBox(height: AppSpacing.section),

          ContinueWatchingSection(),

          SizedBox(height: AppSpacing.section),

          PremieringTodaySection(),

          SizedBox(height: AppSpacing.section),

          UpcomingSection(),

          SizedBox(height: AppSpacing.section),

          MissedRecentlySection(),

          SizedBox(height: AppSpacing.section),

          RecentActivitySection(),
        ],
      ),
    );
  }
}

Future<void> _refreshHome(BuildContext context) async {
  final HomeCubit homeCubit = context.read<HomeCubit>();

  final StatisticsCubit statisticsCubit = context.read<StatisticsCubit>();

  final List<bool> results = await Future.wait<bool>(<Future<bool>>[
    homeCubit.refresh(),
    statisticsCubit.refreshWeeklyStatistics(),
  ]);

  if (!context.mounted) {
    return;
  }

  final bool succeeded = results.every((bool result) => result);

  if (succeeded) {
    return;
  }

  /*
   * Individual sections keep their valid data and expose their own failure
   * state. The global refresh feedback therefore stays intentionally subtle.
   */
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Text('Some Home sections could not be refreshed.'),
      ),
    );
}
