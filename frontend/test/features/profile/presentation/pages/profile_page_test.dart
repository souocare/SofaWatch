import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/history/domain/models/history_episode.dart';
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
import 'package:sofawatch/features/history/application/cubit/history_preview_cubit.dart';
import 'package:sofawatch/features/history/domain/models/history_episode_item.dart';
import 'package:sofawatch/features/history/domain/models/history_movie_item.dart';
import 'package:sofawatch/features/history/domain/models/history_page.dart';
import 'package:sofawatch/features/history/domain/models/history_preview.dart';
import 'package:sofawatch/features/history/domain/repositories/history_repository.dart';
import 'package:sofawatch/features/server/domain/models/server_health.dart';
import 'package:sofawatch/features/server/domain/repositories/server_repository.dart';
import 'package:sofawatch/features/server/domain/models/background_job.dart';
import 'package:sofawatch/features/server/domain/models/background_job.dart';

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

      expect(find.text('TestDisplay'), findsOneWidget);

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

      expect(find.text('TestDisplay'), findsOneWidget);

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

  group('ProfilePage History', () {
    testWidgets('shows recent Episode and Movie History', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          historyRepository: _FakeHistoryRepository(preview: _historyPreview),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-history')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-history-title')),
        findsOneWidget,
      );

      expect(find.text('History'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('profile-history-content')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-history-episodes')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-history-movies')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('profile-history-episode-episode-event-1'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('profile-history-movie-movie-event-1'),
        ),
        findsOneWidget,
      );

      final Finder history = find.byKey(
        const ValueKey<String>('profile-history'),
      );

      expect(
        find.descendant(of: history, matching: find.text('Severance')),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: history,
          matching: find.text('S01E01 · Good News About Hell'),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(of: history, matching: find.text('Dune')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-history-empty')),
        findsNothing,
      );
    });

    testWidgets('supports Episode History without Movie History', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          historyRepository: _FakeHistoryRepository(
            preview: HistoryPreview(
              episodes: <HistoryEpisodeItem>[_historyEpisodeItem],
              movies: const <HistoryMovieItem>[],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-history-episodes')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-history-movies')),
        findsNothing,
      );

      expect(
        find.byKey(
          const ValueKey<String>('profile-history-episode-episode-event-1'),
        ),
        findsOneWidget,
      );

      final Finder history = find.byKey(
        const ValueKey<String>('profile-history'),
      );

      expect(
        find.byKey(const ValueKey<String>('profile-history-episodes')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-history-movies')),
        findsNothing,
      );

      expect(
        find.descendant(of: history, matching: find.text('Severance')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('profile-history-episode-episode-event-1'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('supports Movie History without Episode History', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          historyRepository: _FakeHistoryRepository(
            preview: HistoryPreview(
              episodes: const <HistoryEpisodeItem>[],
              movies: <HistoryMovieItem>[_historyMovieItem],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-history-episodes')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-history-movies')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('profile-history-movie-movie-event-1'),
        ),
        findsOneWidget,
      );

      final Finder history = find.byKey(
        const ValueKey<String>('profile-history'),
      );

      expect(
        find.byKey(const ValueKey<String>('profile-history-movies')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-history-episodes')),
        findsNothing,
      );

      expect(
        find.descendant(of: history, matching: find.text('Dune')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('profile-history-movie-movie-event-1'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows empty History state', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          historyRepository: const _FakeHistoryRepository(
            preview: HistoryPreview(
              episodes: <HistoryEpisodeItem>[],
              movies: <HistoryMovieItem>[],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-history-empty')),
        findsOneWidget,
      );

      expect(find.text('Your viewing History is empty.'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('profile-history-content')),
        findsNothing,
      );
    });

    testWidgets(
      'keeps Profile Statistics and Library visible while History loads',
      (WidgetTester tester) async {
        final _ControlledHistoryRepository historyRepository =
            _ControlledHistoryRepository();

        await tester.pumpWidget(
          _buildTestApp(
            statisticsRepository: _FakeStatisticsRepository(summary: _summary),
            libraryRepository: const _FakeLibraryRepository(
              preview: _libraryPreview,
            ),
            historyRepository: historyRepository,
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
          find.byKey(const ValueKey<String>('profile-library-content')),
          findsOneWidget,
        );

        expect(
          find.byKey(const ValueKey<String>('profile-history-loading')),
          findsOneWidget,
        );

        historyRepository.complete(_historyPreview);

        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('profile-history-loading')),
          findsNothing,
        );

        expect(
          find.byKey(const ValueKey<String>('profile-history-content')),
          findsOneWidget,
        );
      },
    );

    testWidgets('History failure does not hide other Profile sections', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          historyRepository: const _FakeHistoryRepository(
            error: AppException.connection(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-history-failure')),
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

      expect(
        find.byKey(const ValueKey<String>('profile-library-content')),
        findsOneWidget,
      );
    });

    testWidgets('retries only History preview after failure', (
      WidgetTester tester,
    ) async {
      final _RetryHistoryRepository historyRepository =
          _RetryHistoryRepository();

      await tester.pumpWidget(
        _buildTestApp(historyRepository: historyRepository),
      );

      await tester.pumpAndSettle();

      expect(historyRepository.calls, 1);

      expect(
        find.byKey(const ValueKey<String>('profile-history-failure')),
        findsOneWidget,
      );

      final Finder retryButton = find.byKey(
        const ValueKey<String>('profile-history-failure-retry'),
      );

      await tester.ensureVisible(retryButton);
      await tester.pumpAndSettle();

      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      expect(historyRepository.calls, 2);

      expect(
        find.byKey(const ValueKey<String>('profile-history-failure')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-history-content')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-user-card')),
        findsOneWidget,
      );
    });
  });

  group('ProfilePage Server', () {
    testWidgets('loads Server health for administrators', (
      WidgetTester tester,
    ) async {
      final _FakeServerRepository serverRepository = _FakeServerRepository(
        health: _serverHealth,
      );

      await tester.pumpWidget(
        _buildTestApp(serverRepository: serverRepository),
      );

      await tester.pumpAndSettle();

      expect(serverRepository.healthCalls, 1);

      expect(
        find.byKey(const ValueKey<String>('profile-server')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-server-title')),
        findsOneWidget,
      );

      expect(find.text('Server'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('profile-server-health')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-server-health-status')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-server-overall-health')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-server-health-grid')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-server-checked-at')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-server-uptime')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-server-database')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-server-tmdb')),
        findsOneWidget,
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>('profile-server-health-status'),
              ),
            )
            .data,
        'Healthy',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey<String>('profile-server-uptime-value')),
            )
            .data,
        '1h',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>('profile-server-database-value'),
              ),
            )
            .data,
        'Healthy',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>('profile-server-database-detail'),
              ),
            )
            .data,
        '3.5 ms',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey<String>('profile-server-tmdb-value')),
            )
            .data,
        'Healthy',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey<String>('profile-server-tmdb-detail')),
            )
            .data,
        '212 ms',
      );

      expect(
        find.byKey(const ValueKey<String>('profile-server-database-title')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-server-database-status')),
        findsOneWidget,
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>('profile-server-database-engine-value'),
              ),
            )
            .data,
        'SQLite',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>('profile-server-database-size-value'),
              ),
            )
            .data,
        '1.0 MB',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(
                  'profile-server-database-wal-size-value',
                ),
              ),
            )
            .data,
        '8.0 KB',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(
                  'profile-server-database-connectivity-value',
                ),
              ),
            )
            .data,
        'Healthy',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(
                  'profile-server-database-integrity-value',
                ),
              ),
            )
            .data,
        'OK',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(
                  'profile-server-database-foreign-keys-value',
                ),
              ),
            )
            .data,
        'OK',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(
                  'profile-server-database-migration-revision',
                ),
              ),
            )
            .data,
        'bb784a0a2cdc',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(
                  'profile-server-database-migration-message',
                ),
              ),
            )
            .data,
        'add admin flag to users',
      );
      expect(
        find.byKey(const ValueKey<String>('profile-server-environment-title')),
        findsOneWidget,
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>('profile-server-environment-name-value'),
              ),
            )
            .data,
        'production',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(
                  'profile-server-environment-debug-value',
                ),
              ),
            )
            .data,
        'Disabled',
      );
      expect(
        find.byKey(const ValueKey<String>('profile-server-storage-title')),
        findsOneWidget,
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>('profile-server-storage-writable-value'),
              ),
            )
            .data,
        'Writable',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>('profile-server-storage-used-detail'),
              ),
            )
            .data,
        '40%',
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(
                  'profile-server-image-cache-total-files-value',
                ),
              ),
            )
            .data,
        '4',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(
                  'profile-server-image-cache-shows-detail',
                ),
              ),
            )
            .data,
        '2 files',
      );
      expect(
        find.byKey(const ValueKey<String>('profile-server-runtime-title')),
        findsOneWidget,
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>('profile-server-runtime-python-value'),
              ),
            )
            .data,
        '3.12.11',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>('profile-server-runtime-platform-value'),
              ),
            )
            .data,
        'Linux',
      );
      expect(
        find.byKey(const ValueKey<String>('profile-server-providers-title')),
        findsOneWidget,
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(
                  'profile-server-provider-tmdb-configured-value',
                ),
              ),
            )
            .data,
        'Configured',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(
                  'profile-server-provider-tmdb-reachable-value',
                ),
              ),
            )
            .data,
        'Reachable',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(
                  'profile-server-provider-tmdb-latency-value',
                ),
              ),
            )
            .data,
        '212 ms',
      );
    });
    testWidgets('does not load Server health for non-administrators', (
      WidgetTester tester,
    ) async {
      final _FakeServerRepository serverRepository = _FakeServerRepository();

      await tester.pumpWidget(
        _buildTestApp(
          profileRepository: const _FakeProfileRepository(user: _regularUser),
          serverRepository: serverRepository,
        ),
      );

      await tester.pumpAndSettle();

      expect(serverRepository.healthCalls, 0);
      expect(serverRepository.backgroundJobsCalls, 0);
      expect(serverRepository.runBackgroundJobCalls, 0);

      expect(
        find.byKey(const ValueKey<String>('profile-server')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-server-title')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-server-health')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-server-loading')),
        findsNothing,
      );
    });
    testWidgets(
      'loads Server independently when another Profile section fails',
      (WidgetTester tester) async {
        final _FakeServerRepository serverRepository = _FakeServerRepository(
          health: _serverHealth,
        );

        await tester.pumpWidget(
          _buildTestApp(
            libraryRepository: const _FakeLibraryRepository(
              error: AppException.connection(),
            ),
            serverRepository: serverRepository,
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('profile-library-failure')),
          findsOneWidget,
        );

        expect(serverRepository.healthCalls, 1);

        expect(
          find.byKey(const ValueKey<String>('profile-server-health')),
          findsOneWidget,
        );

        expect(
          tester
              .widget<Text>(
                find.byKey(
                  const ValueKey<String>('profile-server-health-status'),
                ),
              )
              .data,
          'Healthy',
        );
      },
    );
    testWidgets('Server failure does not hide other Profile sections', (
      WidgetTester tester,
    ) async {
      final _FakeServerRepository serverRepository = _FakeServerRepository(
        healthError: const AppException.connection(),
      );

      await tester.pumpWidget(
        _buildTestApp(
          statisticsRepository: _FakeStatisticsRepository(summary: _summary),
          libraryRepository: const _FakeLibraryRepository(
            preview: _libraryPreview,
          ),
          historyRepository: _FakeHistoryRepository(preview: _historyPreview),
          serverRepository: serverRepository,
        ),
      );

      await tester.pumpAndSettle();

      expect(serverRepository.healthCalls, 1);

      expect(
        find.byKey(const ValueKey<String>('profile-server-failure')),
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

      expect(
        find.byKey(const ValueKey<String>('profile-library-content')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-history-content')),
        findsOneWidget,
      );
    });
    testWidgets('retries only Server health after failure', (
      WidgetTester tester,
    ) async {
      final _RetryServerRepository serverRepository = _RetryServerRepository();

      await tester.pumpWidget(
        _buildTestApp(serverRepository: serverRepository),
      );

      await tester.pumpAndSettle();

      expect(serverRepository.healthCalls, 1);

      expect(
        find.byKey(const ValueKey<String>('profile-server-failure')),
        findsOneWidget,
      );

      final Finder retryButton = find.byKey(
        const ValueKey<String>('profile-server-failure-retry'),
      );

      await tester.ensureVisible(retryButton);
      await tester.pumpAndSettle();

      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      expect(serverRepository.healthCalls, 2);

      expect(
        find.byKey(const ValueKey<String>('profile-server-failure')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-server-health')),
        findsOneWidget,
      );
    });
    testWidgets('shows Background Jobs for administrators', (
      WidgetTester tester,
    ) async {
      final _FakeServerRepository serverRepository = _FakeServerRepository(
        health: _serverHealth,
        backgroundJobs: <BackgroundJob>[_metadataSyncJob],
      );

      await tester.pumpWidget(
        _buildTestApp(serverRepository: serverRepository),
      );

      await tester.pumpAndSettle();

      expect(serverRepository.backgroundJobsCalls, 1);

      expect(
        find.byKey(const ValueKey<String>('profile-background-jobs')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-background-jobs-title')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-background-jobs-content')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('profile-background-job-metadata_sync'),
        ),
        findsOneWidget,
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(
                  'profile-background-job-metadata_sync-name',
                ),
              ),
            )
            .data,
        'Metadata sync',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(
                  'profile-background-job-metadata_sync-schedule',
                ),
              ),
            )
            .data,
        'Every 8h',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(
                  'profile-background-job-metadata_sync-status-value',
                ),
              ),
            )
            .data,
        'Success',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(
                  'profile-background-job-metadata_sync-duration-value',
                ),
              ),
            )
            .data,
        '11s',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(
                  'profile-background-job-metadata_sync-checked-value',
                ),
              ),
            )
            .data,
        '140',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(
                  'profile-background-job-metadata_sync-refreshed-value',
                ),
              ),
            )
            .data,
        '23',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(
                  'profile-background-job-metadata_sync-skipped-value',
                ),
              ),
            )
            .data,
        '117',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(
                  'profile-background-job-metadata_sync-failed-value',
                ),
              ),
            )
            .data,
        '0',
      );
    });
    testWidgets('shows empty Background Jobs state', (
      WidgetTester tester,
    ) async {
      final _FakeServerRepository serverRepository = _FakeServerRepository(
        health: _serverHealth,
      );

      await tester.pumpWidget(
        _buildTestApp(serverRepository: serverRepository),
      );

      await tester.pumpAndSettle();

      expect(serverRepository.backgroundJobsCalls, 1);

      expect(
        find.byKey(const ValueKey<String>('profile-background-jobs-empty')),
        findsOneWidget,
      );

      expect(find.text('No background jobs are registered.'), findsOneWidget);
    });
    testWidgets('retries only Background Jobs after failure', (
      WidgetTester tester,
    ) async {
      final _RetryBackgroundJobsServerRepository serverRepository =
          _RetryBackgroundJobsServerRepository();

      await tester.pumpWidget(
        _buildTestApp(serverRepository: serverRepository),
      );

      await tester.pumpAndSettle();

      expect(serverRepository.healthCalls, 1);

      expect(serverRepository.backgroundJobsCalls, 1);

      expect(
        find.byKey(const ValueKey<String>('profile-background-jobs-failure')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-server-health')),
        findsOneWidget,
      );

      final Finder retryButton = find.byKey(
        const ValueKey<String>('profile-background-jobs-failure-retry'),
      );

      await tester.ensureVisible(retryButton);

      await tester.pumpAndSettle();

      await tester.tap(retryButton);

      await tester.pumpAndSettle();

      expect(serverRepository.healthCalls, 1);

      expect(serverRepository.backgroundJobsCalls, 2);

      expect(
        find.byKey(const ValueKey<String>('profile-background-jobs-failure')),
        findsNothing,
      );

      expect(
        find.byKey(
          const ValueKey<String>('profile-background-job-metadata_sync'),
        ),
        findsOneWidget,
      );
    });
    testWidgets('loads Background Jobs independently from Server health', (
      WidgetTester tester,
    ) async {
      final _ControlledBackgroundJobsServerRepository serverRepository =
          _ControlledBackgroundJobsServerRepository();

      await tester.pumpWidget(
        _buildTestApp(serverRepository: serverRepository),
      );

      await tester.pump();

      expect(serverRepository.healthCalls, 1);

      expect(serverRepository.backgroundJobsCalls, 1);

      expect(
        find.byKey(const ValueKey<String>('profile-server-health')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-background-jobs-loading')),
        findsOneWidget,
      );

      serverRepository.complete(<BackgroundJob>[_metadataSyncJob]);

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-background-jobs-loading')),
        findsNothing,
      );

      expect(
        find.byKey(
          const ValueKey<String>('profile-background-job-metadata_sync'),
        ),
        findsOneWidget,
      );
    });
    testWidgets('runs Background Job now', (WidgetTester tester) async {
      final _FakeServerRepository serverRepository = _FakeServerRepository(
        health: _serverHealth,
        backgroundJobs: <BackgroundJob>[_metadataSyncJob],
        runBackgroundJobResult: _runningMetadataSyncJob,
      );

      await tester.pumpWidget(
        _buildTestApp(serverRepository: serverRepository),
      );

      await tester.pumpAndSettle();

      final Finder runButton = find.byKey(
        const ValueKey<String>('profile-background-job-metadata_sync-run-now'),
      );

      await tester.ensureVisible(runButton);

      await tester.pumpAndSettle();

      await tester.tap(runButton);

      await tester.pump();
      await tester.pump();

      expect(serverRepository.runBackgroundJobCalls, 1);

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(
                  'profile-background-job-metadata_sync-status-value',
                ),
              ),
            )
            .data,
        'Running',
      );

      expect(
        find.byKey(
          const ValueKey<String>(
            'profile-background-job-metadata_sync-run-state',
          ),
        ),
        findsOneWidget,
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(
                  'profile-background-job-metadata_sync-run-state',
                ),
              ),
            )
            .data,
        'Running',
      );
    });
    testWidgets('shows isolated Background Job Run Now failure', (
      WidgetTester tester,
    ) async {
      final _FakeServerRepository serverRepository = _FakeServerRepository(
        health: _serverHealth,
        backgroundJobs: <BackgroundJob>[_metadataSyncJob],
        runBackgroundJobError: const AppException.connection(),
      );

      await tester.pumpWidget(
        _buildTestApp(serverRepository: serverRepository),
      );

      await tester.pumpAndSettle();

      final Finder runButton = find.byKey(
        const ValueKey<String>('profile-background-job-metadata_sync-run-now'),
      );

      await tester.ensureVisible(runButton);

      await tester.tap(runButton);

      await tester.pumpAndSettle();

      expect(serverRepository.runBackgroundJobCalls, 1);

      expect(
        find.byKey(
          const ValueKey<String>(
            'profile-background-job-metadata_sync-run-failure',
          ),
        ),
        findsOneWidget,
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(
                  'profile-background-job-metadata_sync-run-failure-message',
                ),
              ),
            )
            .data,
        'Could not connect to the server. Check the address and your network connection.',
      );

      expect(
        find.byKey(
          const ValueKey<String>('profile-background-job-metadata_sync'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-server-health')),
        findsOneWidget,
      );
    });
    testWidgets('disables Run Now while Background Job is running', (
      WidgetTester tester,
    ) async {
      final _FakeServerRepository serverRepository = _FakeServerRepository(
        health: _serverHealth,
        backgroundJobs: <BackgroundJob>[_runningMetadataSyncJob],
      );

      await tester.pumpWidget(
        _buildTestApp(serverRepository: serverRepository),
      );

      await tester.pump();
      await tester.pump();

      final OutlinedButton button = tester.widget<OutlinedButton>(
        find.byKey(
          const ValueKey<String>(
            'profile-background-job-metadata_sync-run-now',
          ),
        ),
      );

      expect(button.onPressed, isNull);

      expect(serverRepository.runBackgroundJobCalls, 0);

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(
                  'profile-background-job-metadata_sync-run-state',
                ),
              ),
            )
            .data,
        'Running',
      );
    });
  });
}

