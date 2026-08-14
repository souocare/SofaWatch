import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/shows/data/models/watch_next_show_dto.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_show.dart';

void main() {
  group('WatchNextShowDto', () {
    test('maps a complete Watch Next response', () {
      final WatchNextShow result = WatchNextShowDto.fromJson(<String, dynamic>{
        'library_entry_id': 'library-entry-uuid',
        'library_status': 'watching',
        'show': <String, dynamic>{
          'id': 'show-uuid',
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
        'next_episode': <String, dynamic>{
          'id': 'episode-uuid',
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
      }).toDomain();

      expect(result.libraryEntryId, 'library-entry-uuid');

      expect(result.libraryStatus, LibraryStatus.watching);

      expect(result.showId, 'show-uuid');
      expect(result.showTmdbId, 95396);
      expect(result.showTitle, 'Severance');

      expect(result.posterUrl, 'https://example.com/poster.jpg');

      expect(result.backdropUrl, 'https://example.com/backdrop.jpg');

      expect(result.nextEpisode.id, 'episode-uuid');

      expect(result.nextEpisode.tmdbId, 1947648);

      expect(result.nextEpisode.seasonNumber, 2);

      expect(result.nextEpisode.episodeNumber, 4);

      expect(result.nextEpisode.code, 'S02E04');

      expect(result.nextEpisode.title, "Woe's Hollow");

      expect(result.nextEpisode.airDate, DateTime(2026, 8, 10));

      expect(result.nextEpisode.runtime, 52);

      expect(result.nextEpisode.stillUrl, 'https://example.com/still.jpg');
      expect(result.progress.watchedEpisodes, 7);
      expect(result.progress.airedEpisodes, 10);
      expect(result.progress.percentage, 70.0);
    });

    test('supports optional Episode and image metadata', () {
      final WatchNextShow result = WatchNextShowDto.fromJson(<String, dynamic>{
        'library_entry_id': 'library-entry-uuid',
        'library_status': 'watching',
        'show': <String, dynamic>{
          'id': 'show-uuid',
          'tmdb_id': 95396,
          'title': 'Severance',
          'poster_url': null,
          'backdrop_url': null,
        },
        'next_episode': <String, dynamic>{
          'id': 'episode-uuid',
          'tmdb_id': 1947648,
          'season_number': 2,
          'episode_number': 4,
          'title': "Woe's Hollow",
          'air_date': null,
          'runtime': null,
          'still_url': null,
        },
        'progress': <String, dynamic>{
          'watched_episodes': 0,
          'aired_episodes': 1,
          'percentage': 0.0,
        },
      }).toDomain();

      expect(result.posterUrl, isNull);
      expect(result.backdropUrl, isNull);

      expect(result.nextEpisode.airDate, isNull);

      expect(result.nextEpisode.runtime, isNull);

      expect(result.nextEpisode.stillUrl, isNull);
    });

    test('rejects malformed next Episode data', () {
      expect(() {
        WatchNextShowDto.fromJson(<String, dynamic>{
          'library_entry_id': 'library-entry-uuid',
          'library_status': 'watching',
          'show': <String, dynamic>{
            'id': 'show-uuid',
            'tmdb_id': 95396,
            'title': 'Severance',
          },
          'next_episode': <String, dynamic>{
            'id': 'episode-uuid',
            'tmdb_id': 1947648,
            'season_number': 0,
            'episode_number': 4,
            'title': "Woe's Hollow",
          },
        });
      }, throwsA(isA<FormatException>()));
    });

    test('rejects an unknown Library status', () {
      expect(() {
        WatchNextShowDto.fromJson(<String, dynamic>{
          'library_entry_id': 'library-entry-uuid',
          'library_status': 'banana',
          'show': <String, dynamic>{
            'id': 'show-uuid',
            'tmdb_id': 95396,
            'title': 'Severance',
          },
          'next_episode': <String, dynamic>{
            'id': 'episode-uuid',
            'tmdb_id': 1947648,
            'season_number': 2,
            'episode_number': 4,
            'title': "Woe's Hollow",
          },
        });
      }, throwsA(isA<FormatException>()));
    });
  });
}
