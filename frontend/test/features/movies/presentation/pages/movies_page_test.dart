import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/core/viewing/viewing_state_change_notifier.dart';
import 'package:sofawatch/features/history/domain/models/history_media_type.dart';
import 'package:sofawatch/features/history/domain/models/history_movie_item.dart';
import 'package:sofawatch/features/history/domain/models/history_page.dart';
import 'package:sofawatch/features/history/domain/models/history_preview.dart';
import 'package:sofawatch/features/history/domain/repositories/history_repository.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/movies/application/cubit/movie_history_cubit.dart';
import 'package:sofawatch/features/movies/application/cubit/movies_cubit.dart';
import 'package:sofawatch/features/movies/application/models/movies_filter.dart';
import 'package:sofawatch/features/movies/application/models/movies_sort.dart';
import 'package:sofawatch/features/movies/domain/models/library_movie.dart';
import 'package:sofawatch/features/movies/domain/repositories/movie_viewing_repository.dart';
import 'package:sofawatch/features/movies/domain/repositories/movies_repository.dart';
import 'package:sofawatch/features/movies/presentation/pages/movies_page.dart';

void main() {
  group('MoviesPage', () {
    late _MoviesPageTestDependencies dependencies;

    setUp(() {
      dependencies = _MoviesPageTestDependencies();
    });

    tearDown(() async {
      await dependencies.dispose();
    });
    testWidgets('shows loading state', (WidgetTester tester) async {
      final _ControlledMoviesRepository repository =
          _ControlledMoviesRepository();

      final MoviesCubit cubit = MoviesCubit(repository: repository);

      final Future<void> load = cubit.load();

      await repository.requested.future;

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          movieHistoryCubit: dependencies.movieHistoryCubit,
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('movies-loading')),
        findsOneWidget,
      );

      repository.complete(const <LibraryMovie>[]);

      await load;
      await tester.pumpAndSettle();

      await cubit.close();
    });

    testWidgets('shows empty state for an empty Movie Library', (
      WidgetTester tester,
    ) async {
      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(),
      );

      await cubit.load();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          movieHistoryCubit: dependencies.movieHistoryCubit,
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('movies-page-title')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('movies-empty')),
        findsOneWidget,
      );

      expect(find.text('Your movie library is empty'), findsOneWidget);

      expect(
        find.text('Add movies from Search or Explore to build your Watchlist.'),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets('renders Watchlist and watched History events', (
      WidgetTester tester,
    ) async {
      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(
          movies: <LibraryMovie>[_watchlistMovie, _watchedMovie],
        ),
      );

      await cubit.load();

      /*
   * This test needs History data, so use dedicated dependencies rather than
   * replacing the group-level test dependencies midway through the test.
   */
      final _MoviesPageTestDependencies historyDependencies =
          _MoviesPageTestDependencies(
            historyItems: <HistoryMovieItem>[_watchedHistoryItem],
          );

      addTearDown(() async {
        await historyDependencies.dispose();
      });

      await historyDependencies.movieHistoryCubit.load();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          movieHistoryCubit: historyDependencies.movieHistoryCubit,
        ),
      );

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('movies-watchlist')),
        findsOneWidget,
      );

      expect(find.text('Watchlist'), findsOneWidget);

      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('movies-card-movie-1')),
          matching: find.text('Dune'),
        ),
        findsOneWidget,
      );

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));

      await tester.pump();

      expect(find.text('Watched'), findsWidgets);
      expect(find.text('Arrival'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('does not render empty sections', (WidgetTester tester) async {
      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(
          movies: <LibraryMovie>[_watchlistMovie],
        ),
      );

      await cubit.load();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          movieHistoryCubit: dependencies.movieHistoryCubit,
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('movies-watchlist')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('movies-watched')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('movies-coming-soon')),
        findsNothing,
      );

      await cubit.close();
    });

    testWidgets('renders Coming Soon for future Watchlist Movies', (
      WidgetTester tester,
    ) async {
      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(
          movies: <LibraryMovie>[_comingSoonMovie],
        ),
      );

      await cubit.load();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          movieHistoryCubit: dependencies.movieHistoryCubit,
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('movies-watchlist')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('movies-coming-soon')),
        findsOneWidget,
      );

      expect(find.text('Coming Soon'), findsOneWidget);

      /*
      * Future Watchlist Movies belong exclusively to Coming Soon
      * and must not be duplicated in the regular Watchlist section.
      */
      expect(find.text('Future Movie'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('shows safe initial loading failure', (
      WidgetTester tester,
    ) async {
      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(
          error: const AppException.connection(),
        ),
      );

      await cubit.load();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          movieHistoryCubit: dependencies.movieHistoryCubit,
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('movies-failure')),
        findsOneWidget,
      );

      expect(find.text('Could not load your movies.'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('movies-retry')),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets('shows timeout-specific initial failure', (
      WidgetTester tester,
    ) async {
      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(
          error: const AppException.connectionTimeout(),
        ),
      );

      await cubit.load();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          movieHistoryCubit: dependencies.movieHistoryCubit,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Loading your movies took too long.'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('Retry reloads Movies after initial failure', (
      WidgetTester tester,
    ) async {
      final _RetryMoviesRepository repository = _RetryMoviesRepository();

      final MoviesCubit cubit = MoviesCubit(repository: repository);

      await cubit.load();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          movieHistoryCubit: dependencies.movieHistoryCubit,
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('movies-failure')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey<String>('movies-retry')));

      await tester.pumpAndSettle();

      expect(repository.calls, 2);

      expect(
        find.byKey(const ValueKey<String>('movies-watchlist')),
        findsOneWidget,
      );

      expect(find.text('Dune'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('refresh button reloads Movies', (WidgetTester tester) async {
      final _SequencedMoviesRepository repository = _SequencedMoviesRepository(
        responses: <List<LibraryMovie>>[
          <LibraryMovie>[_watchlistMovie],
          <LibraryMovie>[_secondWatchlistMovie],
        ],
      );

      final MoviesCubit cubit = MoviesCubit(repository: repository);

      await cubit.load();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          movieHistoryCubit: dependencies.movieHistoryCubit,
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('movies-card-movie-1')),
          matching: find.text('Dune'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('movies-card-movie-4')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey<String>('movies-refresh')));

      await tester.pumpAndSettle();

      expect(repository.calls, 2);

      expect(find.text('Dune'), findsNothing);
      expect(find.text('Blade Runner 2049'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('preserves Movies and shows snackbar when refresh fails', (
      WidgetTester tester,
    ) async {
      final _RefreshFailureMoviesRepository repository =
          _RefreshFailureMoviesRepository();

      final MoviesCubit cubit = MoviesCubit(repository: repository);

      await cubit.load();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          movieHistoryCubit: dependencies.movieHistoryCubit,
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('movies-refresh')));

      await tester.pumpAndSettle();

      expect(find.text('Dune'), findsOneWidget);

      expect(find.text('Could not refresh your movies.'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('movies-failure')),
        findsNothing,
      );

      await cubit.close();
    });

    testWidgets('opens Movie Details from a Movie card', (
      WidgetTester tester,
    ) async {
      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(
          movies: <LibraryMovie>[_watchlistMovie],
        ),
      );

      await cubit.load();

      final GoRouter router = GoRouter(
        initialLocation: '/movies',
        routes: <RouteBase>[
          GoRoute(
            path: '/movies',
            builder: (BuildContext context, GoRouterState state) {
              return MultiBlocProvider(
                providers: <BlocProvider<dynamic>>[
                  BlocProvider<MoviesCubit>.value(value: cubit),
                  BlocProvider<MovieHistoryCubit>.value(
                    value: dependencies.movieHistoryCubit,
                  ),
                ],
                child: const MoviesPage(),
              );
            },
          ),
          GoRoute(
            name: AppRoute.movieDetails.name,
            path: '/movies/:movieId',
            builder: (BuildContext context, GoRouterState state) {
              return Scaffold(
                body: Text(
                  'Movie ${state.pathParameters['movieId']}',
                  key: const ValueKey<String>('movie-details-test'),
                ),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('movies-card-movie-1')),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('movie-details-test')),
        findsOneWidget,
      );

      expect(find.text('Movie 438631'), findsOneWidget);

      router.dispose();
      await cubit.close();
    });
    testWidgets('keeps Movies visible while refresh is running', (
      WidgetTester tester,
    ) async {
      final _ControlledRefreshMoviesRepository repository =
          _ControlledRefreshMoviesRepository();

      final MoviesCubit cubit = MoviesCubit(repository: repository);

      await cubit.load();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          movieHistoryCubit: dependencies.movieHistoryCubit,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dune'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('movies-refresh')));

      await repository.refreshRequested.future;

      await tester.pump();

      expect(find.text('Dune'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('movies-loading')),
        findsNothing,
      );

      final IconButton refreshButton = tester.widget<IconButton>(
        find.byKey(const ValueKey<String>('movies-refresh')),
      );

      expect(refreshButton.onPressed, isNull);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      repository.completeRefresh(<LibraryMovie>[_secondWatchlistMovie]);

      await tester.pumpAndSettle();

      expect(find.text('Dune'), findsNothing);
      expect(find.text('Blade Runner 2049'), findsOneWidget);

      await cubit.close();
    });
    testWidgets('shows timeout message when refresh takes too long', (
      WidgetTester tester,
    ) async {
      final _RefreshTimeoutMoviesRepository repository =
          _RefreshTimeoutMoviesRepository();

      final MoviesCubit cubit = MoviesCubit(repository: repository);

      await cubit.load();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          movieHistoryCubit: dependencies.movieHistoryCubit,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dune'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('movies-refresh')));

      await tester.pumpAndSettle();

      expect(find.text('Dune'), findsOneWidget);

      expect(
        find.text('Refreshing your movies took too long.'),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('movies-failure')),
        findsNothing,
      );

      await cubit.close();
    });
    testWidgets(
      'preserves Movies local state after returning from Movie Details',
      (WidgetTester tester) async {
        final MoviesCubit cubit = MoviesCubit(
          repository: _FakeMoviesRepository(
            movies: <LibraryMovie>[
              _watchlistMovie,
              _watchedMovie,
              _comingSoonMovie,
            ],
          ),
        );

        await cubit.load();

        cubit.setSearchQuery('dune');
        cubit.setFilter(MoviesFilter.watchlist);
        cubit.setSort(MoviesSort.title);

        final GoRouter router = GoRouter(
          initialLocation: '/movies',
          routes: <RouteBase>[
            GoRoute(
              path: '/movies',
              builder: (BuildContext context, GoRouterState state) {
                return MultiBlocProvider(
                  providers: <BlocProvider<dynamic>>[
                    BlocProvider<MoviesCubit>.value(value: cubit),
                    BlocProvider<MovieHistoryCubit>.value(
                      value: dependencies.movieHistoryCubit,
                    ),
                  ],
                  child: const MoviesPage(),
                );
              },
            ),
            GoRoute(
              name: AppRoute.movieDetails.name,
              path: '/movies/:movieId',
              builder: (BuildContext context, GoRouterState state) {
                return Scaffold(
                  body: Column(
                    children: <Widget>[
                      Text(
                        'Movie ${state.pathParameters['movieId']}',
                        key: const ValueKey<String>('movie-details-test'),
                      ),
                      TextButton(
                        key: const ValueKey<String>('movie-details-back'),
                        onPressed: () {
                          context.pop();
                        },
                        child: const Text('Back'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));

        await tester.pumpAndSettle();

        /*
   * Local Movies state has already been configured before opening Details.
   */
        expect(cubit.state.searchQuery, 'dune');
        expect(cubit.state.filter, MoviesFilter.watchlist);
        expect(cubit.state.sort, MoviesSort.title);

        expect(
          find.descendant(
            of: find.byKey(const ValueKey<String>('movies-card-movie-1')),
            matching: find.text('Dune'),
          ),
          findsOneWidget,
        );

        expect(
          find.byKey(const ValueKey<String>('movies-card-movie-2')),
          findsNothing,
        );
        expect(find.text('Future Movie'), findsNothing);

        await tester.tap(
          find.byKey(const ValueKey<String>('movies-card-movie-1')),
        );

        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('movie-details-test')),
          findsOneWidget,
        );

        expect(find.text('Movie 438631'), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey<String>('movie-details-back')),
        );

        await tester.pumpAndSettle();

        /*
   * Returning from Movie Details must reveal the same Movies state instead
   * of recreating the feature with its default search/filter/sort values.
   */
        expect(cubit.state.searchQuery, 'dune');
        expect(cubit.state.filter, MoviesFilter.watchlist);
        expect(cubit.state.sort, MoviesSort.title);

        expect(
          find.descendant(
            of: find.byKey(const ValueKey<String>('movies-card-movie-1')),
            matching: find.text('Dune'),
          ),
          findsOneWidget,
        );

        expect(
          find.byKey(const ValueKey<String>('movies-card-movie-2')),
          findsNothing,
        );
        expect(find.text('Future Movie'), findsNothing);

        expect(
          find.byKey(const ValueKey<String>('movies-watchlist')),
          findsOneWidget,
        );

        router.dispose();

        await cubit.close();
      },
    );
    testWidgets('uses three Watchlist columns on a narrow mobile viewport', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(
          movies: <LibraryMovie>[
            _watchlistMovie,
            LibraryMovie(
              libraryEntryId: 'library-entry-mobile-2',
              movieId: 'movie-mobile-2',
              tmdbId: 100002,
              title: 'Blade Runner 2049',
              originalTitle: 'Blade Runner 2049',
              status: LibraryStatus.planning,
              movieStatus: 'Released',
              voteAverage: 8.0,
              releaseDate: DateTime(2017, 10, 6),
              createdAt: DateTime.utc(2026, 8, 1),
              updatedAt: DateTime.utc(2026, 8, 9),
            ),
          ],
        ),
      );

      await cubit.load();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          movieHistoryCubit: dependencies.movieHistoryCubit,
        ),
      );

      await tester.pumpAndSettle();

      final GridView grid = tester.widget<GridView>(
        find.byKey(const ValueKey<String>('movies-watchlist-grid')),
      );

      final SliverGridDelegateWithFixedCrossAxisCount delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      expect(delegate.crossAxisCount, 3);

      expect(tester.takeException(), isNull);

      await cubit.close();
    });
    testWidgets('uses stacked Movies controls on mobile', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(
          movies: <LibraryMovie>[_watchlistMovie],
        ),
      );

      await cubit.load();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          movieHistoryCubit: dependencies.movieHistoryCubit,
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('movies-search-field')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('movies-filter-menu')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('movies-sort-menu')),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);

      await cubit.close();
    });
    testWidgets('filters Movies from search on mobile', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(
          movies: <LibraryMovie>[_watchlistMovie, _watchedMovie],
        ),
      );

      await cubit.load();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          movieHistoryCubit: dependencies.movieHistoryCubit,
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey<String>('movies-search-field')),
        'Dune',
      );

      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('movies-card-movie-1')),
          matching: find.text('Dune'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('movies-card-movie-2')),
        findsNothing,
      );

      expect(cubit.state.searchQuery, 'Dune');

      expect(tester.takeException(), isNull);

      await cubit.close();
    });
    testWidgets('uses six Movie columns on a desktop viewport', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1000));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(
          movies: <LibraryMovie>[_watchlistMovie],
        ),
      );

      await cubit.load();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          movieHistoryCubit: dependencies.movieHistoryCubit,
        ),
      );

      await tester.pumpAndSettle();

      final GridView grid = tester.widget<GridView>(
        find.byKey(const ValueKey<String>('movies-watchlist-grid')),
      );

      final SliverGridDelegateWithFixedCrossAxisCount delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      expect(delegate.crossAxisCount, 6);

      expect(tester.takeException(), isNull);

      await cubit.close();
    });
    testWidgets('limits Movies content width on an ultrawide viewport', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(
          movies: <LibraryMovie>[_watchlistMovie],
        ),
      );

      await cubit.load();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          movieHistoryCubit: dependencies.movieHistoryCubit,
        ),
      );

      await tester.pumpAndSettle();

      final Size headerSize = tester.getSize(
        find.byKey(const ValueKey<String>('movies-header-content')),
      );

      expect(headerSize.width, AppSpacing.maxContentWidth);

      expect(headerSize.width, lessThan(1920));

      expect(tester.takeException(), isNull);

      await cubit.close();
    });
    testWidgets('lays out Search Filter and Sort horizontally on desktop', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(
          movies: <LibraryMovie>[_watchlistMovie],
        ),
      );

      await cubit.load();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          movieHistoryCubit: dependencies.movieHistoryCubit,
        ),
      );

      await tester.pumpAndSettle();

      expect(
        MediaQuery.sizeOf(
          tester.element(
            find.byKey(const ValueKey<String>('movies-page-title')),
          ),
        ).width,
        1440,
      );

      final Rect searchRect = tester.getRect(
        find.byKey(const ValueKey<String>('movies-search-field')),
      );

      final Rect filterRect = tester.getRect(
        find.byKey(const ValueKey<String>('movies-filter-menu')),
      );

      final Rect sortRect = tester.getRect(
        find.byKey(const ValueKey<String>('movies-sort-menu')),
      );

      /*
   * Desktop controls share the same horizontal row.
   */
      expect((searchRect.center.dy - filterRect.center.dy).abs(), lessThan(2));

      expect((filterRect.center.dy - sortRect.center.dy).abs(), lessThan(2));

      /*
   * Filter and Sort must appear after Search.
   */
      expect(filterRect.left, greaterThan(searchRect.left));
      expect(sortRect.left, greaterThan(filterRect.left));

      expect(tester.takeException(), isNull);

      await cubit.close();
    });
    testWidgets('shows no results and clears local search', (
      WidgetTester tester,
    ) async {
      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(
          movies: <LibraryMovie>[_watchlistMovie, _secondWatchlistMovie],
        ),
      );

      await cubit.load();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          movieHistoryCubit: dependencies.movieHistoryCubit,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey<String>('movies-search-field')),
        'Interstellar',
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('movies-no-results')),
        findsOneWidget,
      );

      expect(find.text('No movies found'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('movies-card-movie-1')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('movies-card-movie-4')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('movies-clear-filters')),
      );

      await tester.pumpAndSettle();

      expect(cubit.state.searchQuery, isEmpty);

      expect(
        find.byKey(const ValueKey<String>('movies-no-results')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('movies-card-movie-1')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('movies-card-movie-4')),
        findsOneWidget,
      );

      await cubit.close();
    });
    testWidgets('filters Watchlist Movies from the filter menu', (
      WidgetTester tester,
    ) async {
      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(
          movies: <LibraryMovie>[_watchlistMovie, _watchedMovie],
        ),
      );

      await cubit.load();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          movieHistoryCubit: dependencies.movieHistoryCubit,
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('movies-filter-menu')),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Watchlist').last);

      await tester.pumpAndSettle();

      expect(cubit.state.filter, MoviesFilter.watchlist);

      expect(
        find.byKey(const ValueKey<String>('movies-card-movie-1')),
        findsOneWidget,
      );

      /*
   * Completed Library Movies are not rendered as Movie cards anymore.
   * Watched presentation is backed by historical viewing events instead.
   */
      expect(
        find.byKey(const ValueKey<String>('movies-card-movie-2')),
        findsNothing,
      );

      await cubit.close();
    });
    testWidgets('records a watch event from the Watchlist check button', (
      WidgetTester tester,
    ) async {
      final _FakeMovieViewingRepository viewingRepository =
          _FakeMovieViewingRepository();

      final _MoviesPageTestDependencies historyDependencies =
          _MoviesPageTestDependencies(viewingRepository: viewingRepository);

      addTearDown(historyDependencies.dispose);

      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(
          movies: <LibraryMovie>[_watchlistMovie],
        ),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          movieHistoryCubit: historyDependencies.movieHistoryCubit,
        ),
      );

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('movies-watch-movie-1')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('movies-watch-movie-1')),
      );

      await tester.pump();

      expect(viewingRepository.recordedMovieIds, <String>['movie-1']);
    });
    testWidgets(
      'renders repeated watches of the same Movie as separate events',
      (WidgetTester tester) async {
        final _MoviesPageTestDependencies historyDependencies =
            _MoviesPageTestDependencies(
              historyItems: <HistoryMovieItem>[
                _movieHistoryItem(1, movieId: 'arrival', title: 'Arrival'),
                HistoryMovieItem(
                  eventId: 'event-arrival-second-watch',
                  watchedAt: DateTime.utc(2026, 8, 30, 20),
                  movieId: 'arrival',
                  movieTmdbId: 329865,
                  movieTitle: 'Arrival',
                ),
              ],
            );

        addTearDown(historyDependencies.dispose);

        await historyDependencies.movieHistoryCubit.load();

        final MoviesCubit cubit = MoviesCubit(
          repository: _FakeMoviesRepository(
            movies: <LibraryMovie>[_watchlistMovie],
          ),
        );

        addTearDown(cubit.close);

        await cubit.load();

        await tester.pumpWidget(
          _buildTestApp(
            cubit: cubit,
            movieHistoryCubit: historyDependencies.movieHistoryCubit,
          ),
        );

        await tester.pump();

        await tester.drag(
          find.byKey(const ValueKey<String>('movies-scroll-view')),
          const Offset(0, -600),
        );

        await tester.pump();

        expect(
          find.byKey(const ValueKey<String>('movies-watched-event-event-1')),
          findsOneWidget,
        );

        expect(
          find.byKey(
            const ValueKey<String>(
              'movies-watched-event-event-arrival-second-watch',
            ),
          ),
          findsOneWidget,
        );

        expect(find.text('Arrival'), findsNWidgets(2));
      },
    );
    testWidgets('shows up to 18 watched events in six-item pages', (
      WidgetTester tester,
    ) async {
      final List<HistoryMovieItem> historyItems =
          List<HistoryMovieItem>.generate(
            18,
            (int index) => _movieHistoryItem(index + 1),
          );

      final _MoviesPageTestDependencies historyDependencies =
          _MoviesPageTestDependencies(historyItems: historyItems);

      addTearDown(historyDependencies.dispose);

      await historyDependencies.movieHistoryCubit.load();

      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(
          movies: <LibraryMovie>[_watchlistMovie],
        ),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          movieHistoryCubit: historyDependencies.movieHistoryCubit,
        ),
      );

      await tester.pump();

      await tester.drag(
        find.byKey(const ValueKey<String>('movies-scroll-view')),
        const Offset(0, -700),
      );

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('movies-watched')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('movies-watched-page-0')),
        findsOneWidget,
      );

      for (int index = 1; index <= 6; index++) {
        expect(
          find.byKey(ValueKey<String>('movies-watched-event-event-$index')),
          findsOneWidget,
        );
      }

      final Finder indicator = find.byKey(
        const ValueKey<String>('movies-watched-page-indicator'),
      );

      expect(indicator, findsOneWidget);

      expect(
        find.descendant(
          of: indicator,
          matching: find.byType(AnimatedContainer),
        ),
        findsNWidgets(4),
      );
    });
    testWidgets('swipes through watched Movie History pages', (
      WidgetTester tester,
    ) async {
      final List<HistoryMovieItem> historyItems =
          List<HistoryMovieItem>.generate(
            18,
            (int index) => _movieHistoryItem(index + 1),
          );

      final _MoviesPageTestDependencies historyDependencies =
          _MoviesPageTestDependencies(historyItems: historyItems);

      addTearDown(historyDependencies.dispose);

      await historyDependencies.movieHistoryCubit.load();

      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(
          movies: <LibraryMovie>[_watchlistMovie],
        ),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          movieHistoryCubit: historyDependencies.movieHistoryCubit,
        ),
      );

      await tester.pump();

      await tester.drag(
        find.byKey(const ValueKey<String>('movies-scroll-view')),
        const Offset(0, -700),
      );

      await tester.pump();

      final Finder pager = find.byKey(
        const ValueKey<String>('movies-watched-pager'),
      );

      expect(pager, findsOneWidget);

      await tester.drag(pager, const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('movies-watched-page-1')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('movies-watched-event-event-7')),
        findsOneWidget,
      );

      await tester.drag(pager, const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('movies-watched-page-2')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('movies-watched-event-event-13')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('movies-watched-event-event-18')),
        findsOneWidget,
      );
    });
    testWidgets('places See All after all 18 watched events', (
      WidgetTester tester,
    ) async {
      final List<HistoryMovieItem> historyItems =
          List<HistoryMovieItem>.generate(
            18,
            (int index) => _movieHistoryItem(index + 1),
          );

      final _MoviesPageTestDependencies historyDependencies =
          _MoviesPageTestDependencies(historyItems: historyItems);

      addTearDown(historyDependencies.dispose);

      await historyDependencies.movieHistoryCubit.load();

      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(
          movies: <LibraryMovie>[_watchlistMovie],
        ),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          movieHistoryCubit: historyDependencies.movieHistoryCubit,
        ),
      );

      await tester.pump();

      await tester.drag(
        find.byKey(const ValueKey<String>('movies-scroll-view')),
        const Offset(0, -700),
      );

      await tester.pump();

      final Finder pager = find.byKey(
        const ValueKey<String>('movies-watched-pager'),
      );

      for (int page = 0; page < 2; page++) {
        await tester.drag(pager, const Offset(-500, 0));
        await tester.pumpAndSettle();
      }

      // Event 18 still belongs to the third History page.
      expect(
        find.byKey(const ValueKey<String>('movies-watched-event-event-18')),
        findsOneWidget,
      );

      await tester.drag(pager, const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('movies-watched-see-all')),
        findsOneWidget,
      );

      expect(find.text('See All'), findsOneWidget);
      expect(find.text('Movie history'), findsOneWidget);
    });
    testWidgets('opens watched Movie actions with rewatch and remove options', (
      WidgetTester tester,
    ) async {
      final HistoryMovieItem historyItem = _movieHistoryItem(
        1,
        movieId: 'arrival',
        title: 'Arrival',
      );

      final _MoviesPageTestDependencies historyDependencies =
          _MoviesPageTestDependencies(
            historyItems: <HistoryMovieItem>[historyItem],
          );

      addTearDown(historyDependencies.dispose);

      await historyDependencies.movieHistoryCubit.load();

      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(
          movies: <LibraryMovie>[_watchlistMovie],
        ),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          movieHistoryCubit: historyDependencies.movieHistoryCubit,
        ),
      );

      await tester.pump();

      await tester.drag(
        find.byKey(const ValueKey<String>('movies-scroll-view')),
        const Offset(0, -600),
      );

      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey<String>('movies-watched-action-event-1')),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('movies-watched-rewatch-event-1')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('movies-watched-remove-event-1')),
        findsOneWidget,
      );

      expect(find.text('Watched again'), findsOneWidget);
      expect(find.text('Remove this watch'), findsOneWidget);
    });
    testWidgets('records another viewing from Watched again', (
      WidgetTester tester,
    ) async {
      final _FakeMovieViewingRepository viewingRepository =
          _FakeMovieViewingRepository();

      final HistoryMovieItem historyItem = _movieHistoryItem(
        1,
        movieId: 'arrival',
        title: 'Arrival',
      );

      final _MoviesPageTestDependencies historyDependencies =
          _MoviesPageTestDependencies(
            historyItems: <HistoryMovieItem>[historyItem],
            viewingRepository: viewingRepository,
          );

      addTearDown(historyDependencies.dispose);

      await historyDependencies.movieHistoryCubit.load();

      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(
          movies: <LibraryMovie>[_watchlistMovie],
        ),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          movieHistoryCubit: historyDependencies.movieHistoryCubit,
        ),
      );

      await tester.pump();

      await tester.drag(
        find.byKey(const ValueKey<String>('movies-scroll-view')),
        const Offset(0, -600),
      );

      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey<String>('movies-watched-action-event-1')),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('movies-watched-rewatch-event-1')),
      );

      await tester.pump();

      expect(viewingRepository.recordedMovieIds, <String>['arrival']);
    });
    testWidgets('removes the selected watched Movie event', (
      WidgetTester tester,
    ) async {
      final _FakeMovieViewingRepository viewingRepository =
          _FakeMovieViewingRepository();

      final HistoryMovieItem historyItem = _movieHistoryItem(
        1,
        movieId: 'arrival',
        title: 'Arrival',
      );

      final _MoviesPageTestDependencies historyDependencies =
          _MoviesPageTestDependencies(
            historyItems: <HistoryMovieItem>[historyItem],
            viewingRepository: viewingRepository,
          );

      addTearDown(historyDependencies.dispose);

      await historyDependencies.movieHistoryCubit.load();

      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(
          movies: <LibraryMovie>[_watchlistMovie],
        ),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          movieHistoryCubit: historyDependencies.movieHistoryCubit,
        ),
      );

      await tester.pump();

      await tester.drag(
        find.byKey(const ValueKey<String>('movies-scroll-view')),
        const Offset(0, -600),
      );

      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey<String>('movies-watched-action-event-1')),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('movies-watched-remove-event-1')),
      );

      await tester.pump();

      expect(viewingRepository.deletedEvents, hasLength(1));

      expect(viewingRepository.deletedEvents.single.movieId, 'arrival');

      expect(viewingRepository.deletedEvents.single.eventId, 'event-1');
    });
  });
}

