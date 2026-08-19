import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_habits_cubit.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_habits_state.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity_period.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_habits.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_summary.dart';
import 'package:sofawatch/features/statistics/domain/models/weekly_statistics.dart';
import 'package:sofawatch/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_content_insights.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_library.dart';

void main() {
  group('StatisticsHabitsCubit', () {
    test('starts in initial state', () async {
      final StatisticsHabitsCubit cubit = StatisticsHabitsCubit(
        repository: const _HabitsRepository(habits: _habits),
      );

      expect(cubit.state, const StatisticsHabitsInitial());

      await cubit.close();
    });

    test('loads viewing habits', () async {
      final StatisticsHabitsCubit cubit = StatisticsHabitsCubit(
        repository: const _HabitsRepository(habits: _habits),
      );

      await cubit.load();

      expect(cubit.state, const StatisticsHabitsSuccess(_habits));

      await cubit.close();
    });

    test('maps AppException to failure', () async {
      final StatisticsHabitsCubit cubit = StatisticsHabitsCubit(
        repository: const _FailingHabitsRepository(),
      );

      await cubit.load();

      expect(cubit.state, isA<StatisticsHabitsFailure>());

      final StatisticsHabitsFailure failure =
          cubit.state as StatisticsHabitsFailure;

      expect(failure.error.type, AppExceptionType.connection);

      await cubit.close();
    });

    test('maps unexpected repository errors to unknown', () async {
      final StatisticsHabitsCubit cubit = StatisticsHabitsCubit(
        repository: const _UnexpectedFailureHabitsRepository(),
      );

      await cubit.load();

      expect(cubit.state, isA<StatisticsHabitsFailure>());

      final StatisticsHabitsFailure failure =
          cubit.state as StatisticsHabitsFailure;

      expect(failure.error.type, AppExceptionType.unknown);

      await cubit.close();
    });

    test('retry repeats a failed request', () async {
      final _RetryHabitsRepository repository = _RetryHabitsRepository();

      final StatisticsHabitsCubit cubit = StatisticsHabitsCubit(
        repository: repository,
      );

      await cubit.load();

      expect(cubit.state, isA<StatisticsHabitsFailure>());

      await cubit.retry();

      expect(cubit.state, const StatisticsHabitsSuccess(_habits));

      expect(repository.calls, 2);

      await cubit.close();
    });

    test('ignores duplicate load while request is active', () async {
      final _ControlledHabitsRepository repository =
          _ControlledHabitsRepository();

      final StatisticsHabitsCubit cubit = StatisticsHabitsCubit(
        repository: repository,
      );

      final Future<void> firstLoad = cubit.load();

      final Future<void> duplicateLoad = cubit.load();

      await duplicateLoad;

      expect(repository.calls, 1);

      repository.complete(_habits);

      await firstLoad;

      expect(cubit.state, const StatisticsHabitsSuccess(_habits));

      await cubit.close();
    });
  });
}

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

final class _HabitsRepository implements StatisticsRepository {
  const _HabitsRepository({required this.habits});

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
}

final class _UnexpectedFailureHabitsRepository implements StatisticsRepository {
  const _UnexpectedFailureHabitsRepository();

  @override
  Future<StatisticsHabits> getHabits() {
    throw StateError('Unexpected Statistics failure.');
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
}

final class _ControlledHabitsRepository implements StatisticsRepository {
  final Completer<StatisticsHabits> _result = Completer<StatisticsHabits>();

  int calls = 0;

  void complete(StatisticsHabits habits) {
    _result.complete(habits);
  }

  @override
  Future<StatisticsHabits> getHabits() {
    calls += 1;

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
}
