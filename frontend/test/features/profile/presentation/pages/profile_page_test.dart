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
import 'package:sofawatch/features/statistics/domain/models/statistics_activity_period.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_habits.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_content_insights.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_library.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_backlog.dart';
import 'package:sofawatch/features/library/application/cubit/library_preview_cubit.dart';
import 'package:sofawatch/features/library/domain/models/imported_library_media.dart';
import 'package:sofawatch/features/library/domain/models/library_entry.dart';
import 'package:sofawatch/features/library/domain/models/library_preview.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/library/domain/repositories/library_repository.dart';

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

      final Finder statisticsGrid = find.byKey(
        const ValueKey<String>('profile-statistics-grid'),
      );

      expect(
        find.descendant(of: statisticsGrid, matching: find.text('Shows')),
        findsOneWidget,
      );

      expect(
        find.descendant(of: statisticsGrid, matching: find.text('Movies')),
        findsOneWidget,
      );

      expect(
        find.descendant(of: statisticsGrid, matching: find.text('Episodes')),
        findsOneWidget,
      );

      expect(
        find.descendant(of: statisticsGrid, matching: find.text('Watch time')),
        findsOneWidget,
      );
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
  group('ProfilePage Library', () {
    testWidgets('shows Library preview with recent Shows and Movies', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          libraryRepository: const _FakeLibraryRepository(
            preview: _libraryPreview,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-library')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-library-title')),
        findsOneWidget,
      );

      expect(find.text('Library'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('profile-library-shows')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-library-movies')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-library-show-show-1')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-library-movie-movie-1')),
        findsOneWidget,
      );

      expect(find.text('Severance'), findsOneWidget);
      expect(find.text('Dune'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('profile-library-shows-empty')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-library-movies-empty')),
        findsNothing,
      );
    });

    testWidgets('keeps Profile and Statistics visible while Library loads', (
      WidgetTester tester,
    ) async {
      final _ControlledLibraryRepository libraryRepository =
          _ControlledLibraryRepository();

      await tester.pumpWidget(
        _buildTestApp(
          statisticsRepository: _FakeStatisticsRepository(summary: _summary),
          libraryRepository: libraryRepository,
        ),
      );

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('profile-user-card')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-statistics-grid')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-library-loading')),
        findsOneWidget,
      );

      libraryRepository.complete(_libraryPreview);

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-library-loading')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-library-content')),
        findsOneWidget,
      );
    });

    testWidgets('supports empty Shows independently from Movies', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          libraryRepository: const _FakeLibraryRepository(
            preview: LibraryPreview(
              shows: <LibraryPreviewShow>[],
              movies: <LibraryPreviewMovie>[
                LibraryPreviewMovie(
                  id: 'movie-1',
                  tmdbId: 438631,
                  title: 'Dune',
                  posterUrl: null,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-library-shows-empty')),
        findsOneWidget,
      );

      expect(find.text('No Shows in your Library yet.'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('profile-library-movie-movie-1')),
        findsOneWidget,
      );

      expect(find.text('Dune'), findsOneWidget);
    });

    testWidgets('supports empty Movies independently from Shows', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          libraryRepository: const _FakeLibraryRepository(
            preview: LibraryPreview(
              shows: <LibraryPreviewShow>[
                LibraryPreviewShow(
                  id: 'show-1',
                  tmdbId: 95396,
                  title: 'Severance',
                  posterUrl: null,
                ),
              ],
              movies: <LibraryPreviewMovie>[],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-library-show-show-1')),
        findsOneWidget,
      );

      expect(find.text('Severance'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('profile-library-movies-empty')),
        findsOneWidget,
      );

      expect(find.text('No Movies in your Library yet.'), findsOneWidget);
    });

    testWidgets('Library failure does not hide Profile or Statistics', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          libraryRepository: const _FakeLibraryRepository(
            error: AppException.connection(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-library-failure')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-user-card')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-statistics-grid')),
        findsOneWidget,
      );
    });

    testWidgets('retries only Library preview after failure', (
      WidgetTester tester,
    ) async {
      final _RetryLibraryRepository libraryRepository =
          _RetryLibraryRepository();

      await tester.pumpWidget(
        _buildTestApp(libraryRepository: libraryRepository),
      );

      await tester.pumpAndSettle();

      expect(libraryRepository.calls, 1);

      expect(
        find.byKey(const ValueKey<String>('profile-library-failure')),
        findsOneWidget,
      );

      final Finder retryButton = find.byKey(
        const ValueKey<String>('profile-library-failure-retry'),
      );

      await tester.ensureVisible(retryButton);
      await tester.pumpAndSettle();

      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      expect(libraryRepository.calls, 2);

      expect(
        find.byKey(const ValueKey<String>('profile-library-failure')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-library-content')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-user-card')),
        findsOneWidget,
      );
    });
    testWidgets('shows See All actions for Shows and Movies', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          libraryRepository: const _FakeLibraryRepository(
            preview: _libraryPreview,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-library-shows-see-all')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('profile-library-shows-see-all-footer'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-library-movies-see-all')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('profile-library-movies-see-all-footer'),
        ),
        findsOneWidget,
      );
    });
  });
}

