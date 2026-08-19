import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_library_cubit.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_library_state.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity_period.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_content_insights.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_habits.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_library.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_summary.dart';
import 'package:sofawatch/features/statistics/domain/models/weekly_statistics.dart';
import 'package:sofawatch/features/statistics/domain/repositories/statistics_repository.dart';

void main() {
  group('StatisticsLibraryCubit', () {
    test('starts in Initial', () {
      final StatisticsLibraryCubit cubit = StatisticsLibraryCubit(
        repository: const _LibraryRepository(),
      );

      addTearDown(cubit.close);

      expect(cubit.state, const StatisticsLibraryInitial());
    });

    test('loads Library Statistics successfully', () async {
      final StatisticsLibraryCubit cubit = StatisticsLibraryCubit(
        repository: const _LibraryRepository(),
      );

      addTearDown(cubit.close);

      final Future<List<StatisticsLibraryState>> states = cubit.stream
          .take(2)
          .toList();

      await cubit.load();

      expect(await states, <StatisticsLibraryState>[
        const StatisticsLibraryLoading(),
        const StatisticsLibrarySuccess(_statistics),
      ]);
    });

    test('maps AppException failure', () async {
      final StatisticsLibraryCubit cubit = StatisticsLibraryCubit(
        repository: const _FailingLibraryRepository(),
      );

      addTearDown(cubit.close);

      await cubit.load();

      expect(
        cubit.state,
        isA<StatisticsLibraryFailure>().having(
          (StatisticsLibraryFailure state) => state.error.type,
          'error.type',
          AppExceptionType.connection,
        ),
      );
    });

    test('maps unexpected failure to unknown', () async {
      final StatisticsLibraryCubit cubit = StatisticsLibraryCubit(
        repository: const _UnexpectedFailureLibraryRepository(),
      );

      addTearDown(cubit.close);

      await cubit.load();

      expect(
        cubit.state,
        isA<StatisticsLibraryFailure>().having(
          (StatisticsLibraryFailure state) => state.error.type,
          'error.type',
          AppExceptionType.unknown,
        ),
      );
    });

    test('ignores another load while loading', () async {
      final _ControlledLibraryRepository repository =
          _ControlledLibraryRepository();

      final StatisticsLibraryCubit cubit = StatisticsLibraryCubit(
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

      expect(cubit.state, const StatisticsLibrarySuccess(_statistics));
    });

    test('retry loads Library Statistics again', () async {
      final _RetryLibraryRepository repository = _RetryLibraryRepository();

      final StatisticsLibraryCubit cubit = StatisticsLibraryCubit(
        repository: repository,
      );

      addTearDown(cubit.close);

      await cubit.load();

      expect(repository.calls, 1);
      expect(cubit.state, isA<StatisticsLibraryFailure>());

      await cubit.retry();

      expect(repository.calls, 2);

      expect(cubit.state, const StatisticsLibrarySuccess(_statistics));
    });
  });
}

const StatisticsLibrary _statistics = StatisticsLibrary(
  showsAdded: 18,
  moviesAdded: 42,
  showsCompleted: 7,
);

final class _LibraryRepository implements StatisticsRepository {
  const _LibraryRepository();

  @override
  Future<StatisticsLibrary> getLibraryStatistics() async {
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
}

final class _FailingLibraryRepository implements StatisticsRepository {
  const _FailingLibraryRepository();

  @override
  Future<StatisticsLibrary> getLibraryStatistics() {
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
}

final class _UnexpectedFailureLibraryRepository
    implements StatisticsRepository {
  const _UnexpectedFailureLibraryRepository();

  @override
  Future<StatisticsLibrary> getLibraryStatistics() {
    throw StateError('Unexpected Library Statistics failure.');
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
}

final class _ControlledLibraryRepository implements StatisticsRepository {
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
}

final class _RetryLibraryRepository implements StatisticsRepository {
  int calls = 0;

  @override
  Future<StatisticsLibrary> getLibraryStatistics() async {
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
}
