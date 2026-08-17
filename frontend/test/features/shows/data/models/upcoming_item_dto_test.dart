import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/shows/data/models/upcoming_item_dto.dart';
import 'package:sofawatch/features/shows/domain/models/upcoming_item.dart';

void main() {
  group('UpcomingItemDto', () {
    test('maps valid Upcoming data to domain', () {
      final UpcomingItem result = UpcomingItemDto.fromJson(<String, dynamic>{
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
          'is_watched': false,
          'title': "Woe's Hollow",
          'air_date': '2026-08-20',
          'runtime': 52,
          'still_url': 'https://example.com/still.jpg',
        },
      }).toDomain();

      expect(result.libraryEntryId, 'library-entry-1');
      expect(result.libraryStatus, LibraryStatus.watching);

      expect(result.showId, 'show-1');
      expect(result.showTmdbId, 95396);
      expect(result.showTitle, 'Severance');
      expect(result.posterUrl, 'https://example.com/poster.jpg');
      expect(result.backdropUrl, 'https://example.com/backdrop.jpg');

      expect(result.episode.id, 'episode-1');
      expect(result.episode.tmdbId, 1947648);
      expect(result.episode.seasonNumber, 2);
      expect(result.episode.episodeNumber, 4);
      expect(result.episode.code, 'S02E04');
      expect(result.episode.title, "Woe's Hollow");
      expect(result.episode.airDate, DateTime(2026, 8, 20));
      expect(result.episode.runtime, 52);
      expect(result.episode.stillUrl, 'https://example.com/still.jpg');
    });

    test('supports Planning status', () {
      final UpcomingItem result = UpcomingItemDto.fromJson(<String, dynamic>{
        'library_entry_id': 'library-entry-1',
        'library_status': 'planning',
        'show': <String, dynamic>{
          'id': 'show-1',
          'tmdb_id': 95396,
          'title': 'Severance',
          'poster_url': null,
          'backdrop_url': null,
        },
        'episode': <String, dynamic>{
          'id': 'episode-1',
          'tmdb_id': 1947648,
          'season_number': 1,
          'episode_number': 1,
          'is_watched': false,
          'title': 'Pilot',
          'air_date': '2026-08-20',
          'runtime': null,
          'still_url': null,
        },
      }).toDomain();

      expect(result.libraryStatus, LibraryStatus.planning);
      expect(result.posterUrl, isNull);
      expect(result.backdropUrl, isNull);
      expect(result.episode.runtime, isNull);
      expect(result.episode.stillUrl, isNull);
    });

    test('rejects missing air date', () {
      expect(
        () => UpcomingItemDto.fromJson(<String, dynamic>{
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
            'is_watched': false,
            'season_number': 2,
            'episode_number': 4,
            'title': "Woe's Hollow",
          },
        }),
        throwsFormatException,
      );
    });

    test('rejects invalid air date', () {
      expect(
        () => UpcomingItemDto.fromJson(<String, dynamic>{
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
            'is_watched': false,
            'title': "Woe's Hollow",
            'air_date': 'not-a-date',
          },
        }),
        throwsFormatException,
      );
    });

    test('rejects invalid Library status', () {
      expect(
        () => UpcomingItemDto.fromJson(<String, dynamic>{
          'library_entry_id': 'library-entry-1',
          'library_status': 'invalid',
          'show': <String, dynamic>{
            'id': 'show-1',
            'tmdb_id': 95396,
            'title': 'Severance',
          },
          'episode': <String, dynamic>{
            'id': 'episode-1',
            'tmdb_id': 1947648,
            'season_number': 2,
            'is_watched': false,
            'episode_number': 4,
            'title': "Woe's Hollow",
            'air_date': '2026-08-20',
          },
        }),
        throwsFormatException,
      );
    });
  });
}
