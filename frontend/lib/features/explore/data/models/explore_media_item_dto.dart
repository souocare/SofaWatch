import 'package:sofawatch/features/explore/domain/entities/explore_media_item.dart';

class ExploreMediaItemDto {
  const ExploreMediaItemDto({
    required this.mediaType,
    required this.tmdbId,
    required this.title,
    required this.originalTitle,
    required this.originalLanguage,
    required this.genreIds,
    required this.popularity,
    required this.voteAverage,
    required this.voteCount,
    this.overview,
    this.releaseDate,
    this.posterUrl,
    this.backdropUrl,
  });

  factory ExploreMediaItemDto.fromJson(Map<String, dynamic> json) {
    return ExploreMediaItemDto(
      mediaType: _parseMediaType(json['media_type']),
      tmdbId: _readPositiveInt(json, 'tmdb_id'),
      title: _readString(json, 'title'),
      originalTitle: _readString(json, 'original_title'),
      overview: _readNullableString(json, 'overview'),
      releaseDate: _parseNullableDate(json['release_date']),
      posterUrl: _parseNullableUri(json['poster_url']),
      backdropUrl: _parseNullableUri(json['backdrop_url']),
      originalLanguage: _readString(json, 'original_language'),
      genreIds: _parseGenreIds(json['genre_ids']),
      popularity: _readDouble(json, 'popularity'),
      voteAverage: _readDouble(json, 'vote_average'),
      voteCount: _readNonNegativeInt(json, 'vote_count'),
    );
  }

  final ExploreMediaType mediaType;

  final int tmdbId;

  final String title;
  final String originalTitle;
  final String? overview;

  final DateTime? releaseDate;

  final Uri? posterUrl;
  final Uri? backdropUrl;

  final String originalLanguage;

  final List<int> genreIds;

  final double popularity;
  final double voteAverage;
  final int voteCount;

  ExploreMediaItem toDomain() {
    return ExploreMediaItem(
      mediaType: mediaType,
      tmdbId: tmdbId,
      title: title,
      originalTitle: originalTitle,
      overview: overview,
      releaseDate: releaseDate,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
      originalLanguage: originalLanguage,
      genreIds: List<int>.unmodifiable(genreIds),
      popularity: popularity,
      voteAverage: voteAverage,
      voteCount: voteCount,
    );
  }

  static ExploreMediaType _parseMediaType(Object? value) {
    return switch (value) {
      'show' => ExploreMediaType.show,
      'movie' => ExploreMediaType.movie,
      _ => throw const FormatException('Invalid Explore media type.'),
    };
  }

  static int _readPositiveInt(Map<String, dynamic> json, String key) {
    final Object? value = json[key];

    if (value is int && value > 0) {
      return value;
    }

    throw FormatException('Invalid positive integer for "$key".');
  }

  static int _readNonNegativeInt(Map<String, dynamic> json, String key) {
    final Object? value = json[key];

    if (value is int && value >= 0) {
      return value;
    }

    throw FormatException('Invalid non-negative integer for "$key".');
  }

  static double _readDouble(Map<String, dynamic> json, String key) {
    final Object? value = json[key];

    if (value is num) {
      return value.toDouble();
    }

    throw FormatException('Invalid number for "$key".');
  }

  static String _readString(Map<String, dynamic> json, String key) {
    final Object? value = json[key];

    if (value is String && value.trim().isNotEmpty) {
      return value;
    }

    throw FormatException('Invalid string for "$key".');
  }

  static String? _readNullableString(Map<String, dynamic> json, String key) {
    final Object? value = json[key];

    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw FormatException('Invalid nullable string for "$key".');
    }

    if (value.trim().isEmpty) {
      return null;
    }

    return value;
  }

  static DateTime? _parseNullableDate(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw const FormatException('Invalid Explore release date.');
    }

    if (value.trim().isEmpty) {
      return null;
    }

    final DateTime? date = DateTime.tryParse(value);

    if (date == null) {
      throw const FormatException('Invalid Explore release date.');
    }

    return date;
  }

  static Uri? _parseNullableUri(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw const FormatException('Invalid Explore image URL.');
    }

    if (value.trim().isEmpty) {
      return null;
    }

    final Uri? uri = Uri.tryParse(value);

    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const FormatException('Invalid Explore image URL.');
    }

    return uri;
  }

  static List<int> _parseGenreIds(Object? value) {
    if (value is! List<dynamic>) {
      throw const FormatException('Invalid Explore genre IDs.');
    }

    final List<int> genreIds = <int>[];

    for (final Object? item in value) {
      if (item is! int || item <= 0) {
        throw const FormatException('Invalid Explore genre ID.');
      }

      genreIds.add(item);
    }

    return List<int>.unmodifiable(genreIds);
  }
}
