import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/shows/data/models/library_show_dto.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';

void main() {
  group('LibraryShowDto', () {
    test('maps a Library Show response to the domain model', () {
      final LibraryShowDto dto = LibraryShowDto.fromJson(<String, dynamic>{
        'id': 'library-entry-uuid',
        'status': 'watching',
        'rating': 8.5,
        'started_at': '2026-08-01T20:00:00Z',
        'completed_at': null,
        'created_at': '2026-07-01T10:00:00Z',
        'updated_at': '2026-08-10T10:00:00Z',
        'show': <String, dynamic>{
          'id': 'show-uuid',
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
      });

      final LibraryShow show = dto.toDomain();

      expect(show.libraryEntryId, 'library-entry-uuid');

      expect(show.showId, 'show-uuid');
      expect(show.tmdbId, 95396);

      expect(show.title, 'Severance');
      expect(show.originalTitle, 'Severance');

      expect(show.firstAirDate, DateTime(2022, 2, 18));

      expect(show.posterUrl, 'https://example.com/poster.jpg');

      expect(show.backdropUrl, 'https://example.com/backdrop.jpg');

      expect(show.status, LibraryStatus.watching);
      expect(show.showStatus, 'Returning Series');

      expect(show.voteAverage, 8.4);
      expect(show.rating, 8.5);

      expect(show.startedAt, DateTime.parse('2026-08-01T20:00:00Z'));

      expect(show.completedAt, isNull);

      expect(show.createdAt, DateTime.parse('2026-07-01T10:00:00Z'));

      expect(show.updatedAt, DateTime.parse('2026-08-10T10:00:00Z'));
    });

    test('supports optional Show and Library metadata', () {
      final LibraryShow show = LibraryShowDto.fromJson(<String, dynamic>{
        'id': 'library-entry-uuid',
        'status': 'planning',
        'rating': null,
        'started_at': null,
        'completed_at': null,
        'created_at': '2026-07-01T10:00:00Z',
        'updated_at': '2026-07-01T10:00:00Z',
        'show': <String, dynamic>{
          'id': 'show-uuid',
          'tmdb_id': 95396,
          'title': 'Severance',
          'original_title': 'Severance',
          'first_air_date': null,
          'tmdb_poster_path': null,
          'local_poster_path': null,
          'poster_url': null,
          'backdrop_url': null,
          'status': 'Returning Series',
          'vote_average': 0,
        },
      }).toDomain();

      expect(show.status, LibraryStatus.planning);

      expect(show.firstAirDate, isNull);
      expect(show.posterUrl, isNull);
      expect(show.backdropUrl, isNull);

      expect(show.rating, isNull);
      expect(show.startedAt, isNull);
      expect(show.completedAt, isNull);
    });

    test('rejects an unknown Library status', () {
      expect(() {
        LibraryShowDto.fromJson(<String, dynamic>{
          'id': 'library-entry-uuid',
          'status': 'banana',
          'rating': null,
          'started_at': null,
          'completed_at': null,
          'created_at': '2026-07-01T10:00:00Z',
          'updated_at': '2026-07-01T10:00:00Z',
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
        });
      }, throwsA(isA<FormatException>()));
    });

    test('rejects an invalid optional date', () {
      expect(() {
        LibraryShowDto.fromJson(<String, dynamic>{
          'id': 'library-entry-uuid',
          'status': 'watching',
          'rating': null,
          'started_at': null,
          'completed_at': null,
          'created_at': '2026-07-01T10:00:00Z',
          'updated_at': '2026-07-01T10:00:00Z',
          'show': <String, dynamic>{
            'id': 'show-uuid',
            'tmdb_id': 95396,
            'title': 'Severance',
            'original_title': 'Severance',
            'first_air_date': 'not-a-date',
            'poster_url': null,
            'backdrop_url': null,
            'status': 'Returning Series',
            'vote_average': 8.4,
          },
        });
      }, throwsA(isA<FormatException>()));
    });
  });
}
