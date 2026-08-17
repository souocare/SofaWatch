import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/movies/data/repositories/api_movies_repository.dart';
import 'package:sofawatch/features/movies/domain/models/library_movie.dart';

void main() {
  group('ApiMoviesRepository', () {
    late ApiClient apiClient;
    late DioAdapter dioAdapter;
    late ApiMoviesRepository repository;

    setUp(() {
      apiClient = ApiClient(baseUrl: Uri.parse('http://localhost:8000'));

      dioAdapter = DioAdapter(dio: apiClient.dio, printLogs: false);

      repository = ApiMoviesRepository(apiClient);
    });

    test('loads and maps Movies from the Library', () async {
      dioAdapter.onGet('/library/movies', (server) {
        server.reply(200, <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'library-entry-1',
            'status': 'planning',
            'rating': null,
            'started_at': null,
            'completed_at': null,
            'created_at': '2026-08-01T10:00:00Z',
            'updated_at': '2026-08-10T10:00:00Z',
            'movie': <String, dynamic>{
              'id': 'movie-1',
              'tmdb_id': 438631,
              'title': 'Dune',
              'original_title': 'Dune',
              'release_date': '2021-10-22',
              'poster_url': 'https://example.com/dune-poster.jpg',
              'backdrop_url': 'https://example.com/dune-backdrop.jpg',
              'status': 'Released',
              'vote_average': 8.2,
            },
          },
          <String, dynamic>{
            'id': 'library-entry-2',
            'status': 'completed',
            'rating': 9.0,
            'started_at': null,
            'completed_at': '2026-08-14T21:00:00Z',
            'created_at': '2026-08-02T10:00:00Z',
            'updated_at': '2026-08-14T21:00:00Z',
            'movie': <String, dynamic>{
              'id': 'movie-2',
              'tmdb_id': 157336,
              'title': 'Interstellar',
              'original_title': 'Interstellar',
              'release_date': '2014-11-07',
              'poster_url': null,
              'backdrop_url': null,
              'status': 'Released',
              'vote_average': 8.5,
            },
          },
        ]);
      });

      final List<LibraryMovie> result = await repository.getLibraryMovies();

      expect(result, hasLength(2));

      expect(result[0].libraryEntryId, 'library-entry-1');
      expect(result[0].movieId, 'movie-1');
      expect(result[0].tmdbId, 438631);
      expect(result[0].title, 'Dune');
      expect(result[0].originalTitle, 'Dune');
      expect(result[0].releaseDate, DateTime(2021, 10, 22));
      expect(result[0].posterUrl, 'https://example.com/dune-poster.jpg');
      expect(result[0].backdropUrl, 'https://example.com/dune-backdrop.jpg');
      expect(result[0].status, LibraryStatus.planning);
      expect(result[0].movieStatus, 'Released');
      expect(result[0].voteAverage, 8.2);
      expect(result[0].rating, isNull);

      expect(result[1].libraryEntryId, 'library-entry-2');
      expect(result[1].movieId, 'movie-2');
      expect(result[1].tmdbId, 157336);
      expect(result[1].title, 'Interstellar');
      expect(result[1].status, LibraryStatus.completed);
      expect(result[1].rating, 9.0);
      expect(result[1].posterUrl, isNull);
      expect(result[1].backdropUrl, isNull);

      expect(result[1].completedAt, DateTime.utc(2026, 8, 14, 21));
    });

    test('supports an empty Movie Library', () async {
      dioAdapter.onGet('/library/movies', (server) {
        server.reply(200, <Map<String, dynamic>>[]);
      });

      final List<LibraryMovie> result = await repository.getLibraryMovies();

      expect(result, isEmpty);
    });

    test('maps malformed Library Movie data to invalidData', () async {
      dioAdapter.onGet('/library/movies', (server) {
        server.reply(200, <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'library-entry-1',
            'status': 'planning',
            'rating': null,
            'started_at': null,
            'completed_at': null,
            'created_at': '2026-08-01T10:00:00Z',
            'updated_at': '2026-08-10T10:00:00Z',

            // Invalid API contract.
            'movie': <String, dynamic>{
              'id': 'movie-1',
              'tmdb_id': 0,
              'title': 'Dune',
              'original_title': 'Dune',
              'release_date': null,
              'poster_url': null,
              'backdrop_url': null,
              'status': 'Released',
              'vote_average': 8.2,
            },
          },
        ]);
      });

      expect(
        repository.getLibraryMovies(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('maps invalid Library Movie response items to invalidData', () async {
      dioAdapter.onGet('/library/movies', (server) {
        server.reply(200, <dynamic>['not-a-map']);
      });

      expect(
        repository.getLibraryMovies(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('propagates API errors unchanged', () async {
      dioAdapter.onGet('/library/movies', (server) {
        server.reply(500, <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'internal_error',
            'message': 'Unexpected error.',
          },
        });
      });

      expect(repository.getLibraryMovies(), throwsA(isA<AppException>()));
    });
  });
}
