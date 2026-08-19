import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/application/cubit/library_collection_cubit.dart';
import 'package:sofawatch/features/library/application/cubit/library_collection_state.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/movies/domain/models/library_movie.dart';
import 'package:sofawatch/features/movies/domain/repositories/movies_repository.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';
import 'package:sofawatch/features/shows/domain/models/library_show_progress.dart';
import 'package:sofawatch/features/shows/domain/models/stale_watching_show.dart';
import 'package:sofawatch/features/shows/domain/models/upcoming_item.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_page.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_show.dart';
import 'package:sofawatch/features/shows/domain/repositories/shows_repository.dart';

void main() {
  group('LibraryCollectionCubit', () {
    test('starts empty and idle', () {
      final LibraryCollectionCubit cubit = LibraryCollectionCubit(
        showsRepository: const _ShowsRepository(),
        moviesRepository: const _MoviesRepository(),
      );

      addTearDown(cubit.close);

      expect(cubit.state.shows, isEmpty);
      expect(cubit.state.movies, isEmpty);

      expect(cubit.state.isLoadingShows, isFalse);
      expect(cubit.state.isLoadingMovies, isFalse);
      expect(cubit.state.isLoading, isFalse);

      expect(cubit.state.showsError, isNull);
      expect(cubit.state.moviesError, isNull);
    });

    test('loads Shows and Movies independently', () async {
      final LibraryCollectionCubit cubit = LibraryCollectionCubit(
        showsRepository: _ShowsRepository(shows: <LibraryShow>[_watchingShow]),
        moviesRepository: _MoviesRepository(
          movies: <LibraryMovie>[_watchlistMovie],
        ),
      );

      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.shows, <LibraryShow>[_watchingShow]);

      expect(cubit.state.movies, <LibraryMovie>[_watchlistMovie]);

      expect(cubit.state.isLoadingShows, isFalse);
      expect(cubit.state.isLoadingMovies, isFalse);

      expect(cubit.state.showsError, isNull);
      expect(cubit.state.moviesError, isNull);
    });

    test('Show failure does not discard Movies', () async {
      final LibraryCollectionCubit cubit = LibraryCollectionCubit(
        showsRepository: const _ShowsRepository(
          error: AppException.connection(),
        ),
        moviesRepository: _MoviesRepository(
          movies: <LibraryMovie>[_watchlistMovie],
        ),
      );

      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.shows, isEmpty);
      expect(cubit.state.showsError, isNotNull);
      expect(cubit.state.showsError?.type, AppExceptionType.connection);

      expect(cubit.state.movies, <LibraryMovie>[_watchlistMovie]);

      expect(cubit.state.moviesError, isNull);
    });

    test('Movie failure does not discard Shows', () async {
      final LibraryCollectionCubit cubit = LibraryCollectionCubit(
        showsRepository: _ShowsRepository(shows: <LibraryShow>[_watchingShow]),
        moviesRepository: const _MoviesRepository(
          error: AppException.connection(),
        ),
      );

      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.shows, <LibraryShow>[_watchingShow]);

      expect(cubit.state.showsError, isNull);

      expect(cubit.state.movies, isEmpty);

      expect(cubit.state.moviesError?.type, AppExceptionType.connection);
    });

    test('maps unexpected Show failure to unknown', () async {
      final LibraryCollectionCubit cubit = LibraryCollectionCubit(
        showsRepository: const _UnexpectedShowsRepository(),
        moviesRepository: const _MoviesRepository(),
      );

      addTearDown(cubit.close);

      await cubit.loadShows();

      expect(cubit.state.showsError?.type, AppExceptionType.unknown);

      expect(cubit.state.isLoadingShows, isFalse);
    });

    test('maps unexpected Movie failure to unknown', () async {
      final LibraryCollectionCubit cubit = LibraryCollectionCubit(
        showsRepository: const _ShowsRepository(),
        moviesRepository: const _UnexpectedMoviesRepository(),
      );

      addTearDown(cubit.close);

      await cubit.loadMovies();

      expect(cubit.state.moviesError?.type, AppExceptionType.unknown);

      expect(cubit.state.isLoadingMovies, isFalse);
    });

    test('retryShows only reloads Shows', () async {
      final _RetryShowsRepository showsRepository = _RetryShowsRepository();

      final _CountingMoviesRepository moviesRepository =
          _CountingMoviesRepository();

      final LibraryCollectionCubit cubit = LibraryCollectionCubit(
        showsRepository: showsRepository,
        moviesRepository: moviesRepository,
      );

      addTearDown(cubit.close);

      await cubit.load();

      expect(showsRepository.calls, 1);
      expect(moviesRepository.calls, 1);

      expect(cubit.state.showsError, isNotNull);

      expect(cubit.state.movies, <LibraryMovie>[_watchlistMovie]);

      await cubit.retryShows();

      expect(showsRepository.calls, 2);
      expect(moviesRepository.calls, 1);

      expect(cubit.state.shows, <LibraryShow>[_watchingShow]);

      expect(cubit.state.showsError, isNull);

      expect(cubit.state.movies, <LibraryMovie>[_watchlistMovie]);
    });

    test('retryMovies only reloads Movies', () async {
      final _CountingShowsRepository showsRepository =
          _CountingShowsRepository();

      final _RetryMoviesRepository moviesRepository = _RetryMoviesRepository();

      final LibraryCollectionCubit cubit = LibraryCollectionCubit(
        showsRepository: showsRepository,
        moviesRepository: moviesRepository,
      );

      addTearDown(cubit.close);

      await cubit.load();

      expect(showsRepository.calls, 1);
      expect(moviesRepository.calls, 1);

      expect(cubit.state.moviesError, isNotNull);

      expect(cubit.state.shows, <LibraryShow>[_watchingShow]);

      await cubit.retryMovies();

      expect(showsRepository.calls, 1);
      expect(moviesRepository.calls, 2);

      expect(cubit.state.movies, <LibraryMovie>[_watchlistMovie]);

      expect(cubit.state.moviesError, isNull);

      expect(cubit.state.shows, <LibraryShow>[_watchingShow]);
    });

    test('does not start another Show load while Shows are loading', () async {
      final _ControlledShowsRepository showsRepository =
          _ControlledShowsRepository();

      final LibraryCollectionCubit cubit = LibraryCollectionCubit(
        showsRepository: showsRepository,
        moviesRepository: const _MoviesRepository(),
      );

      addTearDown(cubit.close);

      final Future<void> firstLoad = cubit.loadShows();

      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.isLoadingShows, isTrue);
      expect(showsRepository.calls, 1);

      await cubit.loadShows();

      expect(showsRepository.calls, 1);

      showsRepository.complete(<LibraryShow>[_watchingShow]);

      await firstLoad;

      expect(cubit.state.isLoadingShows, isFalse);

      expect(cubit.state.shows, <LibraryShow>[_watchingShow]);
    });

    test(
      'does not start another Movie load while Movies are loading',
      () async {
        final _ControlledMoviesRepository moviesRepository =
            _ControlledMoviesRepository();

        final LibraryCollectionCubit cubit = LibraryCollectionCubit(
          showsRepository: const _ShowsRepository(),
          moviesRepository: moviesRepository,
        );

        addTearDown(cubit.close);

        final Future<void> firstLoad = cubit.loadMovies();

        await Future<void>.delayed(Duration.zero);

        expect(cubit.state.isLoadingMovies, isTrue);
        expect(moviesRepository.calls, 1);

        await cubit.loadMovies();

        expect(moviesRepository.calls, 1);

        moviesRepository.complete(<LibraryMovie>[_watchlistMovie]);

        await firstLoad;

        expect(cubit.state.isLoadingMovies, isFalse);

        expect(cubit.state.movies, <LibraryMovie>[_watchlistMovie]);
      },
    );
  });

  group('LibraryCollectionState', () {
    test('reports empty collections', () {
      const LibraryCollectionState state = LibraryCollectionState();

      expect(state.areShowsEmpty, isTrue);
      expect(state.areMoviesEmpty, isTrue);
    });

    test('reports combined loading state', () {
      const LibraryCollectionState idle = LibraryCollectionState();

      const LibraryCollectionState loadingShows = LibraryCollectionState(
        isLoadingShows: true,
      );

      const LibraryCollectionState loadingMovies = LibraryCollectionState(
        isLoadingMovies: true,
      );

      expect(idle.isLoading, isFalse);
      expect(loadingShows.isLoading, isTrue);
      expect(loadingMovies.isLoading, isTrue);
    });

    test('groups Shows by Library state and progress', () {
      final LibraryCollectionState state = LibraryCollectionState(
        shows: <LibraryShow>[
          _watchingShow,
          _upToDateShow,
          _planningShow,
          _completedShow,
          _pausedShow,
          _droppedShow,
        ],
      );

      expect(state.watchingShows, <LibraryShow>[_watchingShow]);

      expect(state.upToDateShows, <LibraryShow>[_upToDateShow]);

      expect(state.haventStartedShows, <LibraryShow>[_planningShow]);

      expect(state.finishedShows, <LibraryShow>[_completedShow]);

      expect(state.pausedShows, <LibraryShow>[_pausedShow]);

      expect(state.droppedShows, <LibraryShow>[_droppedShow]);
    });

    test('every supported Show state belongs to exactly one category', () {
      final LibraryCollectionState state = LibraryCollectionState(
        shows: <LibraryShow>[
          _watchingShow,
          _upToDateShow,
          _planningShow,
          _completedShow,
          _pausedShow,
          _droppedShow,
        ],
      );

      final List<LibraryShow> categorizedShows = <LibraryShow>[
        ...state.watchingShows,
        ...state.upToDateShows,
        ...state.haventStartedShows,
        ...state.finishedShows,
        ...state.pausedShows,
        ...state.droppedShows,
      ];

      expect(categorizedShows.length, state.shows.length);

      expect(categorizedShows.toSet(), state.shows.toSet());
    });

    test('Watching excludes caught-up Shows', () {
      final LibraryCollectionState state = LibraryCollectionState(
        shows: <LibraryShow>[_watchingShow, _upToDateShow],
      );

      expect(state.watchingShows, <LibraryShow>[_watchingShow]);

      expect(state.watchingShows, isNot(contains(_upToDateShow)));
    });

    test('Up to Date only includes caught-up Watching Shows', () {
      final LibraryCollectionState state = LibraryCollectionState(
        shows: <LibraryShow>[_watchingShow, _upToDateShow, _completedShow],
      );

      expect(state.upToDateShows, <LibraryShow>[_upToDateShow]);

      expect(state.upToDateShows, isNot(contains(_watchingShow)));

      expect(state.upToDateShows, isNot(contains(_completedShow)));
    });

    test('groups Movies into Watchlist, Upcoming and Watched', () {
      final LibraryCollectionState state = LibraryCollectionState(
        movies: <LibraryMovie>[_watchlistMovie, _upcomingMovie, _watchedMovie],
      );

      expect(state.watchlistMovies, <LibraryMovie>[_watchlistMovie]);

      expect(state.upcomingMovies, <LibraryMovie>[_upcomingMovie]);

      expect(state.watchedMovies, <LibraryMovie>[_watchedMovie]);
    });

    test('Upcoming Movies are not duplicated in Watchlist', () {
      final LibraryCollectionState state = LibraryCollectionState(
        movies: <LibraryMovie>[_watchlistMovie, _upcomingMovie],
      );

      expect(state.watchlistMovies, <LibraryMovie>[_watchlistMovie]);

      expect(state.upcomingMovies, <LibraryMovie>[_upcomingMovie]);

      expect(state.watchlistMovies, isNot(contains(_upcomingMovie)));
    });
  });
}

