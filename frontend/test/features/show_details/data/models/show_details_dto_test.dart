import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/show_details/data/models/show_details_dto.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details.dart';

void main() {
  group('ShowDetailsDto', () {
    test('maps a valid API response to the domain model', () {
      final ShowDetails details = ShowDetailsDto.fromJson(<String, dynamic>{
        'tmdb_id': 95396,
        'title': 'Severance',
        'original_title': 'Severance',
        'overview': 'A mysterious workplace thriller.',
        'tagline': 'We work for Lumon.',
        'first_air_date': '2022-02-17',
        'last_air_date': '2025-03-20',
        'poster_url': 'https://example.com/poster.jpg',
        'backdrop_url': 'https://example.com/backdrop.jpg',
        'genres': <Map<String, dynamic>>[
          <String, dynamic>{'tmdb_id': 18, 'name': 'Drama'},
          <String, dynamic>{'tmdb_id': 9648, 'name': 'Mystery'},
        ],
        'original_language': 'en',
        'number_of_seasons': 2,
        'number_of_episodes': 19,
        'in_production': true,
        'status': 'Returning Series',
        'vote_average': 8.4,
        'vote_count': 3000,
      }).toDomain();

      expect(details.tmdbId, 95396);
      expect(details.title, 'Severance');
      expect(details.releaseYear, 2022);
      expect(details.numberOfSeasons, 2);
      expect(details.genres, <String>['Drama', 'Mystery']);
      expect(details.voteAverage, 8.4);
    });

    test('throws FormatException for invalid required data', () {
      expect(
        () => ShowDetailsDto.fromJson(<String, dynamic>{'tmdb_id': 'invalid'}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
