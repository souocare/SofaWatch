import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity_period.dart';
import 'package:sofawatch/features/statistics/presentation/widgets/activity_viewing_count_chart.dart';

void main() {
  group('ActivityViewingCountChart', () {
    testWidgets('shows totals and legend', (WidgetTester tester) async {
      await _pumpChart(
        tester,
        activity: _sevenDayActivity,
        period: StatisticsActivityPeriod.days7,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-viewing-count-chart'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-viewing-count-total'),
        ),
        findsOneWidget,
      );

      expect(find.text('5 episodes · 2 movies'), findsOneWidget);

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-viewing-count-legend'),
        ),
        findsOneWidget,
      );

      expect(find.text('Episodes'), findsOneWidget);
      expect(find.text('Movies'), findsOneWidget);
    });

    testWidgets('creates Episode and Movie bars for every bucket', (
      WidgetTester tester,
    ) async {
      await _pumpChart(
        tester,
        activity: _sevenDayActivity,
        period: StatisticsActivityPeriod.days7,
      );

      for (final DailyStatisticsActivity day in _sevenDayActivity.days) {
        final String date = DateTime(
          day.day.year,
          day.day.month,
          day.day.day,
        ).toIso8601String();

        expect(
          find.byKey(
            ValueKey<String>('detailed-statistics-episodes-bar-$date'),
          ),
          findsOneWidget,
        );

        expect(
          find.byKey(ValueKey<String>('detailed-statistics-movies-bar-$date')),
          findsOneWidget,
        );
      }
    });

    testWidgets('shows empty state without viewing counts', (
      WidgetTester tester,
    ) async {
      await _pumpChart(
        tester,
        activity: _zeroActivity,
        period: StatisticsActivityPeriod.days7,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-viewing-count-empty'),
        ),
        findsOneWidget,
      );

      expect(
        find.text('No Episodes or Movies watched in this period.'),
        findsOneWidget,
      );

      expect(find.text('0 episodes · 0 movies'), findsOneWidget);

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-viewing-count-bars'),
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

      expect(find.text('4 episodes · 1 movies'), findsOneWidget);
    });

    testWidgets('uses monthly buckets for 1Y', (WidgetTester tester) async {
      await _pumpChart(
        tester,
        activity: _yearActivity,
        period: StatisticsActivityPeriod.year1,
      );

      expect(find.text('Jul'), findsOneWidget);
      expect(find.text('Aug'), findsOneWidget);
    });

    testWidgets('supports mixed yearly and monthly All buckets', (
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

    testWidgets('uses singular labels in tooltip', (WidgetTester tester) async {
      await _pumpChart(
        tester,
        activity: _singleViewingActivity,
        period: StatisticsActivityPeriod.days7,
      );

      final Finder group = find.byKey(
        ValueKey<String>(
          'detailed-statistics-episodes-bar-'
          '${DateTime(2026, 8, 18).toIso8601String()}',
        ),
      );

      expect(group, findsOneWidget);

      final Finder tooltip = find.ancestor(
        of: group,
        matching: find.byType(Tooltip),
      );

      expect(tooltip, findsOneWidget);

      final Tooltip widget = tester.widget<Tooltip>(tooltip);

      expect(widget.message, contains('1 Episode · 1 Movie'));
    });

    testWidgets('does not overflow on narrow viewport', (
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
          const ValueKey<String>('detailed-statistics-viewing-count-scroll'),
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
          child: ActivityViewingCountChart(activity: activity, period: period),
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
    _day(2026, 8, 12, episodes: 2),
    _day(2026, 8, 13, movies: 1),
    _day(2026, 8, 14, episodes: 1),
    _day(2026, 8, 15),
    _day(2026, 8, 16, episodes: 1),
    _day(2026, 8, 17),
    _day(2026, 8, 18, episodes: 1, movies: 1),
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
    _day(2026, 8, 17, episodes: 2),
    _day(2026, 8, 18, movies: 1),
    _day(2026, 8, 24, episodes: 2),
  ],
);

final StatisticsActivity _yearActivity = StatisticsActivity(
  startDate: DateTime(2026, 7, 31),
  endDate: DateTime(2026, 8, 18),
  days: <DailyStatisticsActivity>[
    _day(2026, 7, 31, episodes: 1),
    _day(2026, 8, 18, movies: 1),
  ],
);

final StatisticsActivity _allActivity = StatisticsActivity(
  startDate: DateTime(2022, 2, 10),
  endDate: DateTime(2026, 8, 18),
  days: <DailyStatisticsActivity>[
    _day(2022, 2, 10, episodes: 1),
    _day(2023, 6, 5, movies: 1),
    _day(2024, 8, 20, episodes: 1),
    _day(2024, 9, 1, episodes: 1),
    _day(2025, 1, 15, movies: 1),
    _day(2026, 8, 18, episodes: 1),
  ],
);

final StatisticsActivity _singleViewingActivity = StatisticsActivity(
  startDate: DateTime(2026, 8, 18),
  endDate: DateTime(2026, 8, 18),
  days: <DailyStatisticsActivity>[_day(2026, 8, 18, episodes: 1, movies: 1)],
);

final StatisticsActivity _thirtyDayActivity = StatisticsActivity(
  startDate: DateTime(2026, 7, 20),
  endDate: DateTime(2026, 8, 18),
  days: List<DailyStatisticsActivity>.generate(30, (int index) {
    final DateTime day = DateTime(2026, 7, 20).add(Duration(days: index));

    return _day(
      day.year,
      day.month,
      day.day,
      episodes: 1,
      movies: index.isEven ? 1 : 0,
    );
  }, growable: false),
);

DailyStatisticsActivity _day(
  int year,
  int month,
  int day, {
  int episodes = 0,
  int movies = 0,
}) {
  return DailyStatisticsActivity(
    day: DateTime(year, month, day),
    episodesWatched: episodes,
    moviesWatched: movies,
    episodeWatchTimeMinutes: 0,
    movieWatchTimeMinutes: 0,
    watchTimeMinutes: 0,
  );
}
