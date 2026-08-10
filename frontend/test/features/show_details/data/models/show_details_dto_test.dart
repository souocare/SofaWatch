import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/show_details/data/models/show_details_dto.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details.dart';

void main() {
  group('ShowDetailsDto', () {
    test('maps a complete API response to the domain model', () {
      final ShowDetails details = ShowDetailsDto.fromJson(
        _completeResponse(),
      ).toDomain();

      expect(details.tmdbId, 95396);

      expect(details.title, 'Severance');

      expect(details.originalTitle, 'Severance');

      expect(details.overview, 'A mysterious workplace thriller.');

      expect(details.tagline, 'We work for Lumon.');

      expect(details.firstAirDate, DateTime(2022, 2, 17));

      expect(details.lastAirDate, DateTime(2025, 3, 20));

      expect(details.releaseYear, 2022);

      expect(details.endYear, 2025);

      expect(details.posterUrl, 'https://example.com/poster.jpg');

      expect(details.backdropUrl, 'https://example.com/backdrop.jpg');

      expect(details.homepageUrl, 'https://tv.apple.com/show/severance');

      expect(details.originalLanguage, 'en');

      expect(details.numberOfSeasons, 2);

      expect(details.numberOfEpisodes, 19);

      expect(details.inProduction, isTrue);

      expect(details.status, 'Returning Series');

      expect(details.showType, 'Scripted');

      expect(details.popularity, 120.5);

      expect(details.voteAverage, 8.4);

      expect(details.voteCount, 3000);
    });

    test('maps structured genres', () {
      final ShowDetails details = ShowDetailsDto.fromJson(
        _completeResponse(),
      ).toDomain();

      expect(details.genres, hasLength(2));

      expect(details.genres[0].tmdbId, 18);

      expect(details.genres[0].name, 'Drama');

      expect(details.genres[1].tmdbId, 9648);

      expect(details.genres[1].name, 'Mystery');
    });

    test('maps seasons', () {
      final ShowDetails details = ShowDetailsDto.fromJson(
        _completeResponse(),
      ).toDomain();

      expect(details.seasons, hasLength(2));

      final firstSeason = details.seasons[0];

      expect(firstSeason.tmdbId, 134792);

      expect(firstSeason.seasonNumber, 1);

      expect(firstSeason.title, 'Season 1');

      expect(firstSeason.airDate, DateTime(2022, 2, 17));

      expect(firstSeason.airYear, 2022);

      expect(firstSeason.episodeCount, 9);

      expect(firstSeason.posterPath, '/season-1.jpg');

      expect(firstSeason.voteAverage, 8.4);

      expect(firstSeason.isSpecial, isFalse);
    });

    test('maps networks', () {
      final ShowDetails details = ShowDetailsDto.fromJson(
        _completeResponse(),
      ).toDomain();

      expect(details.networks, hasLength(1));

      final network = details.networks.single;

      expect(network.tmdbId, 2552);

      expect(network.name, 'Apple TV+');

      expect(network.logoPath, '/apple-tv.png');

      expect(network.logoUrl, 'https://example.com/apple-tv.png');

      expect(network.originCountry, 'US');
    });

    test('maps episode runtimes', () {
      final ShowDetails details = ShowDetailsDto.fromJson(
        _completeResponse(),
      ).toDomain();

      expect(details.episodeRunTimes, <int>[50, 55]);

      expect(details.primaryEpisodeRunTime, 50);
    });

    test('supports empty optional collections', () {
      final Map<String, dynamic> response = _completeResponse();

      response['genres'] = <dynamic>[];
      response['seasons'] = <dynamic>[];
      response['networks'] = <dynamic>[];
      response['episode_run_times'] = <dynamic>[];

      final ShowDetails details = ShowDetailsDto.fromJson(response).toDomain();

      expect(details.genres, isEmpty);

      expect(details.seasons, isEmpty);

      expect(details.networks, isEmpty);

      expect(details.episodeRunTimes, isEmpty);

      expect(details.primaryEpisodeRunTime, isNull);
    });

    test('normalizes empty optional strings to null', () {
      final Map<String, dynamic> response = _completeResponse();

      response['tagline'] = '';
      response['homepage_url'] = '   ';

      final ShowDetails details = ShowDetailsDto.fromJson(response).toDomain();

      expect(details.tagline, isNull);

      expect(details.homepageUrl, isNull);
    });

    test('throws FormatException for invalid required data', () {
      expect(
        () => ShowDetailsDto.fromJson(<String, dynamic>{'tmdb_id': 'invalid'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException for invalid season data', () {
      final Map<String, dynamic> response = _completeResponse();

      response['seasons'] = <Map<String, dynamic>>[
        <String, dynamic>{
          'tmdb_id': 10,
          'season_number': -1,
          'title': 'Invalid',
          'overview': '',
          'air_date': null,
          'episode_count': 1,
          'poster_path': null,
          'vote_average': 0.0,
        },
      ];

      expect(
        () => ShowDetailsDto.fromJson(response),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

Map<String, dynamic> _completeResponse() {
  return <String, dynamic>{
    'tmdb_id': 95396,
    'title': 'Severance',
    'original_title': 'Severance',
    'overview': 'A mysterious workplace thriller.',
    'tagline': 'We work for Lumon.',
    'first_air_date': '2022-02-17',
    'last_air_date': '2025-03-20',
    'poster_url': 'https://example.com/poster.jpg',
    'backdrop_url': 'https://example.com/backdrop.jpg',
    'homepage_url': 'https://tv.apple.com/show/severance',
    'genres': <Map<String, dynamic>>[
      <String, dynamic>{'tmdb_id': 18, 'name': 'Drama'},
      <String, dynamic>{'tmdb_id': 9648, 'name': 'Mystery'},
    ],
    'seasons': <Map<String, dynamic>>[
      <String, dynamic>{
        'tmdb_id': 134792,
        'season_number': 1,
        'title': 'Season 1',
        'overview': 'The first season.',
        'air_date': '2022-02-17',
        'episode_count': 9,
        'poster_path': '/season-1.jpg',
        'vote_average': 8.4,
      },
      <String, dynamic>{
        'tmdb_id': 368201,
        'season_number': 2,
        'title': 'Season 2',
        'overview': 'The second season.',
        'air_date': '2025-01-17',
        'episode_count': 10,
        'poster_path': '/season-2.jpg',
        'vote_average': 8.6,
      },
    ],
    'networks': <Map<String, dynamic>>[
      <String, dynamic>{
        'tmdb_id': 2552,
        'name': 'Apple TV+',
        'logo_path': '/apple-tv.png',
        'logo_url': 'https://example.com/apple-tv.png',
        'origin_country': 'US',
      },
    ],
    'original_language': 'en',
    'episode_run_times': <int>[50, 55],
    'number_of_seasons': 2,
    'number_of_episodes': 19,
    'in_production': true,
    'status': 'Returning Series',
    'show_type': 'Scripted',
    'popularity': 120.5,
    'vote_average': 8.4,
    'vote_count': 3000,
  };
}