Widget _buildTestApp({
  ProfileRepository? profileRepository,
  StatisticsRepository? statisticsRepository,
  LibraryRepository? libraryRepository,
  HistoryRepository? historyRepository,
  ServerRepository? serverRepository,
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

  final HistoryPreviewCubit historyPreviewCubit = HistoryPreviewCubit(
    repository: historyRepository ?? const _FakeHistoryRepository(),
  )..load();

  return RepositoryProvider<ServerRepository>(
    create: (BuildContext context) {
      return serverRepository ?? _FakeServerRepository();
    },
    child: MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<ProfileCubit>.value(value: profileCubit),
        BlocProvider<StatisticsSummaryCubit>.value(
          value: statisticsSummaryCubit,
        ),
        BlocProvider<LibraryPreviewCubit>.value(value: libraryPreviewCubit),
        BlocProvider<HistoryPreviewCubit>.value(value: historyPreviewCubit),
      ],
      child: const MaterialApp(home: ProfilePage()),
    ),
  );
}

const ProfileUser _user = ProfileUser(
  id: 'user-1',
  displayName: 'TestDisplay',
  isLocal: true,
  isAdmin: true,
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

final HistoryEpisodeItem _historyEpisodeItem = HistoryEpisodeItem(
  eventId: 'episode-event-1',
  watchedAt: DateTime.utc(2026, 8, 19, 20),
  showId: 'show-1',
  showTmdbId: 95396,
  showTitle: 'Severance',
  episode: const HistoryEpisode(
    id: 'episode-1',
    tmdbId: 2101,
    seasonNumber: 1,
    episodeNumber: 1,
    title: 'Good News About Hell',
  ),
);

final HistoryMovieItem _historyMovieItem = HistoryMovieItem(
  eventId: 'movie-event-1',
  watchedAt: DateTime.utc(2026, 8, 19, 19),
  movieId: 'movie-1',
  movieTmdbId: 438631,
  movieTitle: 'Dune',
);

final HistoryPreview _historyPreview = HistoryPreview(
  episodes: <HistoryEpisodeItem>[_historyEpisodeItem],
  movies: <HistoryMovieItem>[_historyMovieItem],
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

final class _FakeHistoryRepository implements HistoryRepository {
  const _FakeHistoryRepository({
    this.preview = const HistoryPreview(
      episodes: <HistoryEpisodeItem>[],
      movies: <HistoryMovieItem>[],
    ),
    this.error,
  });

  final HistoryPreview preview;
  final AppException? error;

  @override
  Future<HistoryPreview> getPreview() async {
    final AppException? failure = error;

    if (failure != null) {
      throw failure;
    }

    return preview;
  }

  @override
  Future<HistoryPage> getHistory({int limit = 30, String? cursor}) {
    throw UnimplementedError('Full History is not used by ProfilePage tests.');
  }
}

final class _ControlledHistoryRepository implements HistoryRepository {
  final Completer<HistoryPreview> _result = Completer<HistoryPreview>();

  void complete(HistoryPreview preview) {
    if (_result.isCompleted) {
      return;
    }

    _result.complete(preview);
  }

  @override
  Future<HistoryPreview> getPreview() {
    return _result.future;
  }

  @override
  Future<HistoryPage> getHistory({int limit = 30, String? cursor}) {
    throw UnimplementedError('Full History is not used by ProfilePage tests.');
  }
}

final class _RetryHistoryRepository implements HistoryRepository {
  int calls = 0;

  @override
  Future<HistoryPreview> getPreview() async {
    calls += 1;

    if (calls == 1) {
      throw const AppException.connection();
    }

    return _historyPreview;
  }

  @override
  Future<HistoryPage> getHistory({int limit = 30, String? cursor}) {
    throw UnimplementedError('Full History is not used by ProfilePage tests.');
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

class _FakeServerRepository implements ServerRepository {
  _FakeServerRepository({
    this.health,
    this.healthError,
    this.backgroundJobs = const <BackgroundJob>[],
    this.backgroundJobsError,
    this.runBackgroundJobResult,
    this.runBackgroundJobError,
  });

  final ServerHealth? health;
  final AppException? healthError;

  final List<BackgroundJob> backgroundJobs;
  final AppException? backgroundJobsError;
  final BackgroundJob? runBackgroundJobResult;
  final AppException? runBackgroundJobError;

  int healthCalls = 0;
  int backgroundJobsCalls = 0;
  int runBackgroundJobCalls = 0;

  @override
  Future<ServerHealth> getHealth() async {
    healthCalls += 1;

    final AppException? failure = healthError;

    if (failure != null) {
      throw failure;
    }

    return health ?? _serverHealth;
  }

  @override
  Future<List<BackgroundJob>> getBackgroundJobs() async {
    backgroundJobsCalls += 1;

    final AppException? failure = backgroundJobsError;

    if (failure != null) {
      throw failure;
    }

    return backgroundJobs;
  }

  @override
  Future<BackgroundJob> runBackgroundJob(String jobKey) async {
    runBackgroundJobCalls += 1;

    final AppException? failure = runBackgroundJobError;

    if (failure != null) {
      throw failure;
    }

    final BackgroundJob? result = runBackgroundJobResult;

    if (result == null) {
      throw UnimplementedError();
    }

    return result;
  }
}

final class _RetryServerRepository implements ServerRepository {
  int healthCalls = 0;
  int backgroundJobsCalls = 0;
  int runBackgroundJobCalls = 0;

  @override
  Future<ServerHealth> getHealth() async {
    healthCalls += 1;

    if (healthCalls == 1) {
      throw const AppException.connection();
    }

    return _serverHealth;
  }

  @override
  Future<List<BackgroundJob>> getBackgroundJobs() async {
    backgroundJobsCalls += 1;

    return const <BackgroundJob>[];
  }

  @override
  Future<BackgroundJob> runBackgroundJob(String jobKey) {
    runBackgroundJobCalls += 1;

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

final class _RetryBackgroundJobsServerRepository implements ServerRepository {
  int healthCalls = 0;
  int backgroundJobsCalls = 0;
  int runBackgroundJobCalls = 0;

  @override
  Future<ServerHealth> getHealth() async {
    healthCalls += 1;

    return _serverHealth;
  }

  @override
  Future<List<BackgroundJob>> getBackgroundJobs() async {
    backgroundJobsCalls += 1;

    if (backgroundJobsCalls == 1) {
      throw const AppException.connection();
    }

    return <BackgroundJob>[_metadataSyncJob];
  }

  @override
  Future<BackgroundJob> runBackgroundJob(String jobKey) {
    runBackgroundJobCalls += 1;

    throw UnimplementedError();
  }
}

final class _ControlledBackgroundJobsServerRepository
    implements ServerRepository {
  final Completer<List<BackgroundJob>> _result =
      Completer<List<BackgroundJob>>();

  int healthCalls = 0;
  int backgroundJobsCalls = 0;
  int runBackgroundJobCalls = 0;

  void complete(List<BackgroundJob> jobs) {
    if (_result.isCompleted) {
      return;
    }

    _result.complete(jobs);
  }

  @override
  Future<ServerHealth> getHealth() async {
    healthCalls += 1;

    return _serverHealth;
  }

  @override
  Future<List<BackgroundJob>> getBackgroundJobs() {
    backgroundJobsCalls += 1;

    return _result.future;
  }

  @override
  Future<BackgroundJob> runBackgroundJob(String jobKey) {
    runBackgroundJobCalls += 1;

    throw UnimplementedError();
  }
}

const ProfileUser _regularUser = ProfileUser(
  id: 'user-2',
  displayName: 'Regular User',
  isLocal: false,
  isAdmin: false,
);

final ServerHealth _serverHealth = ServerHealth(
  status: ServerHealthStatus.healthy,
  checkedAt: DateTime.utc(2026, 8, 20, 12),
  uptimeSeconds: 3600,
  environment: const ServerEnvironment(
    appName: 'SofaWatch',
    environment: 'production',
    debug: false,
    apiHost: '0.0.0.0',
    apiPort: 8000,
    defaultLanguage: 'en-US',
    supportedLanguages: <String>['en-US', 'pt-PT'],
    metadataRefreshDays: 7,
  ),
  storage: const ServerStorage(
    dataDirectory: './data',
    writable: true,
    totalSpaceBytes: 1_000_000,
    usedSpaceBytes: 400_000,
    freeSpaceBytes: 600_000,
    usagePercentage: 40,
    imageCache: ServerImageCache(
      totalSizeBytes: 375,
      totalFiles: 4,
      breakdown: ServerImageCacheBreakdown(
        shows: ServerImageCacheCategory(sizeBytes: 300, files: 2),
        seasons: ServerImageCacheCategory(sizeBytes: 50, files: 1),
        episodes: ServerImageCacheCategory(sizeBytes: 25, files: 1),
      ),
    ),
  ),
  runtime: ServerRuntime(
    pythonVersion: '3.12.11',
    platform: 'Linux',
    startedAt: DateTime.utc(2026, 8, 20, 11),
  ),
  database: const ServerDatabaseHealth(
    status: ServerComponentStatus.healthy,
    engine: 'sqlite',
    latencyMs: 3.5,
    sizeBytes: 1_048_576,
    walSizeBytes: 8_192,
    integrityCheck: ServerDatabaseCheckStatus.ok,
    foreignKeyCheck: ServerDatabaseCheckStatus.ok,
    migration: ServerDatabaseMigration(
      revision: 'bb784a0a2cdc',
      message: 'add admin flag to users',
    ),
  ),
  tmdb: const ServerTmdbHealth(
    status: ServerComponentStatus.healthy,
    configured: true,
    latencyMs: 212,
  ),
);

final BackgroundJob _metadataSyncJob = BackgroundJob(
  id: 'job-1',
  key: 'metadata_sync',
  name: 'Metadata sync',
  schedule: 'Every 8h',
  status: BackgroundJobStatus.success,
  lastStartedAt: DateTime.utc(2026, 8, 20, 12),
  lastFinishedAt: DateTime.utc(2026, 8, 20, 12, 0, 11),
  lastDurationMs: 11000,
  lastError: null,
  nextRunAt: DateTime.utc(2026, 8, 20, 20),
  lastResult: const BackgroundJobResultSummary(
    checked: 140,
    refreshed: 23,
    skipped: 117,
    failed: 0,
  ),
);

final BackgroundJob _runningMetadataSyncJob = BackgroundJob(
  id: 'job-1',
  key: 'metadata_sync',
  name: 'Metadata sync',
  schedule: 'Every 8h',
  status: BackgroundJobStatus.running,
  lastStartedAt: DateTime.utc(2026, 8, 20, 15),
  lastFinishedAt: null,
  lastDurationMs: null,
  lastError: null,
  nextRunAt: null,
  lastResult: null,
);
