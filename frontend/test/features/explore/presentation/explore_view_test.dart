import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/explore/application/cubit/explore_cubit.dart';
import 'package:sofawatch/features/explore/application/cubit/explore_state.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_genre.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_genre_options.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_collection.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_item.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending_window.dart';
import 'package:sofawatch/features/explore/domain/repositories/explore_repository.dart';
import 'package:sofawatch/features/explore/presentation/views/explore_view.dart';
import 'package:sofawatch/features/library/application/cubit/library_cubit.dart';
import 'package:sofawatch/features/library/domain/repositories/library_repository.dart';

void main() {
  testWidgets('shows Trending and Popular discovery sections', (
    WidgetTester tester,
  ) async {
    final ExploreCubit cubit = ExploreCubit(
      _FakeExploreRepository(
        results: <ExploreTrendingWindow, ExploreTrending>{
          ExploreTrendingWindow.day: ExploreTrending(
            items: const <ExploreMediaItem>[_movie],
          ),
          ExploreTrendingWindow.week: ExploreTrending(
            items: const <ExploreMediaItem>[_show],
          ),
        },
        genres: _genreOptions,
        popularShows: const ExploreMediaCollection(
          items: <ExploreMediaItem>[_popularShow],
        ),
        popularMovies: const ExploreMediaCollection(
          items: <ExploreMediaItem>[_popularMovie],
        ),
      ),
    );

    await cubit.load();

    await tester.pumpWidget(_buildTestApp(cubit));
    await tester.pump();

    expect(find.text('Trending Today'), findsOneWidget);
    expect(find.text('Trending This Week'), findsOneWidget);
    expect(find.text('Popular TV Shows'), findsOneWidget);
    expect(find.text('Popular Movies'), findsOneWidget);

    expect(find.text('Dune'), findsOneWidget);
    expect(find.text('Severance'), findsOneWidget);
    expect(find.text('Breaking Bad'), findsOneWidget);
    expect(find.text('Interstellar'), findsOneWidget);

    await cubit.close();
  });

  testWidgets('shows Week media filters', (WidgetTester tester) async {
    final ExploreCubit cubit = await _createLoadedCubit();

    await tester.pumpWidget(_buildTestApp(cubit));
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('explore-week-filter-all')),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey<String>('explore-week-filter-shows')),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey<String>('explore-week-filter-movies')),
      findsOneWidget,
    );

    await cubit.close();
  });

  testWidgets('shows independent genre filters for Popular Shows and Movies', (
    WidgetTester tester,
  ) async {
    final ExploreCubit cubit = await _createLoadedCubit();

    await tester.pumpWidget(_buildTestApp(cubit));
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('explore-popular-shows-genre-all')),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey<String>('explore-popular-shows-genre-18')),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey<String>('explore-popular-movies-genre-all')),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey<String>('explore-popular-movies-genre-878')),
      findsOneWidget,
    );

    await cubit.close();
  });

  testWidgets('All Genres is selected initially for both Popular sections', (
    WidgetTester tester,
  ) async {
    final ExploreCubit cubit = await _createLoadedCubit();

    await tester.pumpWidget(_buildTestApp(cubit));
    await tester.pump();

    expect(cubit.state.selectedShowGenreId, isNull);
    expect(cubit.state.selectedMovieGenreId, isNull);

    final ChoiceChip showAllChip = tester.widget<ChoiceChip>(
      find.descendant(
        of: find.byKey(
          const ValueKey<String>('explore-popular-shows-genre-all'),
        ),
        matching: find.byType(ChoiceChip),
      ),
    );

    final ChoiceChip movieAllChip = tester.widget<ChoiceChip>(
      find.descendant(
        of: find.byKey(
          const ValueKey<String>('explore-popular-movies-genre-all'),
        ),
        matching: find.byType(ChoiceChip),
      ),
    );

    expect(showAllChip.selected, isTrue);
    expect(movieAllChip.selected, isTrue);

    await cubit.close();
  });

  testWidgets('changing Show genre does not request Popular Movies again', (
    WidgetTester tester,
  ) async {
    final _FakeExploreRepository repository = _FakeExploreRepository(
      genres: _genreOptions,
      popularShowsByGenre: <int?, ExploreMediaCollection>{
        null: const ExploreMediaCollection(
          items: <ExploreMediaItem>[_popularShow],
        ),
        18: const ExploreMediaCollection(items: <ExploreMediaItem>[_dramaShow]),
      },
      popularMovies: const ExploreMediaCollection(
        items: <ExploreMediaItem>[_popularMovie],
      ),
    );

    final ExploreCubit cubit = ExploreCubit(repository);

    await cubit.load();

    await tester.pumpWidget(_buildTestApp(cubit));
    await tester.pump();

    expect(repository.popularShowsCalls, 1);
    expect(repository.popularMoviesCalls, 1);

    await tester.tap(
      find.byKey(const ValueKey<String>('explore-popular-shows-genre-18')),
    );

    await tester.pumpAndSettle();

    expect(cubit.state.selectedShowGenreId, 18);
    expect(cubit.state.selectedMovieGenreId, isNull);

    expect(repository.popularShowsCalls, 2);
    expect(repository.popularMoviesCalls, 1);

    expect(find.text('The Last of Us'), findsOneWidget);
    expect(find.text('Interstellar'), findsOneWidget);

    await cubit.close();
  });

  testWidgets('changing Movie genre does not request Popular Shows again', (
    WidgetTester tester,
  ) async {
    final _FakeExploreRepository repository = _FakeExploreRepository(
      genres: _genreOptions,
      popularShows: const ExploreMediaCollection(
        items: <ExploreMediaItem>[_popularShow],
      ),
      popularMoviesByGenre: <int?, ExploreMediaCollection>{
        null: const ExploreMediaCollection(
          items: <ExploreMediaItem>[_popularMovie],
        ),
        878: const ExploreMediaCollection(
          items: <ExploreMediaItem>[_scienceFictionMovie],
        ),
      },
    );

    final ExploreCubit cubit = ExploreCubit(repository);

    await cubit.load();

    await tester.pumpWidget(_buildTestApp(cubit));
    await tester.pump();

    expect(repository.popularShowsCalls, 1);
    expect(repository.popularMoviesCalls, 1);

    await tester.tap(
      find.byKey(const ValueKey<String>('explore-popular-movies-genre-878')),
    );

    await tester.pumpAndSettle();

    expect(cubit.state.selectedShowGenreId, isNull);
    expect(cubit.state.selectedMovieGenreId, 878);

    expect(repository.popularShowsCalls, 1);
    expect(repository.popularMoviesCalls, 2);

    expect(find.text('Breaking Bad'), findsOneWidget);
    expect(find.text('Blade Runner 2049'), findsOneWidget);

    await cubit.close();
  });

  testWidgets('shows loading only in Popular TV Shows when its genre changes', (
    WidgetTester tester,
  ) async {
    final _ControlledExploreRepository repository =
        _ControlledExploreRepository();

    final ExploreCubit cubit = ExploreCubit(repository);

    await cubit.load();

    await tester.pumpWidget(_buildTestApp(cubit));
    await tester.pump();

    expect(cubit.state.popularShows.isSuccess, isTrue);
    expect(cubit.state.popularMovies.isSuccess, isTrue);

    final Finder dramaFilter = find.byKey(
      const ValueKey<String>('explore-popular-shows-genre-18'),
    );

    expect(dramaFilter, findsOneWidget);

    await tester.ensureVisible(dramaFilter);
    await tester.tap(dramaFilter);

    // Processa o emit/loading provocado pelo tap.
    await tester.pump();
    await tester.pump();

    expect(cubit.state.selectedShowGenreId, 18);
    expect(cubit.state.selectedMovieGenreId, isNull);

    expect(cubit.state.popularShows.isLoading, isTrue);
    expect(cubit.state.popularMovies.isSuccess, isTrue);

    expect(
      find.byKey(const ValueKey<String>('explore-popular-shows-loading')),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey<String>('explore-popular-movies-loading')),
      findsNothing,
    );

    expect(find.text('Popular Movies'), findsOneWidget);
    expect(find.text('Interstellar'), findsOneWidget);
    expect(find.text('Trending Today'), findsOneWidget);

    repository.completeShowGenre(
      const ExploreMediaCollection(items: <ExploreMediaItem>[_dramaShow]),
    );

    await tester.pump();
    await tester.pump();

    expect(cubit.state.popularShows.isSuccess, isTrue);

    expect(
      find.byKey(const ValueKey<String>('explore-popular-shows-loading')),
      findsNothing,
    );

    expect(find.text('The Last of Us'), findsOneWidget);

    await cubit.close();
  });

  testWidgets('shows loading only in Popular Movies when its genre changes', (
    WidgetTester tester,
  ) async {
    final _ControlledExploreRepository repository =
        _ControlledExploreRepository();

    final ExploreCubit cubit = ExploreCubit(repository);

    await cubit.load();

    await tester.pumpWidget(_buildTestApp(cubit));
    await tester.pump();

    expect(cubit.state.popularShows.isSuccess, isTrue);
    expect(cubit.state.popularMovies.isSuccess, isTrue);

    final Finder scienceFictionFilter = find.byKey(
      const ValueKey<String>('explore-popular-movies-genre-878'),
    );

    expect(scienceFictionFilter, findsOneWidget);

    await tester.ensureVisible(scienceFictionFilter);
    await tester.tap(scienceFictionFilter);

    // Processa o emit/loading provocado pelo tap.
    await tester.pump();
    await tester.pump();

    expect(cubit.state.selectedMovieGenreId, 878);
    expect(cubit.state.selectedShowGenreId, isNull);

    expect(cubit.state.popularMovies.isLoading, isTrue);
    expect(cubit.state.popularShows.isSuccess, isTrue);

    expect(
      find.byKey(const ValueKey<String>('explore-popular-movies-loading')),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey<String>('explore-popular-shows-loading')),
      findsNothing,
    );

    expect(find.text('Popular TV Shows'), findsOneWidget);
    expect(find.text('Breaking Bad'), findsOneWidget);
    expect(find.text('Trending Today'), findsOneWidget);

    repository.completeMovieGenre(
      const ExploreMediaCollection(
        items: <ExploreMediaItem>[_scienceFictionMovie],
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(cubit.state.popularMovies.isSuccess, isTrue);

    expect(
      find.byKey(const ValueKey<String>('explore-popular-movies-loading')),
      findsNothing,
    );

    expect(find.text('Blade Runner 2049'), findsOneWidget);

    await cubit.close();
  });

  testWidgets(
    'shows empty state only for Popular TV Shows when genre has no results',
    (WidgetTester tester) async {
      final _FakeExploreRepository repository = _FakeExploreRepository(
        genres: _genreOptions,
        popularShowsByGenre: const <int?, ExploreMediaCollection>{
          18: ExploreMediaCollection(items: <ExploreMediaItem>[]),
        },
        popularMovies: const ExploreMediaCollection(
          items: <ExploreMediaItem>[_popularMovie],
        ),
      );

      final ExploreCubit cubit = ExploreCubit(repository);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit));
      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey<String>('explore-popular-shows-genre-18')),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('explore-popular-shows-empty')),
        findsOneWidget,
      );

      expect(find.text('No TV shows found for this genre.'), findsOneWidget);

      expect(find.text('Popular Movies'), findsOneWidget);
      expect(find.text('Interstellar'), findsOneWidget);

      await cubit.close();
    },
  );

  testWidgets(
    'shows empty state only for Popular Movies when genre has no results',
    (WidgetTester tester) async {
      final _FakeExploreRepository repository = _FakeExploreRepository(
        genres: _genreOptions,
        popularShows: const ExploreMediaCollection(
          items: <ExploreMediaItem>[_popularShow],
        ),
        popularMoviesByGenre: const <int?, ExploreMediaCollection>{
          878: ExploreMediaCollection(items: <ExploreMediaItem>[]),
        },
      );

      final ExploreCubit cubit = ExploreCubit(repository);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit));
      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey<String>('explore-popular-movies-genre-878')),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('explore-popular-movies-empty')),
        findsOneWidget,
      );

      expect(find.text('No Movies found for this genre.'), findsOneWidget);

      expect(find.text('Popular TV Shows'), findsOneWidget);
      expect(find.text('Breaking Bad'), findsOneWidget);

      await cubit.close();
    },
  );

  testWidgets(
    'filters Trending This Week locally without hiding other sections',
    (WidgetTester tester) async {
      final _FakeExploreRepository repository = _FakeExploreRepository(
        results: <ExploreTrendingWindow, ExploreTrending>{
          ExploreTrendingWindow.day: ExploreTrending(
            items: const <ExploreMediaItem>[_movie],
          ),
          ExploreTrendingWindow.week: ExploreTrending(
            items: const <ExploreMediaItem>[_show, _movie],
          ),
        },
        genres: _genreOptions,
        popularShows: const ExploreMediaCollection(
          items: <ExploreMediaItem>[_popularShow],
        ),
        popularMovies: const ExploreMediaCollection(
          items: <ExploreMediaItem>[_popularMovie],
        ),
      );

      final ExploreCubit cubit = ExploreCubit(repository);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit));
      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey<String>('explore-week-filter-shows')),
      );

      await tester.pump();

      expect(cubit.state.weekFilter, ExploreWeekFilter.shows);

      expect(cubit.state.filteredWeekItems, hasLength(1));

      expect(
        cubit.state.filteredWeekItems.single.mediaType,
        ExploreMediaType.show,
      );

      expect(find.text('Trending Today'), findsOneWidget);
      expect(find.text('Popular TV Shows'), findsOneWidget);
      expect(find.text('Popular Movies'), findsOneWidget);

      expect(repository.trendingCalls, 2);
      expect(repository.popularShowsCalls, 1);
      expect(repository.popularMoviesCalls, 1);

      await cubit.close();
    },
  );

  testWidgets('shows global skeleton during initial Explore load', (
    WidgetTester tester,
  ) async {
    final _PendingExploreRepository repository = _PendingExploreRepository();

    final ExploreCubit cubit = ExploreCubit(repository);

    final Future<void> loadFuture = cubit.load();

    await tester.pumpWidget(_buildTestApp(cubit));
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('explore-trending-loading')),
      findsOneWidget,
    );

    repository.completeTrending(
      ExploreTrendingWindow.day,
      ExploreTrending(items: const <ExploreMediaItem>[]),
    );

    repository.completeTrending(
      ExploreTrendingWindow.week,
      ExploreTrending(items: const <ExploreMediaItem>[]),
    );

    repository.completeGenres(_genreOptions);

    repository.completePopularShows(
      const ExploreMediaCollection(items: <ExploreMediaItem>[]),
    );

    repository.completePopularMovies(
      const ExploreMediaCollection(items: <ExploreMediaItem>[]),
    );

    await loadFuture;
    await tester.pump();

    await cubit.close();
  });

  testWidgets('shows global error and Retry when initial Explore load fails', (
    WidgetTester tester,
  ) async {
    final _RecoverableExploreRepository repository =
        _RecoverableExploreRepository(failInitialLoad: true);

    final ExploreCubit cubit = ExploreCubit(repository);

    await cubit.load();

    await tester.pumpWidget(_buildTestApp(cubit));

    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('explore-trending-failure')),
      findsOneWidget,
    );

    expect(find.text('Could not load Explore.'), findsOneWidget);

    expect(find.byKey(const ValueKey<String>('explore-retry')), findsOneWidget);

    repository.failInitialLoad = false;

    await tester.tap(find.byKey(const ValueKey<String>('explore-retry')));

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('explore-trending-failure')),
      findsNothing,
    );

    expect(
      find.byKey(const ValueKey<String>('explore-trending-content')),
      findsOneWidget,
    );

    expect(repository.trendingCalls, greaterThanOrEqualTo(3));

    await cubit.close();
  });

  testWidgets('shows and retries error only in Popular TV Shows', (
    WidgetTester tester,
  ) async {
    final _RecoverableExploreRepository repository =
        _RecoverableExploreRepository(failShowGenre: true);

    final ExploreCubit cubit = ExploreCubit(repository);

    await cubit.load();

    await tester.pumpWidget(_buildTestApp(cubit));

    await tester.pump();

    final Finder showGenreChip = find.byKey(
      const ValueKey<String>('explore-popular-shows-genre-18'),
    );

    await tester.ensureVisible(showGenreChip);
    await tester.pumpAndSettle();

    await tester.tap(showGenreChip);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('explore-popular-shows-failure')),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey<String>('explore-popular-movies-failure')),
      findsNothing,
    );

    expect(find.text('Popular Movies'), findsOneWidget);

    expect(find.text('Interstellar'), findsOneWidget);

    repository.failShowGenre = false;

    final Finder showRetry = find.byKey(
      const ValueKey<String>('explore-popular-shows-retry'),
    );

    await tester.ensureVisible(showRetry);
    await tester.pumpAndSettle();

    await tester.tap(showRetry);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('explore-popular-shows-failure')),
      findsNothing,
    );

    expect(find.text('The Last of Us'), findsOneWidget);

    expect(cubit.state.selectedShowGenreId, 18);

    await cubit.close();
  });

  testWidgets('shows and retries error only in Popular Movies', (
    WidgetTester tester,
  ) async {
    final _RecoverableExploreRepository repository =
        _RecoverableExploreRepository(failMovieGenre: true);

    final ExploreCubit cubit = ExploreCubit(repository);

    await cubit.load();

    await tester.pumpWidget(_buildTestApp(cubit));

    await tester.pump();

    final Finder movieGenreChip = find.byKey(
      const ValueKey<String>('explore-popular-movies-genre-878'),
    );

    await tester.ensureVisible(movieGenreChip);
    await tester.pumpAndSettle();

    await tester.tap(movieGenreChip);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('explore-popular-movies-failure')),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey<String>('explore-popular-shows-failure')),
      findsNothing,
    );

    expect(find.text('Popular TV Shows'), findsOneWidget);

    expect(find.text('Breaking Bad'), findsOneWidget);

    repository.failMovieGenre = false;

    final Finder movieRetry = find.byKey(
      const ValueKey<String>('explore-popular-movies-retry'),
    );

    await tester.ensureVisible(movieRetry);
    await tester.pumpAndSettle();

    await tester.tap(movieRetry);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('explore-popular-movies-failure')),
      findsNothing,
    );

    expect(find.text('Blade Runner 2049'), findsOneWidget);

    expect(cubit.state.selectedMovieGenreId, 878);

    await cubit.close();
  });
}

