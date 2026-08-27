import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_content_insights_cubit.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_content_insights_state.dart';
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
  group('StatisticsContentInsightsCubit', () {
    test('starts in Initial', () {
      final StatisticsContentInsightsCubit cubit =
          StatisticsContentInsightsCubit(
            repository: const _ContentInsightsRepository(),
          );

      addTearDown(cubit.close);

      expect(cubit.state, const StatisticsContentInsightsInitial());
    });

    test('loads Content Insights successfully', () async {
      final StatisticsContentInsightsCubit cubit =
          StatisticsContentInsightsCubit(
            repository: const _ContentInsightsRepository(),
          );

      addTearDown(cubit.close);

      final Future<List<StatisticsContentInsightsState>> states = cubit.stream
          .take(2)
          .toList();

      await cubit.load();

      expect(await states, <StatisticsContentInsightsState>[
        const StatisticsContentInsightsLoading(),
        const StatisticsContentInsightsSuccess(_insights),
      ]);
    });

    test('maps AppException failure', () async {
      final StatisticsContentInsightsCubit cubit =
          StatisticsContentInsightsCubit(
            repository: const _FailingContentInsightsRepository(),
          );

      addTearDown(cubit.close);

      await cubit.load();

      expect(
        cubit.state,
        isA<StatisticsContentInsightsFailure>().having(
          (StatisticsContentInsightsFailure state) => state.error.type,
          'error.type',
          AppExceptionType.connection,
        ),
      );
    });

    test('maps unexpected failure to unknown', () async {
      final StatisticsContentInsightsCubit cubit =
          StatisticsContentInsightsCubit(
            repository: const _UnexpectedFailureContentInsightsRepository(),
          );

      addTearDown(cubit.close);

      await cubit.load();

      expect(
        cubit.state,
        isA<StatisticsContentInsightsFailure>().having(
          (StatisticsContentInsightsFailure state) => state.error.type,
          'error.type',
          AppExceptionType.unknown,
        ),
      );
    });

    test('ignores another load while loading', () async {
      final _ControlledContentInsightsRepository repository =
          _ControlledContentInsightsRepository();

      final StatisticsContentInsightsCubit cubit =
          StatisticsContentInsightsCubit(repository: repository);

      addTearDown(cubit.close);

      final Future<void> firstLoad = cubit.load();

      await Future<void>.delayed(Duration.zero);

      expect(repository.calls, 1);

      await cubit.load();

      expect(repository.calls, 1);

      repository.complete(_insights);

      await firstLoad;

      expect(cubit.state, const StatisticsContentInsightsSuccess(_insights));
    });

    test('retry loads Content Insights again', () async {
      final _RetryContentInsightsRepository repository =
          _RetryContentInsightsRepository();

      final StatisticsContentInsightsCubit cubit =
          StatisticsContentInsightsCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.load();

      expect(repository.calls, 1);
      expect(cubit.state, isA<StatisticsContentInsightsFailure>());

      await cubit.retry();

      expect(repository.calls, 2);
      expect(cubit.state, const StatisticsContentInsightsSuccess(_insights));
    });
  });
}

const StatisticsContentInsights _insights = StatisticsContentInsights(
  mostWatchedShows: <StatisticsShowInsight>[
    StatisticsShowInsight(
      showId: '11111111-1111-1111-1111-111111111111',
      tmdbId: 95396,
      title: 'Severance',
      posterUrl: null,
      watchCount: 12,
      rewatchCount: 4,
    ),
  ],
  mostRewatchedShows: <StatisticsShowInsight>[],
  mostRewatchedEpisodes: <StatisticsEpisodeInsight>[],
  mostRewatchedMovies: <StatisticsMovieInsight>[
    StatisticsMovieInsight(
      movieId: '33333333-3333-3333-3333-333333333333',
      tmdbId: 438631,
      title: 'Dune',
      posterUrl: null,
      watchCount: 3,
      rewatchCount: 2,
    ),
  ],
  topShowGenres: <StatisticsGenreInsight>[
    StatisticsGenreInsight(genreId: 1, name: 'Drama', watchCount: 12),
  ],
  topMovieGenres: <StatisticsGenreInsight>[],
);

final class _ContentInsightsRepository implements StatisticsRepository {
  const _ContentInsightsRepository();

  @override
  Future<StatisticsContentInsights> getContentInsights() async {
    return _insights;
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
  Future<StatisticsLibrary> getLibraryStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsBacklog> getBacklogStatistics() {
    throw UnimplementedError();
  }
}

final class _UnexpectedFailureContentInsightsRepository
    implements StatisticsRepository {
  const _UnexpectedFailureContentInsightsRepository();

  @override
  Future<StatisticsContentInsights> getContentInsights() {
    throw StateError('Unexpected Content Insights failure.');
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

  int calls = 0;

  void complete(StatisticsContentInsights insights) {
    _result.complete(insights);
  }

  @override
  Future<StatisticsContentInsights> getContentInsights() {
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

    return _insights;
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
  Future<StatisticsLibrary> getLibraryStatistics() {
    throw UnimplementedError();
  }

  @override
  Future<StatisticsBacklog> getBacklogStatistics() {
    throw UnimplementedError();
  }
}
