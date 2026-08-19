import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/statistics/data/models/statistics_content_insights_dto.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_content_insights.dart';

void main() {
  group('StatisticsContentInsightsDto', () {
    test('maps a valid Content Insights response to domain', () {
      final StatisticsContentInsights result =
          StatisticsContentInsightsDto.fromJson(const <String, dynamic>{
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
            'most_rewatched_shows': <dynamic>[
              <String, dynamic>{
                'show_id': '11111111-1111-1111-1111-111111111111',
                'tmdb_id': 95396,
                'title': 'Severance',
                'poster_url': null,
                'watch_count': 12,
                'rewatch_count': 4,
              },
            ],
            'most_rewatched_episodes': <dynamic>[
              <String, dynamic>{
                'episode_id': '22222222-2222-2222-2222-222222222222',
                'show_tmdb_id': 95396,
                'show_title': 'Severance',
                'season_number': 1,
                'episode_number': 1,
                'episode_title': 'Good News About Hell',
                'still_url': '/api/v1/images/episodes/episode-id/still',
                'watch_count': 4,
                'rewatch_count': 3,
              },
            ],
            'most_rewatched_movies': <dynamic>[
              <String, dynamic>{
                'movie_id': '33333333-3333-3333-3333-333333333333',
                'tmdb_id': 438631,
                'title': 'Dune',
                'poster_url': '/api/v1/images/movies/movie-id/poster',
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
            'top_movie_genres': <dynamic>[
              <String, dynamic>{
                'genre_id': 2,
                'name': 'Science Fiction',
                'watch_count': 8,
              },
            ],
          }).toDomain();

      expect(result.mostWatchedShows, hasLength(1));
      expect(result.mostWatchedShows.first.title, 'Severance');
      expect(result.mostWatchedShows.first.watchCount, 12);

      expect(result.mostRewatchedShows, hasLength(1));
      expect(result.mostRewatchedShows.first.rewatchCount, 4);

      expect(result.mostRewatchedEpisodes, hasLength(1));
      expect(
        result.mostRewatchedEpisodes.first.episodeTitle,
        'Good News About Hell',
      );
      expect(result.mostRewatchedEpisodes.first.rewatchCount, 3);

      expect(result.mostRewatchedMovies, hasLength(1));
      expect(result.mostRewatchedMovies.first.title, 'Dune');

      expect(result.topShowGenres, hasLength(1));
      expect(result.topShowGenres.first.name, 'Drama');

      expect(result.topMovieGenres, hasLength(1));
      expect(result.topMovieGenres.first.name, 'Science Fiction');
    });

    test('accepts empty Content Insights lists', () {
      final StatisticsContentInsights result =
          StatisticsContentInsightsDto.fromJson(const <String, dynamic>{
            'most_watched_shows': <dynamic>[],
            'most_rewatched_shows': <dynamic>[],
            'most_rewatched_episodes': <dynamic>[],
            'most_rewatched_movies': <dynamic>[],
            'top_show_genres': <dynamic>[],
            'top_movie_genres': <dynamic>[],
          }).toDomain();

      expect(result.mostWatchedShows, isEmpty);
      expect(result.mostRewatchedShows, isEmpty);
      expect(result.mostRewatchedEpisodes, isEmpty);
      expect(result.mostRewatchedMovies, isEmpty);
      expect(result.topShowGenres, isEmpty);
      expect(result.topMovieGenres, isEmpty);
    });

    test('rejects a missing Content Insights list', () {
      expect(
        () => StatisticsContentInsightsDto.fromJson(const <String, dynamic>{
          'most_watched_shows': <dynamic>[],
          'most_rewatched_shows': <dynamic>[],
          'most_rewatched_episodes': <dynamic>[],
          'most_rewatched_movies': <dynamic>[],
          'top_show_genres': <dynamic>[],
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a negative Rewatch count', () {
      expect(
        () => StatisticsContentInsightsDto.fromJson(const <String, dynamic>{
          'most_watched_shows': <dynamic>[
            <String, dynamic>{
              'show_id': '11111111-1111-1111-1111-111111111111',
              'tmdb_id': 95396,
              'title': 'Severance',
              'poster_url': null,
              'watch_count': 2,
              'rewatch_count': -1,
            },
          ],
          'most_rewatched_shows': <dynamic>[],
          'most_rewatched_episodes': <dynamic>[],
          'most_rewatched_movies': <dynamic>[],
          'top_show_genres': <dynamic>[],
          'top_movie_genres': <dynamic>[],
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects malformed list entries', () {
      expect(
        () => StatisticsContentInsightsDto.fromJson(const <String, dynamic>{
          'most_watched_shows': <dynamic>['invalid'],
          'most_rewatched_shows': <dynamic>[],
          'most_rewatched_episodes': <dynamic>[],
          'most_rewatched_movies': <dynamic>[],
          'top_show_genres': <dynamic>[],
          'top_movie_genres': <dynamic>[],
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