Widget _buildTestApp(ExploreCubit cubit) {
  return MaterialApp(
    home: Scaffold(
      body: MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<ExploreCubit>.value(value: cubit),
          BlocProvider<LibraryCubit>(
            create: (_) => LibraryCubit(_FakeLibraryRepository()),
          ),
        ],
        child: const ExploreView(),
      ),
    ),
  );
}

Future<ExploreCubit> _createLoadedCubit() async {
  final ExploreCubit cubit = ExploreCubit(
    _FakeExploreRepository(
      results: <ExploreTrendingWindow, ExploreTrending>{
        ExploreTrendingWindow.day: ExploreTrending(
          items: const <ExploreMediaItem>[_movie],
        ),
        ExploreTrendingWindow.week: ExploreTrending(
          items: const <ExploreMediaItem>[_show],
        ),
      },
      genres: _genreOptions,
      popularShows: const ExploreMediaCollection(
        items: <ExploreMediaItem>[_popularShow],
      ),
      popularMovies: const ExploreMediaCollection(
        items: <ExploreMediaItem>[_popularMovie],
      ),
    ),
  );

  await cubit.load();

  return cubit;
}

const ExploreGenreOptions _genreOptions = ExploreGenreOptions(
  shows: <ExploreGenre>[
    ExploreGenre(id: 18, name: 'Drama'),
    ExploreGenre(id: 35, name: 'Comedy'),
  ],
  movies: <ExploreGenre>[
    ExploreGenre(id: 878, name: 'Science Fiction'),
    ExploreGenre(id: 12, name: 'Adventure'),
  ],
);

