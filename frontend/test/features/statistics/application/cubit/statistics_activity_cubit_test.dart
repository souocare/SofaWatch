import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_activity_cubit.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_activity_state.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity.dart';
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
        activities: <int, StatisticsActivity>{7: _sevenDayActivity},
      );

      final StatisticsActivityCubit cubit = StatisticsActivityCubit(
        repository: repository,
      );

      await cubit.load();

      expect(
        cubit.state,
        StatisticsActivitySuccess(activity: _sevenDayActivity, days: 7),
      );

      expect(repository.requestedDays, <int>[7]);

      await cubit.close();
    });

    test('loads fourteen days when requested', () async {
      final _FakeStatisticsRepository repository = _FakeStatisticsRepository(
        activities: <int, StatisticsActivity>{14: _fourteenDayActivity},
      );

      final StatisticsActivityCubit cubit = StatisticsActivityCubit(
        repository: repository,
      );

      await cubit.load(days: 14);

      expect(
        cubit.state,
        StatisticsActivitySuccess(activity: _fourteenDayActivity, days: 14),
      );

      expect(repository.requestedDays, <int>[14]);

      await cubit.close();
    });

    test('keeps existing data while changing range', () async {
      final _ControlledStatisticsRepository repository =
          _ControlledStatisticsRepository();

      final StatisticsActivityCubit cubit = StatisticsActivityCubit(
        repository: repository,
      );

      final Future<void> initialLoad = cubit.load();

      repository.complete(_sevenDayActivity);

      await initialLoad;

      final Future<void> rangeChange = cubit.changeRange(14);

      expect(
        cubit.state,
        StatisticsActivitySuccess(
          activity: _sevenDayActivity,
          days: 7,
          isChangingRange: true,
          pendingDays: 14,
        ),
      );

      repository.complete(_fourteenDayActivity);

      await rangeChange;

      expect(
        cubit.state,
        StatisticsActivitySuccess(activity: _fourteenDayActivity, days: 14),
      );

      await cubit.close();
    });

    test('does not reload the currently selected range', () async {
      final _FakeStatisticsRepository repository = _FakeStatisticsRepository(
        activities: <int, StatisticsActivity>{7: _sevenDayActivity},
      );

      final StatisticsActivityCubit cubit = StatisticsActivityCubit(
        repository: repository,
      );

      await cubit.load();

      await cubit.changeRange(7);

      expect(repository.requestedDays, <int>[7]);

      await cubit.close();
    });

    test('preserves existing activity when changing range fails', () async {
      final _RangeFailureStatisticsRepository repository =
          _RangeFailureStatisticsRepository();

      final StatisticsActivityCubit cubit = StatisticsActivityCubit(
        repository: repository,
      );

      await cubit.load();

      await cubit.changeRange(14);

      final StatisticsActivityState state = cubit.state;

      expect(state, isA<StatisticsActivitySuccess>());

      final StatisticsActivitySuccess success =
          state as StatisticsActivitySuccess;

      expect(success.activity, _sevenDayActivity);

      expect(success.days, 7);

      expect(success.isChangingRange, isFalse);

      expect(success.pendingDays, isNull);

      expect(success.rangeChangeError, isA<AppException>());

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

      expect(failure.days, 7);

      await cubit.close();
    });

    test('retry repeats the failed initial range', () async {
      final _RetryStatisticsRepository repository =
          _RetryStatisticsRepository();

      final StatisticsActivityCubit cubit = StatisticsActivityCubit(
        repository: repository,
      );

      await cubit.load(days: 14);

      expect(cubit.state, isA<StatisticsActivityFailure>());

      await cubit.retry();

      expect(
        cubit.state,
        StatisticsActivitySuccess(activity: _fourteenDayActivity, days: 14),
      );

      expect(repository.requestedDays, <int>[14, 14]);

      await cubit.close();
    });
    test('ignores another range request while one is active', () async {
      final _ControlledStatisticsRepository repository =
          _ControlledStatisticsRepository();

      final StatisticsActivityCubit cubit = StatisticsActivityCubit(
        repository: repository,
      );

      final Future<void> load = cubit.load();

      final Future<void> duplicate = cubit.load(days: 14);

      await duplicate;

      repository.complete(_sevenDayActivity);

      await load;

      expect(
        cubit.state,
        StatisticsActivitySuccess(activity: _sevenDayActivity, days: 7),
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
    this.activities = const <int, StatisticsActivity>{},
  });

  final Map<int, StatisticsActivity> activities;

  final List<int> requestedDays = <int>[];

  @override
  Future<StatisticsActivity> getActivity({required int days}) async {
    requestedDays.add(days);

    return activities[days]!;
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

final class _ControlledStatisticsRepository implements StatisticsRepository {
  Completer<StatisticsActivity>? _completer;

  @override
  Future<StatisticsActivity> getActivity({required int days}) {
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
}

final class _RangeFailureStatisticsRepository implements StatisticsRepository {
  int calls = 0;

  @override
  Future<StatisticsActivity> getActivity({required int days}) async {
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
}

final class _AlwaysFailingStatisticsRepository implements StatisticsRepository {
  @override
  Future<StatisticsActivity> getActivity({required int days}) {
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
}

final class _RetryStatisticsRepository implements StatisticsRepository {
  final List<int> requestedDays = <int>[];

  int calls = 0;

  @override
  Future<StatisticsActivity> getActivity({required int days}) async {
    requestedDays.add(days);

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
}
