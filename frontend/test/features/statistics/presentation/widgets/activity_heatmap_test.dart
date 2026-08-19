import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity_period.dart';
import 'package:sofawatch/features/statistics/presentation/widgets/activity_heatmap.dart';

void main() {
  group('ActivityHeatmap', () {
    testWidgets('shows one cell for every visible Activity day', (
      WidgetTester tester,
    ) async {
      await _pumpHeatmap(
        tester,
        activity: _sevenDayActivity,
        period: StatisticsActivityPeriod.days7,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-activity-heatmap'),
        ),
        findsOneWidget,
      );

      for (final DailyStatisticsActivity day in _sevenDayActivity.days) {
        expect(
          find.byKey(
            ValueKey<String>(
              'detailed-statistics-activity-heatmap-day-'
              '${DateTime(day.day.year, day.day.month, day.day.day).toIso8601String()}',
            ),
          ),
          findsOneWidget,
        );
      }
    });

    testWidgets('shows the heatmap legend', (WidgetTester tester) async {
      await _pumpHeatmap(
        tester,
        activity: _sevenDayActivity,
        period: StatisticsActivityPeriod.days7,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-activity-heatmap-legend'),
        ),
        findsOneWidget,
      );

      expect(find.text('Less'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
    });

    testWidgets('shows empty state without Activity days', (
      WidgetTester tester,
    ) async {
      await _pumpHeatmap(
        tester,
        activity: _emptyActivity,
        period: StatisticsActivityPeriod.days7,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-activity-heatmap-empty'),
        ),
        findsOneWidget,
      );

      expect(
        find.text('No activity available for this period.'),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-activity-heatmap-scroll'),
        ),
        findsNothing,
      );
    });

    testWidgets('keeps zero-watch days visible', (WidgetTester tester) async {
      await _pumpHeatmap(
        tester,
        activity: _zeroWatchTimeActivity,
        period: StatisticsActivityPeriod.days7,
      );

      expect(
        find.byKey(
          ValueKey<String>(
            'detailed-statistics-activity-heatmap-day-'
            '${DateTime(2026, 8, 18).toIso8601String()}',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('exposes date and viewing data in tooltip', (
      WidgetTester tester,
    ) async {
      await _pumpHeatmap(
        tester,
        activity: _singleActiveDay,
        period: StatisticsActivityPeriod.days7,
      );

      final Finder cell = find.byKey(
        ValueKey<String>(
          'detailed-statistics-activity-heatmap-day-'
          '${DateTime(2026, 8, 18).toIso8601String()}',
        ),
      );

      final Finder tooltipFinder = find.ancestor(
        of: cell,
        matching: find.byType(Tooltip),
      );

      expect(tooltipFinder, findsOneWidget);

      final Tooltip tooltip = tester.widget<Tooltip>(tooltipFinder);

      expect(tooltip.message, contains('18/8/2026'));

      expect(tooltip.message, contains('2h 30m watched'));

      expect(tooltip.message, contains('2 Episodes'));

      expect(tooltip.message, contains('1 Movie'));
    });

    testWidgets('shows Last 365 days for 1Y', (WidgetTester tester) async {
      await _pumpHeatmap(
        tester,
        activity: _sevenDayActivity,
        period: StatisticsActivityPeriod.year1,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-activity-heatmap-range'),
        ),
        findsOneWidget,
      );

      expect(find.text('Last 365 days'), findsOneWidget);
    });

    testWidgets('shows Last 365 days for All', (WidgetTester tester) async {
      await _pumpHeatmap(
        tester,
        activity: _sevenDayActivity,
        period: StatisticsActivityPeriod.all,
      );

      expect(find.text('Last 365 days'), findsOneWidget);
    });

    testWidgets('does not show Last 365 days for shorter periods', (
      WidgetTester tester,
    ) async {
      await _pumpHeatmap(
        tester,
        activity: _sevenDayActivity,
        period: StatisticsActivityPeriod.days90,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-activity-heatmap-range'),
        ),
        findsNothing,
      );
    });

    testWidgets('limits All heatmap to the last 365 days', (
      WidgetTester tester,
    ) async {
      await _pumpHeatmap(
        tester,
        activity: _fourHundredDayActivity,
        period: StatisticsActivityPeriod.all,
      );

      expect(
        find.byKey(
          ValueKey<String>(
            'detailed-statistics-activity-heatmap-day-'
            '${_fourHundredDayActivity.days.first.day.toIso8601String()}',
          ),
        ),
        findsNothing,
      );

      expect(
        find.byKey(
          ValueKey<String>(
            'detailed-statistics-activity-heatmap-day-'
            '${_fourHundredDayActivity.days.last.day.toIso8601String()}',
          ),
        ),
        findsOneWidget,
      );

      final Finder dayCells = find.byWidgetPredicate((Widget widget) {
        final Key? key = widget.key;

        return key is ValueKey<String> &&
            key.value.startsWith('detailed-statistics-activity-heatmap-day-');
      });

      expect(dayCells, findsNWidgets(365));
    });

    testWidgets('lays Monday through Sunday in one calendar week', (
      WidgetTester tester,
    ) async {
      await _pumpHeatmap(
        tester,
        activity: _calendarWeekActivity,
        period: StatisticsActivityPeriod.days7,
      );

      final Finder monday = find.byKey(
        ValueKey<String>(
          'detailed-statistics-activity-heatmap-day-'
          '${DateTime(2026, 8, 17).toIso8601String()}',
        ),
      );

      final Finder sunday = find.byKey(
        ValueKey<String>(
          'detailed-statistics-activity-heatmap-day-'
          '${DateTime(2026, 8, 23).toIso8601String()}',
        ),
      );

      expect(monday, findsOneWidget);
      expect(sunday, findsOneWidget);

      final Offset mondayTopLeft = tester.getTopLeft(monday);

      final Offset sundayTopLeft = tester.getTopLeft(sunday);

      /*
       * Same week means the cells share the same horizontal position,
       * while Sunday is rendered below Monday.
       */
      expect(sundayTopLeft.dx, moreOrLessEquals(mondayTopLeft.dx));

      expect(sundayTopLeft.dy, greaterThan(mondayTopLeft.dy));
    });

    testWidgets('does not overflow on a narrow viewport', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);

      tester.view.devicePixelRatio = 1;

      addTearDown(tester.view.resetPhysicalSize);

      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpHeatmap(
        tester,
        activity: _ninetyDayActivity,
        period: StatisticsActivityPeriod.days90,
      );

      expect(tester.takeException(), isNull);

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-activity-heatmap-scroll'),
        ),
        findsOneWidget,
      );
    });
  });
}