const ExploreMediaItem _show = ExploreMediaItem(
  mediaType: ExploreMediaType.show,
  tmdbId: 95396,
  title: 'Severance',
  originalTitle: 'Severance',
  originalLanguage: 'en',
  genreIds: <int>[18],
  popularity: 120,
  voteAverage: 8.4,
  voteCount: 2100,
);

const ExploreMediaItem _movie = ExploreMediaItem(
  mediaType: ExploreMediaType.movie,
  tmdbId: 438631,
  title: 'Dune',
  originalTitle: 'Dune',
  originalLanguage: 'en',
  genreIds: <int>[878],
  popularity: 95,
  voteAverage: 7.8,
  voteCount: 13000,
);

const ExploreMediaItem _popularShow = ExploreMediaItem(
  mediaType: ExploreMediaType.show,
  tmdbId: 1396,
  title: 'Breaking Bad',
  originalTitle: 'Breaking Bad',
  originalLanguage: 'en',
  genreIds: <int>[18],
  popularity: 100,
  voteAverage: 9.5,
  voteCount: 16000,
);

const ExploreMediaItem _dramaShow = ExploreMediaItem(
  mediaType: ExploreMediaType.show,
  tmdbId: 100088,
  title: 'The Last of Us',
  originalTitle: 'The Last of Us',
  originalLanguage: 'en',
  genreIds: <int>[18],
  popularity: 90,
  voteAverage: 8.6,
  voteCount: 7000,
);

