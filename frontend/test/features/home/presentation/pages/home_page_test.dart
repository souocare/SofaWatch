import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/app/theme/tokens/app_breakpoints.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/features/home/presentation/pages/home_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_cubit.dart';
import 'package:sofawatch/features/statistics/domain/models/weekly_statistics.dart';
import 'package:sofawatch/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:sofawatch/features/statistics/presentation/widgets/weekly_statistics_section.dart';

void main() {
  group('HomePage', () {
    testWidgets('renders the Home page structure', (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp());

      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);

      expect(find.byKey(const ValueKey<String>('home-header')), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('home-greeting')),
        findsOneWidget,
      );

      expect(find.byKey(const ValueKey<String>('home-date')), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('home-user-avatar')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('home-sections')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('home-your-week')),
        findsOneWidget,
      );

      expect(find.text('Your Week'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('home-stat-episodes')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('home-stat-movies')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('home-stat-watch-time')),
        findsOneWidget,
      );

      expect(find.text('8'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('10h 42m'), findsOneWidget);
    });

    testWidgets('uses a scrollable Home layout', (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp());

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('home-scroll-view')),
        findsOneWidget,
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('uses mobile horizontal padding on a narrow viewport', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(
        const Size(AppBreakpoints.mobile - 100, 800),
      );

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(_buildTestApp());

      await tester.pumpAndSettle();

      final SingleChildScrollView scrollView = tester
          .widget<SingleChildScrollView>(
            find.byKey(const ValueKey<String>('home-scroll-view')),
          );

      expect(
        scrollView.padding,
        const EdgeInsets.fromLTRB(
          AppSpacing.mobileHorizontalPadding,
          AppSpacing.xxl,
          AppSpacing.mobileHorizontalPadding,
          AppSpacing.section,
        ),
      );
    });

    testWidgets('uses desktop horizontal padding on a wide viewport', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(
        const Size(AppBreakpoints.desktop + 200, 900),
      );

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(_buildTestApp());

      await tester.pumpAndSettle();

      final SingleChildScrollView scrollView = tester
          .widget<SingleChildScrollView>(
            find.byKey(const ValueKey<String>('home-scroll-view')),
          );

      expect(
        scrollView.padding,
        const EdgeInsets.fromLTRB(
          AppSpacing.desktopHorizontalPadding,
          AppSpacing.xxl,
          AppSpacing.desktopHorizontalPadding,
          AppSpacing.section,
        ),
      );
    });

    testWidgets('limits Home content width on an ultrawide viewport', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(2200, 1000));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(_buildTestApp());

      await tester.pumpAndSettle();

      final ConstrainedBox content = tester.widget<ConstrainedBox>(
        find.byKey(const ValueKey<String>('home-content')),
      );

      expect(content.constraints.maxWidth, AppSpacing.maxContentWidth);

      final Size contentSize = tester.getSize(
        find.byKey(const ValueKey<String>('home-content')),
      );

      expect(contentSize.width, lessThanOrEqualTo(AppSpacing.maxContentWidth));
    });
    testWidgets(
      'keeps all three weekly Statistics cards side by side on mobile',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(
          const Size(AppBreakpoints.mobile - 100, 800),
        );

        addTearDown(() async {
          await tester.binding.setSurfaceSize(null);
        });

        await tester.pumpWidget(_buildTestApp());

        await tester.pumpAndSettle();

        final Finder episodes = find.byKey(
          const ValueKey<String>('home-stat-episodes'),
        );

        final Finder movies = find.byKey(
          const ValueKey<String>('home-stat-movies'),
        );

        final Finder watchTime = find.byKey(
          const ValueKey<String>('home-stat-watch-time'),
        );

        expect(episodes, findsOneWidget);
        expect(movies, findsOneWidget);
        expect(watchTime, findsOneWidget);

        final Offset episodesPosition = tester.getTopLeft(episodes);

        final Offset moviesPosition = tester.getTopLeft(movies);

        final Offset watchTimePosition = tester.getTopLeft(watchTime);

        expect(moviesPosition.dx, greaterThan(episodesPosition.dx));

        expect(watchTimePosition.dx, greaterThan(moviesPosition.dx));

        expect(moviesPosition.dy, closeTo(episodesPosition.dy, 1));

        expect(watchTimePosition.dy, closeTo(episodesPosition.dy, 1));
      },
    );
    test('formats compact Watch Time values', () {
      expect(formatWatchTime(0), '0m');
      expect(formatWatchTime(35), '35m');
      expect(formatWatchTime(60), '1h');
      expect(formatWatchTime(95), '1h 35m');
      expect(formatWatchTime(720), '12h');
      expect(formatWatchTime(755), '12h 35m');
    });
  });
}

Widget _buildTestApp() {
  final StatisticsCubit statisticsCubit = StatisticsCubit(
    repository: _FakeStatisticsRepository(),
  );

  statisticsCubit.loadWeeklyStatistics();

  return MaterialApp(
    home: BlocProvider<StatisticsCubit>.value(
      value: statisticsCubit,
      child: const HomePage(),
    ),
  );
}

final class _FakeStatisticsRepository implements StatisticsRepository {
  @override
  Future<WeeklyStatistics> getWeeklyStatistics() async {
    return WeeklyStatistics(
      weekStart: DateTime(2026, 8, 17),
      weekEnd: DateTime(2026, 8, 23),
      episodesWatched: 8,
      moviesWatched: 2,
      watchTimeMinutes: 642,
    );
  }
}