Widget _buildTestApp({
  required MoviesCubit cubit,
  required MovieHistoryCubit movieHistoryCubit,
}) {
  return MaterialApp(
    home: MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<MoviesCubit>.value(value: cubit),
        BlocProvider<MovieHistoryCubit>.value(value: movieHistoryCubit),
      ],
      child: const MoviesPage(),
    ),
  );
}

final HistoryMovieItem _watchedHistoryItem = HistoryMovieItem(
  eventId: 'event-arrival-1',
  watchedAt: DateTime.utc(2026, 8, 31, 22, 43),
  movieId: 'movie-2',
  movieTmdbId: 329865,
  movieTitle: 'Arrival',
);

final LibraryMovie _watchlistMovie = LibraryMovie(
  libraryEntryId: 'library-entry-1',
  movieId: 'movie-1',
  tmdbId: 438631,
  title: 'Dune',
  originalTitle: 'Dune',
  status: LibraryStatus.planning,
  movieStatus: 'Released',
  voteAverage: 8.2,
  releaseDate: DateTime(2021, 10, 22),
  createdAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 10),
);

final LibraryMovie _watchedMovie = LibraryMovie(
  libraryEntryId: 'library-entry-2',
  movieId: 'movie-2',
  tmdbId: 329865,
  title: 'Arrival',
  originalTitle: 'Arrival',
  status: LibraryStatus.completed,
  movieStatus: 'Released',
  voteAverage: 7.6,
  releaseDate: DateTime(2016, 11, 11),
  completedAt: DateTime.utc(2026, 8, 10),
  createdAt: DateTime.utc(2026, 7, 1),
  updatedAt: DateTime.utc(2026, 8, 10),
);

