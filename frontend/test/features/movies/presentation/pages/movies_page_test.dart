import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/movies/application/cubit/movies_cubit.dart';
import 'package:sofawatch/features/movies/application/models/movies_filter.dart';
import 'package:sofawatch/features/movies/application/models/movies_sort.dart';
import 'package:sofawatch/features/movies/domain/models/library_movie.dart';
import 'package:sofawatch/features/movies/domain/repositories/movies_repository.dart';
import 'package:sofawatch/features/movies/presentation/pages/movies_page.dart';

void main() {
  group('MoviesPage', () {
    testWidgets('shows loading state', (WidgetTester tester) async {
      final _ControlledMoviesRepository repository =
          _ControlledMoviesRepository();

      final MoviesCubit cubit = MoviesCubit(repository: repository);

      final Future<void> load = cubit.load();

      await repository.requested.future;

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

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

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

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

    testWidgets('renders Watchlist and Watched sections', (
      WidgetTester tester,
    ) async {
      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(
          movies: <LibraryMovie>[_watchlistMovie, _watchedMovie],
        ),
      );

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('movies-watchlist')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('movies-watched')),
        findsOneWidget,
      );

      expect(find.text('Watchlist'), findsOneWidget);
      expect(find.text('Watched'), findsOneWidget);

      expect(find.text('Dune'), findsOneWidget);
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

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

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

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

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

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

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

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

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

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

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
          <LibraryMovie>[_watchedMovie],
        ],
      );

      final MoviesCubit cubit = MoviesCubit(repository: repository);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

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

      await tester.tap(find.byKey(const ValueKey<String>('movies-refresh')));

      await tester.pumpAndSettle();

      expect(repository.calls, 2);

      expect(find.text('Dune'), findsNothing);
      expect(find.text('Arrival'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('preserves Movies and shows snackbar when refresh fails', (
      WidgetTester tester,
    ) async {
      final _RefreshFailureMoviesRepository repository =
          _RefreshFailureMoviesRepository();

      final MoviesCubit cubit = MoviesCubit(repository: repository);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

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
              return BlocProvider<MoviesCubit>.value(
                value: cubit,
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

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

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

      repository.completeRefresh(<LibraryMovie>[_watchedMovie]);

      await tester.pumpAndSettle();

      expect(find.text('Dune'), findsNothing);
      expect(find.text('Arrival'), findsOneWidget);

      await cubit.close();
    });
    testWidgets('shows timeout message when refresh takes too long', (
      WidgetTester tester,
    ) async {
      final _RefreshTimeoutMoviesRepository repository =
          _RefreshTimeoutMoviesRepository();

      final MoviesCubit cubit = MoviesCubit(repository: repository);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

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
                return BlocProvider<MoviesCubit>.value(
                  value: cubit,
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
    testWidgets('uses two Movie columns on a narrow mobile viewport', (
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

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      final GridView grid = tester.widget<GridView>(
        find.byKey(const ValueKey<String>('movies-watchlist-grid')),
      );

      final SliverGridDelegateWithFixedCrossAxisCount delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      expect(delegate.crossAxisCount, 2);

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

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

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

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

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

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

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

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

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

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

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
          movies: <LibraryMovie>[_watchlistMovie, _watchedMovie],
        ),
      );

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
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
        find.byKey(const ValueKey<String>('movies-card-movie-2')),
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
        find.byKey(const ValueKey<String>('movies-card-movie-2')),
        findsOneWidget,
      );

      await cubit.close();
    });
    testWidgets('filters Movies from the filter menu', (
      WidgetTester tester,
    ) async {
      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(
          movies: <LibraryMovie>[_watchlistMovie, _watchedMovie],
        ),
      );

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('movies-filter-menu')),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Watched').last);

      await tester.pumpAndSettle();

      expect(cubit.state.filter, MoviesFilter.watched);

      expect(
        find.byKey(const ValueKey<String>('movies-card-movie-1')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('movies-card-movie-2')),
        findsOneWidget,
      );

      await cubit.close();
    });
  });
}

Widget _buildTestApp({required MoviesCubit cubit}) {
  return MaterialApp(
    home: BlocProvider<MoviesCubit>.value(
      value: cubit,
      child: const MoviesPage(),
    ),
  );
}

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
