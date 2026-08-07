import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/movie_details/data/models/movie_details_dto.dart';
import 'package:sofawatch/features/movie_details/domain/models/movie_details.dart';

void main() {
  group('MovieDetailsDto', () {
    test('maps a valid API response to the domain model', () {
      final MovieDetails details = MovieDetailsDto.fromJson(<String, dynamic>{
        'tmdb_id': 438631,
        'title': 'Dune',
        'original_title': 'Dune',
        'overview': 'Paul Atreides travels to Arrakis.',
        'tagline': 'Beyond fear, destiny awaits.',
        'release_date': '2021-09-15',
        'poster_url': 'https://example.com/poster.jpg',
        'backdrop_url': 'https://example.com/backdrop.jpg',
        'genres': <Map<String, dynamic>>[
          <String, dynamic>{'tmdb_id': 878, 'name': 'Science Fiction'},
          <String, dynamic>{'tmdb_id': 12, 'name': 'Adventure'},
        ],
        'original_language': 'en',
        'runtime': 155,
        'status': 'Released',
        'vote_average': 7.8,
        'vote_count': 13000,
      }).toDomain();

      expect(details.tmdbId, 438631);
      expect(details.title, 'Dune');
      expect(details.releaseYear, 2021);
      expect(details.runtime, 155);
      expect(details.genres, <String>['Science Fiction', 'Adventure']);
      expect(details.voteAverage, 7.8);
    });

    test('supports a missing runtime', () {
      final MovieDetails details = MovieDetailsDto.fromJson(<String, dynamic>{
        'tmdb_id': 438631,
        'title': 'Dune',
        'original_title': 'Dune',
        'overview': null,
        'tagline': null,
        'release_date': null,
        'poster_url': null,
        'backdrop_url': null,
        'genres': <dynamic>[],
        'original_language': 'en',
        'runtime': null,
        'status': 'Released',
        'vote_average': 0,
        'vote_count': 0,
      }).toDomain();

      expect(details.runtime, isNull);
      expect(details.releaseDate, isNull);
    });

    test('throws FormatException for invalid required data', () {
      expect(
        () => MovieDetailsDto.fromJson(<String, dynamic>{'tmdb_id': 'invalid'}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
