import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/movies/application/cubit/movies_cubit.dart';
import 'package:sofawatch/features/movies/application/models/movies_filter.dart';
import 'package:sofawatch/features/movies/application/models/movies_sort.dart';
import 'package:sofawatch/features/movies/domain/models/library_movie.dart';
import 'package:sofawatch/features/movies/domain/repositories/movies_repository.dart';

void main() {
  group('MoviesCubit', () {
    test('starts with an empty Movies state', () async {
      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(),
      );

      expect(cubit.state.libraryMovies, isEmpty);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.error, isNull);
      expect(cubit.state.isRefreshing, isFalse);
      expect(cubit.state.refreshError, isNull);

      await cubit.close();
    });

    test('loads Movies from the Library', () async {
      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(
          movies: <LibraryMovie>[_watchlistMovie, _watchedMovie],
        ),
      );

      await cubit.load();

      expect(cubit.state.libraryMovies, <LibraryMovie>[
        _watchlistMovie,
        _watchedMovie,
      ]);

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.error, isNull);

      await cubit.close();
    });

    test('supports an empty Movie Library', () async {
      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(),
      );

      await cubit.load();

      expect(cubit.state.libraryMovies, isEmpty);
      expect(cubit.state.isLibraryEmpty, isTrue);
      expect(cubit.state.error, isNull);

      await cubit.close();
    });

    test('preserves AppException when initial load fails', () async {
      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(
          loadError: const AppException.connection(),
        ),
      );

      await cubit.load();

      expect(cubit.state.libraryMovies, isEmpty);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.error, isA<AppException>());

      await cubit.close();
    });

    test('maps unexpected initial load failure to unknown', () async {
      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(unexpectedError: StateError('boom')),
      );

      await cubit.load();

      expect(cubit.state.libraryMovies, isEmpty);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.error, isNotNull);

      await cubit.close();
    });

    test('retry repeats the initial load', () async {
      final _RetryMoviesRepository repository = _RetryMoviesRepository();

      final MoviesCubit cubit = MoviesCubit(repository: repository);

      await cubit.load();

      expect(repository.calls, 1);
      expect(cubit.state.error, isNotNull);

      await cubit.retry();

      expect(repository.calls, 2);
      expect(cubit.state.libraryMovies, <LibraryMovie>[_watchlistMovie]);
      expect(cubit.state.error, isNull);

      await cubit.close();
    });

    test('does not start duplicate initial loads', () async {
      final _ControlledMoviesRepository repository =
          _ControlledMoviesRepository();

      final MoviesCubit cubit = MoviesCubit(repository: repository);

      final Future<void> firstLoad = cubit.load();

      await repository.requested.future;

      final Future<void> secondLoad = cubit.load();

      expect(repository.calls, 1);

      repository.complete(<LibraryMovie>[_watchlistMovie]);

      await Future.wait(<Future<void>>[firstLoad, secondLoad]);

      expect(repository.calls, 1);

      expect(cubit.state.libraryMovies, <LibraryMovie>[_watchlistMovie]);

      await cubit.close();
    });

    test('refresh replaces Movies with fresh Library data', () async {
      final _SequencedMoviesRepository repository = _SequencedMoviesRepository(
        responses: <List<LibraryMovie>>[
          <LibraryMovie>[_watchlistMovie],
          <LibraryMovie>[_watchedMovie],
        ],
      );

      final MoviesCubit cubit = MoviesCubit(repository: repository);

      await cubit.load();

      expect(cubit.state.libraryMovies, <LibraryMovie>[_watchlistMovie]);

      await cubit.refresh();

      expect(repository.calls, 2);

      expect(cubit.state.libraryMovies, <LibraryMovie>[_watchedMovie]);

      expect(cubit.state.isRefreshing, isFalse);
      expect(cubit.state.refreshError, isNull);

      await cubit.close();
    });

    test('preserves loaded Movies when refresh fails', () async {
      final _RefreshFailureMoviesRepository repository =
          _RefreshFailureMoviesRepository();

      final MoviesCubit cubit = MoviesCubit(repository: repository);

      await cubit.load();

      expect(cubit.state.libraryMovies, <LibraryMovie>[_watchlistMovie]);

      await cubit.refresh();

      expect(repository.calls, 2);

      expect(cubit.state.libraryMovies, <LibraryMovie>[_watchlistMovie]);

      expect(cubit.state.isRefreshing, isFalse);
      expect(cubit.state.refreshError, isA<AppException>());
      expect(cubit.state.error, isNull);

      await cubit.close();
    });

    test('maps unexpected refresh failure to unknown', () async {
      final _UnexpectedRefreshMoviesRepository repository =
          _UnexpectedRefreshMoviesRepository();

      final MoviesCubit cubit = MoviesCubit(repository: repository);

      await cubit.load();
      await cubit.refresh();

      expect(cubit.state.libraryMovies, <LibraryMovie>[_watchlistMovie]);

      expect(cubit.state.refreshError, isNotNull);
      expect(cubit.state.isRefreshing, isFalse);

      await cubit.close();
    });

    test('ignores a second refresh while refresh is running', () async {
      final _ControlledRefreshMoviesRepository repository =
          _ControlledRefreshMoviesRepository();

      final MoviesCubit cubit = MoviesCubit(repository: repository);

      await cubit.load();

      final Future<void> firstRefresh = cubit.refresh();

      await repository.refreshRequested.future;

      final Future<void> secondRefresh = cubit.refresh();

      expect(repository.calls, 2);

      repository.completeRefresh(<LibraryMovie>[_watchedMovie]);

      await Future.wait(<Future<void>>[firstRefresh, secondRefresh]);

      expect(repository.calls, 2);

      expect(cubit.state.libraryMovies, <LibraryMovie>[_watchedMovie]);

      await cubit.close();
    });

    test('derives Watchlist from planning Movies', () async {
      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(),
      );

      final state = cubit.state.copyWith(
        libraryMovies: <LibraryMovie>[
          _watchlistMovie,
          _watchedMovie,
          _pausedMovie,
        ],
      );

      expect(state.watchlist, <LibraryMovie>[_watchlistMovie]);

      expect(state.isWatchlistEmpty, isFalse);

      await cubit.close();
    });

    test('derives Watched from completed Movies', () async {
      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(),
      );

      final state = cubit.state.copyWith(
        libraryMovies: <LibraryMovie>[
          _watchlistMovie,
          _watchedMovie,
          _pausedMovie,
        ],
      );

      expect(state.watched, <LibraryMovie>[_watchedMovie]);

      expect(state.isWatchedEmpty, isFalse);

      await cubit.close();
    });

    test('derives Coming Soon from future planning Movies', () async {
      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(),
      );

      final state = cubit.state.copyWith(
        libraryMovies: <LibraryMovie>[
          _watchlistMovie,
          _watchedMovie,
          _comingSoonMovie,
        ],
      );

      expect(state.comingSoon, <LibraryMovie>[_comingSoonMovie]);

      expect(state.isComingSoonEmpty, isFalse);

      await cubit.close();
    });

    test('Coming Soon does not include completed future Movies', () async {
      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(),
      );

      final LibraryMovie completedFutureMovie = LibraryMovie(
        libraryEntryId: 'library-entry-future-completed',
        movieId: 'movie-future-completed',
        tmdbId: 999998,
        title: 'Completed Future Movie',
        originalTitle: 'Completed Future Movie',
        status: LibraryStatus.completed,
        movieStatus: 'Post Production',
        voteAverage: 0,
        releaseDate: DateTime(2099, 2, 1),
        createdAt: DateTime.utc(2026, 8, 1),
        updatedAt: DateTime.utc(2026, 8, 10),
      );

      final state = cubit.state.copyWith(
        libraryMovies: <LibraryMovie>[completedFutureMovie],
      );

      expect(state.comingSoon, isEmpty);
      expect(state.isComingSoonEmpty, isTrue);

      await cubit.close();
    });
    test('search matches Movie original title', () async {
      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(),
      );

      final LibraryMovie movie = LibraryMovie(
        libraryEntryId: 'library-entry-original-title',
        movieId: 'movie-original-title',
        tmdbId: 1234567,
        title: 'Spirited Away',
        originalTitle: '千と千尋の神隠し',
        status: LibraryStatus.planning,
        movieStatus: 'Released',
        voteAverage: 8.5,
        releaseDate: DateTime(2001, 7, 20),
        createdAt: DateTime.utc(2026, 8, 1),
        updatedAt: DateTime.utc(2026, 8, 10),
      );

      final state = cubit.state.copyWith(
        libraryMovies: <LibraryMovie>[movie, _watchlistMovie],
        searchQuery: '千と千尋',
      );

      expect(state.visibleMovies, <LibraryMovie>[movie]);

      await cubit.close();
    });
    test('release date sorting keeps Movies without a date last', () async {
      final MoviesCubit cubit = MoviesCubit(
        repository: _FakeMoviesRepository(),
      );

      final LibraryMovie unknownReleaseMovie = LibraryMovie(
        libraryEntryId: 'library-entry-no-release',
        movieId: 'movie-no-release',
        tmdbId: 7654321,
        title: 'Unknown Release',
        originalTitle: 'Unknown Release',
        status: LibraryStatus.planning,
        movieStatus: 'Released',
        voteAverage: 7,
        createdAt: DateTime.utc(2026, 8, 1),
        updatedAt: DateTime.utc(2026, 8, 10),
      );

      final state = cubit.state.copyWith(
        libraryMovies: <LibraryMovie>[
          unknownReleaseMovie,
          _watchedMovie,
          _watchlistMovie,
        ],
        sort: MoviesSort.releaseDateNewest,
      );

      expect(state.visibleMovies, <LibraryMovie>[
        _watchlistMovie,
        _watchedMovie,
        unknownReleaseMovie,
      ]);

      await cubit.close();
    });
  });
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