const LibraryShowProgress _inProgress = LibraryShowProgress(
  watchedEpisodes: 4,
  airedEpisodes: 10,
  percentage: 40,
  caughtUp: false,
);

const LibraryShowProgress _caughtUp = LibraryShowProgress(
  watchedEpisodes: 10,
  airedEpisodes: 10,
  percentage: 100,
  caughtUp: true,
);

const LibraryShowProgress _notStarted = LibraryShowProgress(
  watchedEpisodes: 0,
  airedEpisodes: 10,
  percentage: 0,
  caughtUp: false,
);

final DateTime _createdAt = DateTime.utc(2026, 8, 1);

final DateTime _updatedAt = DateTime.utc(2026, 8, 19);

final LibraryShow _watchingShow = _show(
  id: 'show-watching',
  tmdbId: 1,
  title: 'Watching',
  status: LibraryStatus.watching,
  progress: _inProgress,
);

final LibraryShow _upToDateShow = _show(
  id: 'show-up-to-date',
  tmdbId: 2,
  title: 'Up to Date',
  status: LibraryStatus.watching,
  progress: _caughtUp,
);

final LibraryShow _planningShow = _show(
  id: 'show-planning',
  tmdbId: 3,
  title: 'Planning',
  status: LibraryStatus.planning,
  progress: _notStarted,
);