const ExploreMediaItem _popularMovie = ExploreMediaItem(
  mediaType: ExploreMediaType.movie,
  tmdbId: 157336,
  title: 'Interstellar',
  originalTitle: 'Interstellar',
  originalLanguage: 'en',
  genreIds: <int>[12, 18, 878],
  popularity: 110,
  voteAverage: 8.5,
  voteCount: 36000,
);

const ExploreMediaItem _scienceFictionMovie = ExploreMediaItem(
  mediaType: ExploreMediaType.movie,
  tmdbId: 335984,
  title: 'Blade Runner 2049',
  originalTitle: 'Blade Runner 2049',
  originalLanguage: 'en',
  genreIds: <int>[878],
  popularity: 80,
  voteAverage: 7.6,
  voteCount: 14000,
);

final class _FakeExploreRepository implements ExploreRepository {
  _FakeExploreRepository({
    this.results = const <ExploreTrendingWindow, ExploreTrending>{},
    this.genres = const ExploreGenreOptions(),
    this.popularShows = const ExploreMediaCollection(
      items: <ExploreMediaItem>[],
    ),
    this.popularMovies = const ExploreMediaCollection(
      items: <ExploreMediaItem>[],
    ),
    this.popularShowsByGenre = const <int?, ExploreMediaCollection>{},
    this.popularMoviesByGenre = const <int?, ExploreMediaCollection>{},
  });

