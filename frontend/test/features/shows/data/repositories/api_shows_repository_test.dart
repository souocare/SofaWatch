import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/shows/data/repositories/api_shows_repository.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_show.dart';
import 'package:sofawatch/features/shows/domain/models/stale_watching_show.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_page.dart';
import 'package:sofawatch/features/shows/domain/models/upcoming_item.dart';

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
            'first_available_episode': null,
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
            'first_available_episode': <String, dynamic>{
              'id': 'episode-1',
              'tmdb_id': 62085,
              'season_number': 1,
              'episode_number': 1,
              'title': 'Pilot',
              'air_date': '2008-01-20',
              'runtime': 58,
            },
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
      expect(result[0].firstAvailableEpisode, isNull);

      final firstEpisode = result[1].firstAvailableEpisode;

      expect(firstEpisode, isNotNull);
      expect(firstEpisode!.id, 'episode-1');
      expect(firstEpisode.tmdbId, 62085);
      expect(firstEpisode.seasonNumber, 1);
      expect(firstEpisode.episodeNumber, 1);
      expect(firstEpisode.code, 'S01E01');
      expect(firstEpisode.title, 'Pilot');
      expect(firstEpisode.airDate, DateTime(2008, 1, 20));
      expect(firstEpisode.runtime, 58);
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
            'progress': <String, dynamic>{
              'watched_episodes': 7,
              'aired_episodes': 10,
              'percentage': 70.0,
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
      expect(item.progress.watchedEpisodes, 7);
      expect(item.progress.airedEpisodes, 10);
      expect(item.progress.percentage, 70.0);
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
            'progress': <String, dynamic>{
              'watched_episodes': 7,
              'aired_episodes': 10,
              'percentage': 70.0,
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
    test('loads and maps stale Watching Shows', () async {
      dioAdapter.onGet('/library/shows/stale-watching', (server) {
        server.reply(200, <Map<String, dynamic>>[
          <String, dynamic>{
            'library_entry_id': 'library-entry-1',
            'library_status': 'watching',
            'show': <String, dynamic>{
              'id': 'show-1',
              'tmdb_id': 95396,
              'title': 'Severance',
              'poster_url': 'https://example.com/poster.jpg',
              'backdrop_url': 'https://example.com/backdrop.jpg',
            },
            'last_watched': <String, dynamic>{
              'id': 'episode-1',
              'tmdb_id': 1001,
              'season_number': 1,
              'episode_number': 3,
              'title': 'In Perpetuity',
              'air_date': '2022-03-04',
              'runtime': 50,
              'still_url': 'https://example.com/last.jpg',
              'watched_at': '2026-05-01T20:00:00Z',
            },
            'next_episode': <String, dynamic>{
              'id': 'episode-2',
              'tmdb_id': 1002,
              'season_number': 1,
              'episode_number': 4,
              'title': 'The You You Are',
              'air_date': '2022-03-11',
              'runtime': 51,
              'still_url': 'https://example.com/next.jpg',
            },
          },
        ]);
      });

      final List<StaleWatchingShow> result = await repository
          .getStaleWatching();

      expect(result, hasLength(1));

      final StaleWatchingShow item = result.single;

      expect(item.libraryEntryId, 'library-entry-1');
      expect(item.libraryStatus, LibraryStatus.watching);

      expect(item.showId, 'show-1');
      expect(item.showTmdbId, 95396);
      expect(item.showTitle, 'Severance');

      expect(
        item.lastWatched.watchedAt,
        DateTime.parse('2026-05-01T20:00:00Z'),
      );

      expect(item.lastWatched.code, 'S01E03');
      expect(item.nextEpisode.code, 'S01E04');
      expect(item.nextEpisode.title, 'The You You Are');
    });

    test('supports an empty stale Watching collection', () async {
      dioAdapter.onGet('/library/shows/stale-watching', (server) {
        server.reply(200, <Map<String, dynamic>>[]);
      });

      final List<StaleWatchingShow> result = await repository
          .getStaleWatching();

      expect(result, isEmpty);
    });

    test('maps malformed stale Watching data to invalidData', () async {
      dioAdapter.onGet('/library/shows/stale-watching', (server) {
        server.reply(200, <Map<String, dynamic>>[
          <String, dynamic>{
            'library_entry_id': 'library-entry-1',
            'library_status': 'watching',
            'show': <String, dynamic>{
              'id': 'show-1',
              'tmdb_id': 95396,
              'title': 'Severance',
            },
            'last_watched': <String, dynamic>{
              'id': 'episode-1',
              'tmdb_id': 1001,
              'season_number': 1,
              'episode_number': 3,
              'title': 'In Perpetuity',
              'watched_at': 'not-a-date',
            },
            'next_episode': <String, dynamic>{
              'id': 'episode-2',
              'tmdb_id': 1002,
              'season_number': 1,
              'episode_number': 4,
              'title': 'The You You Are',
            },
          },
        ]);
      });

      expect(
        repository.getStaleWatching(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('propagates stale Watching API errors unchanged', () async {
      dioAdapter.onGet('/library/shows/stale-watching', (server) {
        server.reply(500, <String, dynamic>{
          'code': 'server_error',
          'message': 'Something went wrong.',
        });
      });

      expect(
        repository.getStaleWatching(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.server,
          ),
        ),
      );
    });
    test('loads and maps the first Watch History page', () async {
      dioAdapter.onGet(
        '/library/shows/watch-history',
        (server) {
          server.reply(200, <String, dynamic>{
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'event_id': '550e8400-e29b-41d4-a716-446655440001',
                'show': <String, dynamic>{
                  'id': 'show-1',
                  'tmdb_id': 95396,
                  'title': 'Severance',
                  'original_title': 'Severance',
                  'first_air_date': '2022-02-18',
                  'tmdb_poster_path': null,
                  'local_poster_path': null,
                  'poster_url': 'https://example.com/poster.jpg',
                  'backdrop_url': 'https://example.com/backdrop.jpg',
                  'status': 'Returning Series',
                  'vote_average': 8.4,
                },
                'episode': <String, dynamic>{
                  'id': 'episode-1',
                  'tmdb_id': 1947648,
                  'season_number': 2,
                  'episode_number': 4,
                  'title': "Woe's Hollow",
                  'air_date': '2026-08-10',
                  'runtime': 52,
                  'still_url': 'https://example.com/still.jpg',
                  'watched_at': '2026-08-13T20:00:00Z',
                  'watch_count': 2,
                },
              },
            ],
            'next_cursor': null,
            'has_more': false,
          });
        },
        queryParameters: <String, dynamic>{'limit': 30},
      );

      final WatchHistoryPage result = await repository.getWatchHistory();

      expect(result.items, hasLength(1));
      expect(result.hasMore, isFalse);
      expect(result.nextCursor, isNull);

      final item = result.items.single;

      expect(item.eventId, '550e8400-e29b-41d4-a716-446655440001');

      expect(item.showId, 'show-1');
      expect(item.showTmdbId, 95396);
      expect(item.showTitle, 'Severance');
      expect(item.posterUrl, 'https://example.com/poster.jpg');

      expect(item.episode.id, 'episode-1');
      expect(item.episode.tmdbId, 1947648);
      expect(item.episode.seasonNumber, 2);
      expect(item.episode.episodeNumber, 4);
      expect(item.episode.code, 'S02E04');
      expect(item.episode.title, "Woe's Hollow");
      expect(item.episode.runtime, 52);
      expect(item.episode.watchCount, 2);
      expect(item.episode.watchedAt, DateTime.parse('2026-08-13T20:00:00Z'));
    });

    test('forwards Watch History cursor and maps next page', () async {
      const String cursor = 'opaque-cursor';

      dioAdapter.onGet(
        '/library/shows/watch-history',
        (server) {
          server.reply(200, <String, dynamic>{
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'event_id': '550e8400-e29b-41d4-a716-446655440002',
                'show': <String, dynamic>{
                  'id': 'show-2',
                  'tmdb_id': 100088,
                  'title': 'The Last of Us',
                  'original_title': 'The Last of Us',
                  'first_air_date': '2023-01-15',
                  'tmdb_poster_path': null,
                  'local_poster_path': null,
                  'poster_url': null,
                  'backdrop_url': null,
                  'status': 'Returning Series',
                  'vote_average': 8.6,
                },
                'episode': <String, dynamic>{
                  'id': 'episode-2',
                  'tmdb_id': 3000001,
                  'season_number': 1,
                  'episode_number': 3,
                  'title': 'Long, Long Time',
                  'air_date': '2023-01-29',
                  'runtime': 76,
                  'still_url': null,
                  'watched_at': '2026-07-01T21:00:00Z',
                  'watch_count': 1,
                },
              },
            ],
            'next_cursor': 'next-opaque-cursor',
            'has_more': true,
          });
        },
        queryParameters: <String, dynamic>{'limit': 20, 'cursor': cursor},
      );

      final WatchHistoryPage result = await repository.getWatchHistory(
        limit: 20,
        cursor: cursor,
      );

      expect(result.items, hasLength(1));
      expect(result.hasMore, isTrue);
      expect(result.nextCursor, 'next-opaque-cursor');

      final item = result.items.single;

      expect(item.eventId, '550e8400-e29b-41d4-a716-446655440002');

      expect(item.showTitle, 'The Last of Us');
      expect(item.episode.code, 'S01E03');
      expect(item.episode.watchCount, 1);
    });

    test('supports an empty Watch History page', () async {
      dioAdapter.onGet(
        '/library/shows/watch-history',
        (server) {
          server.reply(200, <String, dynamic>{
            'items': <dynamic>[],
            'next_cursor': null,
            'has_more': false,
          });
        },
        queryParameters: <String, dynamic>{'limit': 30},
      );

      final WatchHistoryPage result = await repository.getWatchHistory();

      expect(result.items, isEmpty);
      expect(result.nextCursor, isNull);
      expect(result.hasMore, isFalse);
    });
    test('maps malformed Watch History data to invalidData', () async {
      dioAdapter.onGet(
        '/library/shows/watch-history',
        (server) {
          server.reply(200, <String, dynamic>{
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'event_id': '550e8400-e29b-41d4-a716-446655440003',
                'show': <String, dynamic>{
                  'id': 'show-1',
                  'tmdb_id': 95396,
                  'title': 'Severance',
                },
                'episode': <String, dynamic>{
                  'id': 'episode-1',
                  'tmdb_id': 1947648,
                  'season_number': 2,
                  'episode_number': 4,
                  'title': "Woe's Hollow",
                  'watch_count': 1,

                  // watched_at intentionally missing
                },
              },
            ],
            'next_cursor': null,
            'has_more': false,
          });
        },
        queryParameters: <String, dynamic>{'limit': 30},
      );

      expect(
        repository.getWatchHistory(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });
    test('propagates Watch History API errors unchanged', () async {
      dioAdapter.onGet(
        '/library/shows/watch-history',
        (server) {
          server.reply(500, <String, dynamic>{
            'code': 'server_error',
            'message': 'Something went wrong.',
          });
        },
        queryParameters: <String, dynamic>{'limit': 30},
      );

      expect(
        repository.getWatchHistory(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.server,
          ),
        ),
      );
    });
    test('maps malformed Watch Next progress to invalidData', () async {
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
              'season_number': 2,
              'episode_number': 4,
              'title': "Woe's Hollow",
            },
            'progress': <String, dynamic>{
              'watched_episodes': 7,
              'aired_episodes': 10,
              'percentage': 120.0,
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
    test('marks an Episode as watched', () async {
      dioAdapter.onPost('/episodes/episode-uuid/watched', (server) {
        server.reply(200, <String, dynamic>{
          'episode_id': 'episode-uuid',
          'is_watched': true,
          'watched_at': '2026-08-13T20:00:00Z',
        });
      }, data: <String, dynamic>{'watched_at': null});

      await repository.markEpisodeWatched(episodeId: 'episode-uuid');
    });

    test('marks an Episode as unwatched', () async {
      dioAdapter.onDelete('/episodes/episode-uuid/watched', (server) {
        server.reply(200, <String, dynamic>{
          'id': 'progress-uuid',
          'episode_id': 'episode-uuid',
          'is_watched': false,
          'watched_at': null,
        });
      });

      await repository.markEpisodeUnwatched(episodeId: 'episode-uuid');
    });

    test('starts a Show from the Library', () async {
      dioAdapter.onPost('/library/shows/show-uuid/start', (server) {
        server.reply(200, <String, dynamic>{
          'library_entry_id': 'library-entry-uuid',
          'library_status': 'watching',
          'show_id': 'show-uuid',
          'started_episode_id': 'episode-uuid',
        });
      });

      await repository.startShow(showId: 'show-uuid');
    });
    test('loads and maps Upcoming Episodes', () async {
      dioAdapter.onGet('/library/shows/upcoming', (server) {
        server.reply(200, <Map<String, dynamic>>[
          <String, dynamic>{
            'library_entry_id': 'library-entry-1',
            'library_status': 'watching',
            'show': <String, dynamic>{
              'id': 'show-1',
              'tmdb_id': 95396,
              'title': 'Severance',
              'poster_url': 'https://example.com/poster.jpg',
              'backdrop_url': 'https://example.com/backdrop.jpg',
            },
            'episode': <String, dynamic>{
              'id': 'episode-1',
              'tmdb_id': 1947648,
              'season_number': 2,
              'episode_number': 4,
              'title': "Woe's Hollow",
              'air_date': '2026-08-20',
              'runtime': 52,
              'still_url': 'https://example.com/still.jpg',
            },
          },
        ]);
      });

      final List<UpcomingItem> result = await repository.getUpcoming();

      expect(result, hasLength(1));

      final UpcomingItem item = result.single;

      expect(item.libraryEntryId, 'library-entry-1');
      expect(item.libraryStatus, LibraryStatus.watching);

      expect(item.showId, 'show-1');
      expect(item.showTmdbId, 95396);
      expect(item.showTitle, 'Severance');
      expect(item.posterUrl, 'https://example.com/poster.jpg');
      expect(item.backdropUrl, 'https://example.com/backdrop.jpg');

      expect(item.episode.id, 'episode-1');
      expect(item.episode.tmdbId, 1947648);
      expect(item.episode.seasonNumber, 2);
      expect(item.episode.episodeNumber, 4);
      expect(item.episode.code, 'S02E04');
      expect(item.episode.title, "Woe's Hollow");
      expect(item.episode.airDate, DateTime(2026, 8, 20));
      expect(item.episode.runtime, 52);
      expect(item.episode.stillUrl, 'https://example.com/still.jpg');
    });

    test('supports an empty Upcoming collection', () async {
      dioAdapter.onGet('/library/shows/upcoming', (server) {
        server.reply(200, <Map<String, dynamic>>[]);
      });

      final List<UpcomingItem> result = await repository.getUpcoming();

      expect(result, isEmpty);
    });

    test('maps malformed Upcoming data to invalidData', () async {
      dioAdapter.onGet('/library/shows/upcoming', (server) {
        server.reply(200, <Map<String, dynamic>>[
          <String, dynamic>{
            'library_entry_id': 'library-entry-1',
            'library_status': 'watching',
            'show': <String, dynamic>{
              'id': 'show-1',
              'tmdb_id': 95396,
              'title': 'Severance',
            },
            'episode': <String, dynamic>{
              'id': 'episode-1',
              'tmdb_id': 1947648,
              'season_number': 2,
              'episode_number': 4,
              'title': "Woe's Hollow",
              // air_date intentionally missing
            },
          },
        ]);
      });

      expect(
        repository.getUpcoming(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('maps invalid Upcoming response items to invalidData', () async {
      dioAdapter.onGet('/library/shows/upcoming', (server) {
        server.reply(200, <dynamic>['not-a-map']);
      });

      expect(
        repository.getUpcoming(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('propagates Upcoming API errors unchanged', () async {
      dioAdapter.onGet('/library/shows/upcoming', (server) {
        server.reply(500, <String, dynamic>{
          'code': 'server_error',
          'message': 'Something went wrong.',
        });
      });

      expect(
        repository.getUpcoming(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.server,
          ),
        ),
      );
    });
    test('requests Upcoming with date range', () async {
      dioAdapter.onGet(
        '/library/shows/upcoming',
        (server) {
          server.reply(200, <Map<String, dynamic>>[]);
        },
        queryParameters: <String, dynamic>{
          'from_date': '2026-08-08',
          'to_date': '2026-08-22',
        },
      );

      final List<UpcomingItem> result = await repository.getUpcoming(
        fromDate: DateTime(2026, 8, 8),
        toDate: DateTime(2026, 8, 22),
      );

      expect(result, isEmpty);
    });
  });
}
