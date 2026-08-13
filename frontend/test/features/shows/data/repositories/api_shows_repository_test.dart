import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/shows/data/repositories/api_shows_repository.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';

void main() {
  group('ApiShowsRepository', () {
    late ApiClient apiClient;
    late DioAdapter dioAdapter;
    late ApiShowsRepository repository;

    setUp(() {
      apiClient = ApiClient(baseUrl: Uri.parse('http://localhost:8000'));

      dioAdapter = DioAdapter(dio: apiClient.dio, printLogs: false);

      repository = ApiShowsRepository(apiClient);
    });

    test('loads and maps Shows from the Library', () async {
      dioAdapter.onGet('/library/shows', (server) {
        server.reply(200, <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'library-entry-1',
            'status': 'watching',
            'rating': 9.0,
            'started_at': '2026-08-01T20:00:00Z',
            'completed_at': null,
            'created_at': '2026-07-01T10:00:00Z',
            'updated_at': '2026-08-10T10:00:00Z',
            'show': <String, dynamic>{
              'id': 'show-1',
              'tmdb_id': 95396,
              'title': 'Severance',
              'original_title': 'Severance',
              'first_air_date': '2022-02-18',
              'tmdb_poster_path': '/poster.jpg',
              'local_poster_path': null,
              'poster_url': 'https://example.com/poster.jpg',
              'backdrop_url': 'https://example.com/backdrop.jpg',
              'status': 'Returning Series',
              'vote_average': 8.4,
            },
          },
          <String, dynamic>{
            'id': 'library-entry-2',
            'status': 'planning',
            'rating': null,
            'started_at': null,
            'completed_at': null,
            'created_at': '2026-08-01T10:00:00Z',
            'updated_at': '2026-08-02T10:00:00Z',
            'show': <String, dynamic>{
              'id': 'show-2',
              'tmdb_id': 1396,
              'title': 'Breaking Bad',
              'original_title': 'Breaking Bad',
              'first_air_date': '2008-01-20',
              'tmdb_poster_path': null,
              'local_poster_path': null,
              'poster_url': null,
              'backdrop_url': null,
              'status': 'Ended',
              'vote_average': 8.9,
            },
          },
        ]);
      });

      final List<LibraryShow> result = await repository.getLibraryShows();

      expect(result, hasLength(2));

      expect(result[0].libraryEntryId, 'library-entry-1');
      expect(result[0].showId, 'show-1');
      expect(result[0].tmdbId, 95396);
      expect(result[0].title, 'Severance');
      expect(result[0].status, LibraryStatus.watching);
      expect(result[0].showStatus, 'Returning Series');
      expect(result[0].voteAverage, 8.4);
      expect(result[0].rating, 9.0);

      expect(result[1].libraryEntryId, 'library-entry-2');
      expect(result[1].tmdbId, 1396);
      expect(result[1].title, 'Breaking Bad');
      expect(result[1].status, LibraryStatus.planning);
      expect(result[1].showStatus, 'Ended');
      expect(result[1].posterUrl, isNull);
    });

    test('supports an empty Library', () async {
      dioAdapter.onGet('/library/shows', (server) {
        server.reply(200, <Map<String, dynamic>>[]);
      });

      final List<LibraryShow> result = await repository.getLibraryShows();

      expect(result, isEmpty);
    });

    test('maps malformed Library Show data to invalidData', () async {
      dioAdapter.onGet('/library/shows', (server) {
        server.reply(200, <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'library-entry-1',
            'status': 'watching',
            'rating': null,
            'started_at': null,
            'completed_at': null,
            'created_at': '2026-07-01T10:00:00Z',
            'updated_at': '2026-08-10T10:00:00Z',
            'show': <String, dynamic>{
              // tmdb_id intentionally missing
              'id': 'show-1',
              'title': 'Severance',
              'original_title': 'Severance',
              'first_air_date': '2022-02-18',
              'poster_url': null,
              'backdrop_url': null,
              'status': 'Returning Series',
              'vote_average': 8.4,
            },
          },
        ]);
      });

      expect(
        repository.getLibraryShows(),
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
      dioAdapter.onGet('/library/shows', (server) {
        server.reply(500, <String, dynamic>{
          'code': 'server_error',
          'message': 'Something went wrong.',
        });
      });

      expect(
        repository.getLibraryShows(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.server,
          ),
        ),
      );
    });
  });
}
