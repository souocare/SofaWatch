import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/application/cubit/library_collection_cubit.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/library/presentation/pages/library_collection_page.dart';
import 'package:sofawatch/features/movies/domain/models/library_movie.dart';
import 'package:sofawatch/features/movies/domain/repositories/movies_repository.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';
import 'package:sofawatch/features/shows/domain/models/library_show_progress.dart';
import 'package:sofawatch/features/shows/domain/models/stale_watching_show.dart';
import 'package:sofawatch/features/shows/domain/models/upcoming_item.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_page.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_show.dart';
import 'package:sofawatch/features/shows/domain/repositories/shows_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';

void main() {
  group('LibraryCollectionPage', () {
    testWidgets('shows the Shows and Movies tabs', (WidgetTester tester) async {
      await _setLargeTestViewport(tester);

      await tester.pumpWidget(
        _buildTestApp(
          shows: <LibraryShow>[_watchingShow],
          movies: <LibraryMovie>[_watchlistMovie],
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('library-collection-page')),
        findsOneWidget,
      );

      expect(find.text('Library'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('library-collection-shows-tab')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('library-collection-movies-tab')),
        findsOneWidget,
      );
    });

    testWidgets('shows all Show categories in the required order', (
      WidgetTester tester,
    ) async {
      await _setLargeTestViewport(tester);

      await tester.pumpWidget(
        _buildTestApp(
          shows: <LibraryShow>[
            _droppedShow,
            _completedShow,
            _pausedShow,
            _planningShow,
            _upToDateShow,
            _watchingShow,
          ],
        ),
      );

      await tester.pumpAndSettle();

      final Finder watching = find.byKey(
        const ValueKey<String>('library-collection-shows-watching-title'),
      );

      final Finder upToDate = find.byKey(
        const ValueKey<String>('library-collection-shows-up-to-date-title'),
      );

      final Finder haventStarted = find.byKey(
        const ValueKey<String>('library-collection-shows-havent-started-title'),
      );

      final Finder finished = find.byKey(
        const ValueKey<String>('library-collection-shows-finished-title'),
      );

      final Finder paused = find.byKey(
        const ValueKey<String>('library-collection-shows-paused-title'),
      );

      final Finder dropped = find.byKey(
        const ValueKey<String>('library-collection-shows-dropped-title'),
      );

      expect(watching, findsOneWidget);
      expect(upToDate, findsOneWidget);
      expect(haventStarted, findsOneWidget);
      expect(finished, findsOneWidget);
      expect(paused, findsOneWidget);
      expect(dropped, findsOneWidget);

      final List<double> positions = <double>[
        tester.getTopLeft(watching).dy,
        tester.getTopLeft(upToDate).dy,
        tester.getTopLeft(haventStarted).dy,
        tester.getTopLeft(finished).dy,
        tester.getTopLeft(paused).dy,
        tester.getTopLeft(dropped).dy,
      ];

      expect(
        positions,
        orderedEquals(positions.toList(growable: false)..sort()),
      );
    });

    testWidgets('separates Watching from Up to Date by caught-up progress', (
      WidgetTester tester,
    ) async {
      await _setLargeTestViewport(tester);

      await tester.pumpWidget(
        _buildTestApp(shows: <LibraryShow>[_watchingShow, _upToDateShow]),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('library-collection-show-show-watching'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('library-collection-show-show-up-to-date'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('library-collection-shows-watching')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('library-collection-shows-up-to-date'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows progress as a bar without percentage text', (
      WidgetTester tester,
    ) async {
      await _setLargeTestViewport(tester);

      await tester.pumpWidget(
        _buildTestApp(shows: <LibraryShow>[_watchingShow]),
      );

      await tester.pumpAndSettle();

      final Finder progressFinder = find.byKey(
        const ValueKey<String>(
          'library-collection-show-progress-show-watching',
        ),
      );

      expect(progressFinder, findsOneWidget);

      final LinearProgressIndicator progress = tester
          .widget<LinearProgressIndicator>(progressFinder);

      expect(progress.value, 0.4);

      expect(find.text('40%'), findsNothing);
      expect(find.text('4 / 10'), findsNothing);
      expect(find.text('4/10'), findsNothing);
    });

    testWidgets('uses three poster columns on mobile', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 1800);

      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          shows: <LibraryShow>[
            _watchingShow,
            _watchingShow2,
            _watchingShow3,
            _watchingShow4,
          ],
        ),
      );

      await tester.pumpAndSettle();

      final GridView grid = tester.widget<GridView>(
        find.byKey(
          const ValueKey<String>('library-collection-shows-watching-grid'),
        ),
      );

      final SliverGridDelegateWithFixedCrossAxisCount delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      expect(delegate.crossAxisCount, 3);
    });

    testWidgets('shows Movies grouped as Watchlist Upcoming and Watched', (
      WidgetTester tester,
    ) async {
      await _setLargeTestViewport(tester);

      await tester.pumpWidget(
        _buildTestApp(
          movies: <LibraryMovie>[
            _watchedMovie,
            _upcomingMovie,
            _watchlistMovie,
          ],
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('library-collection-movies-tab')),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('library-collection-movies-watchlist'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('library-collection-movies-upcoming'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('library-collection-movies-watched')),
        findsOneWidget,
      );

      final List<double> positions = <double>[
        tester
            .getTopLeft(
              find.byKey(
                const ValueKey<String>(
                  'library-collection-movies-watchlist-title',
                ),
              ),
            )
            .dy,
        tester
            .getTopLeft(
              find.byKey(
                const ValueKey<String>(
                  'library-collection-movies-upcoming-title',
                ),
              ),
            )
            .dy,
        tester
            .getTopLeft(
              find.byKey(
                const ValueKey<String>(
                  'library-collection-movies-watched-title',
                ),
              ),
            )
            .dy,
      ];

      expect(
        positions,
        orderedEquals(positions.toList(growable: false)..sort()),
      );
    });

    testWidgets('keeps Movies usable when Shows fail', (
      WidgetTester tester,
    ) async {
      await _setLargeTestViewport(tester);

      await tester.pumpWidget(
        _buildTestApp(
          showsError: const AppException.connection(),
          movies: <LibraryMovie>[_watchlistMovie],
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('library-collection-shows-failure')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('library-collection-movies-tab')),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('library-collection-movies-watchlist'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('library-collection-movie-movie-watchlist'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('keeps Shows usable when Movies fail', (
      WidgetTester tester,
    ) async {
      await _setLargeTestViewport(tester);

      await tester.pumpWidget(
        _buildTestApp(
          shows: <LibraryShow>[_watchingShow],
          moviesError: const AppException.connection(),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('library-collection-shows-watching')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('library-collection-movies-tab')),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('library-collection-movies-failure')),
        findsOneWidget,
      );
    });

    testWidgets('shows independent empty states', (WidgetTester tester) async {
      await _setLargeTestViewport(tester);

      await tester.pumpWidget(_buildTestApp());

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('library-collection-shows-empty')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('library-collection-movies-tab')),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('library-collection-movies-empty')),
        findsOneWidget,
      );
    });

    testWidgets('loads Shows and Movies independently', (
      WidgetTester tester,
    ) async {
      await _setLargeTestViewport(tester);

      final _ControlledShowsRepository showsRepository =
          _ControlledShowsRepository();

      final LibraryCollectionCubit cubit = LibraryCollectionCubit(
        showsRepository: showsRepository,
        moviesRepository: _MoviesRepository(
          movies: <LibraryMovie>[_watchlistMovie],
        ),
      );

      addTearDown(cubit.close);

      unawaited(cubit.load());

      await tester.pumpWidget(_buildTestAppWithCubit(cubit));

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('library-collection-shows-loading')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('library-collection-movies-tab')),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('library-collection-movies-watchlist'),
        ),
        findsOneWidget,
      );

      showsRepository.complete(<LibraryShow>[_watchingShow]);

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('library-collection-shows-tab')),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('library-collection-shows-watching')),
        findsOneWidget,
      );
    });
    testWidgets('opens Movies tab when requested', (WidgetTester tester) async {
      await _setLargeTestViewport(tester);

      await tester.pumpWidget(
        _buildTestApp(
          movies: <LibraryMovie>[_watchlistMovie],
          initialTab: LibraryCollectionTab.movies,
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('library-collection-movies-watchlist'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('library-collection-shows-empty')),
        findsNothing,
      );
    });
    testWidgets('opens Show Details from a Show poster', (
      WidgetTester tester,
    ) async {
      await _setLargeTestViewport(tester);

      await tester.pumpWidget(
        _buildRoutedTestApp(shows: <LibraryShow>[_watchingShow]),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey<String>('library-collection-show-show-watching'),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('test-show-details')),
        findsOneWidget,
      );

      expect(find.text('Show 1'), findsOneWidget);
    });
    testWidgets('opens Movie Details from a Movie poster', (
      WidgetTester tester,
    ) async {
      await _setLargeTestViewport(tester);

      await tester.pumpWidget(
        _buildRoutedTestApp(
          movies: <LibraryMovie>[_watchlistMovie],
          initialTab: LibraryCollectionTab.movies,
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey<String>('library-collection-movie-movie-watchlist'),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('test-movie-details')),
        findsOneWidget,
      );

      expect(find.text('Movie 100'), findsOneWidget);
    });
  });
}

