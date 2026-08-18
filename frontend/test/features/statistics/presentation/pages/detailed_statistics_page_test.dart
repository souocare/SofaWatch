import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_activity_cubit.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_summary_cubit.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_summary.dart';
import 'package:sofawatch/features/statistics/domain/models/weekly_statistics.dart';
import 'package:sofawatch/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:sofawatch/features/statistics/presentation/pages/detailed_statistics_page.dart';

void main() {
  group('DetailedStatisticsPage Overview', () {
    testWidgets('shows the lifetime viewing overview', (
      WidgetTester tester,
    ) async {
      await _pumpPage(
        tester,
        summaryRepository: const _SummaryRepository(summary: _summary),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('detailed-statistics-page')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('detailed-statistics-overview')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-overview-title'),
        ),
        findsOneWidget,
      );

      expect(find.text('Overview'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('detailed-statistics-overview-grid')),
        findsOneWidget,
      );

      _expectCardText(
        cardKey: 'detailed-statistics-watch-time',
        texts: <String>['7d 6h', 'Watch time', '1d 5h rewatched'],
      );

      _expectCardText(
        cardKey: 'detailed-statistics-episodes',
        texts: <String>['125', 'Episodes watched', '100 unique · 25 rewatches'],
      );

      _expectCardText(
        cardKey: 'detailed-statistics-movies',
        texts: <String>['34', 'Movies watched', '30 unique · 4 rewatches'],
      );

      _expectCardText(
        cardKey: 'detailed-statistics-shows',
        texts: <String>['12', 'Shows watched'],
      );
    });

    testWidgets('shows the Shows and Movies watch-time split', (
      WidgetTester tester,
    ) async {
      await _pumpPage(
        tester,
        summaryRepository: const _SummaryRepository(summary: _summary),
      );

      await tester.pumpAndSettle();

      final Finder split = find.byKey(
        const ValueKey<String>('detailed-statistics-media-time-split'),
      );

      expect(split, findsOneWidget);

      expect(
        find.descendant(of: split, matching: find.text('Time watching media')),
        findsOneWidget,
      );

      expect(
        find.descendant(of: split, matching: find.text('Shows')),
        findsOneWidget,
      );

      expect(
        find.descendant(of: split, matching: find.text('Movies')),
        findsOneWidget,
      );

      /*
         * 6,250 / 10,450 = 59.8% -> 60%
         * 4,200 / 10,450 = 40.2% -> 40%
         */
      expect(
        find.descendant(of: split, matching: find.text('60%')),
        findsOneWidget,
      );

      expect(
        find.descendant(of: split, matching: find.text('40%')),
        findsOneWidget,
      );

      expect(
        find.descendant(of: split, matching: find.text('4d 8h')),
        findsOneWidget,
      );

      expect(
        find.descendant(of: split, matching: find.text('2d 22h')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-media-time-bar'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('keeps Activity visible while Overview is loading', (
      WidgetTester tester,
    ) async {
      final _ControlledSummaryRepository summaryRepository =
          _ControlledSummaryRepository();

      await _pumpPage(tester, summaryRepository: summaryRepository);

      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-overview-loading'),
        ),
        findsOneWidget,
      );

      /*
         * Activity owns a different Cubit and is therefore free to finish
         * while the Summary request is still pending.
         */
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('detailed-statistics-activity')),
        findsOneWidget,
      );

      summaryRepository.complete(_summary);

      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-overview-loading'),
        ),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('detailed-statistics-overview-grid')),
        findsOneWidget,
      );
    });

    testWidgets(
      'isolates Overview failure from Activity and retries only Summary',
      (WidgetTester tester) async {
        final _RetrySummaryRepository summaryRepository =
            _RetrySummaryRepository();

        await _pumpPage(tester, summaryRepository: summaryRepository);

        await tester.pumpAndSettle();

        expect(summaryRepository.calls, 1);

        expect(
          find.byKey(
            const ValueKey<String>('detailed-statistics-overview-failure'),
          ),
          findsOneWidget,
        );

        expect(
          find.byKey(const ValueKey<String>('detailed-statistics-activity')),
          findsOneWidget,
        );

        expect(
          find.byKey(
            const ValueKey<String>('detailed-statistics-overview-grid'),
          ),
          findsNothing,
        );

        await tester.tap(
          find.byKey(
            const ValueKey<String>(
              'detailed-statistics-overview-failure-retry',
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(summaryRepository.calls, 2);

        expect(
          find.byKey(
            const ValueKey<String>('detailed-statistics-overview-failure'),
          ),
          findsNothing,
        );

        expect(
          find.byKey(
            const ValueKey<String>('detailed-statistics-overview-grid'),
          ),
          findsOneWidget,
        );

        expect(
          find.byKey(const ValueKey<String>('detailed-statistics-activity')),
          findsOneWidget,
        );
      },
    );

    testWidgets('shows usable zero values when there is no viewing history', (
      WidgetTester tester,
    ) async {
      await _pumpPage(
        tester,
        summaryRepository: const _SummaryRepository(summary: _zeroSummary),
      );

      await tester.pumpAndSettle();

      _expectCardText(
        cardKey: 'detailed-statistics-watch-time',
        texts: <String>['0m', 'Watch time', '0m rewatched'],
      );

      _expectCardText(
        cardKey: 'detailed-statistics-episodes',
        texts: <String>['0', 'Episodes watched', '0 unique · 0 rewatches'],
      );

      _expectCardText(
        cardKey: 'detailed-statistics-movies',
        texts: <String>['0', 'Movies watched', '0 unique · 0 rewatches'],
      );

      _expectCardText(
        cardKey: 'detailed-statistics-shows',
        texts: <String>['0', 'Shows watched'],
      );

      final Finder split = find.byKey(
        const ValueKey<String>('detailed-statistics-media-time-split'),
      );

      expect(
        find.descendant(of: split, matching: find.text('0%')),
        findsNWidgets(2),
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-media-time-bar'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('uses singular Rewatch labels when count is one', (
      WidgetTester tester,
    ) async {
      await _pumpPage(
        tester,
        summaryRepository: const _SummaryRepository(
          summary: _singleRewatchSummary,
        ),
      );

      await tester.pumpAndSettle();

      _expectCardText(
        cardKey: 'detailed-statistics-episodes',
        texts: <String>['11', '10 unique · 1 rewatch'],
      );

      _expectCardText(
        cardKey: 'detailed-statistics-movies',
        texts: <String>['6', '5 unique · 1 rewatch'],
      );
    });
  });

  group('DetailedStatisticsPage Activity shell', () {
    testWidgets('shows the page title and loaded Activity', (
      WidgetTester tester,
    ) async {
      await _pumpPage(
        tester,
        summaryRepository: const _SummaryRepository(summary: _summary),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('detailed-statistics-title')),
        findsOneWidget,
      );

      expect(find.text('Detailed Statistics'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('detailed-statistics-activity')),
        findsOneWidget,
      );

      expect(find.text('0 days of activity loaded'), findsOneWidget);
    });
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required StatisticsRepository summaryRepository,
  StatisticsRepository activityRepository = const _ActivityRepository(),
}) async {
  final StatisticsSummaryCubit summaryCubit = StatisticsSummaryCubit(
    repository: summaryRepository,
  )..load();

  final StatisticsActivityCubit activityCubit = StatisticsActivityCubit(
    repository: activityRepository,
  )..load();

  addTearDown(summaryCubit.close);

  addTearDown(activityCubit.close);

  await tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<StatisticsSummaryCubit>.value(value: summaryCubit),
          BlocProvider<StatisticsActivityCubit>.value(value: activityCubit),
        ],
        child: const DetailedStatisticsPage(),
      ),
    ),
  );
}

