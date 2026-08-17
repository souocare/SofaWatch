import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_breakpoints.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/features/home/presentation/widgets/home_header.dart';
import 'package:sofawatch/features/statistics/presentation/widgets/weekly_statistics_section.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/features/home/application/cubit/home_cubit.dart';
import 'package:sofawatch/features/home/application/cubit/home_state.dart';
import 'package:sofawatch/features/home/presentation/widgets/premiering_today_section.dart';

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

        return SingleChildScrollView(
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
              child: const _HomeContent(),
            ),
          ),
        );
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeCubit, HomeState>(
      listenWhen: (HomeState previous, HomeState current) {
        return previous.premieringTodayOperationError !=
                current.premieringTodayOperationError &&
            current.premieringTodayOperationError != null;
      },
      listener: (BuildContext context, HomeState state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Could not mark this episode as watched.'),
            ),
          );
      },
      child: const Column(
        key: ValueKey<String>('home-sections'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          HomeHeader(),

          SizedBox(height: AppSpacing.xxxl),

          WeeklyStatisticsSection(),

          SizedBox(height: AppSpacing.section),

          PremieringTodaySection(),
        ],
      ),
    );
  }
}