final LibraryMovie _comingSoonMovie = LibraryMovie(
  libraryEntryId: 'library-entry-3',
  movieId: 'movie-3',
  tmdbId: 999999,
  title: 'Future Movie',
  originalTitle: 'Future Movie',
  status: LibraryStatus.planning,
  movieStatus: 'Post Production',
  voteAverage: 0,
  releaseDate: DateTime(2099, 1, 1),
  createdAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 10),
);

final LibraryMovie _secondWatchlistMovie = LibraryMovie(
  libraryEntryId: 'library-entry-4',
  movieId: 'movie-4',
  tmdbId: 335984,
  title: 'Blade Runner 2049',
  originalTitle: 'Blade Runner 2049',
  status: LibraryStatus.planning,
  movieStatus: 'Released',
  voteAverage: 8.0,
  releaseDate: DateTime(2017, 10, 6),
  createdAt: DateTime.utc(2026, 7, 1),
  updatedAt: DateTime.utc(2026, 8, 10),
);

HistoryMovieItem _movieHistoryItem(
  int index, {
  String? movieId,
  String? title,
}) {
  return HistoryMovieItem(
    eventId: 'event-$index',
    watchedAt: DateTime.utc(
      2026,
      8,
      31,
      22,
      30,
    ).subtract(Duration(hours: index)),
    movieId: movieId ?? 'history-movie-$index',
    movieTmdbId: 100000 + index,
    movieTitle: title ?? 'History Movie $index',
  );
}