final LibraryShow _completedShow = _show(
  id: 'show-completed',
  tmdbId: 4,
  title: 'Finished',
  status: LibraryStatus.completed,
  progress: _caughtUp,
);

final LibraryShow _pausedShow = _show(
  id: 'show-paused',
  tmdbId: 5,
  title: 'Paused',
  status: LibraryStatus.paused,
  progress: _inProgress,
);

final LibraryShow _droppedShow = _show(
  id: 'show-dropped',
  tmdbId: 6,
  title: 'Dropped',
  status: LibraryStatus.dropped,
  progress: _inProgress,
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
  tmdbId: 10,
  title: 'Watchlist',
  status: LibraryStatus.planning,
  releaseDate: DateTime.utc(2026, 1, 1),
);

final LibraryMovie _upcomingMovie = _movie(
  id: 'movie-upcoming',
  tmdbId: 11,
  title: 'Upcoming',
  status: LibraryStatus.planning,
  releaseDate: DateTime.utc(2099, 1, 1),
);

final LibraryMovie _watchedMovie = _movie(
  id: 'movie-watched',
  tmdbId: 12,
  title: 'Watched',
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
  const _ShowsRepository({this.shows = const <LibraryShow>[], this.error});

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
  const _MoviesRepository({this.movies = const <LibraryMovie>[], this.error});

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

final class _UnexpectedShowsRepository extends _ShowsRepository {
  const _UnexpectedShowsRepository();

  @override
  Future<List<LibraryShow>> getLibraryShows() {
    throw StateError('Unexpected Shows failure.');
  }
}

final class _UnexpectedMoviesRepository extends _MoviesRepository {
  const _UnexpectedMoviesRepository();

  @override
  Future<List<LibraryMovie>> getLibraryMovies() {
    throw StateError('Unexpected Movies failure.');
  }
}

final class _RetryShowsRepository extends _ShowsRepository {
  int calls = 0;

  @override
  Future<List<LibraryShow>> getLibraryShows() async {
    calls += 1;

    if (calls == 1) {
      throw const AppException.connection();
    }

    return <LibraryShow>[_watchingShow];
  }
}

final class _RetryMoviesRepository extends _MoviesRepository {
  int calls = 0;

  @override
  Future<List<LibraryMovie>> getLibraryMovies() async {
    calls += 1;

    if (calls == 1) {
      throw const AppException.connection();
    }

    return <LibraryMovie>[_watchlistMovie];
  }
}

final class _CountingShowsRepository extends _ShowsRepository {
  int calls = 0;

  @override
  Future<List<LibraryShow>> getLibraryShows() async {
    calls += 1;

    return <LibraryShow>[_watchingShow];
  }
}

final class _CountingMoviesRepository extends _MoviesRepository {
  int calls = 0;

  @override
  Future<List<LibraryMovie>> getLibraryMovies() async {
    calls += 1;

    return <LibraryMovie>[_watchlistMovie];
  }
}

final class _ControlledShowsRepository extends _ShowsRepository {
  final Completer<List<LibraryShow>> _result = Completer<List<LibraryShow>>();

  int calls = 0;

  void complete(List<LibraryShow> shows) {
    if (_result.isCompleted) {
      return;
    }

    _result.complete(shows);
  }

  @override
  Future<List<LibraryShow>> getLibraryShows() {
    calls += 1;

    return _result.future;
  }
}

final class _ControlledMoviesRepository extends _MoviesRepository {
  final Completer<List<LibraryMovie>> _result = Completer<List<LibraryMovie>>();

  int calls = 0;

  void complete(List<LibraryMovie> movies) {
    if (_result.isCompleted) {
      return;
    }

    _result.complete(movies);
  }

  @override
  Future<List<LibraryMovie>> getLibraryMovies() {
    calls += 1;

    return _result.future;
  }
}