  final Map<ExploreTrendingWindow, ExploreTrending> results;
  final ExploreGenreOptions genres;

  final ExploreMediaCollection popularShows;
  final ExploreMediaCollection popularMovies;

  final Map<int?, ExploreMediaCollection> popularShowsByGenre;
  final Map<int?, ExploreMediaCollection> popularMoviesByGenre;

  int trendingCalls = 0;
  int genresCalls = 0;
  int popularShowsCalls = 0;
  int popularMoviesCalls = 0;

  @override
  Future<ExploreTrending> getTrending({
    required ExploreTrendingWindow window,
    String? language,
  }) async {
    trendingCalls++;

    return results[window] ??
        ExploreTrending(items: const <ExploreMediaItem>[]);
  }

  @override
  Future<ExploreGenreOptions> getGenres({String? language}) async {
    genresCalls++;
    return genres;
  }

  @override
  Future<ExploreMediaCollection> getPopularShows({
    int? genreId,
    String? language,
  }) async {
    popularShowsCalls++;

    return popularShowsByGenre[genreId] ?? popularShows;
  }

  @override
  Future<ExploreMediaCollection> getPopularMovies({
    int? genreId,
    String? language,
  }) async {
    popularMoviesCalls++;

    return popularMoviesByGenre[genreId] ?? popularMovies;
  }
}

