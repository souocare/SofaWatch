import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/episode_details/data/models/episode_details_dto.dart';
import 'package:sofawatch/features/episode_details/domain/models/episode_details.dart';

void main() {
  group('EpisodeDetailsDto', () {
    test('maps complete Episode Details response to domain', () {
      final EpisodeDetailsDto dto = EpisodeDetailsDto.fromJson(
        <String, dynamic>{
          'episode': <String, dynamic>{
            'id': 'episode-uuid',
            'tmdb_id': 1947648,
            'episode_number': 4,
            'title': "Woe's Hollow",
            'overview': 'An episode overview.',
            'air_date': '2025-02-07',
            'runtime': 52,
            'vote_average': 8.5,
            'vote_count': 100,
            'still_url': '/api/v1/images/episodes/episode-uuid/still',
          },
          'season': <String, dynamic>{
            'id': 'season-uuid',
            'season_number': 2,
            'title': 'Season 2',
          },
          'show': <String, dynamic>{
            'id': 'show-uuid',
            'tmdb_id': 95396,
            'title': 'Severance',
            'original_title': 'Severance',
            'first_air_date': '2022-02-18',
            'poster_url': '/api/v1/images/shows/show-uuid/poster',
            'backdrop_url': '/api/v1/images/shows/show-uuid/backdrop',
            'status': 'Returning Series',
            'vote_average': 8.4,
          },
          'progress': <String, dynamic>{
            'is_watched': true,
            'watched_at': '2026-08-14T21:30:00Z',
            'watch_count': 2,
            'last_watched_at': '2026-08-14T21:30:00Z',
          },
        },
      );

      final EpisodeDetails details = dto.toDomain();

      expect(details.episode.id, 'episode-uuid');
      expect(details.episode.tmdbId, 1947648);
      expect(details.episode.episodeNumber, 4);
      expect(details.episode.title, "Woe's Hollow");
      expect(details.episode.overview, 'An episode overview.');
      expect(details.episode.airDate, DateTime(2025, 2, 7));
      expect(details.episode.runtime, 52);
      expect(details.episode.voteAverage, 8.5);
      expect(details.episode.voteCount, 100);
      expect(
        details.episode.stillUrl,
        '/api/v1/images/episodes/episode-uuid/still',
      );

      expect(details.season.id, 'season-uuid');
      expect(details.season.seasonNumber, 2);
      expect(details.season.title, 'Season 2');

      expect(details.show.id, 'show-uuid');
      expect(details.show.tmdbId, 95396);
      expect(details.show.title, 'Severance');
      expect(details.show.originalTitle, 'Severance');

      expect(details.progress.isWatched, isTrue);
      expect(details.progress.watchCount, 2);
      expect(
        details.progress.watchedAt,
        DateTime.parse('2026-08-14T21:30:00Z'),
      );
      expect(
        details.progress.lastWatchedAt,
        DateTime.parse('2026-08-14T21:30:00Z'),
      );
    });

    test('maps nullable Episode Details fields', () {
      final EpisodeDetails details = EpisodeDetailsDto.fromJson(
        <String, dynamic>{
          'episode': <String, dynamic>{
            'id': 'episode-uuid',
            'tmdb_id': 1947648,
            'episode_number': 4,
            'title': 'Future Episode',
            'overview': null,
            'air_date': null,
            'runtime': null,
            'vote_average': 0.0,
            'vote_count': 0,
            'still_url': null,
          },
          'season': <String, dynamic>{
            'id': 'season-uuid',
            'season_number': 2,
            'title': 'Season 2',
          },
          'show': <String, dynamic>{
            'id': 'show-uuid',
            'tmdb_id': 95396,
            'title': 'Severance',
            'original_title': 'Severance',
            'first_air_date': null,
            'poster_url': null,
            'backdrop_url': null,
            'status': 'Returning Series',
            'vote_average': 8.4,
          },
          'progress': <String, dynamic>{
            'is_watched': false,
            'watched_at': null,
            'watch_count': 0,
            'last_watched_at': null,
          },
        },
      ).toDomain();

      expect(details.episode.overview, isNull);
      expect(details.episode.airDate, isNull);
      expect(details.episode.runtime, isNull);
      expect(details.episode.stillUrl, isNull);

      expect(details.progress.isWatched, isFalse);
      expect(details.progress.watchedAt, isNull);
      expect(details.progress.watchCount, 0);
      expect(details.progress.lastWatchedAt, isNull);
    });

    test('throws FormatException for malformed aggregate', () {
      expect(
        () => EpisodeDetailsDto.fromJson(<String, dynamic>{
          'episode': 'invalid',
          'season': <String, dynamic>{},
          'show': <String, dynamic>{},
          'progress': <String, dynamic>{},
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