final LibraryMovie _pausedMovie = LibraryMovie(
  libraryEntryId: 'library-entry-3',
  movieId: 'movie-3',
  tmdbId: 123456,
  title: 'Paused Movie',
  originalTitle: 'Paused Movie',
  status: LibraryStatus.paused,
  movieStatus: 'Released',
  voteAverage: 7,
  releaseDate: DateTime(2020, 1, 1),
  createdAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 10),
);

final LibraryMovie _comingSoonMovie = LibraryMovie(
  libraryEntryId: 'library-entry-4',
  movieId: 'movie-4',
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
  _FakeMoviesRepository({
    this.movies = const <LibraryMovie>[],
    this.loadError,
    this.unexpectedError,
  });

  final List<LibraryMovie> movies;

  final AppException? loadError;

  final Object? unexpectedError;

  @override
  Future<List<LibraryMovie>> getLibraryMovies() async {
    final AppException? error = loadError;

    if (error != null) {
      throw error;
    }

    final Object? unknownError = unexpectedError;

    if (unknownError != null) {
      throw unknownError;
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

final class _ControlledMoviesRepository implements MoviesRepository {
  int calls = 0;

  final Completer<void> requested = Completer<void>();

  final Completer<List<LibraryMovie>> _result = Completer<List<LibraryMovie>>();

  void complete(List<LibraryMovie> movies) {
    if (_result.isCompleted) {
      return;
    }

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

final class _UnexpectedRefreshMoviesRepository implements MoviesRepository {
  int calls = 0;

  @override
  Future<List<LibraryMovie>> getLibraryMovies() async {
    calls++;

    if (calls == 1) {
      return <LibraryMovie>[_watchlistMovie];
    }

    throw StateError('boom');
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