void _expectCardText({required String cardKey, required List<String> texts}) {
  final Finder card = find.byKey(ValueKey<String>(cardKey));

  expect(card, findsOneWidget);

  for (final String text in texts) {
    expect(
      find.descendant(of: card, matching: find.text(text)),
      findsOneWidget,
    );
  }
}

const StatisticsSummary _summary = StatisticsSummary(
  showsWatched: 12,
  episodes: MediaViewingStatistics(
    watchCount: 125,
    uniqueCount: 100,
    rewatchCount: 25,
    watchTimeMinutes: 6250,
    rewatchTimeMinutes: 1250,
  ),
  movies: MediaViewingStatistics(
    watchCount: 34,
    uniqueCount: 30,
    rewatchCount: 4,
    watchTimeMinutes: 4200,
    rewatchTimeMinutes: 500,
  ),
  watchTimeMinutes: 10450,
  rewatchTimeMinutes: 1750,
);

const StatisticsSummary _zeroSummary = StatisticsSummary(
  showsWatched: 0,
  episodes: MediaViewingStatistics(
    watchCount: 0,
    uniqueCount: 0,
    rewatchCount: 0,
    watchTimeMinutes: 0,
    rewatchTimeMinutes: 0,
  ),
  movies: MediaViewingStatistics(
    watchCount: 0,
    uniqueCount: 0,
    rewatchCount: 0,
    watchTimeMinutes: 0,
    rewatchTimeMinutes: 0,
  ),
  watchTimeMinutes: 0,
  rewatchTimeMinutes: 0,
);