final class _PendingExploreRepository implements ExploreRepository {
  final Map<ExploreTrendingWindow, Completer<ExploreTrending>>
  _trendingCompleters = <ExploreTrendingWindow, Completer<ExploreTrending>>{
    ExploreTrendingWindow.day: Completer<ExploreTrending>(),
    ExploreTrendingWindow.week: Completer<ExploreTrending>(),
  };

  final Completer<ExploreGenreOptions> _genresCompleter =
      Completer<ExploreGenreOptions>();

  final Completer<ExploreMediaCollection> _popularShowsCompleter =
      Completer<ExploreMediaCollection>();

  final Completer<ExploreMediaCollection> _popularMoviesCompleter =
      Completer<ExploreMediaCollection>();

  @override
  Future<ExploreTrending> getTrending({
    required ExploreTrendingWindow window,
    String? language,
  }) {
    return _trendingCompleters[window]!.future;
  }

  @override
  Future<ExploreGenreOptions> getGenres({String? language}) {
    return _genresCompleter.future;
  }

  @override
  Future<ExploreMediaCollection> getPopularShows({
    int? genreId,
    String? language,
  }) {
    return _popularShowsCompleter.future;
  }

  @override
  Future<ExploreMediaCollection> getPopularMovies({
    int? genreId,
    String? language,
  }) {
    return _popularMoviesCompleter.future;
  }