Future<void> _pumpHeatmap(
  WidgetTester tester, {
  required StatisticsActivity activity,
  required StatisticsActivityPeriod period,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ActivityHeatmap(activity: activity, period: period),
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
    _day(2026, 8, 12, watchTimeMinutes: 30),
    _day(2026, 8, 13, watchTimeMinutes: 60),
    _day(2026, 8, 14, watchTimeMinutes: 90),
    _day(2026, 8, 15, watchTimeMinutes: 120),
    _day(2026, 8, 16),
    _day(2026, 8, 17, watchTimeMinutes: 45),
    _day(2026, 8, 18, watchTimeMinutes: 150),
  ],
);

final StatisticsActivity _emptyActivity = StatisticsActivity(
  startDate: DateTime(2026, 8, 18),
  endDate: DateTime(2026, 8, 18),
  days: const <DailyStatisticsActivity>[],
);

final StatisticsActivity _zeroWatchTimeActivity = StatisticsActivity(
  startDate: DateTime(2026, 8, 18),
  endDate: DateTime(2026, 8, 18),
  days: <DailyStatisticsActivity>[_day(2026, 8, 18)],
);

final StatisticsActivity _singleActiveDay = StatisticsActivity(
  startDate: DateTime(2026, 8, 18),
  endDate: DateTime(2026, 8, 18),
  days: <DailyStatisticsActivity>[
    _day(2026, 8, 18, episodes: 2, movies: 1, watchTimeMinutes: 150),
  ],
);

final StatisticsActivity _calendarWeekActivity = StatisticsActivity(
  startDate: DateTime(2026, 8, 17),
  endDate: DateTime(2026, 8, 23),
  days: List<DailyStatisticsActivity>.generate(7, (int index) {
    final DateTime day = DateTime(2026, 8, 17).add(Duration(days: index));

    return _day(day.year, day.month, day.day, watchTimeMinutes: 30);
  }, growable: false),
);

final StatisticsActivity _ninetyDayActivity = StatisticsActivity(
  startDate: DateTime(2026, 5, 21),
  endDate: DateTime(2026, 8, 18),
  days: List<DailyStatisticsActivity>.generate(90, (int index) {
    final DateTime day = DateTime(2026, 5, 21).add(Duration(days: index));

    return _day(
      day.year,
      day.month,
      day.day,
      watchTimeMinutes: index.isEven ? 45 : 0,
    );
  }, growable: false),
);

final StatisticsActivity _fourHundredDayActivity = StatisticsActivity(
  startDate: DateTime(2025, 7, 15),
  endDate: DateTime(2026, 8, 18),
  days: List<DailyStatisticsActivity>.generate(400, (int index) {
    final DateTime day = DateTime(2025, 7, 15).add(Duration(days: index));

    return _day(
      day.year,
      day.month,
      day.day,
      watchTimeMinutes: index.isEven ? 30 : 0,
    );
  }, growable: false),
);

DailyStatisticsActivity _day(
  int year,
  int month,
  int day, {
  int episodes = 0,
  int movies = 0,
  int watchTimeMinutes = 0,
}) {
  return DailyStatisticsActivity(
    day: DateTime(year, month, day),
    episodesWatched: episodes,
    moviesWatched: movies,

    /*
     * The heatmap only needs combined watch time for intensity.
     *
     * Keep the complete domain object coherent by assigning all test
     * minutes to Episode watch time.
     */
    episodeWatchTimeMinutes: watchTimeMinutes,
    movieWatchTimeMinutes: 0,
    watchTimeMinutes: watchTimeMinutes,
  );
}
