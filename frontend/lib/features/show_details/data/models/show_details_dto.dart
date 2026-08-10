import 'package:sofawatch/features/show_details/domain/models/show_details.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_genre.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_network.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_season.dart';

final class ShowDetailsDto {
  const ShowDetailsDto({
    required this.tmdbId,
    required this.title,
    required this.originalTitle,
    required this.originalLanguage,
    required this.numberOfSeasons,
    required this.numberOfEpisodes,
    required this.inProduction,
    required this.status,
    required this.showType,
    required this.popularity,
    required this.voteAverage,
    required this.voteCount,
    required this.genres,
    required this.seasons,
    required this.networks,
    required this.episodeRunTimes,
    this.overview,
    this.tagline,
    this.firstAirDate,
    this.lastAirDate,
    this.posterUrl,
    this.backdropUrl,
    this.homepageUrl,
  });

  factory ShowDetailsDto.fromJson(Map<String, dynamic> json) {
    return ShowDetailsDto(
      tmdbId: _requiredPositiveInt(json, 'tmdb_id'),
      title: _requiredString(json, 'title'),
      originalTitle: _requiredString(json, 'original_title'),
      overview: _nullableString(json['overview']),
      tagline: _nullableString(json['tagline']),
      firstAirDate: _nullableDate(json['first_air_date']),
      lastAirDate: _nullableDate(json['last_air_date']),
      posterUrl: _nullableString(json['poster_url']),
      backdropUrl: _nullableString(json['backdrop_url']),
      homepageUrl: _nullableString(json['homepage_url']),
      genres: _parseGenres(json['genres']),
      seasons: _parseSeasons(json['seasons']),
      networks: _parseNetworks(json['networks']),
      originalLanguage: _requiredString(json, 'original_language'),
      episodeRunTimes: _parseEpisodeRunTimes(json['episode_run_times']),
      numberOfSeasons: _requiredNonNegativeInt(json, 'number_of_seasons'),
      numberOfEpisodes: _requiredNonNegativeInt(json, 'number_of_episodes'),
      inProduction: _requiredBool(json, 'in_production'),
      status: _requiredString(json, 'status'),
      showType: _requiredString(json, 'show_type'),
      popularity: _requiredDouble(json, 'popularity'),
      voteAverage: _requiredDouble(json, 'vote_average'),
      voteCount: _requiredNonNegativeInt(json, 'vote_count'),
    );
  }

  final int tmdbId;

  final String title;
  final String originalTitle;

  final String? overview;
  final String? tagline;

  final DateTime? firstAirDate;
  final DateTime? lastAirDate;

  final String? posterUrl;
  final String? backdropUrl;
  final String? homepageUrl;

  final List<ShowDetailsGenre> genres;
  final List<ShowDetailsSeason> seasons;
  final List<ShowDetailsNetwork> networks;

  final String originalLanguage;

  final List<int> episodeRunTimes;

  final int numberOfSeasons;
  final int numberOfEpisodes;

  final bool inProduction;

  final String status;
  final String showType;

  final double popularity;

  final double voteAverage;
  final int voteCount;