  void completeTrending(ExploreTrendingWindow window, ExploreTrending value) {
    _trendingCompleters[window]!.complete(value);
  }

  void completeGenres(ExploreGenreOptions value) {
    _genresCompleter.complete(value);
  }

  void completePopularShows(ExploreMediaCollection value) {
    _popularShowsCompleter.complete(value);
  }

  void completePopularMovies(ExploreMediaCollection value) {
    _popularMoviesCompleter.complete(value);
  }
}

final class _ControlledExploreRepository implements ExploreRepository {
  Completer<ExploreMediaCollection>? _showGenreCompleter;
  Completer<ExploreMediaCollection>? _movieGenreCompleter;

  @override
  Future<ExploreTrending> getTrending({
    required ExploreTrendingWindow window,
    String? language,
  }) async {
    return switch (window) {
      ExploreTrendingWindow.day => ExploreTrending(
        items: const <ExploreMediaItem>[_movie],
      ),
      ExploreTrendingWindow.week => ExploreTrending(
        items: const <ExploreMediaItem>[_show],
      ),
    };
  }

  @override
  Future<ExploreGenreOptions> getGenres({String? language}) async {
    return _genreOptions;
  }

  @override
  Future<ExploreMediaCollection> getPopularShows({
    int? genreId,
    String? language,
  }) {
    if (genreId == null) {
      return Future<ExploreMediaCollection>.value(
        const ExploreMediaCollection(items: <ExploreMediaItem>[_popularShow]),
      );
    }

    _showGenreCompleter = Completer<ExploreMediaCollection>();

    return _showGenreCompleter!.future;
  }

  @override
  Future<ExploreMediaCollection> getPopularMovies({
    int? genreId,
    String? language,
  }) {
    if (genreId == null) {
      return Future<ExploreMediaCollection>.value(
        const ExploreMediaCollection(items: <ExploreMediaItem>[_popularMovie]),
      );
    }

    _movieGenreCompleter = Completer<ExploreMediaCollection>();

    return _movieGenreCompleter!.future;
  }

  void completeShowGenre(ExploreMediaCollection value) {
    _showGenreCompleter!.complete(value);
  }

  void completeMovieGenre(ExploreMediaCollection value) {
    _movieGenreCompleter!.complete(value);
  }
}

final class _FakeLibraryRepository implements LibraryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

final class _RecoverableExploreRepository implements ExploreRepository {
  _RecoverableExploreRepository({
    this.failInitialLoad = false,
    this.failShowGenre = false,
    this.failMovieGenre = false,
  });

  bool failInitialLoad;
  bool failShowGenre;
  bool failMovieGenre;

  int trendingCalls = 0;
  int genresCalls = 0;
  int popularShowsCalls = 0;
  int popularMoviesCalls = 0;

  @override
  Future<ExploreTrending> getTrending({
    required ExploreTrendingWindow window,
    String? language,
  }) async {
    trendingCalls++;

    if (failInitialLoad) {
      throw const AppException.connection();
    }

    return switch (window) {
      ExploreTrendingWindow.day => ExploreTrending(
        items: const <ExploreMediaItem>[_movie],
      ),
      ExploreTrendingWindow.week => ExploreTrending(
        items: const <ExploreMediaItem>[_show],
      ),
    };
  }

  @override
  Future<ExploreGenreOptions> getGenres({String? language}) async {
    genresCalls++;

    return _genreOptions;
  }

  @override
  Future<ExploreMediaCollection> getPopularShows({
    int? genreId,
    String? language,
  }) async {
    popularShowsCalls++;

    if (genreId == 18) {
      if (failShowGenre) {
        throw const AppException.connection();
      }

      return const ExploreMediaCollection(
        items: <ExploreMediaItem>[_dramaShow],
      );
    }

    return const ExploreMediaCollection(
      items: <ExploreMediaItem>[_popularShow],
    );
  }

  @override
  Future<ExploreMediaCollection> getPopularMovies({
    int? genreId,
    String? language,
  }) async {
    popularMoviesCalls++;

    if (genreId == 878) {
      if (failMovieGenre) {
        throw const AppException.connection();
      }

      return const ExploreMediaCollection(
        items: <ExploreMediaItem>[_scienceFictionMovie],
      );
    }

    return const ExploreMediaCollection(
      items: <ExploreMediaItem>[_popularMovie],
    );
  }
}
