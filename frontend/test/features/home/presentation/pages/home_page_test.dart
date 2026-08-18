import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/app/theme/tokens/app_breakpoints.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/home/application/cubit/home_cubit.dart';
import 'package:sofawatch/features/home/presentation/pages/home_page.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';
import 'package:sofawatch/features/shows/domain/models/stale_watching_show.dart';
import 'package:sofawatch/features/shows/domain/models/upcoming_item.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_item.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_page.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_show.dart';
import 'package:sofawatch/features/shows/domain/repositories/shows_repository.dart';
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
    testWidgets('shows compact empty states for empty Home sections', (
      WidgetTester tester,
    ) async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        continueWatching: const <WatchNextShow>[],
        premieringToday: const <UpcomingItem>[],
        upcoming: const <UpcomingItem>[],
        missedRecently: const <UpcomingItem>[],
        watchHistory: const WatchHistoryPage(
          items: <WatchHistoryItem>[],
          hasMore: false,
        ),
      );

      await tester.pumpWidget(_buildTestApp(repository: repository));

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('home-continue-watching-empty')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('home-premiering-today-empty')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('home-upcoming-empty')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('home-missed-recently-empty')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('home-recent-activity-empty')),
        findsOneWidget,
      );
    });
    testWidgets('does not show an empty state when a Home section fails', (
      WidgetTester tester,
    ) async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        failMissedRecently: true,
      );

      await tester.pumpWidget(_buildTestApp(repository: repository));

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('home-missed-recently-failure')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('home-missed-recently-empty')),
        findsNothing,
      );
    });
    testWidgets(
      'shows zero weekly Statistics without an intrusive empty state',
      (WidgetTester tester) async {
        final StatisticsRepository statisticsRepository =
            _ZeroActivityStatisticsRepository();

        await tester.pumpWidget(
          _buildTestApp(statisticsRepository: statisticsRepository),
        );

        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('home-your-week')),
          findsOneWidget,
        );

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

        /*
   * No activity is still valid Statistics data.
   *
   * Keep the normal compact cards instead of replacing the section
   * with a large or intrusive empty-state message.
   */
        expect(find.text('0'), findsNWidgets(2));
        expect(find.text('0m'), findsOneWidget);

        expect(
          find.byKey(const ValueKey<String>('home-your-week-failure')),
          findsNothing,
        );

        expect(
          find.byKey(const ValueKey<String>('home-your-week-loading')),
          findsNothing,
        );
      },
    );
    testWidgets('shows a specific safe message for a section timeout', (
      WidgetTester tester,
    ) async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        missedRecentlyError: const AppException.receiveTimeout(),
      );

      await tester.pumpWidget(_buildTestApp(repository: repository));

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('home-missed-recently-failure')),
        findsOneWidget,
      );

      expect(find.text('This section took too long to load.'), findsOneWidget);

      expect(
        find.byKey(
          const ValueKey<String>('home-missed-recently-failure-retry'),
        ),
        findsOneWidget,
      );
    });
  });
}

Widget _buildTestApp({
  ShowsRepository? repository,
  StatisticsRepository? statisticsRepository,
}) {
  final HomeCubit homeCubit = HomeCubit(
    repository: repository ?? _FakeShowsRepository(),
    now: () => DateTime(2026, 8, 17),
  )..load();

  final StatisticsCubit statisticsCubit = StatisticsCubit(
    repository: statisticsRepository ?? _FakeStatisticsRepository(),
  )..loadWeeklyStatistics();

  return MultiBlocProvider(
    providers: <BlocProvider>[
      BlocProvider<HomeCubit>.value(value: homeCubit),
      BlocProvider<StatisticsCubit>.value(value: statisticsCubit),
    ],
    child: const MaterialApp(home: HomePage()),
  );
}

final class _FakeShowsRepository implements ShowsRepository {
  const _FakeShowsRepository({
    this.continueWatching = const <WatchNextShow>[],
    this.premieringToday = const <UpcomingItem>[],
    this.upcoming = const <UpcomingItem>[],
    this.missedRecently = const <UpcomingItem>[],
    this.watchHistory = const WatchHistoryPage(
      items: <WatchHistoryItem>[],
      hasMore: false,
    ),
    this.failMissedRecently = false,
    this.missedRecentlyError,
  });

  final List<WatchNextShow> continueWatching;
  final List<UpcomingItem> premieringToday;
  final List<UpcomingItem> upcoming;
  final List<UpcomingItem> missedRecently;

  final WatchHistoryPage watchHistory;

  final bool failMissedRecently;
  final AppException? missedRecentlyError;

  @override
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    /*
     * Home uses the same Upcoming endpoint for:
     *
     * - Premiering Today: fromDate == toDate
     * - Upcoming: future date range
     *
     * Keep the distinction explicit in the fake so page tests can
     * configure both collections independently.
     */
    final bool isPremieringToday =
        fromDate != null &&
        toDate != null &&
        fromDate.year == toDate.year &&
        fromDate.month == toDate.month &&
        fromDate.day == toDate.day;

    final List<UpcomingItem> result = isPremieringToday
        ? premieringToday
        : upcoming;

    if (limit == null) {
      return result;
    }

    return result.take(limit).toList(growable: false);
  }

  @override
  Future<List<LibraryShow>> getLibraryShows() async {
    return const <LibraryShow>[];
  }

  @override
  Future<List<WatchNextShow>> getWatchNext({int? limit}) async {
    if (limit == null) {
      return continueWatching;
    }

    return continueWatching.take(limit).toList(growable: false);
  }

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() async {
    return const <StaleWatchingShow>[];
  }

  @override
  Future<WatchHistoryPage> getWatchHistory({
    int limit = 30,
    String? cursor,
  }) async {
    return watchHistory;
  }

  @override
  Future<List<UpcomingItem>> getMissedRecently() async {
    final AppException? error = missedRecentlyError;

    if (error != null) {
      throw error;
    }

    if (failMissedRecently) {
      throw const AppException.connection();
    }

    return missedRecently;
  }

  @override
  Future<void> markEpisodeWatched({required String episodeId}) async {}

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {}

  @override
  Future<void> startShow({required String showId}) async {}
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

final class _ZeroActivityStatisticsRepository implements StatisticsRepository {
  @override
  Future<WeeklyStatistics> getWeeklyStatistics() async {
    return WeeklyStatistics(
      weekStart: DateTime(2026, 8, 17),
      weekEnd: DateTime(2026, 8, 23),
      episodesWatched: 0,
      moviesWatched: 0,
      watchTimeMinutes: 0,
    );
  }
}
