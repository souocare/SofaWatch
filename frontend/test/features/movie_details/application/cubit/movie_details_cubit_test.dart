import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/movie_details/application/cubit/movie_details_cubit.dart';
import 'package:sofawatch/features/movie_details/application/cubit/movie_details_state.dart';
import 'package:sofawatch/features/movie_details/domain/models/movie_details.dart';
import 'package:sofawatch/features/movie_details/domain/models/movie_details_reference.dart';
import 'package:sofawatch/features/movie_details/domain/repositories/movie_details_repository.dart';

void main() {
  group('MovieDetailsCubit', () {
    test('loads movie details by TMDB ID', () async {
      final _FakeMovieDetailsRepository repository =
          _FakeMovieDetailsRepository();

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        reference: const TmdbMovieDetailsReference(438631),
      );

      final Future<List<MovieDetailsState>> statesFuture = cubit.stream
          .take(2)
          .toList();

      await cubit.load();

      final List<MovieDetailsState> states = await statesFuture;

      expect(states, <MovieDetailsState>[
        const MovieDetailsLoading(),
        const MovieDetailsSuccess(_movieDetails),
      ]);

      expect(repository.requestedTmdbId, 438631);

      await cubit.close();
    });

    test('emits failure when the repository fails', () async {
      final _FakeMovieDetailsRepository repository =
          _FakeMovieDetailsRepository(error: const AppException.connection());

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        reference: const TmdbMovieDetailsReference(438631),
      );

      final Future<List<MovieDetailsState>> statesFuture = cubit.stream
          .take(2)
          .toList();

      await cubit.load();

      final List<MovieDetailsState> states = await statesFuture;

      expect(states.first, const MovieDetailsLoading());
      expect(states.last, isA<MovieDetailsFailure>());

      await cubit.close();
    });

    test('retry loads the same movie again', () async {
      final _FakeMovieDetailsRepository repository =
          _FakeMovieDetailsRepository();

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        reference: const TmdbMovieDetailsReference(438631),
      );

      await cubit.load();
      await cubit.retry();

      expect(repository.requestCount, 2);
      expect(repository.requestedTmdbId, 438631);

      await cubit.close();
    });

    test('maps unexpected repository errors to unknown failure', () async {
      final _UnexpectedMovieDetailsRepository repository =
          _UnexpectedMovieDetailsRepository();

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        reference: const TmdbMovieDetailsReference(438631),
      );

      final Future<List<MovieDetailsState>> statesFuture = cubit.stream
          .take(2)
          .toList();

      await cubit.load();

      final List<MovieDetailsState> states = await statesFuture;

      expect(states.first, const MovieDetailsLoading());

      final MovieDetailsFailure failure = states.last as MovieDetailsFailure;

      expect(failure.error.type, AppExceptionType.unknown);

      await cubit.close();
    });
    test('loads movie details by internal movie id', () async {
      final _FakeMovieDetailsRepository repository =
          _FakeMovieDetailsRepository();

      final MovieDetailsCubit cubit = MovieDetailsCubit(
        repository: repository,
        reference: const LocalMovieDetailsReference(
          '11111111-1111-1111-1111-111111111111',
        ),
      );

      await cubit.load();

      expect(
        repository.requestedMovieId,
        '11111111-1111-1111-1111-111111111111',
      );
      expect(repository.requestedTmdbId, isNull);
      expect(cubit.state, const MovieDetailsSuccess(_movieDetails));

      await cubit.close();
    });
  });
}

const MovieDetails _movieDetails = MovieDetails(
  tmdbId: 438631,
  title: 'Dune',
  originalTitle: 'Dune',
  overview: 'Paul Atreides travels to Arrakis.',
  tagline: 'Beyond fear, destiny awaits.',
  genres: <String>['Science Fiction', 'Adventure'],
  originalLanguage: 'en',
  runtime: 155,
  status: 'Released',
  voteAverage: 7.8,
  voteCount: 13000,
);

final class _FakeMovieDetailsRepository implements MovieDetailsRepository {
  _FakeMovieDetailsRepository({this.error});

  final AppException? error;

  String? requestedMovieId;
  int? requestedTmdbId;
  int requestCount = 0;

  @override
  Future<MovieDetails> getById(String movieId) async {
    requestedMovieId = movieId;
    requestCount++;

    final AppException? repositoryError = error;

    if (repositoryError != null) {
      throw repositoryError;
    }

    return _movieDetails;
  }

  @override
  Future<MovieDetails> getByTmdbId(int tmdbId, {String? language}) async {
    requestedTmdbId = tmdbId;
    requestCount++;

    final AppException? repositoryError = error;

    if (repositoryError != null) {
      throw repositoryError;
    }

    return _movieDetails;
  }
}

final class _UnexpectedMovieDetailsRepository
    implements MovieDetailsRepository {
  @override
  Future<MovieDetails> getById(String movieId) async {
    throw StateError('Unexpected repository failure.');
  }

  @override
  Future<MovieDetails> getByTmdbId(int tmdbId, {String? language}) async {
    throw StateError('Unexpected repository failure.');
  }
}