class _FakeMoviesRepository implements MoviesRepository {
  _FakeMoviesRepository({this.movies = const <LibraryMovie>[], this.error});

  final List<LibraryMovie> movies;
  final AppException? error;

  @override
  Future<List<LibraryMovie>> getLibraryMovies() async {
    if (error != null) {
      throw error!;
    }

    return movies;
  }
}

final class _RetryMoviesRepository implements MoviesRepository {
  int calls = 0;

  @override
  Future<List<LibraryMovie>> getLibraryMovies() async {
    calls++;

    if (calls == 1) {
      throw const AppException.connection();
    }

    return <LibraryMovie>[_watchlistMovie];
  }
}

final class _SequencedMoviesRepository implements MoviesRepository {
  _SequencedMoviesRepository({required this.responses});

  final List<List<LibraryMovie>> responses;

  int calls = 0;

  @override
  Future<List<LibraryMovie>> getLibraryMovies() async {
    final List<LibraryMovie> result = responses[calls];

    calls++;

    return result;
  }
}

final class _RefreshFailureMoviesRepository implements MoviesRepository {
  int calls = 0;

  @override
  Future<List<LibraryMovie>> getLibraryMovies() async {
    calls++;

    if (calls == 1) {
      return <LibraryMovie>[_watchlistMovie];
    }

    throw const AppException.connection();
  }
}

