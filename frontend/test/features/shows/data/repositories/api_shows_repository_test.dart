import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/shows/data/repositories/api_shows_repository.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_show.dart';

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
    test('loads and maps Watch Next Shows', () async {
      dioAdapter.onGet('/library/shows/watch-next', (server) {
        server.reply(200, <Map<String, dynamic>>[
          <String, dynamic>{
            'library_entry_id': 'library-entry-1',
            'library_status': 'watching',
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
            'next_episode': <String, dynamic>{
              'id': 'episode-1',
              'tmdb_id': 1947648,
              'season_number': 2,
              'episode_number': 4,
              'title': "Woe's Hollow",
              'air_date': '2026-08-10',
              'runtime': 52,
              'still_url': 'https://example.com/still.jpg',
            },
          },
        ]);
      });

      final List<WatchNextShow> result = await repository.getWatchNext();

      expect(result, hasLength(1));

      final WatchNextShow item = result.single;

      expect(item.libraryEntryId, 'library-entry-1');
      expect(item.libraryStatus, LibraryStatus.watching);

      expect(item.showId, 'show-1');
      expect(item.showTmdbId, 95396);
      expect(item.showTitle, 'Severance');

      expect(item.posterUrl, 'https://example.com/poster.jpg');
      expect(item.backdropUrl, 'https://example.com/backdrop.jpg');

      expect(item.nextEpisode.id, 'episode-1');
      expect(item.nextEpisode.tmdbId, 1947648);
      expect(item.nextEpisode.seasonNumber, 2);
      expect(item.nextEpisode.episodeNumber, 4);
      expect(item.nextEpisode.code, 'S02E04');
      expect(item.nextEpisode.title, "Woe's Hollow");
      expect(item.nextEpisode.airDate, DateTime(2026, 8, 10));
      expect(item.nextEpisode.runtime, 52);
      expect(item.nextEpisode.stillUrl, 'https://example.com/still.jpg');
    });

    test('supports an empty Watch Next collection', () async {
      dioAdapter.onGet('/library/shows/watch-next', (server) {
        server.reply(200, <Map<String, dynamic>>[]);
      });

      final List<WatchNextShow> result = await repository.getWatchNext();

      expect(result, isEmpty);
    });

    test('maps malformed Watch Next data to invalidData', () async {
      dioAdapter.onGet('/library/shows/watch-next', (server) {
        server.reply(200, <Map<String, dynamic>>[
          <String, dynamic>{
            'library_entry_id': 'library-entry-1',
            'library_status': 'watching',
            'show': <String, dynamic>{
              'id': 'show-1',
              'tmdb_id': 95396,
              'title': 'Severance',
            },
            'next_episode': <String, dynamic>{
              'id': 'episode-1',
              'tmdb_id': 1947648,
              'season_number': 0,
              'episode_number': 4,
              'title': "Woe's Hollow",
            },
          },
        ]);
      });

      expect(
        repository.getWatchNext(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('propagates Watch Next API errors unchanged', () async {
      dioAdapter.onGet('/library/shows/watch-next', (server) {
        server.reply(500, <String, dynamic>{
          'code': 'server_error',
          'message': 'Something went wrong.',
        });
      });

      expect(
        repository.getWatchNext(),
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
