import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_backlog_cubit.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_backlog_state.dart';
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
  group('StatisticsBacklogCubit', () {
    test('starts in Initial', () {
      final StatisticsBacklogCubit cubit = StatisticsBacklogCubit(
        repository: const _BacklogRepository(),
      );

      addTearDown(cubit.close);

      expect(cubit.state, const StatisticsBacklogInitial());
    });

    test('loads Backlog Statistics successfully', () async {
      final StatisticsBacklogCubit cubit = StatisticsBacklogCubit(
        repository: const _BacklogRepository(),
      );

      addTearDown(cubit.close);

      final Future<List<StatisticsBacklogState>> states = cubit.stream
          .take(2)
          .toList();

      await cubit.load();

      expect(await states, <StatisticsBacklogState>[
        const StatisticsBacklogLoading(),
        const StatisticsBacklogSuccess(_statistics),
      ]);
    });

    test('maps AppException failure', () async {
      final StatisticsBacklogCubit cubit = StatisticsBacklogCubit(
        repository: const _FailingBacklogRepository(),
      );

      addTearDown(cubit.close);

      await cubit.load();

      expect(
        cubit.state,
        isA<StatisticsBacklogFailure>().having(
          (StatisticsBacklogFailure state) => state.error.type,
          'error.type',
          AppExceptionType.connection,
        ),
      );
    });

    test('maps unexpected failure to unknown', () async {
      final StatisticsBacklogCubit cubit = StatisticsBacklogCubit(
        repository: const _UnexpectedFailureBacklogRepository(),
      );

      addTearDown(cubit.close);

      await cubit.load();

      expect(
        cubit.state,
        isA<StatisticsBacklogFailure>().having(
          (StatisticsBacklogFailure state) => state.error.type,
          'error.type',
          AppExceptionType.unknown,
        ),
      );
    });

    test('ignores another load while loading', () async {
      final _ControlledBacklogRepository repository =
          _ControlledBacklogRepository();

      final StatisticsBacklogCubit cubit = StatisticsBacklogCubit(
        repository: repository,
      );

      addTearDown(cubit.close);

      final Future<void> firstLoad = cubit.load();

      await Future<void>.delayed(Duration.zero);

      expect(repository.calls, 1);

      await cubit.load();

      expect(repository.calls, 1);

      repository.complete(_statistics);

      await firstLoad;

      expect(cubit.state, const StatisticsBacklogSuccess(_statistics));
    });

    test('retry loads Backlog Statistics again', () async {
      final _RetryBacklogRepository repository = _RetryBacklogRepository();

      final StatisticsBacklogCubit cubit = StatisticsBacklogCubit(
        repository: repository,
      );

      addTearDown(cubit.close);

      await cubit.load();

      expect(repository.calls, 1);
      expect(cubit.state, isA<StatisticsBacklogFailure>());

      await cubit.retry();

      expect(repository.calls, 2);
      expect(cubit.state, const StatisticsBacklogSuccess(_statistics));
    });
  });
}

const StatisticsBacklog _statistics = StatisticsBacklog(
  unwatchedAiredEpisodes: 24,
  plannedMovies: 6,
  futureWatchTimeMinutes: 1830,
  catchUpSpeedEpisodesPerWeek: 4.5,
  backlogTrend: 'shrinking',
  backlogTrendEpisodeDelta: -3,
);

final class _BacklogRepository implements StatisticsRepository {
  const _BacklogRepository();

  @override
  Future<StatisticsBacklog> getBacklogStatistics() async {
    return _statistics;
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

final class _FailingBacklogRepository implements StatisticsRepository {
  const _FailingBacklogRepository();

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

final class _UnexpectedFailureBacklogRepository
    implements StatisticsRepository {
  const _UnexpectedFailureBacklogRepository();

  @override
  Future<StatisticsBacklog> getBacklogStatistics() {
    throw StateError('Unexpected Backlog Statistics failure.');
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

final class _ControlledBacklogRepository implements StatisticsRepository {
  final Completer<StatisticsBacklog> _result = Completer<StatisticsBacklog>();

  int calls = 0;

  void complete(StatisticsBacklog statistics) {
    _result.complete(statistics);
  }

  @override
  Future<StatisticsBacklog> getBacklogStatistics() {
    calls += 1;

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

final class _RetryBacklogRepository implements StatisticsRepository {
  int calls = 0;

  @override
  Future<StatisticsBacklog> getBacklogStatistics() async {
    calls += 1;

    if (calls == 1) {
      throw const AppException.connection();
    }

    return _statistics;
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