  ShowDetails toDomain() {
    return ShowDetails(
      tmdbId: tmdbId,
      title: title,
      originalTitle: originalTitle,
      overview: overview,
      tagline: tagline,
      firstAirDate: firstAirDate,
      lastAirDate: lastAirDate,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
      homepageUrl: homepageUrl,
      genres: List<ShowDetailsGenre>.unmodifiable(genres),
      seasons: List<ShowDetailsSeason>.unmodifiable(seasons),
      networks: List<ShowDetailsNetwork>.unmodifiable(networks),
      originalLanguage: originalLanguage,
      episodeRunTimes: List<int>.unmodifiable(episodeRunTimes),
      numberOfSeasons: numberOfSeasons,
      numberOfEpisodes: numberOfEpisodes,
      inProduction: inProduction,
      status: status,
      showType: showType,
      popularity: popularity,
      voteAverage: voteAverage,
      voteCount: voteCount,
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final Object? value = json[key];

    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    throw FormatException('Expected "$key" to be a non-empty string.');
  }

  static int _requiredPositiveInt(Map<String, dynamic> json, String key) {
    final Object? value = json[key];

    if (value is int && value > 0) {
      return value;
    }

    throw FormatException('Expected "$key" to be a positive integer.');
  }

  static int _requiredNonNegativeInt(Map<String, dynamic> json, String key) {
    final Object? value = json[key];

    if (value is int && value >= 0) {
      return value;
    }

    throw FormatException('Expected "$key" to be a non-negative integer.');
  }

  static double _requiredDouble(Map<String, dynamic> json, String key) {
    final Object? value = json[key];

    if (value is num) {
      return value.toDouble();
    }

    throw FormatException('Expected "$key" to be a number.');
  }

  static bool _requiredBool(Map<String, dynamic> json, String key) {
    final Object? value = json[key];

    if (value is bool) {
      return value;
    }

    throw FormatException('Expected "$key" to be a boolean.');
  }

  static String? _nullableString(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw const FormatException('Expected a nullable string.');
    }

    final String trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  static DateTime? _nullableDate(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw const FormatException('Expected a nullable date string.');
    }

    final String trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    final DateTime? parsedDate = DateTime.tryParse(trimmed);

    if (parsedDate == null) {
      throw FormatException('Invalid date "$value".');
    }

    return parsedDate;
  }

  static List<ShowDetailsGenre> _parseGenres(Object? value) {
    if (value is! List<dynamic>) {
      throw const FormatException('Expected "genres" to be a list.');
    }

    return value
        .map((Object? genre) {
          if (genre is! Map<String, dynamic>) {
            throw const FormatException('Invalid genre object.');
          }

          return ShowDetailsGenre(
            tmdbId: _requiredPositiveInt(genre, 'tmdb_id'),
            name: _requiredString(genre, 'name'),
          );
        })
        .toList(growable: false);
  }

  static List<ShowDetailsSeason> _parseSeasons(Object? value) {
    if (value is! List<dynamic>) {
      throw const FormatException('Expected "seasons" to be a list.');
    }

    return value
        .map((Object? season) {
          if (season is! Map<String, dynamic>) {
            throw const FormatException('Invalid season object.');
          }

          return ShowDetailsSeason(
            tmdbId: _requiredPositiveInt(season, 'tmdb_id'),
            seasonNumber: _requiredNonNegativeInt(season, 'season_number'),
            title: _requiredString(season, 'title'),
            overview: _nullableString(season['overview']),
            airDate: _nullableDate(season['air_date']),
            episodeCount: _requiredNonNegativeInt(season, 'episode_count'),
            posterPath: _nullableString(season['poster_path']),
            voteAverage: _requiredDouble(season, 'vote_average'),
          );
        })
        .toList(growable: false);
  }

  static List<ShowDetailsNetwork> _parseNetworks(Object? value) {
    if (value is! List<dynamic>) {
      throw const FormatException('Expected "networks" to be a list.');
    }

    return value
        .map((Object? network) {
          if (network is! Map<String, dynamic>) {
            throw const FormatException('Invalid network object.');
          }

          return ShowDetailsNetwork(
            tmdbId: _requiredPositiveInt(network, 'tmdb_id'),
            name: _requiredString(network, 'name'),
            logoPath: _nullableString(network['logo_path']),
            logoUrl: _nullableString(network['logo_url']),
            originCountry: _nullableString(network['origin_country']) ?? '',
          );
        })
        .toList(growable: false);
  }

  static List<int> _parseEpisodeRunTimes(Object? value) {
    if (value is! List<dynamic>) {
      throw const FormatException('Expected "episode_run_times" to be a list.');
    }

    final List<int> runtimes = <int>[];

    for (final Object? runtime in value) {
      if (runtime is! int || runtime < 0) {
        throw const FormatException('Invalid episode runtime.');
      }

      runtimes.add(runtime);
    }

    return List<int>.unmodifiable(runtimes);
  }
}
