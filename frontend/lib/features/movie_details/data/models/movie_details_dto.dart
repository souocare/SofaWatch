import 'package:sofawatch/features/movie_details/domain/models/movie_details.dart';

final class MovieDetailsDto {
  const MovieDetailsDto({
    this.id,
    required this.tmdbId,
    required this.title,
    required this.originalTitle,
    required this.originalLanguage,
    required this.status,
    required this.voteAverage,
    required this.voteCount,
    required this.genres,
    this.overview,
    this.tagline,
    this.releaseDate,
    this.posterUrl,
    this.backdropUrl,
    this.runtime,
  });
  factory MovieDetailsDto.fromJson(Map<String, dynamic> json) {
    return MovieDetailsDto(
      id: _nullableString(json['id']),
      tmdbId: _requiredInt(json, 'tmdb_id'),
      title: _requiredString(json, 'title'),
      originalTitle: _requiredString(json, 'original_title'),
      overview: _nullableString(json['overview']),
      tagline: _nullableString(json['tagline']),
      releaseDate: _nullableDate(json['release_date']),
      posterUrl: _nullableString(json['poster_url']),
      backdropUrl: _nullableString(json['backdrop_url']),
      genres: _parseGenres(json['genres']),
      originalLanguage: _requiredString(json, 'original_language'),
      runtime: _nullableInt(json['runtime']),
      status: _requiredString(json, 'status'),
      voteAverage: _requiredDouble(json, 'vote_average'),
      voteCount: _requiredInt(json, 'vote_count'),
    );
  }

  final String? id;
  final int tmdbId;

  final String title;
  final String originalTitle;

  final String? overview;
  final String? tagline;

  final DateTime? releaseDate;

  final String? posterUrl;
  final String? backdropUrl;

  final List<String> genres;

  final String originalLanguage;

  final int? runtime;
  final String status;

  final double voteAverage;
  final int voteCount;

  MovieDetails toDomain() {
    return MovieDetails(
      id: id,
      tmdbId: tmdbId,
      title: title,
      originalTitle: originalTitle,
      overview: overview,
      tagline: tagline,
      releaseDate: releaseDate,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
      genres: genres,
      originalLanguage: originalLanguage,
      runtime: runtime,
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

  static int? _nullableInt(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is! int) {
      throw const FormatException('Expected a nullable integer.');
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
