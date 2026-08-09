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

void main() {
  test('loads all Explore discovery sources successfully', () async {
    final _FakeExploreRepository repository = _FakeExploreRepository(
      results: <ExploreTrendingWindow, ExploreTrending>{
        ExploreTrendingWindow.day: ExploreTrending(
          items: const <ExploreMediaItem>[_movie, _show],
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

    final Future<void> loadFuture = cubit.load();

    expect(cubit.state.today.isLoading, isTrue);
    expect(cubit.state.week.isLoading, isTrue);
    expect(cubit.state.genres.isLoading, isTrue);
    expect(cubit.state.popularShows.isLoading, isTrue);
    expect(cubit.state.popularMovies.isLoading, isTrue);

    await loadFuture;

    expect(cubit.state.today.isSuccess, isTrue);
    expect(cubit.state.week.isSuccess, isTrue);
    expect(cubit.state.genres.isSuccess, isTrue);
    expect(cubit.state.popularShows.isSuccess, isTrue);
    expect(cubit.state.popularMovies.isSuccess, isTrue);

    expect(cubit.state.today.data?.items, hasLength(2));
    expect(cubit.state.week.data?.items, hasLength(2));

    expect(cubit.state.genres.data?.shows, hasLength(2));
    expect(cubit.state.genres.data?.movies, hasLength(2));

    expect(cubit.state.popularShows.data?.items, hasLength(1));
    expect(cubit.state.popularShows.data?.items.single.title, 'Breaking Bad');

    expect(cubit.state.popularMovies.data?.items, hasLength(1));
    expect(cubit.state.popularMovies.data?.items.single.title, 'Interstellar');

    expect(repository.requestedWindows, <ExploreTrendingWindow>[
      ExploreTrendingWindow.day,
      ExploreTrendingWindow.week,
    ]);

    expect(repository.genresCalls, 1);
    expect(repository.popularShowsCalls, 1);
    expect(repository.popularMoviesCalls, 1);

    expect(repository.requestedShowGenres, <int?>[null]);
    expect(repository.requestedMovieGenres, <int?>[null]);

    await cubit.close();
  });

  test('emits failure when initial repository load fails', () async {
    final _FakeExploreRepository repository = _FakeExploreRepository(
      error: const AppException.connection(),
    );

    final ExploreCubit cubit = ExploreCubit(repository);

    await cubit.load();

    expect(cubit.state.today.isFailure, isTrue);
    expect(cubit.state.week.isFailure, isTrue);
    expect(cubit.state.genres.isFailure, isTrue);
    expect(cubit.state.popularShows.isFailure, isTrue);
    expect(cubit.state.popularMovies.isFailure, isTrue);

    expect(cubit.state.today.error?.type, AppExceptionType.connection);
    expect(cubit.state.week.error?.type, AppExceptionType.connection);
    expect(cubit.state.genres.error?.type, AppExceptionType.connection);
    expect(cubit.state.popularShows.error?.type, AppExceptionType.connection);
    expect(cubit.state.popularMovies.error?.type, AppExceptionType.connection);

    await cubit.close();
  });

  test('retry loads all Explore sources again', () async {
    final _FakeExploreRepository repository = _FakeExploreRepository(
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
    );

    final ExploreCubit cubit = ExploreCubit(repository);

    await cubit.load();
    await cubit.retry();

    expect(repository.trendingCalls, 4);
    expect(repository.genresCalls, 2);
    expect(repository.popularShowsCalls, 2);
    expect(repository.popularMoviesCalls, 2);

    expect(repository.requestedWindows, <ExploreTrendingWindow>[
      ExploreTrendingWindow.day,
      ExploreTrendingWindow.week,
      ExploreTrendingWindow.day,
      ExploreTrendingWindow.week,
    ]);

    await cubit.close();
  });

  test('filters weekly trending media locally', () async {
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
    );

    final ExploreCubit cubit = ExploreCubit(repository);

    await cubit.load();

    expect(cubit.state.filteredWeekItems, hasLength(2));

    cubit.changeWeekFilter(ExploreWeekFilter.shows);

    expect(cubit.state.filteredWeekItems, hasLength(1));
    expect(
      cubit.state.filteredWeekItems.single.mediaType,
      ExploreMediaType.show,
    );

    cubit.changeWeekFilter(ExploreWeekFilter.movies);

    expect(cubit.state.filteredWeekItems, hasLength(1));
    expect(
      cubit.state.filteredWeekItems.single.mediaType,
      ExploreMediaType.movie,
    );

    cubit.changeWeekFilter(ExploreWeekFilter.all);

    expect(cubit.state.filteredWeekItems, hasLength(2));

    await cubit.close();
  });

  test('changing Week filter does not repeat remote requests', () async {
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
    );

    final ExploreCubit cubit = ExploreCubit(repository);

    await cubit.load();

    expect(repository.trendingCalls, 2);
    expect(repository.genresCalls, 1);
    expect(repository.popularShowsCalls, 1);
    expect(repository.popularMoviesCalls, 1);

    cubit.changeWeekFilter(ExploreWeekFilter.shows);
    cubit.changeWeekFilter(ExploreWeekFilter.movies);
    cubit.changeWeekFilter(ExploreWeekFilter.all);

    expect(repository.trendingCalls, 2);
    expect(repository.genresCalls, 1);
    expect(repository.popularShowsCalls, 1);
    expect(repository.popularMoviesCalls, 1);

    await cubit.close();
  });

  test('does not emit when selecting the active Week filter', () async {
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
    );

    final ExploreCubit cubit = ExploreCubit(repository);

    await cubit.load();

    expect(cubit.state.weekFilter, ExploreWeekFilter.all);

    final ExploreState previousState = cubit.state;

    cubit.changeWeekFilter(ExploreWeekFilter.all);

    expect(cubit.state, same(previousState));

    await cubit.close();
  });

  test('changing Show genre updates only Popular TV Shows', () async {
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

    expect(repository.popularShowsCalls, 1);
    expect(repository.popularMoviesCalls, 1);

    await cubit.changeShowGenre(18);

    expect(cubit.state.selectedShowGenreId, 18);
    expect(cubit.state.selectedMovieGenreId, isNull);

    expect(cubit.state.popularShows.isSuccess, isTrue);
    expect(cubit.state.popularShows.data?.items.single.title, 'The Last of Us');

    expect(repository.popularShowsCalls, 2);
    expect(repository.popularMoviesCalls, 1);

    expect(repository.requestedShowGenres, <int?>[null, 18]);

    expect(repository.requestedMovieGenres, <int?>[null]);

    await cubit.close();
  });

  test('changing Movie genre updates only Popular Movies', () async {
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

    expect(repository.popularShowsCalls, 1);
    expect(repository.popularMoviesCalls, 1);

    await cubit.changeMovieGenre(878);

    expect(cubit.state.selectedShowGenreId, isNull);
    expect(cubit.state.selectedMovieGenreId, 878);

    expect(cubit.state.popularMovies.isSuccess, isTrue);
    expect(
      cubit.state.popularMovies.data?.items.single.title,
      'Blade Runner 2049',
    );

    expect(repository.popularShowsCalls, 1);
    expect(repository.popularMoviesCalls, 2);

    expect(repository.requestedShowGenres, <int?>[null]);

    expect(repository.requestedMovieGenres, <int?>[null, 878]);

    await cubit.close();
  });

  test('Show and Movie genre filters remain independent', () async {
    final _FakeExploreRepository repository = _FakeExploreRepository(
      genres: _genreOptions,
      popularShowsByGenre: <int?, ExploreMediaCollection>{
        18: const ExploreMediaCollection(items: <ExploreMediaItem>[_dramaShow]),
      },
      popularMoviesByGenre: <int?, ExploreMediaCollection>{
        878: const ExploreMediaCollection(
          items: <ExploreMediaItem>[_scienceFictionMovie],
        ),
      },
    );

    final ExploreCubit cubit = ExploreCubit(repository);

    await cubit.load();

    await cubit.changeShowGenre(18);

    expect(cubit.state.selectedShowGenreId, 18);
    expect(cubit.state.selectedMovieGenreId, isNull);

    await cubit.changeMovieGenre(878);

    expect(cubit.state.selectedShowGenreId, 18);
    expect(cubit.state.selectedMovieGenreId, 878);

    expect(repository.popularShowsCalls, 2);
    expect(repository.popularMoviesCalls, 2);

    await cubit.close();
  });

  test('selecting All Genres clears only the Show genre', () async {
    final _FakeExploreRepository repository = _FakeExploreRepository(
      genres: _genreOptions,
    );

    final ExploreCubit cubit = ExploreCubit(repository);

    await cubit.load();

    await cubit.changeShowGenre(18);
    await cubit.changeMovieGenre(878);

    expect(cubit.state.selectedShowGenreId, 18);
    expect(cubit.state.selectedMovieGenreId, 878);

    await cubit.changeShowGenre(null);

    expect(cubit.state.selectedShowGenreId, isNull);
    expect(cubit.state.selectedMovieGenreId, 878);

    expect(repository.requestedShowGenres, <int?>[null, 18, null]);

    await cubit.close();
  });

  test('does not reload when selecting the active Show genre', () async {
    final _FakeExploreRepository repository = _FakeExploreRepository(
      genres: _genreOptions,
    );

    final ExploreCubit cubit = ExploreCubit(repository);

    await cubit.load();

    await cubit.changeShowGenre(18);

    expect(repository.popularShowsCalls, 2);

    await cubit.changeShowGenre(18);

    expect(repository.popularShowsCalls, 2);

    await cubit.close();
  });

  test('does not reload when selecting the active Movie genre', () async {
    final _FakeExploreRepository repository = _FakeExploreRepository(
      genres: _genreOptions,
    );

    final ExploreCubit cubit = ExploreCubit(repository);

    await cubit.load();

    await cubit.changeMovieGenre(878);

    expect(repository.popularMoviesCalls, 2);

    await cubit.changeMovieGenre(878);

    expect(repository.popularMoviesCalls, 2);

    await cubit.close();
  });
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
    this.error,
  });

  final Map<ExploreTrendingWindow, ExploreTrending> results;
  final ExploreGenreOptions genres;

  final ExploreMediaCollection popularShows;
  final ExploreMediaCollection popularMovies;

  final Map<int?, ExploreMediaCollection> popularShowsByGenre;
  final Map<int?, ExploreMediaCollection> popularMoviesByGenre;

  final AppException? error;

  final List<ExploreTrendingWindow> requestedWindows =
      <ExploreTrendingWindow>[];

  final List<int?> requestedShowGenres = <int?>[];
  final List<int?> requestedMovieGenres = <int?>[];

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
    requestedWindows.add(window);

    _throwIfNeeded();

    return results[window] ??
        ExploreTrending(items: const <ExploreMediaItem>[]);
  }

  @override
  Future<ExploreGenreOptions> getGenres({String? language}) async {
    genresCalls++;

    _throwIfNeeded();

    return genres;
  }

  @override
  Future<ExploreMediaCollection> getPopularShows({
    int? genreId,
    String? language,
  }) async {
    popularShowsCalls++;
    requestedShowGenres.add(genreId);

    _throwIfNeeded();

    return popularShowsByGenre[genreId] ?? popularShows;
  }

  @override
  Future<ExploreMediaCollection> getPopularMovies({
    int? genreId,
    String? language,
  }) async {
    popularMoviesCalls++;
    requestedMovieGenres.add(genreId);

    _throwIfNeeded();

    return popularMoviesByGenre[genreId] ?? popularMovies;
  }

  void _throwIfNeeded() {
    final AppException? currentError = error;

    if (currentError != null) {
      throw currentError;
    }
  }
}
