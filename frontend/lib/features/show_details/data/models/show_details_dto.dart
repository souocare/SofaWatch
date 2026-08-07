import 'package:sofawatch/features/show_details/domain/models/show_details.dart';

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
    required this.voteAverage,
    required this.voteCount,
    required this.genres,
    this.overview,
    this.tagline,
    this.firstAirDate,
    this.lastAirDate,
    this.posterUrl,
    this.backdropUrl,
  });

  factory ShowDetailsDto.fromJson(Map<String, dynamic> json) {
    return ShowDetailsDto(
      tmdbId: _requiredInt(json, 'tmdb_id'),
      title: _requiredString(json, 'title'),
      originalTitle: _requiredString(json, 'original_title'),
      overview: _nullableString(json['overview']),
      tagline: _nullableString(json['tagline']),
      firstAirDate: _nullableDate(json['first_air_date']),
      lastAirDate: _nullableDate(json['last_air_date']),
      posterUrl: _nullableString(json['poster_url']),
      backdropUrl: _nullableString(json['backdrop_url']),
      genres: _parseGenres(json['genres']),
      originalLanguage: _requiredString(json, 'original_language'),
      numberOfSeasons: _requiredInt(json, 'number_of_seasons'),
      numberOfEpisodes: _requiredInt(json, 'number_of_episodes'),
      inProduction: _requiredBool(json, 'in_production'),
      status: _requiredString(json, 'status'),
      voteAverage: _requiredDouble(json, 'vote_average'),
      voteCount: _requiredInt(json, 'vote_count'),
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

  final List<String> genres;

  final String originalLanguage;

  final int numberOfSeasons;
  final int numberOfEpisodes;

  final bool inProduction;
  final String status;

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
      genres: genres,
      originalLanguage: originalLanguage,
      numberOfSeasons: numberOfSeasons,
      numberOfEpisodes: numberOfEpisodes,
      inProduction: inProduction,
      status: status,
      voteAverage: voteAverage,
      voteCount: voteCount,
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final Object? value = json[key];

    if (value is! String) {
      throw FormatException('Expected "$key" to be a string.');
    }

    return value;
  }

  static int _requiredInt(Map<String, dynamic> json, String key) {
    final Object? value = json[key];

    if (value is! int) {
      throw FormatException('Expected "$key" to be an integer.');
    }

    return value;
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

    if (value is! bool) {
      throw FormatException('Expected "$key" to be a boolean.');
    }

    return value;
  }

  static String? _nullableString(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw const FormatException('Expected a nullable string.');
    }

    return value;
  }

  static DateTime? _nullableDate(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw const FormatException('Expected a nullable date string.');
    }

    final DateTime? parsedDate = DateTime.tryParse(value);

    if (parsedDate == null) {
      throw FormatException('Invalid date "$value".');
    }

    return parsedDate;
  }

  static List<String> _parseGenres(Object? value) {
    if (value is! List<dynamic>) {
      throw const FormatException('Expected "genres" to be a list.');
    }

    return value
        .map((dynamic genre) {
          if (genre is! Map<String, dynamic>) {
            throw const FormatException('Invalid genre object.');
          }

          return _requiredString(genre, 'name');
        })
        .toList(growable: false);
  }
}
