import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/search/data/models/search_result_dto.dart';
import 'package:sofawatch/features/search/domain/entities/search_media_type.dart';
import 'package:sofawatch/features/search/domain/entities/search_result.dart';

void main() {
  group('SearchResultDto', () {
    test('parses and maps a show result', () {
      final SearchResultDto dto = SearchResultDto.fromJson(<String, dynamic>{
        'media_type': 'show',
        'tmdb_id': 95396,
        'title': 'Severance',
        'original_title': 'Severance',
        'overview': 'Employees undergo a severance procedure.',
        'release_date': '2022-02-17',
        'poster_url': 'https://image.tmdb.org/t/p/w500/severance.jpg',
        'backdrop_url': 'https://image.tmdb.org/t/p/original/severance.jpg',
        'original_language': 'en',
        'genre_ids': <int>[18, 9648],
        'popularity': 120.5,
        'vote_average': 8.4,
        'vote_count': 2100,
        'in_library': false,
      });

      final SearchResult result = dto.toDomain();

      expect(result.mediaType, SearchMediaType.show);
      expect(result.tmdbId, 95396);
      expect(result.title, 'Severance');
      expect(result.releaseDate, DateTime(2022, 2, 17));
      expect(
        result.posterUrl,
        Uri.parse('https://image.tmdb.org/t/p/w500/severance.jpg'),
      );
      expect(result.genreIds, <int>[18, 9648]);
      expect(result.voteAverage, 8.4);
    });

    test('parses and maps a movie result', () {
      final SearchResult result = SearchResultDto.fromJson(<String, dynamic>{
        'media_type': 'movie',
        'tmdb_id': 438631,
        'title': 'Dune',
        'original_title': 'Dune',
        'overview': 'Paul Atreides travels to Arrakis.',
        'release_date': '2021-09-15',
        'poster_url': 'https://image.tmdb.org/t/p/w500/dune.jpg',
        'backdrop_url': 'https://image.tmdb.org/t/p/original/dune.jpg',
        'original_language': 'en',
        'genre_ids': <int>[878, 12],
        'popularity': 95,
        'vote_average': 7.8,
        'vote_count': 13000,
        'in_library': false,
      }).toDomain();

      expect(result.mediaType, SearchMediaType.movie);
      expect(result.tmdbId, 438631);
      expect(result.popularity, 95.0);
      expect(result.releaseYear, 2021);
    });

    test('normalizes empty optional strings to null', () {
      final SearchResult result = SearchResultDto.fromJson(<String, dynamic>{
        'media_type': 'movie',
        'tmdb_id': 438631,
        'title': 'Dune',
        'original_title': 'Dune',
        'overview': '   ',
        'release_date': '',
        'poster_url': '',
        'backdrop_url': null,
        'original_language': 'en',
        'genre_ids': <int>[],
        'popularity': 0,
        'vote_average': 0,
        'vote_count': 0,
        'in_library': false,
      }).toDomain();

      expect(result.overview, isNull);
      expect(result.releaseDate, isNull);
      expect(result.posterUrl, isNull);
      expect(result.backdropUrl, isNull);
    });

    test('creates an unmodifiable genre list in the domain entity', () {
      final SearchResult result = SearchResultDto.fromJson(<String, dynamic>{
        'media_type': 'movie',
        'tmdb_id': 438631,
        'title': 'Dune',
        'original_title': 'Dune',
        'overview': null,
        'release_date': null,
        'poster_url': null,
        'backdrop_url': null,
        'original_language': 'en',
        'genre_ids': <int>[878, 12],
        'popularity': 0,
        'vote_average': 0,
        'vote_count': 0,
        'in_library': false,
      }).toDomain();

      expect(() => result.genreIds.add(18), throwsUnsupportedError);
    });

    test('rejects an unsupported media type', () {
      expect(
        () => SearchResultDto.fromJson(_validJson(mediaType: 'person')),
        throwsFormatException,
      );
    });

    test('rejects a non-positive TMDB ID', () {
      expect(
        () => SearchResultDto.fromJson(_validJson(tmdbId: 0)),
        throwsFormatException,
      );
    });

    test('rejects an invalid release date', () {
      expect(
        () => SearchResultDto.fromJson(_validJson(releaseDate: 'not-a-date')),
        throwsFormatException,
      );
    });

    test('rejects an image URL without an HTTP scheme', () {
      expect(
        () => SearchResultDto.fromJson(_validJson(posterUrl: '/poster.jpg')),
        throwsFormatException,
      );
    });

    test('rejects invalid genre IDs', () {
      final Map<String, dynamic> json = _validJson();

      json['genre_ids'] = <Object>[18, 'invalid'];

      expect(() => SearchResultDto.fromJson(json), throwsFormatException);
    });

    test('rejects a negative vote count', () {
      final Map<String, dynamic> json = _validJson();

      json['vote_count'] = -1;

      expect(() => SearchResultDto.fromJson(json), throwsFormatException);
    });
  });
  test('maps the library state', () {
    final Map<String, dynamic> json = _validJson();

    json['in_library'] = true;

    final SearchResult result = SearchResultDto.fromJson(json).toDomain();

    expect(result.inLibrary, isTrue);
  });

  test('rejects an invalid library state', () {
    final Map<String, dynamic> json = _validJson();

    json['in_library'] = 'yes';

    expect(() => SearchResultDto.fromJson(json), throwsFormatException);
  });
}

Map<String, dynamic> _validJson({
  String mediaType = 'movie',
  int tmdbId = 438631,
  String? releaseDate = '2021-09-15',
  String? posterUrl = 'https://image.tmdb.org/t/p/w500/dune.jpg',
}) {
  return <String, dynamic>{
    'media_type': mediaType,
    'tmdb_id': tmdbId,
    'title': 'Dune',
    'original_title': 'Dune',
    'overview': 'Paul Atreides travels to Arrakis.',
    'release_date': releaseDate,
    'poster_url': posterUrl,
    'backdrop_url': 'https://image.tmdb.org/t/p/original/dune.jpg',
    'original_language': 'en',
    'genre_ids': <int>[878, 12],
    'popularity': 95.4,
    'vote_average': 7.8,
    'vote_count': 13000,
    'in_library': false,
  };
}
