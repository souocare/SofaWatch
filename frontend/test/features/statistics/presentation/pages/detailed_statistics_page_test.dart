import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_activity_cubit.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_backlog_cubit.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_content_insights_cubit.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_habits_cubit.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_library_cubit.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_summary_cubit.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity_period.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_backlog.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_content_insights.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_habits.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_library.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_summary.dart';
import 'package:sofawatch/features/statistics/domain/models/weekly_statistics.dart';
import 'package:sofawatch/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:sofawatch/features/statistics/presentation/formatters/statistics_watch_time_formatter.dart';
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

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-watch-time-chart'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-watch-time-empty'),
        ),
        findsOneWidget,
      );

      expect(find.text('No viewing activity in this period.'), findsOneWidget);
    });
    group('DetailedStatisticsPage Activity period selector', () {
      testWidgets('shows every supported Activity period', (
        WidgetTester tester,
      ) async {
        await _pumpPage(
          tester,
          summaryRepository: const _SummaryRepository(summary: _summary),
        );

        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const ValueKey<String>(
              'detailed-statistics-activity-period-selector',
            ),
          ),
          findsOneWidget,
        );

        for (final StatisticsActivityPeriod period
            in StatisticsActivityPeriod.values) {
          expect(
            find.byKey(
              ValueKey<String>('detailed-statistics-period-${period.apiValue}'),
            ),
            findsOneWidget,
          );

          expect(find.text(period.label), findsOneWidget);
        }
      });

      testWidgets('selects 7D by default', (WidgetTester tester) async {
        await _pumpPage(
          tester,
          summaryRepository: const _SummaryRepository(summary: _summary),
        );

        await tester.pumpAndSettle();

        final ChoiceChip chip = tester.widget<ChoiceChip>(
          find.byKey(const ValueKey<String>('detailed-statistics-period-7d')),
        );

        expect(chip.selected, isTrue);
      });

      testWidgets('changes Activity period after new data loads', (
        WidgetTester tester,
      ) async {
        final _PeriodActivityRepository activityRepository =
            _PeriodActivityRepository(
              activities: <StatisticsActivityPeriod, StatisticsActivity>{
                StatisticsActivityPeriod.days7: _sevenDayActivity,
                StatisticsActivityPeriod.days14: _fourteenDayActivity,
              },
            );

        await _pumpPage(
          tester,
          summaryRepository: const _SummaryRepository(summary: _summary),
          activityRepository: activityRepository,
        );

        await tester.pumpAndSettle();

        expect(activityRepository.requestedPeriods, <StatisticsActivityPeriod>[
          StatisticsActivityPeriod.days7,
        ]);

        await tester.tap(
          find.byKey(const ValueKey<String>('detailed-statistics-period-14d')),
        );

        await tester.pumpAndSettle();

        expect(activityRepository.requestedPeriods, <StatisticsActivityPeriod>[
          StatisticsActivityPeriod.days7,
          StatisticsActivityPeriod.days14,
        ]);

        final ChoiceChip sevenDayChip = tester.widget<ChoiceChip>(
          find.byKey(const ValueKey<String>('detailed-statistics-period-7d')),
        );

        final ChoiceChip fourteenDayChip = tester.widget<ChoiceChip>(
          find.byKey(const ValueKey<String>('detailed-statistics-period-14d')),
        );

        expect(sevenDayChip.selected, isFalse);

        expect(fourteenDayChip.selected, isTrue);
      });

      testWidgets(
        'keeps previous Activity selected while another period loads',
        (WidgetTester tester) async {
          final _ControlledActivityRepository activityRepository =
              _ControlledActivityRepository();

          await _pumpPage(
            tester,
            summaryRepository: const _SummaryRepository(summary: _summary),
            activityRepository: activityRepository,
          );

          await tester.pump();

          activityRepository.complete(_sevenDayActivity);

          await tester.pumpAndSettle();

          expect(
            find.byKey(
              const ValueKey<String>('detailed-statistics-watch-time-chart'),
            ),
            findsOneWidget,
          );

          await tester.tap(
            find.byKey(
              const ValueKey<String>('detailed-statistics-period-14d'),
            ),
          );

          await tester.pump();

          final ChoiceChip sevenDayChip = tester.widget<ChoiceChip>(
            find.byKey(const ValueKey<String>('detailed-statistics-period-7d')),
          );

          expect(sevenDayChip.selected, isTrue);

          expect(
            find.byKey(
              const ValueKey<String>('detailed-statistics-watch-time-chart'),
            ),
            findsOneWidget,
          );

          final Finder fourteenDayChip = find.byKey(
            const ValueKey<String>('detailed-statistics-period-14d'),
          );

          expect(
            find.descendant(
              of: fourteenDayChip,
              matching: find.byType(CircularProgressIndicator),
            ),
            findsOneWidget,
          );

          activityRepository.complete(_fourteenDayActivity);

          expect(
            find.byKey(
              const ValueKey<String>('detailed-statistics-watch-time-chart'),
            ),
            findsOneWidget,
          );

          await tester.pumpAndSettle();

          final ChoiceChip loadedFourteenDayChip = tester.widget<ChoiceChip>(
            fourteenDayChip,
          );

          expect(loadedFourteenDayChip.selected, isTrue);
        },
      );

      testWidgets(
        'keeps previous period and Activity when period change fails',
        (WidgetTester tester) async {
          final _FailingPeriodActivityRepository activityRepository =
              _FailingPeriodActivityRepository();

          await _pumpPage(
            tester,
            summaryRepository: const _SummaryRepository(summary: _summary),
            activityRepository: activityRepository,
          );

          await tester.pumpAndSettle();

          expect(
            find.byKey(
              const ValueKey<String>('detailed-statistics-watch-time-chart'),
            ),
            findsOneWidget,
          );

          await tester.tap(
            find.byKey(
              const ValueKey<String>('detailed-statistics-period-14d'),
            ),
          );

          await tester.pumpAndSettle();

          final ChoiceChip sevenDayChip = tester.widget<ChoiceChip>(
            find.byKey(const ValueKey<String>('detailed-statistics-period-7d')),
          );

          final ChoiceChip fourteenDayChip = tester.widget<ChoiceChip>(
            find.byKey(
              const ValueKey<String>('detailed-statistics-period-14d'),
            ),
          );

          expect(sevenDayChip.selected, isTrue);

          expect(fourteenDayChip.selected, isFalse);

          expect(
            find.byKey(
              const ValueKey<String>('detailed-statistics-watch-time-chart'),
            ),
            findsOneWidget,
          );

          expect(
            find.byKey(
              const ValueKey<String>(
                'detailed-statistics-activity-period-error',
              ),
            ),
            findsOneWidget,
          );

          expect(
            activityRepository.requestedPeriods,
            <StatisticsActivityPeriod>[
              StatisticsActivityPeriod.days7,
              StatisticsActivityPeriod.days14,
            ],
          );
        },
      );

      testWidgets('does not reload the selected period', (
        WidgetTester tester,
      ) async {
        final _PeriodActivityRepository activityRepository =
            _PeriodActivityRepository(
              activities: <StatisticsActivityPeriod, StatisticsActivity>{
                StatisticsActivityPeriod.days7: _sevenDayActivity,
              },
            );

        await _pumpPage(
          tester,
          summaryRepository: const _SummaryRepository(summary: _summary),
          activityRepository: activityRepository,
        );

        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey<String>('detailed-statistics-period-7d')),
        );

        await tester.pumpAndSettle();

        expect(activityRepository.requestedPeriods, <StatisticsActivityPeriod>[
          StatisticsActivityPeriod.days7,
        ]);
      });
    });
    group('DetailedStatisticsPage Watching habits', () {
      testWidgets('shows current and longest streak values', (
        WidgetTester tester,
      ) async {
        await _pumpPage(
          tester,
          summaryRepository: const _SummaryRepository(summary: _summary),
          habitsRepository: const _HabitsRepository(
            habits: StatisticsHabits(
              currentStreakDays: 4,
              longestStreakDays: 12,
              biggestMarathonWatchTimeMinutes: 0,
              biggestMarathonDay: null,
              longestBingeEpisodeCount: 0,
              longestBingeDay: null,
              averageActiveDayWatchTimeMinutes: 0,
              mostActiveWeekday: null,
              mostActiveWeekdayWatchCount: 0,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const ValueKey<String>('detailed-statistics-watching-habits'),
          ),
          findsOneWidget,
        );

        expect(
          find.byKey(
            const ValueKey<String>('detailed-statistics-watching-habits-title'),
          ),
          findsOneWidget,
        );

        expect(find.text('Watching habits'), findsOneWidget);

        _expectCardText(
          cardKey: 'detailed-statistics-current-streak',
          texts: <String>['4', 'Current streak', 'days'],
        );

        _expectCardText(
          cardKey: 'detailed-statistics-longest-streak',
          texts: <String>['12', 'Longest streak', 'days'],
        );
      });

      testWidgets('uses singular day label when streak is one', (
        WidgetTester tester,
      ) async {
        await _pumpPage(
          tester,
          summaryRepository: const _SummaryRepository(summary: _summary),
          habitsRepository: const _HabitsRepository(
            habits: StatisticsHabits(
              currentStreakDays: 1,
              longestStreakDays: 1,
              biggestMarathonWatchTimeMinutes: 0,
              biggestMarathonDay: null,
              longestBingeEpisodeCount: 0,
              longestBingeDay: null,
              averageActiveDayWatchTimeMinutes: 0,
              mostActiveWeekday: null,
              mostActiveWeekdayWatchCount: 0,
            ),
          ),
        );

        await tester.pumpAndSettle();

        _expectCardText(
          cardKey: 'detailed-statistics-current-streak',
          texts: <String>['1', 'Current streak', 'day'],
        );

        _expectCardText(
          cardKey: 'detailed-statistics-longest-streak',
          texts: <String>['1', 'Longest streak', 'day'],
        );
      });

      testWidgets('shows usable zero streak values', (
        WidgetTester tester,
      ) async {
        await _pumpPage(
          tester,
          summaryRepository: const _SummaryRepository(summary: _summary),
          habitsRepository: const _HabitsRepository(
            habits: StatisticsHabits(
              currentStreakDays: 0,
              longestStreakDays: 0,
              biggestMarathonWatchTimeMinutes: 0,
              biggestMarathonDay: null,
              longestBingeEpisodeCount: 0,
              longestBingeDay: null,
              averageActiveDayWatchTimeMinutes: 0,
              mostActiveWeekday: null,
              mostActiveWeekdayWatchCount: 0,
            ),
          ),
        );

        await tester.pumpAndSettle();

        _expectCardText(
          cardKey: 'detailed-statistics-current-streak',
          texts: <String>['0', 'Current streak', 'days'],
        );

        _expectCardText(
          cardKey: 'detailed-statistics-longest-streak',
          texts: <String>['0', 'Longest streak', 'days'],
        );
      });

      testWidgets(
        'keeps Overview and Activity visible while Watching habits load',
        (WidgetTester tester) async {
          final _ControlledHabitsRepository habitsRepository =
              _ControlledHabitsRepository();

          await _pumpPage(
            tester,
            summaryRepository: const _SummaryRepository(summary: _summary),
            habitsRepository: habitsRepository,
          );

          await tester.pump();

          expect(
            find.byKey(
              const ValueKey<String>(
                'detailed-statistics-watching-habits-loading',
              ),
            ),
            findsOneWidget,
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

          habitsRepository.complete(_habits);

          await tester.pumpAndSettle();

          expect(
            find.byKey(
              const ValueKey<String>(
                'detailed-statistics-watching-habits-loading',
              ),
            ),
            findsNothing,
          );

          expect(
            find.byKey(
              const ValueKey<String>(
                'detailed-statistics-watching-habits-content',
              ),
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'isolates Watching habits failure from Overview and Activity',
        (WidgetTester tester) async {
          await _pumpPage(
            tester,
            summaryRepository: const _SummaryRepository(summary: _summary),
            habitsRepository: const _FailingHabitsRepository(),
          );

          await tester.pumpAndSettle();

          expect(
            find.byKey(
              const ValueKey<String>(
                'detailed-statistics-watching-habits-failure',
              ),
            ),
            findsOneWidget,
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

          expect(
            find.byKey(
              const ValueKey<String>('detailed-statistics-current-streak'),
            ),
            findsNothing,
          );
        },
      );

      testWidgets('retries only Watching habits after failure', (
        WidgetTester tester,
      ) async {
        final _RetryHabitsRepository habitsRepository =
            _RetryHabitsRepository();

        await _pumpPage(
          tester,
          summaryRepository: const _SummaryRepository(summary: _summary),
          habitsRepository: habitsRepository,
        );

        await tester.pumpAndSettle();

        expect(habitsRepository.calls, 1);

        expect(
          find.byKey(
            const ValueKey<String>(
              'detailed-statistics-watching-habits-failure',
            ),
          ),
          findsOneWidget,
        );

        final Finder retryButton = find.byKey(
          const ValueKey<String>(
            'detailed-statistics-watching-habits-failure-retry',
          ),
        );

        await tester.ensureVisible(retryButton);

        await tester.pumpAndSettle();

        await tester.tap(retryButton);

        await tester.pumpAndSettle();

        expect(habitsRepository.calls, 2);

        expect(
          find.byKey(
            const ValueKey<String>(
              'detailed-statistics-watching-habits-failure',
            ),
          ),
          findsNothing,
        );

        expect(
          find.byKey(
            const ValueKey<String>('detailed-statistics-current-streak'),
          ),
          findsOneWidget,
        );

        expect(
          find.byKey(
            const ValueKey<String>('detailed-statistics-longest-streak'),
          ),
          findsOneWidget,
        );
      });
    });
    testWidgets('shows biggest marathon watch time and day', (
      WidgetTester tester,
    ) async {
      await _pumpPage(
        tester,
        summaryRepository: const _SummaryRepository(summary: _summary),
        habitsRepository: _HabitsRepository(habits: _habitsWithMarathonDay),
      );

      await tester.pumpAndSettle();

      _expectCardText(
        cardKey: 'detailed-statistics-biggest-marathon',
        texts: <String>['4h 30m', 'Biggest marathon', '12 Aug 2026'],
      );
    });
    testWidgets('shows a usable empty biggest marathon state', (
      WidgetTester tester,
    ) async {
      await _pumpPage(
        tester,
        summaryRepository: const _SummaryRepository(summary: _summary),
        habitsRepository: const _HabitsRepository(
          habits: StatisticsHabits(
            currentStreakDays: 0,
            longestStreakDays: 0,
            biggestMarathonWatchTimeMinutes: 0,
            biggestMarathonDay: null,
            longestBingeEpisodeCount: 0,
            longestBingeDay: null,
            averageActiveDayWatchTimeMinutes: 0,
            mostActiveWeekday: null,
            mostActiveWeekdayWatchCount: 0,
          ),
        ),
      );

      await tester.pumpAndSettle();

      _expectCardText(
        cardKey: 'detailed-statistics-biggest-marathon',
        texts: <String>['0m', 'Biggest marathon', 'No known day'],
      );
    });
    testWidgets('shows longest binge episode count and day', (
      WidgetTester tester,
    ) async {
      await _pumpPage(
        tester,
        summaryRepository: const _SummaryRepository(summary: _summary),
        habitsRepository: _HabitsRepository(
          habits: StatisticsHabits(
            currentStreakDays: 4,
            longestStreakDays: 12,
            biggestMarathonWatchTimeMinutes: 270,
            biggestMarathonDay: null,
            longestBingeEpisodeCount: 7,
            longestBingeDay: DateTime(2026, 8, 15),
            averageActiveDayWatchTimeMinutes: 103,
            mostActiveWeekday: 'Monday',
            mostActiveWeekdayWatchCount: 8,
          ),
        ),
      );

      await tester.pumpAndSettle();

      _expectCardText(
        cardKey: 'detailed-statistics-longest-binge',
        texts: <String>['7', 'Longest binge', 'episodes · 15 Aug 2026'],
      );
    });

    testWidgets('uses singular episode label for a one-episode binge', (
      WidgetTester tester,
    ) async {
      await _pumpPage(
        tester,
        summaryRepository: const _SummaryRepository(summary: _summary),
        habitsRepository: _HabitsRepository(
          habits: StatisticsHabits(
            currentStreakDays: 1,
            longestStreakDays: 1,
            biggestMarathonWatchTimeMinutes: 50,
            biggestMarathonDay: null,
            longestBingeEpisodeCount: 1,
            longestBingeDay: DateTime(2026, 8, 18),
            averageActiveDayWatchTimeMinutes: 103,
            mostActiveWeekday: 'Monday',
            mostActiveWeekdayWatchCount: 8,
          ),
        ),
      );

      await tester.pumpAndSettle();

      _expectCardText(
        cardKey: 'detailed-statistics-longest-binge',
        texts: <String>['1', 'Longest binge', 'episode · 18 Aug 2026'],
      );
    });

    testWidgets('shows usable empty longest binge state', (
      WidgetTester tester,
    ) async {
      await _pumpPage(
        tester,
        summaryRepository: const _SummaryRepository(summary: _summary),
        habitsRepository: const _HabitsRepository(
          habits: StatisticsHabits(
            currentStreakDays: 0,
            longestStreakDays: 0,
            biggestMarathonWatchTimeMinutes: 0,
            biggestMarathonDay: null,
            longestBingeEpisodeCount: 0,
            longestBingeDay: null,
            averageActiveDayWatchTimeMinutes: 103,
            mostActiveWeekday: 'Monday',
            mostActiveWeekdayWatchCount: 8,
          ),
        ),
      );

      await tester.pumpAndSettle();

      _expectCardText(
        cardKey: 'detailed-statistics-longest-binge',
        texts: <String>['0', 'Longest binge', 'episodes'],
      );
    });
    testWidgets('shows average active-day watch time', (
      WidgetTester tester,
    ) async {
      await _pumpPage(
        tester,
        summaryRepository: const _SummaryRepository(summary: _summary),
        habitsRepository: const _HabitsRepository(
          habits: StatisticsHabits(
            currentStreakDays: 4,
            longestStreakDays: 12,
            biggestMarathonWatchTimeMinutes: 270,
            biggestMarathonDay: null,
            longestBingeEpisodeCount: 7,
            longestBingeDay: null,
            averageActiveDayWatchTimeMinutes: 103,
            mostActiveWeekday: 'Monday',
            mostActiveWeekdayWatchCount: 8,
          ),
        ),
      );

      await tester.pumpAndSettle();

      _expectCardText(
        cardKey: 'detailed-statistics-average-active-day',
        texts: <String>['1h 43m', 'Average active day', 'per active day'],
      );
    });
    testWidgets('shows zero average active-day watch time', (
      WidgetTester tester,
    ) async {
      await _pumpPage(
        tester,
        summaryRepository: const _SummaryRepository(summary: _summary),
        habitsRepository: const _HabitsRepository(
          habits: StatisticsHabits(
            currentStreakDays: 0,
            longestStreakDays: 0,
            biggestMarathonWatchTimeMinutes: 0,
            biggestMarathonDay: null,
            longestBingeEpisodeCount: 0,
            longestBingeDay: null,
            averageActiveDayWatchTimeMinutes: 0,
            mostActiveWeekday: 'Monday',
            mostActiveWeekdayWatchCount: 8,
          ),
        ),
      );

      await tester.pumpAndSettle();

      _expectCardText(
        cardKey: 'detailed-statistics-average-active-day',
        texts: <String>['0m', 'Average active day', 'per active day'],
      );
    });
    testWidgets('shows most active weekday', (WidgetTester tester) async {
      await _pumpPage(
        tester,
        summaryRepository: const _SummaryRepository(summary: _summary),
        habitsRepository: const _HabitsRepository(
          habits: StatisticsHabits(
            currentStreakDays: 4,
            longestStreakDays: 12,
            biggestMarathonWatchTimeMinutes: 270,
            biggestMarathonDay: null,
            longestBingeEpisodeCount: 7,
            longestBingeDay: null,
            averageActiveDayWatchTimeMinutes: 103,
            mostActiveWeekday: 'Monday',
            mostActiveWeekdayWatchCount: 8,
          ),
        ),
      );

      await tester.pumpAndSettle();

      _expectCardText(
        cardKey: 'detailed-statistics-most-active-weekday',
        texts: <String>['Monday', 'Most active weekday', '8 watches'],
      );
    });
    testWidgets('uses singular watch label for most active weekday', (
      WidgetTester tester,
    ) async {
      await _pumpPage(
        tester,
        summaryRepository: const _SummaryRepository(summary: _summary),
        habitsRepository: const _HabitsRepository(
          habits: StatisticsHabits(
            currentStreakDays: 1,
            longestStreakDays: 1,
            biggestMarathonWatchTimeMinutes: 50,
            biggestMarathonDay: null,
            longestBingeEpisodeCount: 1,
            longestBingeDay: null,
            averageActiveDayWatchTimeMinutes: 50,
            mostActiveWeekday: 'Tuesday',
            mostActiveWeekdayWatchCount: 1,
          ),
        ),
      );

      await tester.pumpAndSettle();

      _expectCardText(
        cardKey: 'detailed-statistics-most-active-weekday',
        texts: <String>['Tuesday', 'Most active weekday', '1 watch'],
      );
    });
    testWidgets('shows usable empty most active weekday state', (
      WidgetTester tester,
    ) async {
      await _pumpPage(
        tester,
        summaryRepository: const _SummaryRepository(summary: _summary),
        habitsRepository: const _HabitsRepository(
          habits: StatisticsHabits(
            currentStreakDays: 0,
            longestStreakDays: 0,
            biggestMarathonWatchTimeMinutes: 0,
            biggestMarathonDay: null,
            longestBingeEpisodeCount: 0,
            longestBingeDay: null,
            averageActiveDayWatchTimeMinutes: 0,
            mostActiveWeekday: null,
            mostActiveWeekdayWatchCount: 0,
          ),
        ),
      );

      await tester.pumpAndSettle();

      _expectCardText(
        cardKey: 'detailed-statistics-most-active-weekday',
        texts: <String>['—', 'Most active weekday', '0 watches'],
      );
    });

    group('DetailedStatisticsPage Content insights', () {
      testWidgets('shows every Content insights group', (
        WidgetTester tester,
      ) async {
        await _pumpPage(
          tester,
          summaryRepository: const _SummaryRepository(summary: _summary),
        );

        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const ValueKey<String>('detailed-statistics-content-insights'),
          ),
          findsOneWidget,
        );

        expect(
          find.byKey(
            const ValueKey<String>(
              'detailed-statistics-content-insights-title',
            ),
          ),
          findsOneWidget,
        );

        expect(find.text('Content insights'), findsOneWidget);

        expect(
          find.byKey(
            const ValueKey<String>('detailed-statistics-most-watched-shows'),
          ),
          findsOneWidget,
        );

        expect(
          find.byKey(
            const ValueKey<String>('detailed-statistics-most-rewatched-shows'),
          ),
          findsOneWidget,
        );

        expect(
          find.byKey(
            const ValueKey<String>(
              'detailed-statistics-most-rewatched-episodes',
            ),
          ),
          findsOneWidget,
        );

        expect(
          find.byKey(
            const ValueKey<String>('detailed-statistics-most-rewatched-movies'),
          ),
          findsOneWidget,
        );

        expect(
          find.byKey(
            const ValueKey<String>('detailed-statistics-top-show-genres'),
          ),
          findsOneWidget,
        );

        expect(
          find.byKey(
            const ValueKey<String>('detailed-statistics-top-movie-genres'),
          ),
          findsOneWidget,
        );
      });

      testWidgets('shows ranked Content insight values', (
        WidgetTester tester,
      ) async {
        await _pumpPage(
          tester,
          summaryRepository: const _SummaryRepository(summary: _summary),
        );

        await tester.pumpAndSettle();

        final Finder mostWatchedShows = find.byKey(
          const ValueKey<String>('detailed-statistics-most-watched-shows'),
        );

        expect(
          find.descendant(
            of: mostWatchedShows,
            matching: find.text('Severance'),
          ),
          findsOneWidget,
        );

        expect(
          find.descendant(
            of: mostWatchedShows,
            matching: find.text('18 watches'),
          ),
          findsOneWidget,
        );

        final Finder rewatchedShows = find.byKey(
          const ValueKey<String>('detailed-statistics-most-rewatched-shows'),
        );

        expect(
          find.descendant(
            of: rewatchedShows,
            matching: find.text('8 rewatches'),
          ),
          findsOneWidget,
        );

        final Finder episodes = find.byKey(
          const ValueKey<String>('detailed-statistics-most-rewatched-episodes'),
        );

        expect(
          find.descendant(
            of: episodes,
            matching: find.text('Good News About Hell'),
          ),
          findsOneWidget,
        );

        expect(
          find.descendant(
            of: episodes,
            matching: find.text('Severance · S01E01'),
          ),
          findsOneWidget,
        );

        expect(
          find.descendant(of: episodes, matching: find.text('3 rewatches')),
          findsOneWidget,
        );

        final Finder movies = find.byKey(
          const ValueKey<String>('detailed-statistics-most-rewatched-movies'),
        );

        expect(
          find.descendant(of: movies, matching: find.text('Dune')),
          findsOneWidget,
        );

        expect(
          find.descendant(of: movies, matching: find.text('4 rewatches')),
          findsOneWidget,
        );

        final Finder showGenres = find.byKey(
          const ValueKey<String>('detailed-statistics-top-show-genres'),
        );

        expect(
          find.descendant(of: showGenres, matching: find.text('Drama')),
          findsOneWidget,
        );

        expect(
          find.descendant(of: showGenres, matching: find.text('24 watches')),
          findsOneWidget,
        );

        final Finder movieGenres = find.byKey(
          const ValueKey<String>('detailed-statistics-top-movie-genres'),
        );

        expect(
          find.descendant(
            of: movieGenres,
            matching: find.text('Science Fiction'),
          ),
          findsOneWidget,
        );

        expect(
          find.descendant(of: movieGenres, matching: find.text('11 watches')),
          findsOneWidget,
        );
      });
    });
    testWidgets('keeps previous sections visible while Content insights load', (
      WidgetTester tester,
    ) async {
      final _ControlledContentInsightsRepository repository =
          _ControlledContentInsightsRepository();

      await _pumpPage(
        tester,
        summaryRepository: const _SummaryRepository(summary: _summary),
        contentInsightsRepository: repository,
      );

      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>(
            'detailed-statistics-content-insights-loading',
          ),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('detailed-statistics-overview-grid')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('detailed-statistics-activity')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-watching-habits-content'),
        ),
        findsOneWidget,
      );

      repository.complete(_contentInsights);

      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>(
            'detailed-statistics-content-insights-loading',
          ),
        ),
        findsNothing,
      );

      expect(
        find.byKey(
          const ValueKey<String>(
            'detailed-statistics-content-insights-content',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('isolates Content insights failure from the other sections', (
      WidgetTester tester,
    ) async {
      await _pumpPage(
        tester,
        summaryRepository: const _SummaryRepository(summary: _summary),
        contentInsightsRepository: const _FailingContentInsightsRepository(),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>(
            'detailed-statistics-content-insights-failure',
          ),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('detailed-statistics-overview-grid')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('detailed-statistics-activity')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-watching-habits-content'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('retries only Content insights after failure', (
      WidgetTester tester,
    ) async {
      final _RetryContentInsightsRepository repository =
          _RetryContentInsightsRepository();

      await _pumpPage(
        tester,
        summaryRepository: const _SummaryRepository(summary: _summary),
        contentInsightsRepository: repository,
      );

      await tester.pumpAndSettle();

      expect(repository.calls, 1);

      final Finder retryButton = find.byKey(
        const ValueKey<String>(
          'detailed-statistics-content-insights-failure-retry',
        ),
      );

      await tester.ensureVisible(retryButton);
      await tester.pumpAndSettle();

      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      expect(repository.calls, 2);

      expect(
        find.byKey(
          const ValueKey<String>(
            'detailed-statistics-content-insights-failure',
          ),
        ),
        findsNothing,
      );

      expect(
        find.byKey(
          const ValueKey<String>(
            'detailed-statistics-content-insights-content',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows usable Content insights empty states', (
      WidgetTester tester,
    ) async {
      await _pumpPage(
        tester,
        summaryRepository: const _SummaryRepository(summary: _summary),
        contentInsightsRepository: const _ContentInsightsRepository(
          insights: _emptyContentInsights,
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-most-watched-shows'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-most-rewatched-shows'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-most-rewatched-episodes'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-most-rewatched-movies'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-top-show-genres'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-top-movie-genres'),
        ),
        findsOneWidget,
      );
    });
    group('DetailedStatisticsPage Library', () {
      testWidgets('shows Library Statistics', (WidgetTester tester) async {
        await _pumpPage(
          tester,
          summaryRepository: const _SummaryRepository(summary: _summary),
        );

        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('detailed-statistics-library')),
          findsOneWidget,
        );

        expect(
          find.byKey(
            const ValueKey<String>('detailed-statistics-library-title'),
          ),
          findsOneWidget,
        );

        expect(find.text('Library'), findsOneWidget);

        _expectCardText(
          cardKey: 'detailed-statistics-shows-added',
          texts: <String>['18', 'Shows added'],
        );

        _expectCardText(
          cardKey: 'detailed-statistics-movies-added',
          texts: <String>['42', 'Movies added'],
        );

        _expectCardText(
          cardKey: 'detailed-statistics-shows-completed',
          texts: <String>['7', 'Shows completed'],
        );
      });

      testWidgets('shows usable zero Library Statistics', (
        WidgetTester tester,
      ) async {
        await _pumpPage(
          tester,
          summaryRepository: const _SummaryRepository(summary: _summary),
          libraryRepository: const _LibraryStatisticsRepository(
            statistics: _emptyLibraryStatistics,
          ),
        );

        await tester.pumpAndSettle();

        _expectCardText(
          cardKey: 'detailed-statistics-shows-added',
          texts: <String>['0', 'Shows added'],
        );

        _expectCardText(
          cardKey: 'detailed-statistics-movies-added',
          texts: <String>['0', 'Movies added'],
        );

        _expectCardText(
          cardKey: 'detailed-statistics-shows-completed',
          texts: <String>['0', 'Shows completed'],
        );
      });
    });
    testWidgets(
      'keeps previous sections visible while Library Statistics load',
      (WidgetTester tester) async {
        final _ControlledLibraryStatisticsRepository repository =
            _ControlledLibraryStatisticsRepository();

        await _pumpPage(
          tester,
          summaryRepository: const _SummaryRepository(summary: _summary),
          libraryRepository: repository,
        );

        await tester.pump();

        expect(
          find.byKey(
            const ValueKey<String>('detailed-statistics-library-loading'),
          ),
          findsOneWidget,
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

        expect(
          find.byKey(
            const ValueKey<String>(
              'detailed-statistics-watching-habits-content',
            ),
          ),
          findsOneWidget,
        );

        expect(
          find.byKey(
            const ValueKey<String>(
              'detailed-statistics-content-insights-content',
            ),
          ),
          findsOneWidget,
        );

        repository.complete(_libraryStatistics);

        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const ValueKey<String>('detailed-statistics-library-loading'),
          ),
          findsNothing,
        );

        expect(
          find.byKey(
            const ValueKey<String>('detailed-statistics-library-content'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('isolates Library Statistics failure from the other sections', (
      WidgetTester tester,
    ) async {
      await _pumpPage(
        tester,
        summaryRepository: const _SummaryRepository(summary: _summary),
        libraryRepository: const _FailingLibraryStatisticsRepository(),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-library-failure'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('detailed-statistics-overview-grid')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('detailed-statistics-activity')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-watching-habits-content'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>(
            'detailed-statistics-content-insights-content',
          ),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-library-content'),
        ),
        findsNothing,
      );
    });

    testWidgets('retries only Library Statistics after failure', (
      WidgetTester tester,
    ) async {
      final _RetryLibraryStatisticsRepository repository =
          _RetryLibraryStatisticsRepository();

      await _pumpPage(
        tester,
        summaryRepository: const _SummaryRepository(summary: _summary),
        libraryRepository: repository,
      );

      await tester.pumpAndSettle();

      expect(repository.calls, 1);

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-library-failure'),
        ),
        findsOneWidget,
      );

      final Finder retryButton = find.byKey(
        const ValueKey<String>('detailed-statistics-library-failure-retry'),
      );

      await tester.ensureVisible(retryButton);
      await tester.pumpAndSettle();

      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      expect(repository.calls, 2);

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-library-failure'),
        ),
        findsNothing,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-library-content'),
        ),
        findsOneWidget,
      );
    });
    testWidgets('shows Backlog and future Statistics', (
      WidgetTester tester,
    ) async {
      await _pumpPage(
        tester,
        summaryRepository: const _SummaryRepository(summary: _summary),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('detailed-statistics-backlog')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('detailed-statistics-backlog-title')),
        findsOneWidget,
      );

      _expectCardText(
        cardKey: 'detailed-statistics-unwatched-aired-episodes',
        texts: <String>['Unwatched aired', '24', 'episodes'],
      );

      _expectCardText(
        cardKey: 'detailed-statistics-planned-movies',
        texts: <String>['Planned Movies', '6', 'movies'],
      );

      _expectCardText(
        cardKey: 'detailed-statistics-future-watch-time',
        texts: <String>[
          'Future watch time',
          formatStatisticsWatchTime(1830),
          'known backlog runtime',
        ],
      );

      _expectCardText(
        cardKey: 'detailed-statistics-catch-up-speed',
        texts: <String>['Catch-up speed', '4.5', 'episodes per week'],
      );

      _expectCardText(
        cardKey: 'detailed-statistics-backlog-trend',
        texts: <String>['Backlog trend', 'Shrinking', '-3 episodes'],
      );
    });
    testWidgets('shows usable empty Backlog Statistics', (
      WidgetTester tester,
    ) async {
      await _pumpPage(
        tester,
        summaryRepository: const _SummaryRepository(summary: _summary),
        backlogRepository: const _BacklogStatisticsRepository(
          statistics: _emptyBacklogStatistics,
        ),
      );

      await tester.pumpAndSettle();

      _expectCardText(
        cardKey: 'detailed-statistics-unwatched-aired-episodes',
        texts: <String>['0', 'episodes'],
      );

      _expectCardText(
        cardKey: 'detailed-statistics-planned-movies',
        texts: <String>['0', 'movies'],
      );

      _expectCardText(
        cardKey: 'detailed-statistics-catch-up-speed',
        texts: <String>['0', 'episodes per week'],
      );

      _expectCardText(
        cardKey: 'detailed-statistics-backlog-trend',
        texts: <String>['Stable', 'no change'],
      );
    });
    testWidgets('keeps previous sections visible while Backlog loads', (
      WidgetTester tester,
    ) async {
      final _ControlledBacklogStatisticsRepository repository =
          _ControlledBacklogStatisticsRepository();

      await _pumpPage(
        tester,
        summaryRepository: const _SummaryRepository(summary: _summary),
        backlogRepository: repository,
      );

      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-backlog-loading'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('detailed-statistics-overview-grid')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-watching-habits-content'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>(
            'detailed-statistics-content-insights-content',
          ),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-library-content'),
        ),
        findsOneWidget,
      );

      repository.complete(_backlogStatistics);

      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-backlog-loading'),
        ),
        findsNothing,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-backlog-content'),
        ),
        findsOneWidget,
      );
    });
    testWidgets('isolates Backlog failure from other sections', (
      WidgetTester tester,
    ) async {
      await _pumpPage(
        tester,
        summaryRepository: const _SummaryRepository(summary: _summary),
        backlogRepository: const _FailingBacklogStatisticsRepository(),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-backlog-failure'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('detailed-statistics-overview-grid')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-watching-habits-content'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>(
            'detailed-statistics-content-insights-content',
          ),
        ),
        findsOneWidget,
      );
    });
    testWidgets('retries only Backlog after failure', (
      WidgetTester tester,
    ) async {
      final _RetryBacklogStatisticsRepository repository =
          _RetryBacklogStatisticsRepository();

      await _pumpPage(
        tester,
        summaryRepository: const _SummaryRepository(summary: _summary),
        backlogRepository: repository,
      );

      await tester.pumpAndSettle();

      expect(repository.calls, 1);

      final Finder retryButton = find.byKey(
        const ValueKey<String>('detailed-statistics-backlog-failure-retry'),
      );

      await tester.ensureVisible(retryButton);
      await tester.pumpAndSettle();

      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      expect(repository.calls, 2);

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-backlog-failure'),
        ),
        findsNothing,
      );

      expect(
        find.byKey(
          const ValueKey<String>('detailed-statistics-backlog-content'),
        ),
        findsOneWidget,
      );
    });
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required StatisticsRepository summaryRepository,
  StatisticsRepository activityRepository = const _ActivityRepository(),
  StatisticsRepository habitsRepository = const _HabitsRepository(),
  StatisticsRepository contentInsightsRepository =
      const _ContentInsightsRepository(),
  StatisticsRepository libraryRepository = const _LibraryStatisticsRepository(),
  StatisticsRepository backlogRepository = const _BacklogStatisticsRepository(),
}) async {
  final StatisticsSummaryCubit summaryCubit = StatisticsSummaryCubit(
    repository: summaryRepository,
  )..load();

  final StatisticsActivityCubit activityCubit = StatisticsActivityCubit(
    repository: activityRepository,
  )..load();

  final StatisticsHabitsCubit habitsCubit = StatisticsHabitsCubit(
    repository: habitsRepository,
  )..load();

  final StatisticsContentInsightsCubit contentInsightsCubit =
      StatisticsContentInsightsCubit(repository: contentInsightsRepository)
        ..load();

  final StatisticsLibraryCubit libraryCubit = StatisticsLibraryCubit(
    repository: libraryRepository,
  )..load();

  final StatisticsBacklogCubit backlogCubit = StatisticsBacklogCubit(
    repository: backlogRepository,
  )..load();

  addTearDown(summaryCubit.close);

  addTearDown(activityCubit.close);

  addTearDown(habitsCubit.close);

  addTearDown(contentInsightsCubit.close);

  addTearDown(libraryCubit.close);

  addTearDown(backlogCubit.close);

  await tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<StatisticsSummaryCubit>.value(value: summaryCubit),
          BlocProvider<StatisticsActivityCubit>.value(value: activityCubit),
          BlocProvider<StatisticsHabitsCubit>.value(value: habitsCubit),
          BlocProvider<StatisticsContentInsightsCubit>.value(
            value: contentInsightsCubit,
          ),
          BlocProvider<StatisticsLibraryCubit>.value(value: libraryCubit),
          BlocProvider<StatisticsBacklogCubit>.value(value: backlogCubit),
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

const StatisticsLibrary _libraryStatistics = StatisticsLibrary(
  showsAdded: 18,
  moviesAdded: 42,
  showsCompleted: 7,
);

const StatisticsLibrary _emptyLibraryStatistics = StatisticsLibrary(
  showsAdded: 0,
  moviesAdded: 0,
  showsCompleted: 0,
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

const StatisticsHabits _habits = StatisticsHabits(
  currentStreakDays: 4,
  longestStreakDays: 12,
  biggestMarathonWatchTimeMinutes: 270,
  biggestMarathonDay: null,
  longestBingeEpisodeCount: 7,
  longestBingeDay: null,
  averageActiveDayWatchTimeMinutes: 103,
  mostActiveWeekday: 'Monday',
  mostActiveWeekdayWatchCount: 8,
);

const StatisticsContentInsights _contentInsights = StatisticsContentInsights(
  mostWatchedShows: <StatisticsShowInsight>[
    StatisticsShowInsight(
      showId: 'show-1',
      tmdbId: 95396,
      title: 'Severance',
      posterUrl: null,
      watchCount: 18,
      rewatchCount: 8,
    ),
    StatisticsShowInsight(
      showId: 'show-2',
      tmdbId: 1399,
      title: 'Game of Thrones',
      posterUrl: null,
      watchCount: 12,
      rewatchCount: 2,
    ),
  ],
  mostRewatchedShows: <StatisticsShowInsight>[
    StatisticsShowInsight(
      showId: 'show-1',
      tmdbId: 95396,
      title: 'Severance',
      posterUrl: null,
      watchCount: 18,
      rewatchCount: 8,
    ),
  ],
  mostRewatchedEpisodes: <StatisticsEpisodeInsight>[
    StatisticsEpisodeInsight(
      episodeId: 'episode-1',
      showTmdbId: 95396,
      showTitle: 'Severance',
      seasonNumber: 1,
      episodeNumber: 1,
      episodeTitle: 'Good News About Hell',
      stillUrl: null,
      watchCount: 4,
      rewatchCount: 3,
    ),
  ],
  mostRewatchedMovies: <StatisticsMovieInsight>[
    StatisticsMovieInsight(
      movieId: 'movie-1',
      tmdbId: 438631,
      title: 'Dune',
      posterUrl: null,
      watchCount: 5,
      rewatchCount: 4,
    ),
  ],
  topShowGenres: <StatisticsGenreInsight>[
    StatisticsGenreInsight(genreId: 18, name: 'Drama', watchCount: 24),
    StatisticsGenreInsight(genreId: 9648, name: 'Mystery', watchCount: 15),
  ],
  topMovieGenres: <StatisticsGenreInsight>[
    StatisticsGenreInsight(
      genreId: 878,
      name: 'Science Fiction',
      watchCount: 11,
    ),
  ],
);

const StatisticsContentInsights _emptyContentInsights =
    StatisticsContentInsights(
      mostWatchedShows: <StatisticsShowInsight>[],
      mostRewatchedShows: <StatisticsShowInsight>[],
      mostRewatchedEpisodes: <StatisticsEpisodeInsight>[],
      mostRewatchedMovies: <StatisticsMovieInsight>[],
      topShowGenres: <StatisticsGenreInsight>[],
      topMovieGenres: <StatisticsGenreInsight>[],
    );

const StatisticsBacklog _backlogStatistics = StatisticsBacklog(
  unwatchedAiredEpisodes: 24,
  plannedMovies: 6,
  futureWatchTimeMinutes: 1830,
  catchUpSpeedEpisodesPerWeek: 4.5,
  backlogTrend: 'shrinking',
  backlogTrendEpisodeDelta: -3,
);

const StatisticsBacklog _emptyBacklogStatistics = StatisticsBacklog(
  unwatchedAiredEpisodes: 0,
  plannedMovies: 0,
  futureWatchTimeMinutes: 0,
  catchUpSpeedEpisodesPerWeek: 0,
  backlogTrend: 'stable',
  backlogTrendEpisodeDelta: 0,
);

final StatisticsHabits _habitsWithMarathonDay = StatisticsHabits(
  currentStreakDays: 4,
  longestStreakDays: 12,
  biggestMarathonWatchTimeMinutes: 270,
  biggestMarathonDay: DateTime(2026, 8, 12),
  longestBingeEpisodeCount: 7,
  longestBingeDay: null,
  averageActiveDayWatchTimeMinutes: 103,
  mostActiveWeekday: 'Monday',
  mostActiveWeekdayWatchCount: 8,
);

final StatisticsActivity _sevenDayActivity = StatisticsActivity(
  startDate: DateTime(2026, 8, 12),
  endDate: DateTime(2026, 8, 18),
  days: List<DailyStatisticsActivity>.generate(7, (int index) {
    return DailyStatisticsActivity(
      day: DateTime(2026, 8, 12 + index),
      episodesWatched: 0,
      moviesWatched: 0,
      episodeWatchTimeMinutes: 0,
      movieWatchTimeMinutes: 0,
      watchTimeMinutes: 0,
    );
  }, growable: false),
);

final StatisticsActivity _fourteenDayActivity = StatisticsActivity(
  startDate: DateTime(2026, 8, 5),
  endDate: DateTime(2026, 8, 18),
  days: List<DailyStatisticsActivity>.generate(14, (int index) {
    return DailyStatisticsActivity(
      day: DateTime(2026, 8, 5 + index),
      episodesWatched: 0,
      moviesWatched: 0,
      episodeWatchTimeMinutes: 0,
      movieWatchTimeMinutes: 0,
      watchTimeMinutes: 0,
    );
  }, growable: false),
);

final class _SummaryRepository implements StatisticsRepository {
  const _SummaryRepository({required this.summary});

  final StatisticsSummary summary;

  @override
  Future<StatisticsSummary> getSummary() async {
    return summary;
  }

  @override
  Future<StatisticsActivity> getActivity({
    required StatisticsActivityPeriod period,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsHabits> getHabits() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsContentInsights> getContentInsights() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsLibrary> getLibraryStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsBacklog> getBacklogStatistics() {
    throw UnimplementedError();
  }
}

final class _ActivityRepository implements StatisticsRepository {
  const _ActivityRepository();

  @override
  Future<StatisticsActivity> getActivity({
    required StatisticsActivityPeriod period,
  }) async {
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

  @override
  Future<StatisticsHabits> getHabits() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsContentInsights> getContentInsights() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsLibrary> getLibraryStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsBacklog> getBacklogStatistics() {
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
  Future<StatisticsActivity> getActivity({
    required StatisticsActivityPeriod period,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsHabits> getHabits() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsContentInsights> getContentInsights() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsLibrary> getLibraryStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsBacklog> getBacklogStatistics() {
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
  Future<StatisticsActivity> getActivity({
    required StatisticsActivityPeriod period,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsHabits> getHabits() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsContentInsights> getContentInsights() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsLibrary> getLibraryStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsBacklog> getBacklogStatistics() {
    throw UnimplementedError();
  }
}

final class _PeriodActivityRepository implements StatisticsRepository {
  _PeriodActivityRepository({required this.activities});

  final Map<StatisticsActivityPeriod, StatisticsActivity> activities;

  final List<StatisticsActivityPeriod> requestedPeriods =
      <StatisticsActivityPeriod>[];

  @override
  Future<StatisticsActivity> getActivity({
    required StatisticsActivityPeriod period,
  }) async {
    requestedPeriods.add(period);

    return activities[period]!;
  }

  @override
  Future<StatisticsSummary> getSummary() {
    throw UnimplementedError();
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsHabits> getHabits() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsContentInsights> getContentInsights() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsLibrary> getLibraryStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsBacklog> getBacklogStatistics() {
    throw UnimplementedError();
  }
}

final class _ControlledActivityRepository implements StatisticsRepository {
  Completer<StatisticsActivity>? _result;

  @override
  Future<StatisticsActivity> getActivity({
    required StatisticsActivityPeriod period,
  }) {
    _result = Completer<StatisticsActivity>();

    return _result!.future;
  }

  void complete(StatisticsActivity activity) {
    _result!.complete(activity);
  }

  @override
  Future<StatisticsSummary> getSummary() {
    throw UnimplementedError();
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsHabits> getHabits() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsContentInsights> getContentInsights() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsLibrary> getLibraryStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsBacklog> getBacklogStatistics() {
    throw UnimplementedError();
  }
}

final class _FailingPeriodActivityRepository implements StatisticsRepository {
  final List<StatisticsActivityPeriod> requestedPeriods =
      <StatisticsActivityPeriod>[];

  int calls = 0;

  @override
  Future<StatisticsActivity> getActivity({
    required StatisticsActivityPeriod period,
  }) async {
    requestedPeriods.add(period);

    calls += 1;

    if (calls == 1) {
      return _sevenDayActivity;
    }

    throw const AppException.connection();
  }

  @override
  Future<StatisticsSummary> getSummary() {
    throw UnimplementedError();
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsHabits> getHabits() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsContentInsights> getContentInsights() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsLibrary> getLibraryStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsBacklog> getBacklogStatistics() {
    throw UnimplementedError();
  }
}

final class _HabitsRepository implements StatisticsRepository {
  const _HabitsRepository({this.habits = _habits});

  final StatisticsHabits habits;

  @override
  Future<StatisticsHabits> getHabits() async {
    return habits;
  }

  @override
  Future<StatisticsActivity> getActivity({
    required StatisticsActivityPeriod period,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsSummary> getSummary() {
    throw UnimplementedError();
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsContentInsights> getContentInsights() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsLibrary> getLibraryStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsBacklog> getBacklogStatistics() {
    throw UnimplementedError();
  }
}

final class _ContentInsightsRepository implements StatisticsRepository {
  const _ContentInsightsRepository({this.insights = _contentInsights});

  final StatisticsContentInsights insights;

  @override
  Future<StatisticsContentInsights> getContentInsights() async {
    return insights;
  }

  @override
  Future<StatisticsSummary> getSummary() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsActivity> getActivity({
    required StatisticsActivityPeriod period,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsHabits> getHabits() {
    throw UnimplementedError();
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsLibrary> getLibraryStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsBacklog> getBacklogStatistics() {
    throw UnimplementedError();
  }
}

final class _ControlledHabitsRepository implements StatisticsRepository {
  final Completer<StatisticsHabits> _result = Completer<StatisticsHabits>();

  void complete(StatisticsHabits habits) {
    _result.complete(habits);
  }

  @override
  Future<StatisticsHabits> getHabits() {
    return _result.future;
  }

  @override
  Future<StatisticsActivity> getActivity({
    required StatisticsActivityPeriod period,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsSummary> getSummary() {
    throw UnimplementedError();
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsContentInsights> getContentInsights() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsLibrary> getLibraryStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsBacklog> getBacklogStatistics() {
    throw UnimplementedError();
  }
}

final class _FailingHabitsRepository implements StatisticsRepository {
  const _FailingHabitsRepository();

  @override
  Future<StatisticsHabits> getHabits() {
    throw const AppException.connection();
  }

  @override
  Future<StatisticsActivity> getActivity({
    required StatisticsActivityPeriod period,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsSummary> getSummary() {
    throw UnimplementedError();
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsContentInsights> getContentInsights() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsLibrary> getLibraryStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsBacklog> getBacklogStatistics() {
    throw UnimplementedError();
  }
}

final class _RetryHabitsRepository implements StatisticsRepository {
  int calls = 0;

  @override
  Future<StatisticsHabits> getHabits() async {
    calls += 1;

    if (calls == 1) {
      throw const AppException.connection();
    }

    return _habits;
  }

  @override
  Future<StatisticsActivity> getActivity({
    required StatisticsActivityPeriod period,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsSummary> getSummary() {
    throw UnimplementedError();
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsContentInsights> getContentInsights() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsLibrary> getLibraryStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsBacklog> getBacklogStatistics() {
    throw UnimplementedError();
  }
}

final class _ControlledContentInsightsRepository
    implements StatisticsRepository {
  final Completer<StatisticsContentInsights> _result =
      Completer<StatisticsContentInsights>();

  void complete(StatisticsContentInsights insights) {
    _result.complete(insights);
  }

  @override
  Future<StatisticsContentInsights> getContentInsights() {
    return _result.future;
  }

  @override
  Future<StatisticsSummary> getSummary() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsActivity> getActivity({
    required StatisticsActivityPeriod period,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsHabits> getHabits() {
    throw UnimplementedError();
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsLibrary> getLibraryStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsBacklog> getBacklogStatistics() {
    throw UnimplementedError();
  }
}

final class _RetryContentInsightsRepository implements StatisticsRepository {
  int calls = 0;

  @override
  Future<StatisticsContentInsights> getContentInsights() async {
    calls += 1;

    if (calls == 1) {
      throw const AppException.connection();
    }

    return _contentInsights;
  }

  @override
  Future<StatisticsSummary> getSummary() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsActivity> getActivity({
    required StatisticsActivityPeriod period,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsHabits> getHabits() {
    throw UnimplementedError();
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsLibrary> getLibraryStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsBacklog> getBacklogStatistics() {
    throw UnimplementedError();
  }
}

final class _FailingContentInsightsRepository implements StatisticsRepository {
  const _FailingContentInsightsRepository();

  @override
  Future<StatisticsContentInsights> getContentInsights() {
    throw const AppException.connection();
  }

  @override
  Future<StatisticsSummary> getSummary() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsActivity> getActivity({
    required StatisticsActivityPeriod period,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsHabits> getHabits() {
    throw UnimplementedError();
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsLibrary> getLibraryStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsBacklog> getBacklogStatistics() {
    throw UnimplementedError();
  }
}

final class _LibraryStatisticsRepository implements StatisticsRepository {
  const _LibraryStatisticsRepository({this.statistics = _libraryStatistics});

  final StatisticsLibrary statistics;

  @override
  Future<StatisticsLibrary> getLibraryStatistics() async {
    return statistics;
  }

  @override
  Future<StatisticsSummary> getSummary() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsActivity> getActivity({
    required StatisticsActivityPeriod period,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsHabits> getHabits() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsContentInsights> getContentInsights() {
    throw UnimplementedError();
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsBacklog> getBacklogStatistics() {
    throw UnimplementedError();
  }
}

final class _ControlledLibraryStatisticsRepository
    implements StatisticsRepository {
  final Completer<StatisticsLibrary> _result = Completer<StatisticsLibrary>();

  int calls = 0;

  void complete(StatisticsLibrary statistics) {
    _result.complete(statistics);
  }

  @override
  Future<StatisticsLibrary> getLibraryStatistics() {
    calls += 1;

    return _result.future;
  }

  @override
  Future<StatisticsSummary> getSummary() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsActivity> getActivity({
    required StatisticsActivityPeriod period,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsHabits> getHabits() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsContentInsights> getContentInsights() {
    throw UnimplementedError();
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsBacklog> getBacklogStatistics() {
    throw UnimplementedError();
  }
}

final class _FailingLibraryStatisticsRepository
    implements StatisticsRepository {
  const _FailingLibraryStatisticsRepository();

  @override
  Future<StatisticsLibrary> getLibraryStatistics() {
    throw const AppException.connection();
  }

  @override
  Future<StatisticsSummary> getSummary() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsActivity> getActivity({
    required StatisticsActivityPeriod period,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsHabits> getHabits() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsContentInsights> getContentInsights() {
    throw UnimplementedError();
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsBacklog> getBacklogStatistics() {
    throw UnimplementedError();
  }
}

final class _RetryLibraryStatisticsRepository implements StatisticsRepository {
  int calls = 0;

  @override
  Future<StatisticsLibrary> getLibraryStatistics() async {
    calls += 1;

    if (calls == 1) {
      throw const AppException.connection();
    }

    return _libraryStatistics;
  }

  @override
  Future<StatisticsSummary> getSummary() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsActivity> getActivity({
    required StatisticsActivityPeriod period,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsHabits> getHabits() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsContentInsights> getContentInsights() {
    throw UnimplementedError();
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsBacklog> getBacklogStatistics() {
    throw UnimplementedError();
  }
}

final class _BacklogStatisticsRepository implements StatisticsRepository {
  const _BacklogStatisticsRepository({this.statistics = _backlogStatistics});

  final StatisticsBacklog statistics;

  @override
  Future<StatisticsBacklog> getBacklogStatistics() async {
    return statistics;
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsSummary> getSummary() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsActivity> getActivity({
    required StatisticsActivityPeriod period,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsHabits> getHabits() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsContentInsights> getContentInsights() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsLibrary> getLibraryStatistics() {
    throw UnimplementedError();
  }
}

final class _ControlledBacklogStatisticsRepository
    implements StatisticsRepository {
  final Completer<StatisticsBacklog> _result = Completer<StatisticsBacklog>();

  void complete(StatisticsBacklog statistics) {
    _result.complete(statistics);
  }

  @override
  Future<StatisticsBacklog> getBacklogStatistics() {
    return _result.future;
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsSummary> getSummary() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsActivity> getActivity({
    required StatisticsActivityPeriod period,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsHabits> getHabits() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsContentInsights> getContentInsights() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsLibrary> getLibraryStatistics() {
    throw UnimplementedError();
  }
}

final class _FailingBacklogStatisticsRepository
    implements StatisticsRepository {
  const _FailingBacklogStatisticsRepository();

  @override
  Future<StatisticsBacklog> getBacklogStatistics() {
    throw const AppException.connection();
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsSummary> getSummary() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsActivity> getActivity({
    required StatisticsActivityPeriod period,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsHabits> getHabits() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsContentInsights> getContentInsights() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsLibrary> getLibraryStatistics() {
    throw UnimplementedError();
  }
}

final class _RetryBacklogStatisticsRepository implements StatisticsRepository {
  int calls = 0;

  @override
  Future<StatisticsBacklog> getBacklogStatistics() async {
    calls += 1;

    if (calls == 1) {
      throw const AppException.connection();
    }

    return _backlogStatistics;
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsSummary> getSummary() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsActivity> getActivity({
    required StatisticsActivityPeriod period,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsHabits> getHabits() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsContentInsights> getContentInsights() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsLibrary> getLibraryStatistics() {
    throw UnimplementedError();
  }
}
