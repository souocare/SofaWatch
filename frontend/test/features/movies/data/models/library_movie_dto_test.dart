import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/movies/data/models/library_movie_dto.dart';
import 'package:sofawatch/features/movies/domain/models/library_movie.dart';

void main() {
  group('LibraryMovieDto', () {
    test('maps a Library Movie response to the domain model', () {
      final LibraryMovie movie = LibraryMovieDto.fromJson(<String, dynamic>{
        'id': 'library-entry-1',
        'status': 'planning',
        'rating': 8.5,
        'started_at': null,
        'completed_at': null,
        'created_at': '2026-08-01T10:00:00Z',
        'updated_at': '2026-08-10T12:00:00Z',
        'movie': <String, dynamic>{
          'id': 'movie-1',
          'tmdb_id': 438631,
          'title': 'Dune',
          'original_title': 'Dune',
          'release_date': '2021-10-22',
          'poster_url': 'https://example.com/poster.jpg',
          'backdrop_url': 'https://example.com/backdrop.jpg',
          'status': 'Released',
          'vote_average': 8.2,
        },
      }).toDomain();

      expect(movie.libraryEntryId, 'library-entry-1');

      expect(movie.movieId, 'movie-1');
      expect(movie.tmdbId, 438631);

      expect(movie.title, 'Dune');
      expect(movie.originalTitle, 'Dune');

      expect(movie.releaseDate, DateTime(2021, 10, 22));

      expect(movie.posterUrl, 'https://example.com/poster.jpg');
      expect(movie.backdropUrl, 'https://example.com/backdrop.jpg');

      expect(movie.status, LibraryStatus.planning);
      expect(movie.movieStatus, 'Released');

      expect(movie.voteAverage, 8.2);
      expect(movie.rating, 8.5);

      expect(movie.startedAt, isNull);
      expect(movie.completedAt, isNull);

      expect(movie.createdAt, DateTime.utc(2026, 8, 1, 10));
      expect(movie.updatedAt, DateTime.utc(2026, 8, 10, 12));

      expect(movie.isWatchlist, isTrue);
      expect(movie.isWatched, isFalse);
      expect(movie.isComingSoon, isFalse);
    });

    test('supports optional Movie and Library metadata', () {
      final LibraryMovie movie = LibraryMovieDto.fromJson(<String, dynamic>{
        'id': 'library-entry-1',
        'status': 'completed',
        'rating': null,
        'started_at': null,
        'completed_at': '2026-08-10T21:30:00Z',
        'created_at': '2026-08-01T10:00:00Z',
        'updated_at': '2026-08-10T21:30:00Z',
        'movie': <String, dynamic>{
          'id': 'movie-1',
          'tmdb_id': 438631,
          'title': 'Dune',
          'original_title': 'Dune',
          'release_date': null,
          'poster_url': null,
          'backdrop_url': null,
          'status': 'Released',
          'vote_average': 8,
        },
      }).toDomain();

      expect(movie.releaseDate, isNull);
      expect(movie.posterUrl, isNull);
      expect(movie.backdropUrl, isNull);
      expect(movie.rating, isNull);
      expect(movie.startedAt, isNull);

      expect(movie.completedAt, DateTime.utc(2026, 8, 10, 21, 30));

      expect(movie.status, LibraryStatus.completed);

      expect(movie.isWatchlist, isFalse);
      expect(movie.isWatched, isTrue);
      expect(movie.isComingSoon, isFalse);
    });

    test('normalizes empty optional artwork strings to null', () {
      final LibraryMovie movie = LibraryMovieDto.fromJson(<String, dynamic>{
        'id': 'library-entry-1',
        'status': 'planning',
        'rating': null,
        'started_at': null,
        'completed_at': null,
        'created_at': '2026-08-01T10:00:00Z',
        'updated_at': '2026-08-01T10:00:00Z',
        'movie': <String, dynamic>{
          'id': 'movie-1',
          'tmdb_id': 438631,
          'title': 'Dune',
          'original_title': 'Dune',
          'release_date': null,
          'poster_url': '',
          'backdrop_url': '   ',
          'status': 'Released',
          'vote_average': 8.0,
        },
      }).toDomain();

      expect(movie.posterUrl, isNull);
      expect(movie.backdropUrl, isNull);
    });

    test('identifies a future Movie as Coming Soon', () {
      final LibraryMovie movie = LibraryMovieDto.fromJson(<String, dynamic>{
        'id': 'library-entry-1',
        'status': 'planning',
        'rating': null,
        'started_at': null,
        'completed_at': null,
        'created_at': '2026-08-01T10:00:00Z',
        'updated_at': '2026-08-01T10:00:00Z',
        'movie': <String, dynamic>{
          'id': 'movie-1',
          'tmdb_id': 999999,
          'title': 'Future Movie',
          'original_title': 'Future Movie',
          'release_date': '2099-01-01',
          'poster_url': null,
          'backdrop_url': null,
          'status': 'Planned',
          'vote_average': 0.0,
        },
      }).toDomain();

      expect(movie.isComingSoon, isTrue);
    });

    test('rejects an unknown Library status', () {
      expect(
        () => LibraryMovieDto.fromJson(<String, dynamic>{
          'id': 'library-entry-1',
          'status': 'invalid',
          'rating': null,
          'started_at': null,
          'completed_at': null,
          'created_at': '2026-08-01T10:00:00Z',
          'updated_at': '2026-08-01T10:00:00Z',
          'movie': <String, dynamic>{
            'id': 'movie-1',
            'tmdb_id': 438631,
            'title': 'Dune',
            'original_title': 'Dune',
            'release_date': '2021-10-22',
            'poster_url': null,
            'backdrop_url': null,
            'status': 'Released',
            'vote_average': 8.2,
          },
        }),
        throwsFormatException,
      );
    });

    test('rejects an invalid optional release date', () {
      expect(
        () => LibraryMovieDto.fromJson(<String, dynamic>{
          'id': 'library-entry-1',
          'status': 'planning',
          'rating': null,
          'started_at': null,
          'completed_at': null,
          'created_at': '2026-08-01T10:00:00Z',
          'updated_at': '2026-08-01T10:00:00Z',
          'movie': <String, dynamic>{
            'id': 'movie-1',
            'tmdb_id': 438631,
            'title': 'Dune',
            'original_title': 'Dune',
            'release_date': 'not-a-date',
            'poster_url': null,
            'backdrop_url': null,
            'status': 'Released',
            'vote_average': 8.2,
          },
        }),
        throwsFormatException,
      );
    });

    test('rejects an invalid Movie payload', () {
      expect(
        () => LibraryMovieDto.fromJson(<String, dynamic>{
          'id': 'library-entry-1',
          'status': 'planning',
          'rating': null,
          'started_at': null,
          'completed_at': null,
          'created_at': '2026-08-01T10:00:00Z',
          'updated_at': '2026-08-01T10:00:00Z',
          'movie': 'invalid',
        }),
        throwsFormatException,
      );
    });

    test('rejects an invalid TMDB identifier', () {
      expect(
        () => LibraryMovieDto.fromJson(<String, dynamic>{
          'id': 'library-entry-1',
          'status': 'planning',
          'rating': null,
          'started_at': null,
          'completed_at': null,
          'created_at': '2026-08-01T10:00:00Z',
          'updated_at': '2026-08-01T10:00:00Z',
          'movie': <String, dynamic>{
            'id': 'movie-1',
            'tmdb_id': 0,
            'title': 'Dune',
            'original_title': 'Dune',
            'release_date': null,
            'poster_url': null,
            'backdrop_url': null,
            'status': 'Released',
            'vote_average': 8.2,
          },
        }),
        throwsFormatException,
      );
    });
  });
}
