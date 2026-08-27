import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_cubit.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_state.dart';
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
  group('StatisticsCubit', () {
    test('starts in initial state', () async {
      final StatisticsCubit cubit = StatisticsCubit(
        repository: _FakeStatisticsRepository(),
      );

      expect(cubit.state, isA<StatisticsInitial>());

      await cubit.close();
    });

    test('loads weekly Statistics', () async {
      final StatisticsCubit cubit = StatisticsCubit(
        repository: _FakeStatisticsRepository(statistics: _statistics),
      );

      await cubit.loadWeeklyStatistics();

      expect(cubit.state, StatisticsSuccess(_statistics));

      await cubit.close();
    });

    test('preserves AppException when loading fails', () async {
      final StatisticsCubit cubit = StatisticsCubit(
        repository: _FakeStatisticsRepository(
          error: const AppException.connection(),
        ),
      );

      await cubit.loadWeeklyStatistics();

      expect(cubit.state, isA<StatisticsFailure>());

      final StatisticsFailure state = cubit.state as StatisticsFailure;

      expect(state.error.type, AppExceptionType.connection);

      await cubit.close();
    });

    test('maps unexpected failures to unknown', () async {
      final StatisticsCubit cubit = StatisticsCubit(
        repository: _FakeStatisticsRepository(
          unexpectedError: StateError('boom'),
        ),
      );

      await cubit.loadWeeklyStatistics();

      final StatisticsFailure state = cubit.state as StatisticsFailure;

      expect(state.error.type, AppExceptionType.unknown);

      await cubit.close();
    });

    test('Retry repeats the weekly Statistics request', () async {
      final _RetryStatisticsRepository repository =
          _RetryStatisticsRepository();

      final StatisticsCubit cubit = StatisticsCubit(repository: repository);

      await cubit.loadWeeklyStatistics();

      expect(repository.calls, 1);
      expect(cubit.state, isA<StatisticsFailure>());

      await cubit.retry();

      expect(repository.calls, 2);
      expect(cubit.state, StatisticsSuccess(_statistics));

      await cubit.close();
    });

    test('does not start duplicate loads', () async {
      final _ControlledStatisticsRepository repository =
          _ControlledStatisticsRepository();

      final StatisticsCubit cubit = StatisticsCubit(repository: repository);

      final Future<void> firstLoad = cubit.loadWeeklyStatistics();

      await repository.requested.future;

      final Future<void> secondLoad = cubit.loadWeeklyStatistics();

      expect(repository.calls, 1);

      repository.complete(_statistics);

      await Future.wait(<Future<void>>[firstLoad, secondLoad]);

      expect(repository.calls, 1);
      expect(cubit.state, StatisticsSuccess(_statistics));

      await cubit.close();
    });
    test('failed background refresh preserves existing Statistics', () async {
      final _RefreshFailureStatisticsRepository repository =
          _RefreshFailureStatisticsRepository();

      final StatisticsCubit cubit = StatisticsCubit(repository: repository);

      await cubit.loadWeeklyStatistics();

      expect(cubit.state, StatisticsSuccess(_statistics));

      final bool succeeded = await cubit.refreshWeeklyStatistics();

      expect(succeeded, isFalse);

      expect(repository.calls, 2);

      expect(cubit.state, StatisticsSuccess(_statistics));

      await cubit.close();
    });
    test('successful background refresh reports success', () async {
      final StatisticsCubit cubit = StatisticsCubit(
        repository: _FakeStatisticsRepository(statistics: _statistics),
      );

      await cubit.loadWeeklyStatistics();

      final bool succeeded = await cubit.refreshWeeklyStatistics();

      expect(succeeded, isTrue);

      expect(cubit.state, StatisticsSuccess(_statistics));

      await cubit.close();
    });
  });
}

final WeeklyStatistics _statistics = WeeklyStatistics(
  weekStart: DateTime(2026, 8, 17),
  weekEnd: DateTime(2026, 8, 23),
  episodesWatched: 8,
  moviesWatched: 2,
  watchTimeMinutes: 642,
);

final class _FakeStatisticsRepository implements StatisticsRepository {
  _FakeStatisticsRepository({
    this.statistics,
    this.error,
    this.unexpectedError,
  });

  final WeeklyStatistics? statistics;
  final AppException? error;
  final Object? unexpectedError;

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() async {
    final AppException? appError = error;

    if (appError != null) {
      throw appError;
    }

    final Object? unknownError = unexpectedError;

    if (unknownError != null) {
      throw unknownError;
    }

    return statistics ?? _statistics;
  }

  @override
  Future<StatisticsSummary> getSummary() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsLibrary> getLibraryStatistics() {
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
  Future<StatisticsBacklog> getBacklogStatistics() {
    throw UnimplementedError();
  }
}

final class _RetryStatisticsRepository implements StatisticsRepository {
  int calls = 0;

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() async {
    calls++;

    if (calls == 1) {
      throw const AppException.connection();
    }

    return _statistics;
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

  @override
  Future<StatisticsBacklog> getBacklogStatistics() {
    throw UnimplementedError();
  }
}

final class _ControlledStatisticsRepository implements StatisticsRepository {
  int calls = 0;

  final Completer<void> requested = Completer<void>();

  final Completer<WeeklyStatistics> _result = Completer<WeeklyStatistics>();

  void complete(WeeklyStatistics statistics) {
    if (_result.isCompleted) {
      return;
    }

    _result.complete(statistics);
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    calls++;

    if (!requested.isCompleted) {
      requested.complete();
    }

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
  Future<StatisticsLibrary> getLibraryStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsBacklog> getBacklogStatistics() {
    throw UnimplementedError();
  }
}

final class _RefreshFailureStatisticsRepository
    implements StatisticsRepository {
  int calls = 0;

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() async {
    calls++;

    if (calls == 1) {
      return _statistics;
    }

    throw const AppException.receiveTimeout();
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

  @override
  Future<StatisticsBacklog> getBacklogStatistics() {
    throw UnimplementedError();
  }
}