Future<void> _setLargeTestViewport(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(900, 5000);

  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Widget _buildTestApp({
  List<LibraryShow> shows = const <LibraryShow>[],
  List<LibraryMovie> movies = const <LibraryMovie>[],
  AppException? showsError,
  AppException? moviesError,
  LibraryCollectionTab initialTab = LibraryCollectionTab.shows,
}) {
  return MaterialApp(
    home: BlocProvider<LibraryCollectionCubit>(
      create: (BuildContext context) {
        return LibraryCollectionCubit(
          showsRepository: _ShowsRepository(shows: shows, error: showsError),
          moviesRepository: _MoviesRepository(
            movies: movies,
            error: moviesError,
          ),
        )..load();
      },
      child: LibraryCollectionPage(initialTab: initialTab),
    ),
  );
}

Widget _buildTestAppWithCubit(LibraryCollectionCubit cubit) {
  return MaterialApp(
    home: BlocProvider<LibraryCollectionCubit>.value(
      value: cubit,
      child: const LibraryCollectionPage(),
    ),
  );
}

final DateTime _createdAt = DateTime.utc(2026, 8, 1);

final DateTime _updatedAt = DateTime.utc(2026, 8, 19);

const LibraryShowProgress _watchingProgress = LibraryShowProgress(
  watchedEpisodes: 4,
  airedEpisodes: 10,
  percentage: 40,
  caughtUp: false,
);

const LibraryShowProgress _caughtUpProgress = LibraryShowProgress(
  watchedEpisodes: 10,
  airedEpisodes: 10,
  percentage: 100,
  caughtUp: true,
);

const LibraryShowProgress _notStartedProgress = LibraryShowProgress(
  watchedEpisodes: 0,
  airedEpisodes: 10,
  percentage: 0,
  caughtUp: false,
);

final LibraryShow _watchingShow = _show(
  id: 'show-watching',
  tmdbId: 1,
  title: 'Watching Show',
  status: LibraryStatus.watching,
  progress: _watchingProgress,
);

final LibraryShow _watchingShow2 = _show(
  id: 'show-watching-2',
  tmdbId: 2,
  title: 'Watching Show 2',
  status: LibraryStatus.watching,
  progress: _watchingProgress,
);

final LibraryShow _watchingShow3 = _show(
  id: 'show-watching-3',
  tmdbId: 3,
  title: 'Watching Show 3',
  status: LibraryStatus.watching,
  progress: _watchingProgress,
);

final LibraryShow _watchingShow4 = _show(
  id: 'show-watching-4',
  tmdbId: 4,
  title: 'Watching Show 4',
  status: LibraryStatus.watching,
  progress: _watchingProgress,
);

final LibraryShow _upToDateShow = _show(
  id: 'show-up-to-date',
  tmdbId: 5,
  title: 'Up to Date Show',
  status: LibraryStatus.watching,
  progress: _caughtUpProgress,
);

final LibraryShow _planningShow = _show(
  id: 'show-planning',
  tmdbId: 6,
  title: 'Planning Show',
  status: LibraryStatus.planning,
  progress: _notStartedProgress,
);

final LibraryShow _completedShow = _show(
  id: 'show-completed',
  tmdbId: 7,
  title: 'Finished Show',
  status: LibraryStatus.completed,
  progress: _caughtUpProgress,
);

final LibraryShow _pausedShow = _show(
  id: 'show-paused',
  tmdbId: 8,
  title: 'Paused Show',
  status: LibraryStatus.paused,
  progress: _watchingProgress,
);

final LibraryShow _droppedShow = _show(
  id: 'show-dropped',
  tmdbId: 9,
  title: 'Dropped Show',
  status: LibraryStatus.dropped,
  progress: _watchingProgress,
);

LibraryShow _show({
  required String id,
  required int tmdbId,
  required String title,
  required LibraryStatus status,
  required LibraryShowProgress progress,
}) {
  return LibraryShow(
    libraryEntryId: 'entry-$id',
    showId: id,
    tmdbId: tmdbId,
    title: title,
    originalTitle: title,
    status: status,
    showStatus: 'Returning Series',
    voteAverage: 8,
    createdAt: _createdAt,
    updatedAt: _updatedAt,
    progress: progress,
  );
}

final LibraryMovie _watchlistMovie = _movie(
  id: 'movie-watchlist',
  tmdbId: 100,
  title: 'Watchlist Movie',
  status: LibraryStatus.planning,
  releaseDate: DateTime.utc(2026, 1, 1),
);

final LibraryMovie _upcomingMovie = _movie(
  id: 'movie-upcoming',
  tmdbId: 101,
  title: 'Upcoming Movie',
  status: LibraryStatus.planning,
  releaseDate: DateTime.utc(2099, 1, 1),
);

final LibraryMovie _watchedMovie = _movie(
  id: 'movie-watched',
  tmdbId: 102,
  title: 'Watched Movie',
  status: LibraryStatus.completed,
  releaseDate: DateTime.utc(2026, 1, 1),
);

LibraryMovie _movie({
  required String id,
  required int tmdbId,
  required String title,
  required LibraryStatus status,
  required DateTime releaseDate,
}) {
  return LibraryMovie(
    libraryEntryId: 'entry-$id',
    movieId: id,
    tmdbId: tmdbId,
    title: title,
    originalTitle: title,
    status: status,
    createdAt: _createdAt,
    updatedAt: _updatedAt,
    movieStatus: 'Released',
    voteAverage: 8,
    releaseDate: releaseDate,
  );
}

class _ShowsRepository implements ShowsRepository {
  _ShowsRepository({this.shows = const <LibraryShow>[], this.error});

  final List<LibraryShow> shows;
  final AppException? error;

  @override
  Future<List<LibraryShow>> getLibraryShows() async {
    final AppException? failure = error;

    if (failure != null) {
      throw failure;
    }

    return shows;
  }

  @override
  Future<List<WatchNextShow>> getWatchNext({int? limit}) {
    throw UnimplementedError();
  }

  @override
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<UpcomingItem>> getMissedRecently() {
    throw UnimplementedError();
  }

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() {
    throw UnimplementedError();
  }

  @override
  Future<WatchHistoryPage> getWatchHistory({int limit = 30, String? cursor}) {
    throw UnimplementedError();
  }

  @override
  Future<void> markEpisodeWatched({required String episodeId}) {
    throw UnimplementedError();
  }

  @override
  Future<void> startShow({required String showId}) {
    throw UnimplementedError();
  }

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) {
    throw UnimplementedError();
  }
}

