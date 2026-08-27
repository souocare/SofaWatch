import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_activity_cubit.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_activity_state.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity_period.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_backlog.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_content_insights.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_habits.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_library.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_summary.dart';
import 'package:sofawatch/features/statistics/domain/models/weekly_statistics.dart';
import 'package:sofawatch/features/statistics/domain/repositories/statistics_repository.dart';

void main() {
  group('StatisticsActivityCubit', () {
    test('starts in initial state', () async {
      final StatisticsActivityCubit cubit = StatisticsActivityCubit(
        repository: _FakeStatisticsRepository(),
      );

      expect(cubit.state, const StatisticsActivityInitial());

      await cubit.close();
    });

    test('loads seven days by default', () async {
      final _FakeStatisticsRepository repository = _FakeStatisticsRepository(
        activities: <StatisticsActivityPeriod, StatisticsActivity>{
          StatisticsActivityPeriod.days7: _sevenDayActivity,
        },
      );

      final StatisticsActivityCubit cubit = StatisticsActivityCubit(
        repository: repository,
      );

      await cubit.load();

      expect(
        cubit.state,
        StatisticsActivitySuccess(
          activity: _sevenDayActivity,
          period: StatisticsActivityPeriod.days7,
        ),
      );

      expect(repository.requestedPeriods, <StatisticsActivityPeriod>[
        StatisticsActivityPeriod.days7,
      ]);

      await cubit.close();
    });

    test('loads fourteen days when requested', () async {
      final _FakeStatisticsRepository repository = _FakeStatisticsRepository(
        activities: <StatisticsActivityPeriod, StatisticsActivity>{
          StatisticsActivityPeriod.days14: _fourteenDayActivity,
        },
      );

      final StatisticsActivityCubit cubit = StatisticsActivityCubit(
        repository: repository,
      );

      await cubit.load(period: StatisticsActivityPeriod.days14);

      expect(
        cubit.state,
        StatisticsActivitySuccess(
          activity: _fourteenDayActivity,
          period: StatisticsActivityPeriod.days14,
        ),
      );

      expect(repository.requestedPeriods, <StatisticsActivityPeriod>[
        StatisticsActivityPeriod.days14,
      ]);

      await cubit.close();
    });

    test('supports every activity period', () async {
      final Map<StatisticsActivityPeriod, StatisticsActivity> activities =
          <StatisticsActivityPeriod, StatisticsActivity>{
            for (final StatisticsActivityPeriod period
                in StatisticsActivityPeriod.values)
              period: _sevenDayActivity,
          };

      final _FakeStatisticsRepository repository = _FakeStatisticsRepository(
        activities: activities,
      );

      final StatisticsActivityCubit cubit = StatisticsActivityCubit(
        repository: repository,
      );

      for (final StatisticsActivityPeriod period
          in StatisticsActivityPeriod.values) {
        await cubit.load(period: period);
      }

      expect(repository.requestedPeriods, StatisticsActivityPeriod.values);

      await cubit.close();
    });

    test('keeps existing data while changing period', () async {
      final _ControlledStatisticsRepository repository =
          _ControlledStatisticsRepository();

      final StatisticsActivityCubit cubit = StatisticsActivityCubit(
        repository: repository,
      );

      final Future<void> initialLoad = cubit.load();

      repository.complete(_sevenDayActivity);

      await initialLoad;

      final Future<void> periodChange = cubit.changePeriod(
        StatisticsActivityPeriod.days14,
      );

      expect(
        cubit.state,
        StatisticsActivitySuccess(
          activity: _sevenDayActivity,
          period: StatisticsActivityPeriod.days7,
          isChangingPeriod: true,
          pendingPeriod: StatisticsActivityPeriod.days14,
        ),
      );

      repository.complete(_fourteenDayActivity);

      await periodChange;

      expect(
        cubit.state,
        StatisticsActivitySuccess(
          activity: _fourteenDayActivity,
          period: StatisticsActivityPeriod.days14,
        ),
      );

      await cubit.close();
    });

    test('does not reload currently selected period', () async {
      final _FakeStatisticsRepository repository = _FakeStatisticsRepository(
        activities: <StatisticsActivityPeriod, StatisticsActivity>{
          StatisticsActivityPeriod.days7: _sevenDayActivity,
        },
      );

      final StatisticsActivityCubit cubit = StatisticsActivityCubit(
        repository: repository,
      );

      await cubit.load();

      await cubit.changePeriod(StatisticsActivityPeriod.days7);

      expect(repository.requestedPeriods, <StatisticsActivityPeriod>[
        StatisticsActivityPeriod.days7,
      ]);

      await cubit.close();
    });

    test('preserves existing activity when changing period fails', () async {
      final _PeriodFailureStatisticsRepository repository =
          _PeriodFailureStatisticsRepository();

      final StatisticsActivityCubit cubit = StatisticsActivityCubit(
        repository: repository,
      );

      await cubit.load();

      await cubit.changePeriod(StatisticsActivityPeriod.days14);

      final StatisticsActivityState state = cubit.state;

      expect(state, isA<StatisticsActivitySuccess>());

      final StatisticsActivitySuccess success =
          state as StatisticsActivitySuccess;

      expect(success.activity, _sevenDayActivity);

      expect(success.period, StatisticsActivityPeriod.days7);

      expect(success.isChangingPeriod, isFalse);

      expect(success.pendingPeriod, isNull);

      expect(success.periodChangeError, isA<AppException>());

      await cubit.close();
    });

    test('initial failure becomes blocking failure state', () async {
      final StatisticsActivityCubit cubit = StatisticsActivityCubit(
        repository: _AlwaysFailingStatisticsRepository(),
      );

      await cubit.load();

      expect(cubit.state, isA<StatisticsActivityFailure>());

      final StatisticsActivityFailure failure =
          cubit.state as StatisticsActivityFailure;

      expect(failure.period, StatisticsActivityPeriod.days7);

      await cubit.close();
    });

    test('retry repeats failed initial period', () async {
      final _RetryStatisticsRepository repository =
          _RetryStatisticsRepository();

      final StatisticsActivityCubit cubit = StatisticsActivityCubit(
        repository: repository,
      );

      await cubit.load(period: StatisticsActivityPeriod.days14);

      expect(cubit.state, isA<StatisticsActivityFailure>());

      await cubit.retry();

      expect(
        cubit.state,
        StatisticsActivitySuccess(
          activity: _fourteenDayActivity,
          period: StatisticsActivityPeriod.days14,
        ),
      );

      expect(repository.requestedPeriods, <StatisticsActivityPeriod>[
        StatisticsActivityPeriod.days14,
        StatisticsActivityPeriod.days14,
      ]);

      await cubit.close();
    });

    test('ignores another period request while one is active', () async {
      final _ControlledStatisticsRepository repository =
          _ControlledStatisticsRepository();

      final StatisticsActivityCubit cubit = StatisticsActivityCubit(
        repository: repository,
      );

      final Future<void> load = cubit.load();

      final Future<void> duplicate = cubit.load(
        period: StatisticsActivityPeriod.days14,
      );

      await duplicate;

      repository.complete(_sevenDayActivity);

      await load;

      expect(
        cubit.state,
        StatisticsActivitySuccess(
          activity: _sevenDayActivity,
          period: StatisticsActivityPeriod.days7,
        ),
      );

      await cubit.close();
    });
  });
}

