import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/profile/application/cubit/profile_cubit.dart';
import 'package:sofawatch/features/profile/domain/models/profile_user.dart';
import 'package:sofawatch/features/profile/domain/repositories/profile_repository.dart';
import 'package:sofawatch/features/profile/presentation/pages/profile_page.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_summary_cubit.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_summary.dart';
import 'package:sofawatch/features/statistics/domain/models/weekly_statistics.dart';
import 'package:sofawatch/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity.dart';

void main() {
  group('ProfilePage Statistics', () {
    testWidgets('shows lifetime Statistics summary', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          statisticsRepository: _FakeStatisticsRepository(summary: _summary),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-statistics')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-statistics-title')),
        findsOneWidget,
      );

      expect(find.text('Statistics'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('profile-stat-shows')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-stat-movies')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-stat-episodes')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-stat-watch-time')),
        findsOneWidget,
      );

      expect(find.text('12'), findsOneWidget);
      expect(find.text('34'), findsOneWidget);
      expect(find.text('125'), findsOneWidget);
      expect(find.text('7d 6h'), findsOneWidget);

      expect(find.text('Shows'), findsOneWidget);
      expect(find.text('Movies'), findsOneWidget);
      expect(find.text('Episodes'), findsOneWidget);
      expect(find.text('Watch time'), findsOneWidget);
    });

    testWidgets('shows the detailed Statistics action', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());

      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('profile-detailed-statistics-action'),
        ),
        findsOneWidget,
      );

      expect(find.text('View detailed statistics →'), findsOneWidget);

      final TextButton action = tester.widget<TextButton>(
        find.byKey(
          const ValueKey<String>('profile-detailed-statistics-action'),
        ),
      );

      expect(action.onPressed, isNotNull);
    });

    testWidgets('keeps Profile identity visible while Statistics load', (
      WidgetTester tester,
    ) async {
      final _ControlledStatisticsRepository statisticsRepository =
          _ControlledStatisticsRepository();

      await tester.pumpWidget(
        _buildTestApp(statisticsRepository: statisticsRepository),
      );

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('profile-user-card')),
        findsOneWidget,
      );

      expect(find.text('Gonçalo'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('profile-statistics-loading')),
        findsOneWidget,
      );

      statisticsRepository.complete(_summary);

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-statistics-loading')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-statistics-grid')),
        findsOneWidget,
      );
    });

    testWidgets('Statistics failure does not hide Profile identity', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          statisticsRepository: _FakeStatisticsRepository(
            error: const AppException.connection(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-user-card')),
        findsOneWidget,
      );

      expect(find.text('Gonçalo'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('profile-statistics-failure')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-statistics-grid')),
        findsNothing,
      );
    });

    testWidgets('retries only the Statistics summary after failure', (
      WidgetTester tester,
    ) async {
      final _RetryStatisticsRepository statisticsRepository =
          _RetryStatisticsRepository();

      await tester.pumpWidget(
        _buildTestApp(statisticsRepository: statisticsRepository),
      );

      await tester.pumpAndSettle();

      expect(statisticsRepository.summaryCalls, 1);

      expect(
        find.byKey(const ValueKey<String>('profile-statistics-failure')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('profile-statistics-failure-retry')),
      );

      await tester.pumpAndSettle();

      expect(statisticsRepository.summaryCalls, 2);

      expect(
        find.byKey(const ValueKey<String>('profile-statistics-failure')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-statistics-grid')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-user-card')),
        findsOneWidget,
      );
    });

    testWidgets('Statistics can load independently when Profile fails', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          profileRepository: _FakeProfileRepository(
            error: const AppException.connection(),
          ),
          statisticsRepository: _FakeStatisticsRepository(summary: _summary),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-failure')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-statistics-grid')),
        findsOneWidget,
      );

      expect(find.text('12'), findsOneWidget);
      expect(find.text('34'), findsOneWidget);
      expect(find.text('125'), findsOneWidget);
      expect(find.text('7d 6h'), findsOneWidget);
    });
  });

  group('formatProfileWatchTime', () {
    test('formats lifetime watch time compactly', () {
      expect(formatProfileWatchTime(0), '0m');
      expect(formatProfileWatchTime(45), '45m');
      expect(formatProfileWatchTime(90), '1h 30m');
      expect(formatProfileWatchTime(1440), '1d');
      expect(formatProfileWatchTime(1620), '1d 3h');
      expect(formatProfileWatchTime(26340), '18d 7h');
    });
  });
}

Widget _buildTestApp({
  ProfileRepository? profileRepository,
  StatisticsRepository? statisticsRepository,
}) {
  final ProfileCubit profileCubit = ProfileCubit(
    repository: profileRepository ?? _FakeProfileRepository(),
  )..load();

  final StatisticsSummaryCubit statisticsSummaryCubit = StatisticsSummaryCubit(
    repository: statisticsRepository ?? _FakeStatisticsRepository(),
  )..load();

  return MultiBlocProvider(
    providers: <BlocProvider<dynamic>>[
      BlocProvider<ProfileCubit>.value(value: profileCubit),
      BlocProvider<StatisticsSummaryCubit>.value(value: statisticsSummaryCubit),
    ],
    child: const MaterialApp(home: ProfilePage()),
  );
}

const ProfileUser _user = ProfileUser(
  id: 'user-1',
  displayName: 'Gonçalo',
  isLocal: true,
);

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

final class _FakeProfileRepository implements ProfileRepository {
  const _FakeProfileRepository({this.user = _user, this.error});

  final ProfileUser user;
  final AppException? error;

  @override
  Future<ProfileUser> getCurrentUser() async {
    final AppException? failure = error;

    if (failure != null) {
      throw failure;
    }

    return user;
  }
}

class _FakeStatisticsRepository implements StatisticsRepository {
  const _FakeStatisticsRepository({this.summary = _summary, this.error});

  final StatisticsSummary summary;
  final AppException? error;

  @override
  Future<StatisticsSummary> getSummary() async {
    final AppException? failure = error;

    if (failure != null) {
      throw failure;
    }

    return summary;
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    throw UnimplementedError(
      'Weekly Statistics are not used by ProfilePage tests.',
    );
  }

  @override
  Future<StatisticsActivity> getActivity({required int days}) {
    throw UnimplementedError();
  }
}

final class _RetryStatisticsRepository implements StatisticsRepository {
  int summaryCalls = 0;

  @override
  Future<StatisticsSummary> getSummary() async {
    summaryCalls++;

    if (summaryCalls == 1) {
      throw const AppException.connection();
    }

    return _summary;
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    throw UnimplementedError(
      'Weekly Statistics are not used by ProfilePage tests.',
    );
  }

  @override
  Future<StatisticsActivity> getActivity({required int days}) {
    throw UnimplementedError();
  }
}

final class _ControlledStatisticsRepository implements StatisticsRepository {
  final Completer<StatisticsSummary> _result = Completer<StatisticsSummary>();

  void complete(StatisticsSummary summary) {
    if (_result.isCompleted) {
      return;
    }

    _result.complete(summary);
  }

  @override
  Future<StatisticsSummary> getSummary() {
    return _result.future;
  }

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() {
    throw UnimplementedError(
      'Weekly Statistics are not used by ProfilePage tests.',
    );
  }

  @override
  Future<StatisticsActivity> getActivity({required int days}) {
    throw UnimplementedError();
  }
}
