import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/explore/data/models/explore_trending_dto.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_item.dart';

void main() {
  test('parses trending Shows and Movies', () {
    final ExploreTrendingDto dto = ExploreTrendingDto.fromJson(
      <String, dynamic>{
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'media_type': 'show',
            'tmdb_id': 95396,
            'title': 'Severance',
            'original_title': 'Severance',
            'overview': 'Employees undergo a severance procedure.',
            'release_date': '2022-02-17',
            'poster_url': 'https://image.tmdb.org/t/p/w500/severance.jpg',
            'backdrop_url': null,
            'original_language': 'en',
            'genre_ids': <int>[18, 9648],
            'popularity': 120.5,
            'vote_average': 8.4,
            'vote_count': 2100,
            'in_library': false,
          },
          <String, dynamic>{
            'media_type': 'movie',
            'tmdb_id': 438631,
            'title': 'Dune',
            'original_title': 'Dune',
            'overview': 'Paul Atreides travels to Arrakis.',
            'release_date': '2021-09-15',
            'poster_url': 'https://image.tmdb.org/t/p/w500/dune.jpg',
            'backdrop_url': null,
            'original_language': 'en',
            'genre_ids': <int>[878, 12],
            'popularity': 95.4,
            'vote_average': 7.8,
            'vote_count': 13000,
            'in_library': false,
          },
        ],
      },
    );

    final trending = dto.toDomain();

    expect(trending.items, hasLength(2));

    expect(trending.items[0].mediaType, ExploreMediaType.show);

    expect(trending.items[0].title, 'Severance');

    expect(trending.items[1].mediaType, ExploreMediaType.movie);

    expect(trending.items[1].title, 'Dune');

    expect(trending.shows, hasLength(1));
    expect(trending.movies, hasLength(1));
  });

  test('preserves the provider ordering', () {
    final ExploreTrendingDto dto = ExploreTrendingDto.fromJson(
      <String, dynamic>{
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'media_type': 'movie',
            'tmdb_id': 438631,
            'title': 'Dune',
            'original_title': 'Dune',
            'overview': '',
            'release_date': '2021-09-15',
            'poster_url': null,
            'backdrop_url': null,
            'original_language': 'en',
            'genre_ids': <int>[878],
            'popularity': 95,
            'vote_average': 7.8,
            'vote_count': 13000,
            'in_library': false,
          },
          <String, dynamic>{
            'media_type': 'show',
            'tmdb_id': 95396,
            'title': 'Severance',
            'original_title': 'Severance',
            'overview': '',
            'release_date': '2022-02-17',
            'poster_url': null,
            'backdrop_url': null,
            'original_language': 'en',
            'genre_ids': <int>[18],
            'popularity': 120,
            'vote_average': 8.4,
            'vote_count': 2100,
            'in_library': false,
          },
        ],
      },
    );

    final trending = dto.toDomain();

    expect(
      trending.items.map((ExploreMediaItem item) => item.mediaType),
      <ExploreMediaType>[ExploreMediaType.movie, ExploreMediaType.show],
    );
  });

  test('rejects an invalid items value', () {
    expect(
      () => ExploreTrendingDto.fromJson(<String, dynamic>{'items': 'invalid'}),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects an invalid trending item', () {
    expect(
      () => ExploreTrendingDto.fromJson(<String, dynamic>{
        'items': <dynamic>['invalid'],
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects an invalid media type', () {
    expect(
      () => ExploreTrendingDto.fromJson(<String, dynamic>{
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'media_type': 'person',
            'tmdb_id': 1,
            'title': 'Someone',
            'original_title': 'Someone',
            'overview': '',
            'release_date': null,
            'poster_url': null,
            'backdrop_url': null,
            'original_language': 'en',
            'genre_ids': <int>[],
            'popularity': 1,
            'vote_average': 0,
            'vote_count': 0,
            'in_library': false,
          },
        ],
      }),
      throwsA(isA<FormatException>()),
    );
  });
}
