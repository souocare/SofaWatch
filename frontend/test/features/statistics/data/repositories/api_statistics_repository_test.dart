import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/statistics/data/repositories/api_statistics_repository.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity_period.dart';
import 'package:sofawatch/features/statistics/domain/models/weekly_statistics.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_content_insights.dart';

void main() {
  group('ApiStatisticsRepository', () {
    late ApiClient apiClient;
    late DioAdapter dioAdapter;
    late ApiStatisticsRepository repository;

    setUp(() {
      apiClient = ApiClient(baseUrl: Uri.parse('http://localhost:8000'));

      dioAdapter = DioAdapter(dio: apiClient.dio, printLogs: false);

      repository = ApiStatisticsRepository(apiClient);
    });

    test('loads weekly Statistics', () async {
      dioAdapter.onGet('/statistics/weekly', (server) {
        server.reply(200, <String, dynamic>{
          'week_start': '2026-08-17',
          'week_end': '2026-08-23',
          'episodes_watched': 8,
          'movies_watched': 2,
          'watch_time_minutes': 642,
        });
      });

      final WeeklyStatistics result = await repository.getWeeklyStatistics();

      expect(result.episodesWatched, 8);

      expect(result.moviesWatched, 2);

      expect(result.watchTimeMinutes, 642);

      expect(result.weekStart, DateTime(2026, 8, 17));

      expect(result.weekEnd, DateTime(2026, 8, 23));
    });

    test('supports a week without viewing activity', () async {
      dioAdapter.onGet('/statistics/weekly', (server) {
        server.reply(200, <String, dynamic>{
          'week_start': '2026-08-17',
          'week_end': '2026-08-23',
          'episodes_watched': 0,
          'movies_watched': 0,
          'watch_time_minutes': 0,
        });
      });

      final WeeklyStatistics result = await repository.getWeeklyStatistics();

      expect(result.episodesWatched, 0);

      expect(result.moviesWatched, 0);

      expect(result.watchTimeMinutes, 0);
    });

    test('maps malformed Statistics response to invalidData', () async {
      dioAdapter.onGet('/statistics/weekly', (server) {
        server.reply(200, <String, dynamic>{
          'week_start': '2026-08-17',
          'week_end': '2026-08-23',
          'episodes_watched': -1,
          'movies_watched': 2,
          'watch_time_minutes': 642,
        });
      });

      expect(
        repository.getWeeklyStatistics(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('maps missing response body to invalidData', () async {
      dioAdapter.onGet('/statistics/weekly', (server) {
        server.reply(200, null);
      });

      expect(
        repository.getWeeklyStatistics(),
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
      dioAdapter.onGet('/statistics/weekly', (server) {
        server.reply(500, <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'internal_error',
            'message': 'Unexpected error.',
          },
        });
      });

      expect(repository.getWeeklyStatistics(), throwsA(isA<AppException>()));
    });

    test('gets seven-day statistics activity', () async {
      dioAdapter.onGet('/statistics/activity', (server) {
        server.reply(200, <String, dynamic>{
          'start_date': '2026-08-12',
          'end_date': '2026-08-18',
          'days': <Map<String, dynamic>>[
            <String, dynamic>{
              'day': '2026-08-12',
              'episodes_watched': 3,
              'movies_watched': 1,
              'episode_watch_time_minutes': 150,
              'movie_watch_time_minutes': 120,
              'watch_time_minutes': 270,
            },
          ],
        });
      }, queryParameters: <String, dynamic>{'range': '7d'});

      final StatisticsActivity result = await repository.getActivity(
        period: StatisticsActivityPeriod.days7,
      );

      expect(result.startDate, DateTime(2026, 8, 12));

      expect(result.endDate, DateTime(2026, 8, 18));

      expect(result.days, hasLength(1));

      expect(result.days.first.episodesWatched, 3);

      expect(result.days.first.moviesWatched, 1);

      expect(result.days.first.watchTimeMinutes, 270);
    });

    test('gets fourteen-day statistics activity', () async {
      dioAdapter.onGet('/statistics/activity', (server) {
        server.reply(200, <String, dynamic>{
          'start_date': '2026-08-05',
          'end_date': '2026-08-18',
          'days': <Map<String, dynamic>>[],
        });
      }, queryParameters: <String, dynamic>{'range': '14d'});

      final StatisticsActivity result = await repository.getActivity(
        period: StatisticsActivityPeriod.days14,
      );

      expect(result.startDate, DateTime(2026, 8, 5));

      expect(result.endDate, DateTime(2026, 8, 18));

      expect(result.days, isEmpty);
    });

    test('maps invalid statistics activity data to invalid data', () async {
      dioAdapter.onGet('/statistics/activity', (server) {
        server.reply(200, <String, dynamic>{
          'start_date': '2026-08-12',
          'end_date': '2026-08-18',
          'days': <Map<String, dynamic>>[
            <String, dynamic>{
              'day': '2026-08-12',
              'episodes_watched': 'invalid',
              'movies_watched': 1,
              'episode_watch_time_minutes': 150,
              'movie_watch_time_minutes': 120,
              'watch_time_minutes': 270,
            },
          ],
        });
      }, queryParameters: <String, dynamic>{'range': '7d'});

      expect(
        () => repository.getActivity(period: StatisticsActivityPeriod.days7),
        throwsA(isA<AppException>()),
      );
    });

    test('gets the statistics summary', () async {
      dioAdapter.onGet('/statistics/summary', (server) {
        server.reply(200, const <String, dynamic>{
          'shows_watched': 12,
          'episodes': <String, dynamic>{
            'watch_count': 125,
            'unique_count': 100,
            'rewatch_count': 25,
            'watch_time_minutes': 6250,
            'rewatch_time_minutes': 1250,
          },
          'movies': <String, dynamic>{
            'watch_count': 34,
            'unique_count': 30,
            'rewatch_count': 4,
            'watch_time_minutes': 4200,
            'rewatch_time_minutes': 500,
          },
          'watch_time_minutes': 10450,
          'rewatch_time_minutes': 1750,
        });
      });

      final result = await repository.getSummary();

      expect(result.showsWatched, 12);

      expect(result.episodes.watchCount, 125);

      expect(result.episodes.uniqueCount, 100);

      expect(result.episodes.rewatchCount, 25);

      expect(result.movies.watchCount, 34);

      expect(result.movies.rewatchCount, 4);

      expect(result.watchTimeMinutes, 10450);

      expect(result.rewatchTimeMinutes, 1750);
    });

    test('maps invalid statistics summary data to invalid data', () async {
      dioAdapter.onGet('/statistics/summary', (server) {
        server.reply(200, const <String, dynamic>{
          'shows_watched': 12,
          'episodes': 'invalid',
          'movies': <String, dynamic>{
            'watch_count': 34,
            'unique_count': 30,
            'rewatch_count': 4,
            'watch_time_minutes': 4200,
            'rewatch_time_minutes': 500,
          },
          'watch_time_minutes': 10450,
          'rewatch_time_minutes': 1750,
        });
      });

      expect(() => repository.getSummary(), throwsA(isA<AppException>()));
    });

    test('requests all-time Activity using the API range value', () async {
      dioAdapter.onGet('/statistics/activity', (server) {
        server.reply(200, <String, dynamic>{
          'start_date': '2024-01-01',
          'end_date': '2026-08-18',
          'days': <dynamic>[],
        });
      }, queryParameters: <String, dynamic>{'range': 'all'});

      final StatisticsActivity result = await repository.getActivity(
        period: StatisticsActivityPeriod.all,
      );

      expect(result.days, isEmpty);
    });

    test('gets Statistics habits', () async {
      dioAdapter.onGet('/statistics/habits', (server) {
        server.reply(200, const <String, dynamic>{
          'current_streak_days': 4,
          'longest_streak_days': 12,
          'biggest_marathon_watch_time_minutes': 270,
          'biggest_marathon_day': '2026-08-12',
          'longest_binge_episode_count': 7,
          'average_active_day_watch_time_minutes': 103,
          'longest_binge_day': '2026-08-15',
          'most_active_weekday': 'Monday',
          'most_active_weekday_watch_count': 8,
        });
      });

      final result = await repository.getHabits();

      expect(result.currentStreakDays, 4);

      expect(result.longestStreakDays, 12);

      expect(result.biggestMarathonWatchTimeMinutes, 270);

      expect(result.biggestMarathonDay, DateTime(2026, 8, 12));
      expect(result.longestBingeEpisodeCount, 7);

      expect(result.longestBingeDay, DateTime(2026, 8, 15));
      expect(result.averageActiveDayWatchTimeMinutes, 103);
      expect(result.mostActiveWeekday, 'Monday');
      expect(result.mostActiveWeekdayWatchCount, 8);
    });

    test('supports Statistics habits without a marathon', () async {
      dioAdapter.onGet('/statistics/habits', (server) {
        server.reply(200, const <String, dynamic>{
          'current_streak_days': 0,
          'longest_streak_days': 0,
          'biggest_marathon_watch_time_minutes': 0,
          'biggest_marathon_day': null,
          'longest_binge_episode_count': 0,
          'longest_binge_day': null,
          'average_active_day_watch_time_minutes': 0,
          'most_active_weekday': null,
          'most_active_weekday_watch_count': 0,
        });
      });

      final result = await repository.getHabits();

      expect(result.currentStreakDays, 0);

      expect(result.longestStreakDays, 0);

      expect(result.biggestMarathonWatchTimeMinutes, 0);

      expect(result.biggestMarathonDay, isNull);
      expect(result.longestBingeEpisodeCount, 0);
      expect(result.longestBingeDay, isNull);
    });

    test('maps invalid Statistics habits response to invalidData', () async {
      dioAdapter.onGet('/statistics/habits', (server) {
        server.reply(200, const <String, dynamic>{
          'current_streak_days': -1,
          'longest_streak_days': 12,
          'biggest_marathon_watch_time_minutes': 270,
          'biggest_marathon_day': '2026-08-12',
          'average_active_day_watch_time_minutes': 103,
          'most_active_weekday': 'Monday',
          'most_active_weekday_watch_count': 8,
        });
      });

      expect(
        repository.getHabits(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('maps invalid marathon day to invalidData', () async {
      dioAdapter.onGet('/statistics/habits', (server) {
        server.reply(200, const <String, dynamic>{
          'current_streak_days': 4,
          'longest_streak_days': 12,
          'biggest_marathon_watch_time_minutes': 270,
          'biggest_marathon_day': 'invalid-date',
          'average_active_day_watch_time_minutes': 103,
          'most_active_weekday': 'Monday',
          'most_active_weekday_watch_count': 8,
        });
      });

      expect(
        repository.getHabits(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });
    test('gets Statistics Content Insights', () async {
      dioAdapter.onGet('/statistics/content-insights', (server) {
        server.reply(200, const <String, dynamic>{
          'most_watched_shows': <dynamic>[
            <String, dynamic>{
              'show_id': '11111111-1111-1111-1111-111111111111',
              'tmdb_id': 95396,
              'title': 'Severance',
              'poster_url': '/api/v1/images/shows/show-id/poster',
              'watch_count': 12,
              'rewatch_count': 4,
            },
          ],
          'most_rewatched_shows': <dynamic>[],
          'most_rewatched_episodes': <dynamic>[],
          'most_rewatched_movies': <dynamic>[
            <String, dynamic>{
              'movie_id': '33333333-3333-3333-3333-333333333333',
              'tmdb_id': 438631,
              'title': 'Dune',
              'poster_url': null,
              'watch_count': 3,
              'rewatch_count': 2,
            },
          ],
          'top_show_genres': <dynamic>[
            <String, dynamic>{
              'genre_id': 1,
              'name': 'Drama',
              'watch_count': 12,
            },
          ],
          'top_movie_genres': <dynamic>[],
        });
      });

      final StatisticsContentInsights result = await repository
          .getContentInsights();

      expect(result.mostWatchedShows, hasLength(1));
      expect(result.mostWatchedShows.first.title, 'Severance');
      expect(result.mostWatchedShows.first.watchCount, 12);

      expect(result.mostRewatchedMovies, hasLength(1));
      expect(result.mostRewatchedMovies.first.title, 'Dune');
      expect(result.mostRewatchedMovies.first.rewatchCount, 2);

      expect(result.topShowGenres, hasLength(1));
      expect(result.topShowGenres.first.name, 'Drama');
    });

    test('supports empty Statistics Content Insights', () async {
      dioAdapter.onGet('/statistics/content-insights', (server) {
        server.reply(200, const <String, dynamic>{
          'most_watched_shows': <dynamic>[],
          'most_rewatched_shows': <dynamic>[],
          'most_rewatched_episodes': <dynamic>[],
          'most_rewatched_movies': <dynamic>[],
          'top_show_genres': <dynamic>[],
          'top_movie_genres': <dynamic>[],
        });
      });

      final StatisticsContentInsights result = await repository
          .getContentInsights();

      expect(result.mostWatchedShows, isEmpty);
      expect(result.mostRewatchedShows, isEmpty);
      expect(result.mostRewatchedEpisodes, isEmpty);
      expect(result.mostRewatchedMovies, isEmpty);
      expect(result.topShowGenres, isEmpty);
      expect(result.topMovieGenres, isEmpty);
    });

    test(
      'maps invalid Statistics Content Insights response to invalidData',
      () async {
        dioAdapter.onGet('/statistics/content-insights', (server) {
          server.reply(200, const <String, dynamic>{
            'most_watched_shows': 'invalid',
            'most_rewatched_shows': <dynamic>[],
            'most_rewatched_episodes': <dynamic>[],
            'most_rewatched_movies': <dynamic>[],
            'top_show_genres': <dynamic>[],
            'top_movie_genres': <dynamic>[],
          });
        });

        expect(
          repository.getContentInsights(),
          throwsA(
            isA<AppException>().having(
              (AppException error) => error.type,
              'type',
              AppExceptionType.invalidData,
            ),
          ),
        );
      },
    );
  });
}