class _MoviesRepository implements MoviesRepository {
  _MoviesRepository({this.movies = const <LibraryMovie>[], this.error});

  final List<LibraryMovie> movies;
  final AppException? error;

  @override
  Future<List<LibraryMovie>> getLibraryMovies() async {
    final AppException? failure = error;

    if (failure != null) {
      throw failure;
    }

    return movies;
  }
}

final class _ControlledShowsRepository extends _ShowsRepository {
  _ControlledShowsRepository();

  final Completer<List<LibraryShow>> _result = Completer<List<LibraryShow>>();

  void complete(List<LibraryShow> shows) {
    if (_result.isCompleted) {
      return;
    }

    _result.complete(shows);
  }

  @override
  Future<List<LibraryShow>> getLibraryShows() {
    return _result.future;
  }
}

Widget _buildRoutedTestApp({
  List<LibraryShow> shows = const <LibraryShow>[],
  List<LibraryMovie> movies = const <LibraryMovie>[],
  LibraryCollectionTab initialTab = LibraryCollectionTab.shows,
}) {
  final LibraryCollectionCubit cubit = LibraryCollectionCubit(
    showsRepository: _ShowsRepository(shows: shows),
    moviesRepository: _MoviesRepository(movies: movies),
  )..load();

  final GoRouter router = GoRouter(
    initialLocation: '/library-test',
    routes: <RouteBase>[
      GoRoute(
        path: '/library-test',
        builder: (BuildContext context, GoRouterState state) {
          return BlocProvider<LibraryCollectionCubit>.value(
            value: cubit,
            child: LibraryCollectionPage(initialTab: initialTab),
          );
        },
      ),
      GoRoute(
        name: AppRoute.showDetails.name,
        path: '/shows/:showId',
        builder: (BuildContext context, GoRouterState state) {
          return Scaffold(
            key: const ValueKey<String>('test-show-details'),
            body: Text('Show ${state.pathParameters['showId']}'),
          );
        },
      ),
      GoRoute(
        name: AppRoute.movieDetails.name,
        path: '/movies/:movieId',
        builder: (BuildContext context, GoRouterState state) {
          return Scaffold(
            key: const ValueKey<String>('test-movie-details'),
            body: Text('Movie ${state.pathParameters['movieId']}'),
          );
        },
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router);
}
