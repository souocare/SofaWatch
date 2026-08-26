import 'dart:async';

import 'package:sofawatch/core/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_error_message_mapper.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/admin_users/domain/models/admin_user.dart';
import 'package:sofawatch/features/admin_users/domain/models/password_recovery_link.dart';
import 'package:sofawatch/features/admin_users/domain/repositories/admin_users_repository.dart';
import 'package:sofawatch/features/history/domain/models/history_episode.dart';
import 'package:sofawatch/features/profile/application/cubit/profile_cubit.dart';
import 'package:sofawatch/features/profile/domain/models/profile_user.dart';
import 'package:sofawatch/features/profile/domain/repositories/profile_repository.dart';
import 'package:sofawatch/features/profile/presentation/pages/profile_page.dart';
import 'package:sofawatch/features/server/domain/models/server_logs.dart';
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
import 'package:sofawatch/features/server/domain/models/server_logs.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/features/profile/application/cubit/data_transfer_cubit.dart';
import 'package:sofawatch/features/profile/domain/models/data_import_preview.dart';
import 'package:sofawatch/features/profile/domain/models/data_import_result.dart';
import 'package:sofawatch/features/profile/domain/repositories/data_transfer_repository.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_cubit.dart';
import 'package:sofawatch/features/auth/domain/models/auth_session.dart';
import 'package:sofawatch/features/auth/domain/repositories/auth_repository.dart';
import 'package:sofawatch/features/security/application/cubit/security_settings_cubit.dart';
import 'package:sofawatch/features/security/domain/models/security_settings.dart';
import 'package:sofawatch/features/security/domain/repositories/security_settings_repository.dart';

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
    testWidgets('navigates from Episode History to Episode details', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildNavigationTestApp(
          historyRepository: _FakeHistoryRepository(preview: _historyPreview),
          destinationRoutes: <GoRoute>[
            GoRoute(
              name: AppRoute.episodeDetails.name,
              path: '/episodes/:episodeId',
              builder: (BuildContext context, GoRouterState state) {
                return Scaffold(
                  body: Text(
                    state.pathParameters['episodeId'] ?? 'missing',
                    key: const ValueKey<String>(
                      'test-episode-details-destination',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      final Finder row = find.byKey(
        const ValueKey<String>('profile-history-episode-episode-event-1'),
      );

      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('test-episode-details-destination')),
        findsOneWidget,
      );

      expect(find.text('episode-1'), findsOneWidget);
    });

    testWidgets('navigates from Movie History to Movie details using TMDB id', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildNavigationTestApp(
          historyRepository: _FakeHistoryRepository(preview: _historyPreview),
          destinationRoutes: <GoRoute>[
            GoRoute(
              name: AppRoute.movieDetails.name,
              path: '/movies/:movieId',
              builder: (BuildContext context, GoRouterState state) {
                return Scaffold(
                  body: Text(
                    state.pathParameters['movieId'] ?? 'missing',
                    key: const ValueKey<String>(
                      'test-movie-details-destination',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      final Finder row = find.byKey(
        const ValueKey<String>('profile-history-movie-movie-event-1'),
      );

      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('test-movie-details-destination')),
        findsOneWidget,
      );

      expect(find.text('438631'), findsOneWidget);
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
    testWidgets('navigates from Episode History to Episode details', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildNavigationTestApp(
          historyRepository: _FakeHistoryRepository(preview: _historyPreview),
          destinationRoutes: <GoRoute>[
            GoRoute(
              name: AppRoute.episodeDetails.name,
              path: '/episodes/:episodeId',
              builder: (BuildContext context, GoRouterState state) {
                return Scaffold(
                  body: Text(
                    state.pathParameters['episodeId'] ?? 'missing',
                    key: const ValueKey<String>(
                      'test-episode-details-destination',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      final Finder row = find.byKey(
        const ValueKey<String>('profile-history-episode-episode-event-1'),
      );

      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('test-episode-details-destination')),
        findsOneWidget,
      );

      expect(find.text('episode-1'), findsOneWidget);
    });

    testWidgets('navigates from Movie History to Movie details using TMDB id', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildNavigationTestApp(
          historyRepository: _FakeHistoryRepository(preview: _historyPreview),
          destinationRoutes: <GoRoute>[
            GoRoute(
              name: AppRoute.movieDetails.name,
              path: '/movies/:movieId',
              builder: (BuildContext context, GoRouterState state) {
                return Scaffold(
                  body: Text(
                    state.pathParameters['movieId'] ?? 'missing',
                    key: const ValueKey<String>(
                      'test-movie-details-destination',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      final Finder row = find.byKey(
        const ValueKey<String>('profile-history-movie-movie-event-1'),
      );

      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('test-movie-details-destination')),
        findsOneWidget,
      );

      expect(find.text('438631'), findsOneWidget);
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
          profileRepository: _FakeProfileRepository(user: _regularUser),
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
    testWidgets('loads Server Logs for administrators', (
      WidgetTester tester,
    ) async {
      final _FakeServerRepository serverRepository = _FakeServerRepository(
        health: _serverHealth,
        logsPage: _serverLogsPage,
      );

      await tester.pumpWidget(
        _buildTestApp(serverRepository: serverRepository),
      );

      await tester.pumpAndSettle();

      expect(serverRepository.logsCalls, 1);

      expect(
        find.byKey(const ValueKey<String>('profile-server-logs')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-server-logs-title')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-server-logs-filter')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-server-logs-list')),
        findsOneWidget,
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey<String>('profile-server-log-0-logger')),
            )
            .data,
        'app.jobs.executor',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>('profile-server-log-0-message'),
              ),
            )
            .data,
        'Metadata sync failed.',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>('profile-server-log-0-component'),
              ),
            )
            .data,
        'Worker',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey<String>('profile-server-logs-count')),
            )
            .data,
        '2 of 2 logs',
      );
    });
    testWidgets('filters Server Logs by level', (WidgetTester tester) async {
      final _FakeServerRepository serverRepository = _FakeServerRepository(
        health: _serverHealth,
        logsPage: _serverLogsPage,
      );

      await tester.pumpWidget(
        _buildTestApp(serverRepository: serverRepository),
      );

      await tester.pumpAndSettle();

      final Finder errorFilter = find.byKey(
        const ValueKey<String>('profile-server-logs-filter-error'),
      );

      await tester.ensureVisible(errorFilter);

      await tester.tap(errorFilter);

      await tester.pumpAndSettle();

      expect(serverRepository.logsCalls, 2);

      expect(serverRepository.logLevelRequests.last, ServerLogLevel.error);

      expect(serverRepository.logOffsetRequests.last, 0);
    });
    testWidgets('refreshes Server Logs independently', (
      WidgetTester tester,
    ) async {
      final _FakeServerRepository serverRepository = _FakeServerRepository(
        health: _serverHealth,
        logsPage: _serverLogsPage,
      );

      await tester.pumpWidget(
        _buildTestApp(serverRepository: serverRepository),
      );

      await tester.pumpAndSettle();

      expect(serverRepository.healthCalls, 1);

      expect(serverRepository.backgroundJobsCalls, 1);

      expect(serverRepository.logsCalls, 1);

      final Finder refreshButton = find.byKey(
        const ValueKey<String>('profile-server-logs-refresh'),
      );

      await tester.ensureVisible(refreshButton);

      await tester.tap(refreshButton);

      await tester.pumpAndSettle();

      expect(serverRepository.logsCalls, 2);

      expect(serverRepository.healthCalls, 1);

      expect(serverRepository.backgroundJobsCalls, 1);
    });
    testWidgets('shows Server Logs failure independently', (
      WidgetTester tester,
    ) async {
      final _FakeServerRepository serverRepository = _FakeServerRepository(
        health: _serverHealth,
        logsError: const AppException.connection(),
      );

      await tester.pumpWidget(
        _buildTestApp(serverRepository: serverRepository),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-server-logs-failure')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-server-health')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-background-jobs')),
        findsOneWidget,
      );
    });
    testWidgets('loads more Server Logs', (WidgetTester tester) async {
      final _PaginatedLogsServerRepository serverRepository =
          _PaginatedLogsServerRepository();

      await tester.pumpWidget(
        _buildTestApp(serverRepository: serverRepository),
      );

      await tester.pumpAndSettle();

      expect(serverRepository.logsCalls, 1);

      expect(
        find.byKey(const ValueKey<String>('profile-server-logs-load-more')),
        findsOneWidget,
      );

      final Finder loadMoreButton = find.byKey(
        const ValueKey<String>('profile-server-logs-load-more'),
      );

      await tester.ensureVisible(loadMoreButton);

      await tester.tap(loadMoreButton);

      await tester.pumpAndSettle();

      expect(serverRepository.logsCalls, 2);

      expect(serverRepository.offsetRequests, <int>[0, 2]);

      expect(
        find.byKey(const ValueKey<String>('profile-server-log-2')),
        findsOneWidget,
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>('profile-server-log-2-message'),
              ),
            )
            .data,
        'TMDB request retry.',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey<String>('profile-server-logs-count')),
            )
            .data,
        '3 of 3 logs',
      );

      expect(
        find.byKey(const ValueKey<String>('profile-server-logs-load-more')),
        findsNothing,
      );
    });

    testWidgets('preserves Server Logs after pagination failure', (
      WidgetTester tester,
    ) async {
      final _PaginationFailureLogsServerRepository serverRepository =
          _PaginationFailureLogsServerRepository();

      await tester.pumpWidget(
        _buildTestApp(serverRepository: serverRepository),
      );

      await tester.pumpAndSettle();

      final Finder loadMoreButton = find.byKey(
        const ValueKey<String>('profile-server-logs-load-more'),
      );

      await tester.ensureVisible(loadMoreButton);

      await tester.tap(loadMoreButton);

      await tester.pumpAndSettle();

      expect(serverRepository.logsCalls, 2);

      expect(
        find.byKey(
          const ValueKey<String>('profile-server-logs-pagination-failure'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-server-log-0')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-server-log-1')),
        findsOneWidget,
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(
                  'profile-server-logs-pagination-failure-message',
                ),
              ),
            )
            .data,
        'Could not connect to the server. Check the address and your network connection.',
      );
    });

    testWidgets('retries failed Server Logs pagination', (
      WidgetTester tester,
    ) async {
      final _RetryPaginationLogsServerRepository serverRepository =
          _RetryPaginationLogsServerRepository();

      await tester.pumpWidget(
        _buildTestApp(serverRepository: serverRepository),
      );

      await tester.pumpAndSettle();

      final Finder loadMoreButton = find.byKey(
        const ValueKey<String>('profile-server-logs-load-more'),
      );

      await tester.ensureVisible(loadMoreButton);

      await tester.tap(loadMoreButton);

      await tester.pumpAndSettle();

      expect(serverRepository.logsCalls, 2);

      expect(
        find.byKey(
          const ValueKey<String>('profile-server-logs-pagination-failure'),
        ),
        findsOneWidget,
      );

      final Finder retryButton = find.byKey(
        const ValueKey<String>('profile-server-logs-pagination-failure-retry'),
      );

      await tester.ensureVisible(retryButton);

      await tester.tap(retryButton);

      await tester.pumpAndSettle();

      expect(serverRepository.logsCalls, 3);

      expect(serverRepository.offsetRequests, <int>[0, 2, 2]);

      expect(
        find.byKey(
          const ValueKey<String>('profile-server-logs-pagination-failure'),
        ),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-server-log-2')),
        findsOneWidget,
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey<String>('profile-server-logs-count')),
            )
            .data,
        '3 of 3 logs',
      );
    });
    testWidgets('adapts Profile layout to narrow mobile width', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildTestApp(
          serverRepository: _FakeServerRepository(
            backgroundJobs: <BackgroundJob>[_metadataSyncJob],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      expect(
        find.byKey(const ValueKey<String>('profile-page')),
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
        find.byKey(
          const ValueKey<String>(
            'profile-background-job-metadata_sync-stacked-header',
          ),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>(
            'profile-background-job-metadata_sync-wide-header',
          ),
        ),
        findsNothing,
      );
    });

    testWidgets('adapts Profile layout to desktop width', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildTestApp(
          serverRepository: _FakeServerRepository(
            backgroundJobs: <BackgroundJob>[_metadataSyncJob],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      expect(
        find.byKey(const ValueKey<String>('profile-page')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>(
            'profile-background-job-metadata_sync-wide-header',
          ),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>(
            'profile-background-job-metadata_sync-stacked-header',
          ),
        ),
        findsNothing,
      );
    });
    testWidgets('navigates from Profile to detailed Statistics', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildNavigationTestApp(
          destinationRoutes: <GoRoute>[
            GoRoute(
              name: AppRoute.detailedStatistics.name,
              path: '/statistics',
              builder: (BuildContext context, GoRouterState state) {
                return const Scaffold(
                  body: Text(
                    'Detailed Statistics destination',
                    key: ValueKey<String>(
                      'test-detailed-statistics-destination',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      final Finder action = find.byKey(
        const ValueKey<String>('profile-detailed-statistics-action'),
      );

      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('test-detailed-statistics-destination'),
        ),
        findsOneWidget,
      );
    });
  });
  group('ProfilePage Import / Export', () {
    testWidgets('shows Import / Export tools on Web Profile', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(isWeb: true));

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-data-transfer')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-data-transfer-title')),
        findsOneWidget,
      );

      expect(find.text('Import / Export'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('profile-data-transfer-export-card')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-data-transfer-import-card')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-data-transfer-export')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('profile-data-transfer-import-select'),
        ),
        findsOneWidget,
      );
    });
    testWidgets('shows Export loading and safe failure state', (
      WidgetTester tester,
    ) async {
      final _ControlledDataTransferRepository repository =
          _ControlledDataTransferRepository();

      await tester.pumpWidget(
        _buildTestApp(isWeb: true, dataTransferRepository: repository),
      );

      await tester.pumpAndSettle();

      final Finder exportButton = find.byKey(
        const ValueKey<String>('profile-data-transfer-export'),
      );

      await tester.ensureVisible(exportButton);
      await tester.pumpAndSettle();

      await tester.tap(exportButton);
      await tester.pump();

      expect(repository.exportCalls, 1);

      final FilledButton loadingButton = tester.widget<FilledButton>(
        exportButton,
      );

      expect(loadingButton.onPressed, isNull);
      expect(find.text('Exporting…'), findsOneWidget);

      repository.failExport(const AppException.connection());

      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('profile-data-transfer-export-error'),
        ),
        findsOneWidget,
      );

      final FilledButton retryableButton = tester.widget<FilledButton>(
        exportButton,
      );

      expect(retryableButton.onPressed, isNotNull);
    });
    testWidgets('shows validated Import preview and confirmation actions', (
      WidgetTester tester,
    ) async {
      final _FakeDataTransferRepository repository =
          _FakeDataTransferRepository(
            preview: const DataImportPreview(
              format: 'sofawatch-export',
              version: 1,
              userDisplayName: 'Backup User',
              libraryShows: 12,
              libraryMovies: 7,
              episodeWatchEvents: 145,
              movieWatchEvents: 19,
            ),
          );

      await tester.pumpWidget(
        _buildTestApp(isWeb: true, dataTransferRepository: repository),
      );

      await tester.pumpAndSettle();

      final DataTransferCubit cubit = tester
          .element(
            find.byKey(
              const ValueKey<String>('profile-data-transfer-import-card'),
            ),
          )
          .read<DataTransferCubit>();

      await cubit.previewImport(
        filename: 'sofawatch-backup.json',
        json: '{"format":"sofawatch-export","version":1}',
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('profile-data-transfer-import-preview'),
        ),
        findsOneWidget,
      );

      expect(find.text('sofawatch-backup.json'), findsOneWidget);
      expect(find.text('Backup from Backup User'), findsOneWidget);
      expect(find.text('sofawatch-export · Version 1'), findsOneWidget);

      expect(
        find.byKey(
          const ValueKey<String>(
            'profile-data-transfer-import-preview-library-shows',
          ),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>(
            'profile-data-transfer-import-preview-library-movies',
          ),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>(
            'profile-data-transfer-import-preview-episode-watch-events',
          ),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>(
            'profile-data-transfer-import-preview-movie-watch-events',
          ),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('profile-data-transfer-import-cancel'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('profile-data-transfer-import-confirm'),
        ),
        findsOneWidget,
      );
    });
    testWidgets('shows partial Import result including failed items', (
      WidgetTester tester,
    ) async {
      const DataImportResult result = DataImportResult(
        library: DataImportLibraryResult(
          shows: DataImportMediaResult(
            created: 4,
            updated: 2,
            unchanged: 6,
            failed: 1,
          ),
          movies: DataImportMediaResult(
            created: 3,
            updated: 1,
            unchanged: 3,
            failed: 0,
          ),
        ),
        history: DataImportHistoryResult(
          episodes: DataImportHistoryMediaResult(
            created: 130,
            skipped: 10,
            failed: 5,
          ),
          movies: DataImportHistoryMediaResult(
            created: 15,
            skipped: 4,
            failed: 0,
          ),
        ),
      );

      final _FakeDataTransferRepository repository =
          _FakeDataTransferRepository(importResult: result);

      await tester.pumpWidget(
        _buildTestApp(isWeb: true, dataTransferRepository: repository),
      );

      await tester.pumpAndSettle();

      final DataTransferCubit cubit = tester
          .element(
            find.byKey(
              const ValueKey<String>('profile-data-transfer-import-card'),
            ),
          )
          .read<DataTransferCubit>();

      await cubit.importData('{"format":"sofawatch-export","version":1}');

      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('profile-data-transfer-import-success'),
        ),
        findsOneWidget,
      );

      expect(find.text('Import completed with some issues'), findsOneWidget);

      expect(
        find.byKey(
          const ValueKey<String>(
            'profile-data-transfer-import-result-library-shows-failed',
          ),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>(
            'profile-data-transfer-import-result-history-episodes-failed',
          ),
        ),
        findsOneWidget,
      );

      // Zero failures should not create visual noise.
      expect(
        find.byKey(
          const ValueKey<String>(
            'profile-data-transfer-import-result-library-movies-failed',
          ),
        ),
        findsNothing,
      );

      expect(
        find.byKey(
          const ValueKey<String>(
            'profile-data-transfer-import-result-history-movies-failed',
          ),
        ),
        findsNothing,
      );

      expect(
        find.byKey(
          const ValueKey<String>('profile-data-transfer-import-another'),
        ),
        findsOneWidget,
      );
    });
    testWidgets('shows Import failure and can start over', (
      WidgetTester tester,
    ) async {
      final _FakeDataTransferRepository repository =
          _FakeDataTransferRepository(
            importError: const AppException.connection(),
          );

      await tester.pumpWidget(
        _buildTestApp(isWeb: true, dataTransferRepository: repository),
      );

      await tester.pumpAndSettle();

      final DataTransferCubit cubit = tester
          .element(
            find.byKey(
              const ValueKey<String>('profile-data-transfer-import-card'),
            ),
          )
          .read<DataTransferCubit>();

      await cubit.importData('{"format":"sofawatch-export","version":1}');

      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('profile-data-transfer-import-failure'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('profile-data-transfer-import-error'),
        ),
        findsOneWidget,
      );

      final Finder startOver = find.byKey(
        const ValueKey<String>('profile-data-transfer-import-start-over'),
      );

      expect(startOver, findsOneWidget);

      await tester.ensureVisible(startOver);
      await tester.pumpAndSettle();

      await tester.tap(startOver);
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('profile-data-transfer-import-failure'),
        ),
        findsNothing,
      );

      expect(
        find.byKey(
          const ValueKey<String>('profile-data-transfer-import-select'),
        ),
        findsOneWidget,
      );
    });
    group('ProfilePage Account', () {
      testWidgets('shows Log out everywhere action', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(_buildTestApp());

        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const ValueKey<String>('profile-logout-everywhere-action'),
          ),
          findsOneWidget,
        );

        expect(find.text('Log out everywhere'), findsOneWidget);

        expect(
          find.text('End all active SofaWatch sessions on every device.'),
          findsOneWidget,
        );
      });

      testWidgets('asks for confirmation before logging out everywhere', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(_buildTestApp());

        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(
            const ValueKey<String>('profile-logout-everywhere-action'),
          ),
        );

        await tester.tap(
          find.byKey(
            const ValueKey<String>('profile-logout-everywhere-action'),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const ValueKey<String>('profile-logout-everywhere-dialog'),
          ),
          findsOneWidget,
        );

        expect(find.text('Log out everywhere?'), findsOneWidget);

        expect(
          find.text(
            'This will end all active SofaWatch sessions on every device, '
            'including this one.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('cancelling does not log out everywhere', (
        WidgetTester tester,
      ) async {
        final _FakeAuthRepository authRepository = _FakeAuthRepository();

        await tester.pumpWidget(_buildTestApp(authRepository: authRepository));

        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(
            const ValueKey<String>('profile-logout-everywhere-action'),
          ),
        );

        await tester.tap(
          find.byKey(
            const ValueKey<String>('profile-logout-everywhere-action'),
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(
            const ValueKey<String>('profile-logout-everywhere-cancel'),
          ),
        );

        await tester.pumpAndSettle();

        expect(authRepository.logoutEverywhereCalls, 0);

        expect(
          find.byKey(
            const ValueKey<String>('profile-logout-everywhere-dialog'),
          ),
          findsNothing,
        );
      });

      testWidgets('confirmation logs out everywhere', (
        WidgetTester tester,
      ) async {
        final _FakeAuthRepository authRepository = _FakeAuthRepository();

        await tester.pumpWidget(_buildTestApp(authRepository: authRepository));

        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(
            const ValueKey<String>('profile-logout-everywhere-action'),
          ),
        );

        await tester.tap(
          find.byKey(
            const ValueKey<String>('profile-logout-everywhere-action'),
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(
            const ValueKey<String>('profile-logout-everywhere-confirm'),
          ),
        );

        await tester.pumpAndSettle();

        expect(authRepository.logoutEverywhereCalls, 1);
      });
    });
  });
  group('ProfilePage Security', () {
    testWidgets('shows Security settings for administrator', (
      WidgetTester tester,
    ) async {
      final _FakeSecuritySettingsRepository securityRepository =
          _FakeSecuritySettingsRepository();

      await tester.pumpWidget(
        _buildTestApp(securitySettingsRepository: securityRepository),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-security')),
        findsOneWidget,
      );

      expect(find.text('Security'), findsOneWidget);
      expect(find.text('Open registration'), findsOneWidget);

      expect(securityRepository.getSettingsCalls, 1);
    });

    testWidgets(
      'hides Security settings and does not load them for regular user',
      (WidgetTester tester) async {
        final _FakeSecuritySettingsRepository securityRepository =
            _FakeSecuritySettingsRepository();

        const ProfileUser regularUser = ProfileUser(
          id: 'user-2',
          displayName: 'Regular User',
          username: 'souocare',
          email: 'test@test.pt',
          isLocal: false,
          isAdmin: false,
        );

        await tester.pumpWidget(
          _buildTestApp(
            profileRepository: _FakeProfileRepository(user: regularUser),
            securitySettingsRepository: securityRepository,
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('profile-security')),
          findsNothing,
        );

        expect(find.text('Open registration'), findsNothing);

        expect(securityRepository.getSettingsCalls, 0);
      },
    );

    testWidgets('shows current Open registration value', (
      WidgetTester tester,
    ) async {
      final _FakeSecuritySettingsRepository securityRepository =
          _FakeSecuritySettingsRepository(
            settings: const SecuritySettings(openRegistration: true),
          );

      await tester.pumpWidget(
        _buildTestApp(securitySettingsRepository: securityRepository),
      );

      await tester.pumpAndSettle();

      final Finder switchFinder = find.byKey(
        const ValueKey<String>('profile-security-open-registration'),
      );

      expect(switchFinder, findsOneWidget);

      final SwitchListTile registrationTile = tester.widget<SwitchListTile>(
        switchFinder,
      );

      expect(registrationTile.value, isTrue);
    });

    testWidgets('enables Open registration', (WidgetTester tester) async {
      final _FakeSecuritySettingsRepository securityRepository =
          _FakeSecuritySettingsRepository(
            settings: const SecuritySettings(openRegistration: false),
          );

      await tester.pumpWidget(
        _buildTestApp(securitySettingsRepository: securityRepository),
      );

      await tester.pumpAndSettle();

      final Finder switchFinder = find.byKey(
        const ValueKey<String>('profile-security-open-registration'),
      );

      await tester.ensureVisible(switchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(switchFinder).value, isFalse);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(securityRepository.updateCalls, 1);
      expect(securityRepository.lastEnabled, isTrue);

      expect(tester.widget<SwitchListTile>(switchFinder).value, isTrue);
    });

    testWidgets('disables Open registration', (WidgetTester tester) async {
      final _FakeSecuritySettingsRepository securityRepository =
          _FakeSecuritySettingsRepository(
            settings: const SecuritySettings(openRegistration: true),
          );

      await tester.pumpWidget(
        _buildTestApp(securitySettingsRepository: securityRepository),
      );

      await tester.pumpAndSettle();

      final Finder switchFinder = find.byKey(
        const ValueKey<String>('profile-security-open-registration'),
      );

      await tester.ensureVisible(switchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(switchFinder).value, isTrue);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(securityRepository.updateCalls, 1);
      expect(securityRepository.lastEnabled, isFalse);

      expect(tester.widget<SwitchListTile>(switchFinder).value, isFalse);
    });

    testWidgets('keeps previous Open registration value when update fails', (
      WidgetTester tester,
    ) async {
      const AppException updateError = AppException.connection();

      final _FakeSecuritySettingsRepository securityRepository =
          _FakeSecuritySettingsRepository(
            settings: const SecuritySettings(openRegistration: false),
            updateError: updateError,
          );

      await tester.pumpWidget(
        _buildTestApp(securitySettingsRepository: securityRepository),
      );

      await tester.pumpAndSettle();

      final Finder switchFinder = find.byKey(
        const ValueKey<String>('profile-security-open-registration'),
      );

      await tester.ensureVisible(switchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(switchFinder).value, isFalse);

      await tester.tap(switchFinder);
      await tester.pump();

      expect(securityRepository.updateCalls, 1);

      // Failed update must not optimistically change the persisted value.
      expect(tester.widget<SwitchListTile>(switchFinder).value, isFalse);

      // Update failures are surfaced as transient feedback instead of replacing
      // the independently loaded Security settings.
      expect(find.byType(SnackBar), findsOneWidget);

      expect(find.text(AppErrorMessageMapper.map(updateError)), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('shows Security failure independently from other sections', (
      WidgetTester tester,
    ) async {
      final _FakeSecuritySettingsRepository securityRepository =
          _FakeSecuritySettingsRepository(
            loadError: const AppException.connection(),
          );

      await tester.pumpWidget(
        _buildTestApp(securitySettingsRepository: securityRepository),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-security-failure')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-user-card')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-statistics')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-library')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-history')),
        findsOneWidget,
      );
    });

    testWidgets('retries Security settings after load failure', (
      WidgetTester tester,
    ) async {
      final _RetrySecuritySettingsRepository securityRepository =
          _RetrySecuritySettingsRepository();

      await tester.pumpWidget(
        _buildTestApp(securitySettingsRepository: securityRepository),
      );

      await tester.pumpAndSettle();

      expect(securityRepository.getSettingsCalls, 1);

      expect(
        find.byKey(const ValueKey<String>('profile-security-failure')),
        findsOneWidget,
      );

      final Finder retryFinder = find.byKey(
        const ValueKey<String>('profile-security-failure-retry'),
      );

      await tester.ensureVisible(retryFinder);
      await tester.pumpAndSettle();

      await tester.tap(retryFinder);
      await tester.pumpAndSettle();

      expect(securityRepository.getSettingsCalls, 2);

      expect(
        find.byKey(const ValueKey<String>('profile-security-failure')),
        findsNothing,
      );

      expect(find.text('Open registration'), findsOneWidget);
    });
  });
  group('ProfilePage Display name', () {
    testWidgets('opens display name editor from Profile identity card', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-edit-display-name-action')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('profile-edit-display-name-action')),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-edit-display-name-sheet')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-edit-display-name-field')),
        findsOneWidget,
      );

      expect(find.text('Edit display name'), findsOneWidget);
    });

    testWidgets('prefills editor with current display name', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('profile-edit-display-name-action')),
      );

      await tester.pumpAndSettle();

      final TextField field = tester.widget<TextField>(
        find.byKey(const ValueKey<String>('profile-edit-display-name-field')),
      );

      expect(field.controller?.text, 'TestDisplay');
    });

    testWidgets('updates display name and refreshes Profile identity', (
      WidgetTester tester,
    ) async {
      final _FakeProfileRepository profileRepository = _FakeProfileRepository();

      await tester.pumpWidget(
        _buildTestApp(profileRepository: profileRepository),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('profile-edit-display-name-action')),
      );

      await tester.pumpAndSettle();

      final Finder fieldFinder = find.byKey(
        const ValueKey<String>('profile-edit-display-name-field'),
      );

      await tester.enterText(fieldFinder, 'Gonçalo Fonseca');

      await tester.tap(
        find.byKey(const ValueKey<String>('profile-edit-display-name-save')),
      );

      await tester.pumpAndSettle();

      expect(profileRepository.updateDisplayNameCalls, 1);
      expect(profileRepository.lastDisplayName, 'Gonçalo Fonseca');

      expect(
        find.byKey(const ValueKey<String>('profile-edit-display-name-sheet')),
        findsNothing,
      );

      expect(find.text('Gonçalo Fonseca'), findsOneWidget);
    });

    testWidgets('trims display name before updating', (
      WidgetTester tester,
    ) async {
      final _FakeProfileRepository profileRepository = _FakeProfileRepository();

      await tester.pumpWidget(
        _buildTestApp(profileRepository: profileRepository),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('profile-edit-display-name-action')),
      );

      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey<String>('profile-edit-display-name-field')),
        '   Gonçalo Fonseca   ',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('profile-edit-display-name-save')),
      );

      await tester.pumpAndSettle();

      expect(profileRepository.lastDisplayName, 'Gonçalo Fonseca');
    });

    testWidgets('rejects blank display name without calling repository', (
      WidgetTester tester,
    ) async {
      final _FakeProfileRepository profileRepository = _FakeProfileRepository();

      await tester.pumpWidget(
        _buildTestApp(profileRepository: profileRepository),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('profile-edit-display-name-action')),
      );

      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey<String>('profile-edit-display-name-field')),
        '   ',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('profile-edit-display-name-save')),
      );

      await tester.pump();

      expect(find.text('Display name is required.'), findsOneWidget);

      expect(profileRepository.updateDisplayNameCalls, 0);

      expect(
        find.byKey(const ValueKey<String>('profile-edit-display-name-sheet')),
        findsOneWidget,
      );
    });

    testWidgets('closes editor without update when display name is unchanged', (
      WidgetTester tester,
    ) async {
      final _FakeProfileRepository profileRepository = _FakeProfileRepository();

      await tester.pumpWidget(
        _buildTestApp(profileRepository: profileRepository),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('profile-edit-display-name-action')),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('profile-edit-display-name-save')),
      );

      await tester.pumpAndSettle();

      expect(profileRepository.updateDisplayNameCalls, 0);

      expect(
        find.byKey(const ValueKey<String>('profile-edit-display-name-sheet')),
        findsNothing,
      );
    });

    testWidgets('keeps editor open when display name update fails', (
      WidgetTester tester,
    ) async {
      final _FakeProfileRepository profileRepository = _FakeProfileRepository(
        updateDisplayNameError: const AppException.connection(),
      );

      await tester.pumpWidget(
        _buildTestApp(profileRepository: profileRepository),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('profile-edit-display-name-action')),
      );

      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey<String>('profile-edit-display-name-field')),
        'New Name',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('profile-edit-display-name-save')),
      );

      await tester.pumpAndSettle();

      expect(profileRepository.updateDisplayNameCalls, 1);

      expect(
        find.byKey(const ValueKey<String>('profile-edit-display-name-sheet')),
        findsOneWidget,
      );

      expect(find.text('TestDisplay'), findsOneWidget);
    });

    testWidgets('cancel closes editor without updating display name', (
      WidgetTester tester,
    ) async {
      final _FakeProfileRepository profileRepository = _FakeProfileRepository();

      await tester.pumpWidget(
        _buildTestApp(profileRepository: profileRepository),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('profile-edit-display-name-action')),
      );

      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey<String>('profile-edit-display-name-field')),
        'Changed but cancelled',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('profile-edit-display-name-cancel')),
      );

      await tester.pumpAndSettle();

      expect(profileRepository.updateDisplayNameCalls, 0);

      expect(
        find.byKey(const ValueKey<String>('profile-edit-display-name-sheet')),
        findsNothing,
      );

      expect(find.text('TestDisplay'), findsOneWidget);
    });
  });
  group('ProfilePage Change Password', () {
    testWidgets('opens Change password dialog on desktop', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp());

      await tester.pumpAndSettle();

      final Finder action = find.byKey(
        const ValueKey<String>('profile-change-password-action'),
      );

      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-change-password-dialog')),
        findsOneWidget,
      );

      expect(find.text('Change password'), findsWidgets);

      expect(
        find.byKey(
          const ValueKey<String>('profile-change-password-current-field'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-change-password-new-field')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('profile-change-password-confirm-field'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('opens Change password sheet on mobile', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp());

      await tester.pumpAndSettle();

      final Finder action = find.byKey(
        const ValueKey<String>('profile-change-password-action'),
      );

      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-change-password-sheet')),
        findsOneWidget,
      );

      expect(find.text('Change password'), findsWidgets);
    });

    testWidgets('requires current password', (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp());

      await tester.pumpAndSettle();

      final Finder action = find.byKey(
        const ValueKey<String>('profile-change-password-action'),
      );

      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();

      final Finder save = find.byKey(
        const ValueKey<String>('profile-change-password-save'),
      );

      await tester.tap(save);
      await tester.pump();

      expect(find.text('Current password is required.'), findsOneWidget);
    });

    testWidgets('requires new password', (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp());

      await tester.pumpAndSettle();

      final Finder action = find.byKey(
        const ValueKey<String>('profile-change-password-action'),
      );

      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(
          const ValueKey<String>('profile-change-password-current-field'),
        ),
        'current-password',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('profile-change-password-save')),
      );

      await tester.pump();

      expect(
        find.text('New password must be at least 8 characters.'),
        findsOneWidget,
      );

      expect(find.text('Please confirm your new password.'), findsOneWidget);
    });

    testWidgets('rejects new password shorter than eight characters', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());

      await tester.pumpAndSettle();

      final Finder action = find.byKey(
        const ValueKey<String>('profile-change-password-action'),
      );

      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(
          const ValueKey<String>('profile-change-password-current-field'),
        ),
        'current-password',
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('profile-change-password-new-field')),
        'short',
      );

      await tester.enterText(
        find.byKey(
          const ValueKey<String>('profile-change-password-confirm-field'),
        ),
        'short',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('profile-change-password-save')),
      );

      await tester.pump();

      expect(
        find.text('New password must be at least 8 characters.'),
        findsOneWidget,
      );
    });

    testWidgets('requires matching password confirmation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());

      await tester.pumpAndSettle();

      final Finder action = find.byKey(
        const ValueKey<String>('profile-change-password-action'),
      );

      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(
          const ValueKey<String>('profile-change-password-current-field'),
        ),
        'current-password',
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('profile-change-password-new-field')),
        'new-password',
      );

      await tester.enterText(
        find.byKey(
          const ValueKey<String>('profile-change-password-confirm-field'),
        ),
        'different-password',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('profile-change-password-save')),
      );

      await tester.pump();

      expect(find.text('Passwords do not match.'), findsOneWidget);
    });

    testWidgets('changes password successfully', (WidgetTester tester) async {
      final _PasswordProfileRepository profileRepository =
          _PasswordProfileRepository();

      await tester.pumpWidget(
        _buildTestApp(profileRepository: profileRepository),
      );

      await tester.pumpAndSettle();

      final Finder action = find.byKey(
        const ValueKey<String>('profile-change-password-action'),
      );

      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(
          const ValueKey<String>('profile-change-password-current-field'),
        ),
        'current-password',
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('profile-change-password-new-field')),
        'new-password',
      );

      await tester.enterText(
        find.byKey(
          const ValueKey<String>('profile-change-password-confirm-field'),
        ),
        'new-password',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('profile-change-password-save')),
      );

      await tester.pumpAndSettle();

      expect(profileRepository.updatePasswordCalls, 1);
      expect(profileRepository.lastCurrentPassword, 'current-password');
      expect(profileRepository.lastNewPassword, 'new-password');

      expect(
        find.byKey(const ValueKey<String>('profile-change-password-dialog')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-change-password-sheet')),
        findsNothing,
      );
    });

    testWidgets('keeps Change password open when current password is invalid', (
      WidgetTester tester,
    ) async {
      final _PasswordProfileRepository profileRepository =
          _PasswordProfileRepository(
            error: const AppException(
              type: AppExceptionType.badResponse,
              message: 'The current password is incorrect.',
              code: 'current_password_invalid',
              statusCode: 400,
            ),
          );

      await tester.pumpWidget(
        _buildTestApp(profileRepository: profileRepository),
      );

      await tester.pumpAndSettle();

      final Finder action = find.byKey(
        const ValueKey<String>('profile-change-password-action'),
      );

      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(
          const ValueKey<String>('profile-change-password-current-field'),
        ),
        'wrong-password',
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('profile-change-password-new-field')),
        'new-password',
      );

      await tester.enterText(
        find.byKey(
          const ValueKey<String>('profile-change-password-confirm-field'),
        ),
        'new-password',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('profile-change-password-save')),
      );

      await tester.pump();
      await tester.pump();

      expect(profileRepository.updatePasswordCalls, 1);

      expect(find.text('The current password is incorrect.'), findsOneWidget);

      expect(
        find.byKey(
          const ValueKey<String>('profile-change-password-current-field'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('disables Change password actions while request is running', (
      WidgetTester tester,
    ) async {
      final _ControlledPasswordProfileRepository profileRepository =
          _ControlledPasswordProfileRepository();

      await tester.pumpWidget(
        _buildTestApp(profileRepository: profileRepository),
      );

      await tester.pumpAndSettle();

      final Finder action = find.byKey(
        const ValueKey<String>('profile-change-password-action'),
      );

      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(
          const ValueKey<String>('profile-change-password-current-field'),
        ),
        'current-password',
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('profile-change-password-new-field')),
        'new-password',
      );

      await tester.enterText(
        find.byKey(
          const ValueKey<String>('profile-change-password-confirm-field'),
        ),
        'new-password',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('profile-change-password-save')),
      );

      await tester.pump();

      expect(profileRepository.updatePasswordCalls, 1);

      final FilledButton saveButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey<String>('profile-change-password-save')),
      );

      final TextButton cancelButton = tester.widget<TextButton>(
        find.byKey(const ValueKey<String>('profile-change-password-cancel')),
      );

      expect(saveButton.onPressed, isNull);
      expect(cancelButton.onPressed, isNull);

      expect(find.text('Saving…'), findsOneWidget);

      profileRepository.complete();

      await tester.pumpAndSettle();
    });
  });
  group('ProfilePage Admin Users', () {
    testWidgets('shows Users section for administrator', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 900);

      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(
        _buildTestApp(
          adminUsersRepository: const _FakeAdminUsersRepository(
            users: <AdminUser>[
              AdminUser(
                id: 'user-1',
                username: 'regular-user',
                email: 'regular@example.com',
                displayName: 'Regular User',
                isActive: true,
                isLocal: false,
                isAdmin: false,
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-users')),
        findsOneWidget,
      );

      expect(find.text('Regular User'), findsOneWidget);
    });

    testWidgets('hides Users section for regular user', (
      WidgetTester tester,
    ) async {
      const ProfileUser regularProfileUser = ProfileUser(
        id: 'regular-profile-user',
        username: 'regular',
        email: 'regular@example.com',
        displayName: 'Regular User',
        isLocal: false,
        isAdmin: false,
      );

      await tester.pumpWidget(
        _buildTestApp(
          profileRepository: _FakeProfileRepository(user: regularProfileUser),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('profile-users')), findsNothing);
    });

    testWidgets('does not load users for regular user', (
      WidgetTester tester,
    ) async {
      final _CountingAdminUsersRepository repository =
          _CountingAdminUsersRepository();

      const ProfileUser regularProfileUser = ProfileUser(
        id: 'regular-profile-user',
        username: 'regular',
        email: 'regular@example.com',
        displayName: 'Regular User',
        isLocal: false,
        isAdmin: false,
      );

      await tester.pumpWidget(
        _buildTestApp(
          profileRepository: _FakeProfileRepository(user: regularProfileUser),
          adminUsersRepository: repository,
        ),
      );

      await tester.pumpAndSettle();

      expect(repository.listCalls, 0);
    });

    testWidgets('shows Retry when users loading fails', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 900);

      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(
        _buildTestApp(
          adminUsersRepository: const _FakeAdminUsersRepository(
            listError: AppException.connection(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-users-failure')),
        findsOneWidget,
      );
    });

    testWidgets('does not show recovery action for administrator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          adminUsersRepository: const _FakeAdminUsersRepository(
            users: <AdminUser>[
              AdminUser(
                id: 'admin-user',
                username: 'admin',
                email: 'admin@example.com',
                displayName: 'Administrator',
                isActive: true,
                isLocal: false,
                isAdmin: true,
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('profile-user-password-recovery-admin-user'),
        ),
        findsNothing,
      );
    });

    testWidgets('disables recovery for inactive user', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 900);

      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(
        _buildTestApp(
          adminUsersRepository: const _FakeAdminUsersRepository(
            users: <AdminUser>[
              AdminUser(
                id: 'inactive-user',
                username: 'inactive',
                email: null,
                displayName: 'Inactive User',
                isActive: false,
                isLocal: false,
                isAdmin: false,
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      final Finder action = find.byKey(
        const ValueKey<String>('profile-user-password-recovery-inactive-user'),
      );

      expect(action, findsOneWidget);

      final OutlinedButton button = tester.widget<OutlinedButton>(action);

      expect(button.onPressed, isNull);
    });

    testWidgets('generates password recovery link for active user on desktop', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 900);

      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(
        _buildTestApp(
          adminUsersRepository: const _FakeAdminUsersRepository(
            users: <AdminUser>[
              AdminUser(
                id: 'regular-user',
                username: 'regular',
                email: 'regular@example.com',
                displayName: 'Regular User',
                isActive: true,
                isLocal: false,
                isAdmin: false,
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-users')),
        findsOneWidget,
      );

      final Finder recoveryAction = find.byKey(
        const ValueKey<String>('profile-user-password-recovery-regular-user'),
      );

      expect(recoveryAction, findsOneWidget);

      await tester.ensureVisible(recoveryAction);
      await tester.pumpAndSettle();

      await tester.tap(recoveryAction);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-password-recovery-dialog')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('profile-password-recovery-success')),
        findsOneWidget,
      );

      expect(find.textContaining('/auth/password-recovery'), findsOneWidget);

      expect(find.textContaining('recovery-token'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('profile-password-recovery-copy')),
        findsOneWidget,
      );
    });
    testWidgets('hides Users and does not load them on mobile', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(390, 844);

      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      final _CountingAdminUsersRepository repository =
          _CountingAdminUsersRepository();

      await tester.pumpWidget(_buildTestApp(adminUsersRepository: repository));

      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('profile-users')), findsNothing);

      expect(repository.listCalls, 0);
    });
    testWidgets('shows Users at desktop breakpoint', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(900, 900);

      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      final _CountingAdminUsersRepository repository =
          _CountingAdminUsersRepository();

      await tester.pumpWidget(_buildTestApp(adminUsersRepository: repository));

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-users')),
        findsOneWidget,
      );

      expect(repository.listCalls, 1);
    });
  });
}

