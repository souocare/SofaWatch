import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/shows/data/models/stale_watching_show_dto.dart';
import 'package:sofawatch/features/shows/domain/models/stale_watching_show.dart';

void main() {
  group('StaleWatchingShowDto', () {
    test('maps a complete stale Watching response', () {
      final StaleWatchingShow result = StaleWatchingShowDto.fromJson(
        <String, dynamic>{
          'library_entry_id': 'library-entry-uuid',
          'library_status': 'watching',
          'show': <String, dynamic>{
            'id': 'show-uuid',
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
      ).toDomain();

      expect(result.libraryEntryId, 'library-entry-uuid');

      expect(result.libraryStatus, LibraryStatus.watching);

      expect(result.showId, 'show-uuid');
      expect(result.showTmdbId, 95396);
      expect(result.showTitle, 'Severance');

      expect(result.lastWatched.episodeNumber, 3);

      expect(result.lastWatched.code, 'S01E03');

      expect(
        result.lastWatched.watchedAt,
        DateTime.parse('2026-05-01T20:00:00Z'),
      );

      expect(result.nextEpisode.episodeNumber, 4);

      expect(result.nextEpisode.code, 'S01E04');

      expect(result.nextEpisode.title, 'The You You Are');
    });

    test('supports optional image and Episode metadata', () {
      final StaleWatchingShow result = StaleWatchingShowDto.fromJson(
        <String, dynamic>{
          'library_entry_id': 'library-entry-uuid',
          'library_status': 'watching',
          'show': <String, dynamic>{
            'id': 'show-uuid',
            'tmdb_id': 95396,
            'title': 'Severance',
            'poster_url': null,
            'backdrop_url': null,
          },
          'last_watched': <String, dynamic>{
            'id': 'episode-1',
            'tmdb_id': 1001,
            'season_number': 1,
            'episode_number': 3,
            'title': 'In Perpetuity',
            'air_date': null,
            'runtime': null,
            'still_url': null,
            'watched_at': '2026-05-01T20:00:00Z',
          },
          'next_episode': <String, dynamic>{
            'id': 'episode-2',
            'tmdb_id': 1002,
            'season_number': 1,
            'episode_number': 4,
            'title': 'The You You Are',
            'air_date': null,
            'runtime': null,
            'still_url': null,
          },
        },
      ).toDomain();

      expect(result.posterUrl, isNull);
      expect(result.backdropUrl, isNull);

      expect(result.lastWatched.airDate, isNull);

      expect(result.lastWatched.runtime, isNull);

      expect(result.nextEpisode.airDate, isNull);

      expect(result.nextEpisode.runtime, isNull);
    });

    test('rejects malformed watched_at', () {
      expect(() {
        StaleWatchingShowDto.fromJson(<String, dynamic>{
          'library_entry_id': 'library-entry-uuid',
          'library_status': 'watching',
          'show': <String, dynamic>{
            'id': 'show-uuid',
            'tmdb_id': 95396,
            'title': 'Severance',
          },
          'last_watched': <String, dynamic>{
            'id': 'episode-1',
            'tmdb_id': 1001,
            'season_number': 1,
            'episode_number': 3,
            'title': 'In Perpetuity',
            'watched_at': 'banana',
          },
          'next_episode': <String, dynamic>{
            'id': 'episode-2',
            'tmdb_id': 1002,
            'season_number': 1,
            'episode_number': 4,
            'title': 'The You You Are',
          },
        });
      }, throwsA(isA<FormatException>()));
    });
  });
}
