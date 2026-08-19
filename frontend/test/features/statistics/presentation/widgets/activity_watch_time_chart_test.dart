import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity_period.dart';
import 'package:sofawatch/features/statistics/presentation/widgets/activity_watch_time_chart.dart';

void main() {
  group('ActivityWatchTimeChart', () {
    testWidgets('shows total watch time and legend', (
      WidgetTester tester,
    ) async {
      await _pumpChart(
        tester,
        activity: _sevenDayActivity,
        period: StatisticsActivityPeriod.days7,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-watch-time-chart'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-watch-time-chart-total'),
        ),
        findsOneWidget,
      );

      expect(find.text('5h'), findsOneWidget);

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-watch-time-legend'),
        ),
        findsOneWidget,
      );

      expect(find.text('Shows'), findsOneWidget);
      expect(find.text('Movies'), findsOneWidget);
    });

    testWidgets('creates one bar for every daily bucket', (
      WidgetTester tester,
    ) async {
      await _pumpChart(
        tester,
        activity: _sevenDayActivity,
        period: StatisticsActivityPeriod.days7,
      );

      for (final DailyStatisticsActivity day in _sevenDayActivity.days) {
        expect(
          find.byKey(
            ValueKey<String>(
              'detailed-statistics-watch-time-bar-'
              '${DateTime(day.day.year, day.day.month, day.day.day).toIso8601String()}',
            ),
          ),
          findsOneWidget,
        );
      }
    });

    testWidgets('shows daily axis labels for 7D', (WidgetTester tester) async {
      await _pumpChart(
        tester,
        activity: _sevenDayActivity,
        period: StatisticsActivityPeriod.days7,
      );

      for (int day = 12; day <= 18; day++) {
        expect(find.text('$day'), findsOneWidget);
      }
    });

    testWidgets('shows empty state when period has no watch time', (
      WidgetTester tester,
    ) async {
      await _pumpChart(
        tester,
        activity: _zeroActivity,
        period: StatisticsActivityPeriod.days7,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-watch-time-empty'),
        ),
        findsOneWidget,
      );

      expect(find.text('No viewing activity in this period.'), findsOneWidget);

      expect(find.text('0m'), findsOneWidget);

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-watch-time-bars'),
        ),
        findsNothing,
      );
    });

    testWidgets('uses weekly buckets for 90D', (WidgetTester tester) async {
      await _pumpChart(
        tester,
        activity: _ninetyDayActivity,
        period: StatisticsActivityPeriod.days90,
      );

      expect(find.text('17 Aug'), findsOneWidget);
      expect(find.text('24 Aug'), findsOneWidget);
    });

    testWidgets('uses monthly labels for 1Y', (WidgetTester tester) async {
      await _pumpChart(
        tester,
        activity: _yearActivity,
        period: StatisticsActivityPeriod.year1,
      );

      expect(find.text('Jul'), findsOneWidget);
      expect(find.text('Aug'), findsOneWidget);
    });

    testWidgets('supports mixed yearly and monthly buckets for All', (
      WidgetTester tester,
    ) async {
      await _pumpChart(
        tester,
        activity: _allActivity,
        period: StatisticsActivityPeriod.all,
      );

      expect(find.text('2022'), findsOneWidget);
      expect(find.text('2023'), findsOneWidget);
      expect(find.text('2024'), findsOneWidget);

      expect(find.text('Sep'), findsOneWidget);
      expect(find.text('Jan'), findsOneWidget);
      expect(find.text('Aug'), findsOneWidget);
    });

    testWidgets('does not overflow on a narrow viewport', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);

      tester.view.devicePixelRatio = 1;

      addTearDown(tester.view.resetPhysicalSize);

      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpChart(
        tester,
        activity: _thirtyDayActivity,
        period: StatisticsActivityPeriod.days30,
      );

      expect(tester.takeException(), isNull);

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-watch-time-scroll'),
        ),
        findsOneWidget,
      );
    });
  });
}

Future<void> _pumpChart(
  WidgetTester tester, {
  required StatisticsActivity activity,
  required StatisticsActivityPeriod period,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ActivityWatchTimeChart(activity: activity, period: period),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

final StatisticsActivity _sevenDayActivity = StatisticsActivity(
  startDate: DateTime(2026, 8, 12),
  endDate: DateTime(2026, 8, 18),
  days: <DailyStatisticsActivity>[
    _day(2026, 8, 12, episodeMinutes: 50),
    _day(2026, 8, 13, movieMinutes: 120),
    _day(2026, 8, 14, episodeMinutes: 50),
    _day(2026, 8, 15),
    _day(2026, 8, 16, episodeMinutes: 40),
    _day(2026, 8, 17),
    _day(2026, 8, 18, movieMinutes: 40),
  ],
);

final StatisticsActivity _zeroActivity = StatisticsActivity(
  startDate: DateTime(2026, 8, 12),
  endDate: DateTime(2026, 8, 18),
  days: List<DailyStatisticsActivity>.generate(
    7,
    (int index) => _day(2026, 8, 12 + index),
    growable: false,
  ),
);

final StatisticsActivity _ninetyDayActivity = StatisticsActivity(
  startDate: DateTime(2026, 8, 17),
  endDate: DateTime(2026, 8, 24),
  days: <DailyStatisticsActivity>[
    _day(2026, 8, 17, episodeMinutes: 50),
    _day(2026, 8, 18, movieMinutes: 120),
    _day(2026, 8, 24, episodeMinutes: 100),
  ],
);

final StatisticsActivity _yearActivity = StatisticsActivity(
  startDate: DateTime(2026, 7, 31),
  endDate: DateTime(2026, 8, 18),
  days: <DailyStatisticsActivity>[
    _day(2026, 7, 31, episodeMinutes: 50),
    _day(2026, 8, 18, movieMinutes: 120),
  ],
);

final StatisticsActivity _allActivity = StatisticsActivity(
  startDate: DateTime(2022, 2, 10),
  endDate: DateTime(2026, 8, 18),
  days: <DailyStatisticsActivity>[
    _day(2022, 2, 10, episodeMinutes: 40),
    _day(2023, 6, 5, movieMinutes: 100),
    _day(2024, 8, 20, episodeMinutes: 50),
    _day(2024, 9, 1, episodeMinutes: 60),
    _day(2025, 1, 15, movieMinutes: 120),
    _day(2026, 8, 18, episodeMinutes: 45),
  ],
);

final StatisticsActivity _thirtyDayActivity = StatisticsActivity(
  startDate: DateTime(2026, 7, 20),
  endDate: DateTime(2026, 8, 18),
  days: List<DailyStatisticsActivity>.generate(30, (int index) {
    final DateTime day = DateTime(2026, 7, 20).add(Duration(days: index));

    return _day(day.year, day.month, day.day, episodeMinutes: 45);
  }, growable: false),
);

DailyStatisticsActivity _day(
  int year,
  int month,
  int day, {
  int episodes = 0,
  int movies = 0,
  int episodeMinutes = 0,
  int movieMinutes = 0,
}) {
  return DailyStatisticsActivity(
    day: DateTime(year, month, day),
    episodesWatched: episodes,
    moviesWatched: movies,
    episodeWatchTimeMinutes: episodeMinutes,
    movieWatchTimeMinutes: movieMinutes,
    watchTimeMinutes: episodeMinutes + movieMinutes,
  );
}