final class _ControlledMoviesRepository implements MoviesRepository {
  int calls = 0;

  final Completer<void> requested = Completer<void>();

  final Completer<List<LibraryMovie>> _result = Completer<List<LibraryMovie>>();

  void complete(List<LibraryMovie> movies) {
    _result.complete(movies);
  }

  @override
  Future<List<LibraryMovie>> getLibraryMovies() {
    calls++;

    if (!requested.isCompleted) {
      requested.complete();
    }

    return _result.future;
  }
}

final class _ControlledRefreshMoviesRepository implements MoviesRepository {
  int calls = 0;

  final Completer<void> refreshRequested = Completer<void>();

  final Completer<List<LibraryMovie>> _refreshResult =
      Completer<List<LibraryMovie>>();

  void completeRefresh(List<LibraryMovie> movies) {
    if (_refreshResult.isCompleted) {
      return;
    }

    _refreshResult.complete(movies);
  }

  @override
  Future<List<LibraryMovie>> getLibraryMovies() {
    calls++;

    if (calls == 1) {
      return Future<List<LibraryMovie>>.value(<LibraryMovie>[_watchlistMovie]);
    }

    if (!refreshRequested.isCompleted) {
      refreshRequested.complete();
    }

    return _refreshResult.future;
  }
}

final class _RefreshTimeoutMoviesRepository implements MoviesRepository {
  int calls = 0;