final StatisticsActivity _sevenDayActivity = StatisticsActivity(
  startDate: DateTime(2026, 8, 12),
  endDate: DateTime(2026, 8, 18),
  days: const <DailyStatisticsActivity>[],
);

final StatisticsActivity _fourteenDayActivity = StatisticsActivity(
  startDate: DateTime(2026, 8, 5),
  endDate: DateTime(2026, 8, 18),
  days: const <DailyStatisticsActivity>[],
);

class _FakeStatisticsRepository implements StatisticsRepository {
  _FakeStatisticsRepository({
    this.activities = const <StatisticsActivityPeriod, StatisticsActivity>{},
  });

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

final class _ControlledStatisticsRepository implements StatisticsRepository {
  Completer<StatisticsActivity>? _completer;

  @override
  Future<StatisticsActivity> getActivity({
    required StatisticsActivityPeriod period,
  }) {
    _completer = Completer<StatisticsActivity>();

    return _completer!.future;
  }

  void complete(StatisticsActivity activity) {
    _completer!.complete(activity);
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

final class _PeriodFailureStatisticsRepository implements StatisticsRepository {
  int calls = 0;

  @override
  Future<StatisticsActivity> getActivity({
    required StatisticsActivityPeriod period,
  }) async {
    calls++;

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

final class _AlwaysFailingStatisticsRepository implements StatisticsRepository {
  @override
  Future<StatisticsActivity> getActivity({
    required StatisticsActivityPeriod period,
  }) {
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

final class _RetryStatisticsRepository implements StatisticsRepository {
  final List<StatisticsActivityPeriod> requestedPeriods =
      <StatisticsActivityPeriod>[];

  int calls = 0;

  @override
  Future<StatisticsActivity> getActivity({
    required StatisticsActivityPeriod period,
  }) async {
    requestedPeriods.add(period);

    calls++;

    if (calls == 1) {
      throw const AppException.connection();
    }

    return _fourteenDayActivity;
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