const StatisticsSummary _singleRewatchSummary = StatisticsSummary(
  showsWatched: 4,
  episodes: MediaViewingStatistics(
    watchCount: 11,
    uniqueCount: 10,
    rewatchCount: 1,
    watchTimeMinutes: 500,
    rewatchTimeMinutes: 50,
  ),
  movies: MediaViewingStatistics(
    watchCount: 6,
    uniqueCount: 5,
    rewatchCount: 1,
    watchTimeMinutes: 600,
    rewatchTimeMinutes: 100,
  ),
  watchTimeMinutes: 1100,
  rewatchTimeMinutes: 150,
);

final class _SummaryRepository implements StatisticsRepository {
  const _SummaryRepository({required this.summary});

  final StatisticsSummary summary;

  @override
  Future<StatisticsSummary> getSummary() async {
    return summary;
  }

  @override
  Future<StatisticsActivity> getActivity({required int days}) {
    throw UnimplementedError();
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    throw UnimplementedError();
  }
}

final class _ActivityRepository implements StatisticsRepository {
  const _ActivityRepository();

  @override
  Future<StatisticsActivity> getActivity({required int days}) async {
    return StatisticsActivity(
      startDate: DateTime(2026, 8, 12),
      endDate: DateTime(2026, 8, 18),
      days: const <DailyStatisticsActivity>[],
    );
  }

  @override
  Future<StatisticsSummary> getSummary() {
    throw UnimplementedError();
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    throw UnimplementedError();
  }
}

final class _ControlledSummaryRepository implements StatisticsRepository {
  final Completer<StatisticsSummary> _result = Completer<StatisticsSummary>();

  void complete(StatisticsSummary summary) {
    _result.complete(summary);
  }

  @override
  Future<StatisticsSummary> getSummary() {
    return _result.future;
  }

  @override
  Future<StatisticsActivity> getActivity({required int days}) {
    throw UnimplementedError();
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    throw UnimplementedError();
  }
}

final class _RetrySummaryRepository implements StatisticsRepository {
  int calls = 0;

  @override
  Future<StatisticsSummary> getSummary() async {
    calls += 1;

    if (calls == 1) {
      throw StateError('Temporary Statistics failure.');
    }

    return _summary;
  }

  @override
  Future<StatisticsActivity> getActivity({required int days}) {
    throw UnimplementedError();
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    throw UnimplementedError();
  }
}