  @override
  Future<List<LibraryMovie>> getLibraryMovies() async {
    calls++;

    if (calls == 1) {
      return <LibraryMovie>[_watchlistMovie];
    }

    throw const AppException.connectionTimeout();
  }
}

final class _MoviesPageTestDependencies {
  _MoviesPageTestDependencies({
    List<HistoryMovieItem> historyItems = const <HistoryMovieItem>[],
    HistoryRepository? historyRepository,
    MovieViewingRepository? viewingRepository,
  }) : viewingStateChangeNotifier = ViewingStateChangeNotifier() {
    movieHistoryCubit = MovieHistoryCubit(
      historyRepository:
          historyRepository ??
          _FakeHistoryRepository(
            page: HistoryPage(items: historyItems, hasMore: false),
          ),
      viewingRepository: viewingRepository ?? _FakeMovieViewingRepository(),
      viewingStateChangeNotifier: viewingStateChangeNotifier,
    );
  }

  final ViewingStateChangeNotifier viewingStateChangeNotifier;

  late final MovieHistoryCubit movieHistoryCubit;

  Future<void> dispose() async {
    await movieHistoryCubit.close();
    await viewingStateChangeNotifier.dispose();
  }
}

final class _FakeHistoryRepository implements HistoryRepository {
  _FakeHistoryRepository({
    this.page = const HistoryPage(items: <HistoryMovieItem>[], hasMore: false),
  });

  final HistoryPage page;

  @override
  Future<HistoryPage> getHistory({
    int limit = 30,
    String? cursor,
    HistoryMediaType mediaType = HistoryMediaType.all,
  }) async {
    return page;
  }

  @override
  Future<HistoryPreview> getPreview() {
    throw UnimplementedError();
  }
}

final class _FakeMovieViewingRepository implements MovieViewingRepository {
  final List<String> recordedMovieIds = <String>[];

  final List<_DeletedMovieWatchEvent> deletedEvents =
      <_DeletedMovieWatchEvent>[];

  @override
  Future<void> recordWatch(String movieId) async {
    recordedMovieIds.add(movieId);
  }

  @override
  Future<void> deleteWatchEvent({
    required String movieId,
    required String eventId,
  }) async {
    deletedEvents.add(
      _DeletedMovieWatchEvent(movieId: movieId, eventId: eventId),
    );
  }
}

final class _DeletedMovieWatchEvent {
  const _DeletedMovieWatchEvent({required this.movieId, required this.eventId});

  final String movieId;
  final String eventId;
}