Widget _buildTestApp({
  ProfileRepository? profileRepository,
  StatisticsRepository? statisticsRepository,
  LibraryRepository? libraryRepository,
}) {
  final ProfileCubit profileCubit = ProfileCubit(
    repository: profileRepository ?? _FakeProfileRepository(),
  )..load();

  final StatisticsSummaryCubit statisticsSummaryCubit = StatisticsSummaryCubit(
    repository: statisticsRepository ?? _FakeStatisticsRepository(),
  )..load();

  final LibraryPreviewCubit libraryPreviewCubit = LibraryPreviewCubit(
    repository: libraryRepository ?? const _FakeLibraryRepository(),
  )..load();

  return MultiBlocProvider(
    providers: <BlocProvider<dynamic>>[
      BlocProvider<ProfileCubit>.value(value: profileCubit),
      BlocProvider<StatisticsSummaryCubit>.value(value: statisticsSummaryCubit),
      BlocProvider<LibraryPreviewCubit>.value(value: libraryPreviewCubit),
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

const LibraryPreview _libraryPreview = LibraryPreview(
  shows: <LibraryPreviewShow>[
    LibraryPreviewShow(
      id: 'show-1',
      tmdbId: 95396,
      title: 'Severance',
      posterUrl: null,
    ),
  ],
  movies: <LibraryPreviewMovie>[
    LibraryPreviewMovie(
      id: 'movie-1',
      tmdbId: 438631,
      title: 'Dune',
      posterUrl: null,
    ),
  ],
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

class _FakeLibraryRepository implements LibraryRepository {
  const _FakeLibraryRepository({this.preview = _libraryPreview, this.error});

  final LibraryPreview preview;
  final AppException? error;

  @override
  Future<LibraryPreview> getPreview() async {
    final AppException? failure = error;

    if (failure != null) {
      throw failure;
    }

    return preview;
  }

  @override
  Future<ImportedLibraryMedia> importShowByTmdbId(int tmdbId) {
    throw UnimplementedError();
  }

  @override
  Future<ImportedLibraryMedia> importMovieByTmdbId(int tmdbId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry?> getShowEntry(String showId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry?> getMovieEntry(String movieId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry> addShow(String showId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry> addMovie(String movieId) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeShow(String showId) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeMovie(String movieId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry> updateShowStatus(String showId, LibraryStatus status) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry> updateMovieStatus(String movieId, LibraryStatus status) {
    throw UnimplementedError();
  }
}

final class _ControlledLibraryRepository implements LibraryRepository {
  final Completer<LibraryPreview> _result = Completer<LibraryPreview>();

  void complete(LibraryPreview preview) {
    if (_result.isCompleted) {
      return;
    }

    _result.complete(preview);
  }

  @override
  Future<LibraryPreview> getPreview() {
    return _result.future;
  }

  @override
  Future<ImportedLibraryMedia> importShowByTmdbId(int tmdbId) {
    throw UnimplementedError();
  }

  @override
  Future<ImportedLibraryMedia> importMovieByTmdbId(int tmdbId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry?> getShowEntry(String showId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry?> getMovieEntry(String movieId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry> addShow(String showId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry> addMovie(String movieId) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeShow(String showId) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeMovie(String movieId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry> updateShowStatus(String showId, LibraryStatus status) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry> updateMovieStatus(String movieId, LibraryStatus status) {
    throw UnimplementedError();
  }
}

final class _RetryLibraryRepository implements LibraryRepository {
  int calls = 0;

  @override
  Future<LibraryPreview> getPreview() async {
    calls++;

    if (calls == 1) {
      throw const AppException.connection();
    }

    return _libraryPreview;
  }

  @override
  Future<ImportedLibraryMedia> importShowByTmdbId(int tmdbId) {
    throw UnimplementedError();
  }

  @override
  Future<ImportedLibraryMedia> importMovieByTmdbId(int tmdbId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry?> getShowEntry(String showId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry?> getMovieEntry(String movieId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry> addShow(String showId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry> addMovie(String movieId) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeShow(String showId) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeMovie(String movieId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry> updateShowStatus(String showId, LibraryStatus status) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry> updateMovieStatus(String movieId, LibraryStatus status) {
    throw UnimplementedError();
  }
}