Widget _buildNavigationTestApp({
  ProfileRepository? profileRepository,
  StatisticsRepository? statisticsRepository,
  AdminUsersRepository? adminUsersRepository,
  LibraryRepository? libraryRepository,
  HistoryRepository? historyRepository,
  ServerRepository? serverRepository,
  SecuritySettingsRepository? securitySettingsRepository,
  required List<GoRoute> destinationRoutes,
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

  final GoRouter router = GoRouter(
    initialLocation: '/profile',
    routes: <RouteBase>[
      GoRoute(
        path: '/profile',
        builder: (BuildContext context, GoRouterState state) {
          return const ProfilePage();
        },
      ),
      ...destinationRoutes,
    ],
  );

  final ApiClient apiClient = ApiClient(
    baseUrl: Uri.parse('https://server.example.com'),
  );

  return MultiRepositoryProvider(
    providers: <RepositoryProvider<dynamic>>[
      RepositoryProvider<ServerRepository>(
        create: (BuildContext context) {
          return serverRepository ?? _FakeServerRepository();
        },
      ),
      RepositoryProvider<SecuritySettingsRepository>(
        create: (BuildContext context) {
          return securitySettingsRepository ??
              _FakeSecuritySettingsRepository();
        },
      ),
      RepositoryProvider<AdminUsersRepository>(
        create: (BuildContext context) {
          return adminUsersRepository ?? const _FakeAdminUsersRepository();
        },
      ),
      RepositoryProvider<ApiClient>.value(value: apiClient),
    ],
    child: MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<AuthCubit>(
          create: (BuildContext context) {
            return _createAuthenticatedAuthCubit();
          },
        ),
        BlocProvider<ProfileCubit>.value(value: profileCubit),
        BlocProvider<StatisticsSummaryCubit>.value(
          value: statisticsSummaryCubit,
        ),
        BlocProvider<LibraryPreviewCubit>.value(value: libraryPreviewCubit),
        BlocProvider<HistoryPreviewCubit>.value(value: historyPreviewCubit),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

AuthCubit _createAuthenticatedAuthCubit() {
  final AuthCubit cubit = AuthCubit(repository: _FakeAuthRepository());

  cubit.authenticated(
    const AuthSession(
      accessToken: 'test-access-token',
      expiresIn: Duration(minutes: 15),
    ),
  );

  return cubit;
}

Widget _buildTestApp({
  ProfileRepository? profileRepository,
  StatisticsRepository? statisticsRepository,
  LibraryRepository? libraryRepository,
  HistoryRepository? historyRepository,
  ServerRepository? serverRepository,
  DataTransferRepository? dataTransferRepository,
  AuthRepository? authRepository,
  AdminUsersRepository? adminUsersRepository,
  SecuritySettingsRepository? securitySettingsRepository,
  bool isWeb = false,
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

  final DataTransferCubit dataTransferCubit = DataTransferCubit(
    repository: dataTransferRepository ?? _FakeDataTransferRepository(),
  );

  final AuthCubit authCubit =
      AuthCubit(repository: authRepository ?? _FakeAuthRepository())
        ..authenticated(
          const AuthSession(
            accessToken: 'test-access-token',
            expiresIn: Duration(minutes: 15),
          ),
        );

  final ApiClient apiClient = ApiClient(
    baseUrl: Uri.parse('https://server.example.com'),
  );

  return MultiRepositoryProvider(
    providers: <RepositoryProvider<dynamic>>[
      RepositoryProvider<ServerRepository>(
        create: (BuildContext context) {
          return serverRepository ?? _FakeServerRepository();
        },
      ),
      RepositoryProvider<SecuritySettingsRepository>(
        create: (BuildContext context) {
          return securitySettingsRepository ??
              _FakeSecuritySettingsRepository();
        },
      ),
      RepositoryProvider<AdminUsersRepository>(
        create: (BuildContext context) {
          return adminUsersRepository ?? const _FakeAdminUsersRepository();
        },
      ),
      RepositoryProvider<ApiClient>.value(value: apiClient),
    ],
    child: MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<ProfileCubit>.value(value: profileCubit),
        BlocProvider<StatisticsSummaryCubit>.value(
          value: statisticsSummaryCubit,
        ),
        BlocProvider<LibraryPreviewCubit>.value(value: libraryPreviewCubit),
        BlocProvider<HistoryPreviewCubit>.value(value: historyPreviewCubit),
        BlocProvider<DataTransferCubit>.value(value: dataTransferCubit),
        BlocProvider<AuthCubit>.value(value: authCubit),
      ],
      child: MaterialApp(home: ProfilePage(isWebOverride: isWeb)),
    ),
  );
}

const ProfileUser _user = ProfileUser(
  id: 'user-1',
  username: 'testuser',
  email: 'test@example.com',
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

final ServerLogEntry _serverLogError = ServerLogEntry(
  timestamp: DateTime.utc(2026, 8, 20, 15, 30),
  level: ServerLogLevel.error,
  logger: 'app.jobs.executor',
  message: 'Metadata sync failed.',
  component: ServerLogComponent.worker,
);

final ServerLogEntry _serverLogInfo = ServerLogEntry(
  timestamp: DateTime.utc(2026, 8, 20, 15),
  level: ServerLogLevel.info,
  logger: 'app.main',
  message: 'SofaWatch API starting',
  component: ServerLogComponent.api,
);

final ServerLogsPage _serverLogsPage = ServerLogsPage(
  items: <ServerLogEntry>[_serverLogError, _serverLogInfo],
  offset: 0,
  limit: 50,
  total: 2,
  hasNext: false,
);

final HistoryPreview _historyPreview = HistoryPreview(
  episodes: <HistoryEpisodeItem>[_historyEpisodeItem],
  movies: <HistoryMovieItem>[_historyMovieItem],
);

final class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository({
    this.user = _user,
    this.error,
    this.updateDisplayNameError,
    this.updatePasswordError,
  });

  final ProfileUser user;
  final AppException? error;
  final AppException? updateDisplayNameError;
  final AppException? updatePasswordError;

  int updateDisplayNameCalls = 0;
  String? lastDisplayName;

  int updatePasswordCalls = 0;
  String? lastCurrentPassword;
  String? lastNewPassword;

  @override
  Future<ProfileUser> getCurrentUser() async {
    final AppException? failure = error;

    if (failure != null) {
      throw failure;
    }

    return user;
  }

  @override
  Future<ProfileUser> updateDisplayName({required String displayName}) async {
    updateDisplayNameCalls += 1;
    lastDisplayName = displayName;

    final AppException? failure = updateDisplayNameError;

    if (failure != null) {
      throw failure;
    }

    return user.copyWith(displayName: displayName);
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    updatePasswordCalls += 1;
    lastCurrentPassword = currentPassword;
    lastNewPassword = newPassword;

    final AppException? failure = updatePasswordError;

    if (failure != null) {
      throw failure;
    }
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
    ServerLogsPage? logsPage,
    this.logsError,
  }) : logsPage = logsPage ?? _serverLogsPage;

  final ServerHealth? health;
  final AppException? healthError;

  final List<BackgroundJob> backgroundJobs;
  final AppException? backgroundJobsError;
  final BackgroundJob? runBackgroundJobResult;
  final AppException? runBackgroundJobError;
  final ServerLogsPage logsPage;
  final AppException? logsError;

  int logsCalls = 0;

  final List<ServerLogLevel?> logLevelRequests = <ServerLogLevel?>[];

  final List<int> logOffsetRequests = <int>[];

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

  @override
  Future<ServerLogsPage> getLogs({
    ServerLogLevel? level,
    int offset = 0,
    int limit = 50,
  }) async {
    logsCalls += 1;

    logLevelRequests.add(level);

    logOffsetRequests.add(offset);

    final AppException? failure = logsError;

    if (failure != null) {
      throw failure;
    }

    return logsPage;
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

  @override
  Future<ServerLogsPage> getLogs({
    ServerLogLevel? level,
    int offset = 0,
    int limit = 50,
  }) {
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

  @override
  Future<ServerLogsPage> getLogs({
    ServerLogLevel? level,
    int offset = 0,
    int limit = 50,
  }) {
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

  @override
  Future<ServerLogsPage> getLogs({
    ServerLogLevel? level,
    int offset = 0,
    int limit = 50,
  }) {
    throw UnimplementedError();
  }
}

final class _PaginatedLogsServerRepository implements ServerRepository {
  int healthCalls = 0;
  int backgroundJobsCalls = 0;
  int logsCalls = 0;

  final List<int> offsetRequests = <int>[];

  @override
  Future<ServerHealth> getHealth() async {
    healthCalls += 1;

    return _serverHealth;
  }

  @override
  Future<List<BackgroundJob>> getBackgroundJobs() async {
    backgroundJobsCalls += 1;

    return const <BackgroundJob>[];
  }

  @override
  Future<BackgroundJob> runBackgroundJob(String jobKey) {
    throw UnimplementedError();
  }

  @override
  Future<ServerLogsPage> getLogs({
    ServerLogLevel? level,
    int offset = 0,
    int limit = 50,
  }) async {
    logsCalls += 1;
    offsetRequests.add(offset);

    if (offset == 0) {
      return _paginatedServerLogsFirstPage;
    }

    return _paginatedServerLogsSecondPage;
  }
}

final class _PaginationFailureLogsServerRepository implements ServerRepository {
  int logsCalls = 0;

  @override
  Future<ServerHealth> getHealth() async {
    return _serverHealth;
  }

  @override
  Future<List<BackgroundJob>> getBackgroundJobs() async {
    return const <BackgroundJob>[];
  }

  @override
  Future<BackgroundJob> runBackgroundJob(String jobKey) {
    throw UnimplementedError();
  }

  @override
  Future<ServerLogsPage> getLogs({
    ServerLogLevel? level,
    int offset = 0,
    int limit = 50,
  }) async {
    logsCalls += 1;

    if (offset == 0) {
      return _paginatedServerLogsFirstPage;
    }

    throw const AppException.connection();
  }
}

final class _RetryPaginationLogsServerRepository implements ServerRepository {
  int logsCalls = 0;

  final List<int> offsetRequests = <int>[];

  @override
  Future<ServerHealth> getHealth() async {
    return _serverHealth;
  }

  @override
  Future<List<BackgroundJob>> getBackgroundJobs() async {
    return const <BackgroundJob>[];
  }

  @override
  Future<BackgroundJob> runBackgroundJob(String jobKey) {
    throw UnimplementedError();
  }

  @override
  Future<ServerLogsPage> getLogs({
    ServerLogLevel? level,
    int offset = 0,
    int limit = 50,
  }) async {
    logsCalls += 1;
    offsetRequests.add(offset);

    if (offset == 0) {
      return _paginatedServerLogsFirstPage;
    }

    if (logsCalls == 2) {
      throw const AppException.connection();
    }

    return _paginatedServerLogsSecondPage;
  }
}

const ProfileUser _regularUser = ProfileUser(
  id: 'user-2',
  displayName: 'Regular User',
  username: 'souocare',
  email: 'test@test.pt',
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

final ServerLogEntry _serverLogWarning = ServerLogEntry(
  timestamp: DateTime.utc(2026, 8, 20, 14, 30),
  level: ServerLogLevel.warning,
  logger: 'app.providers.tmdb.client',
  message: 'TMDB request retry.',
  component: ServerLogComponent.api,
);

final ServerLogsPage _paginatedServerLogsFirstPage = ServerLogsPage(
  items: <ServerLogEntry>[_serverLogError, _serverLogInfo],
  offset: 0,
  limit: 50,
  total: 3,
  hasNext: true,
);

final ServerLogsPage _paginatedServerLogsSecondPage = ServerLogsPage(
  items: <ServerLogEntry>[_serverLogWarning],
  offset: 2,
  limit: 50,
  total: 3,
  hasNext: false,
);

class _FakeDataTransferRepository implements DataTransferRepository {
  _FakeDataTransferRepository({
    this.exportJson = '{"format":"sofawatch-export","version":1}',
    this.preview = const DataImportPreview(
      format: 'sofawatch-export',
      version: 1,
      userDisplayName: 'Test User',
      libraryShows: 0,
      libraryMovies: 0,
      episodeWatchEvents: 0,
      movieWatchEvents: 0,
    ),
    this.importResult = const DataImportResult(
      library: DataImportLibraryResult(
        shows: DataImportMediaResult(
          created: 0,
          updated: 0,
          unchanged: 0,
          failed: 0,
        ),
        movies: DataImportMediaResult(
          created: 0,
          updated: 0,
          unchanged: 0,
          failed: 0,
        ),
      ),
      history: DataImportHistoryResult(
        episodes: DataImportHistoryMediaResult(
          created: 0,
          skipped: 0,
          failed: 0,
        ),
        movies: DataImportHistoryMediaResult(created: 0, skipped: 0, failed: 0),
      ),
    ),
    this.exportError,
    this.previewError,
    this.importError,
  });

  final String exportJson;
  final DataImportPreview preview;
  final DataImportResult importResult;

  final AppException? exportError;
  final AppException? previewError;
  final AppException? importError;

  @override
  Future<String> exportData() async {
    final AppException? error = exportError;

    if (error != null) {
      throw error;
    }

    return exportJson;
  }

  @override
  Future<DataImportPreview> previewImport(String json) async {
    final AppException? error = previewError;

    if (error != null) {
      throw error;
    }

    return preview;
  }

  @override
  Future<DataImportResult> importData(String json) async {
    final AppException? error = importError;

    if (error != null) {
      throw error;
    }

    return importResult;
  }
}

class _ControlledDataTransferRepository implements DataTransferRepository {
  final Completer<String> _exportCompleter = Completer<String>();

  int exportCalls = 0;

  void completeExport(String json) {
    if (_exportCompleter.isCompleted) {
      return;
    }

    _exportCompleter.complete(json);
  }

  void failExport(AppException error) {
    if (_exportCompleter.isCompleted) {
      return;
    }

    _exportCompleter.completeError(error);
  }

  @override
  Future<String> exportData() {
    exportCalls += 1;

    return _exportCompleter.future;
  }

  @override
  Future<DataImportPreview> previewImport(String json) {
    throw UnimplementedError();
  }

  @override
  Future<DataImportResult> importData(String json) {
    throw UnimplementedError();
  }
}

final class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository();

  int logoutCalls = 0;
  int logoutEverywhereCalls = 0;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSession?> restore() async {
    return const AuthSession(
      accessToken: 'test-access-token',
      expiresIn: Duration(minutes: 15),
    );
  }

  @override
  Future<void> logout() async {
    logoutCalls += 1;
  }

  @override
  Future<void> logoutEverywhere() async {
    logoutEverywhereCalls += 1;
  }
}

final class _FakeSecuritySettingsRepository
    implements SecuritySettingsRepository {
  _FakeSecuritySettingsRepository({
    this.settings = const SecuritySettings(openRegistration: false),
    this.loadError,
    this.updateError,
  });

  SecuritySettings settings;

  final AppException? loadError;
  final AppException? updateError;

  int getSettingsCalls = 0;
  int updateCalls = 0;

  bool? lastEnabled;

  @override
  Future<SecuritySettings> getSettings() async {
    getSettingsCalls += 1;

    final AppException? error = loadError;

    if (error != null) {
      throw error;
    }

    return settings;
  }

  @override
  Future<SecuritySettings> updateOpenRegistration({
    required bool enabled,
  }) async {
    updateCalls += 1;
    lastEnabled = enabled;

    final AppException? error = updateError;

    if (error != null) {
      throw error;
    }

    settings = SecuritySettings(openRegistration: enabled);

    return settings;
  }
}

final class _RetrySecuritySettingsRepository
    implements SecuritySettingsRepository {
  int getSettingsCalls = 0;

  @override
  Future<SecuritySettings> getSettings() async {
    getSettingsCalls += 1;

    if (getSettingsCalls == 1) {
      throw const AppException.connection();
    }

    return const SecuritySettings(openRegistration: false);
  }

  @override
  Future<SecuritySettings> updateOpenRegistration({required bool enabled}) {
    throw UnimplementedError(
      'Updating Security settings is not used by this retry test.',
    );
  }
}

final class _PasswordProfileRepository implements ProfileRepository {
  _PasswordProfileRepository({this.error, this.user = _user});

  final AppException? error;
  final ProfileUser user;

  int updatePasswordCalls = 0;
  String? lastCurrentPassword;
  String? lastNewPassword;

  @override
  Future<ProfileUser> getCurrentUser() async {
    return user;
  }

  @override
  Future<ProfileUser> updateDisplayName({required String displayName}) async {
    return user.copyWith(displayName: displayName);
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    updatePasswordCalls += 1;
    lastCurrentPassword = currentPassword;
    lastNewPassword = newPassword;

    final AppException? failure = error;

    if (failure != null) {
      throw failure;
    }
  }
}

final class _ControlledPasswordProfileRepository implements ProfileRepository {
  final Completer<void> _passwordCompleter = Completer<void>();

  int updatePasswordCalls = 0;

  @override
  Future<ProfileUser> getCurrentUser() async {
    return _user;
  }

  @override
  Future<ProfileUser> updateDisplayName({required String displayName}) async {
    return _user.copyWith(displayName: displayName);
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    updatePasswordCalls += 1;

    return _passwordCompleter.future;
  }

  void complete() {
    if (_passwordCompleter.isCompleted) {
      return;
    }

    _passwordCompleter.complete();
  }
}

final class _FakeAdminUsersRepository implements AdminUsersRepository {
  const _FakeAdminUsersRepository({
    this.users = const <AdminUser>[],
    this.listError,
    this.recoveryError,
  });

  final List<AdminUser> users;
  final AppException? listError;
  final AppException? recoveryError;

  @override
  Future<List<AdminUser>> listUsers() async {
    final AppException? failure = listError;

    if (failure != null) {
      throw failure;
    }

    return users;
  }

  @override
  Future<PasswordRecoveryLink> startPasswordRecovery({
    required String userId,
  }) async {
    final AppException? failure = recoveryError;

    if (failure != null) {
      throw failure;
    }

    return PasswordRecoveryLink(
      token: 'recovery-token',
      expiresAt: DateTime.utc(2026, 8, 26, 10),
    );
  }
}

final class _CountingAdminUsersRepository implements AdminUsersRepository {
  int listCalls = 0;

  @override
  Future<List<AdminUser>> listUsers() async {
    listCalls += 1;

    return const <AdminUser>[];
  }

  @override
  Future<PasswordRecoveryLink> startPasswordRecovery({required String userId}) {
    throw UnimplementedError();
  }
}
