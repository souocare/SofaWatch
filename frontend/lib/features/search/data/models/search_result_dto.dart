import 'package:sofawatch/features/search/domain/entities/search_media_type.dart';
import 'package:sofawatch/features/search/domain/entities/search_result.dart';

class SearchResultDto {
  const SearchResultDto({
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

  factory SearchResultDto.fromJson(Map<String, dynamic> json) {
    return SearchResultDto(
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

  final SearchMediaType mediaType;
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

  SearchResult toDomain() {
    return SearchResult(
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

  static SearchMediaType _parseMediaType(Object? value) {
    return switch (value) {
      'show' => SearchMediaType.show,
      'movie' => SearchMediaType.movie,
      _ => throw const FormatException('Invalid search result media type.'),
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

    final String normalizedValue = value.trim();

    if (normalizedValue.isEmpty) {
      return null;
    }

    return value;
  }

  static DateTime? _parseNullableDate(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw const FormatException('Invalid search result release date.');
    }

    final String normalizedValue = value.trim();

    if (normalizedValue.isEmpty) {
      return null;
    }

    final DateTime? parsedDate = DateTime.tryParse(normalizedValue);

    if (parsedDate == null) {
      throw const FormatException('Invalid search result release date.');
    }

    return parsedDate;
  }

  static Uri? _parseNullableUri(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw const FormatException('Invalid search result image URL.');
    }

    final String normalizedValue = value.trim();

    if (normalizedValue.isEmpty) {
      return null;
    }

    final Uri? uri = Uri.tryParse(normalizedValue);

    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const FormatException('Invalid search result image URL.');
    }

    return uri;
  }

  static List<int> _parseGenreIds(Object? value) {
    if (value is! List<dynamic>) {
      throw const FormatException('Invalid search result genre IDs.');
    }

    final List<int> genreIds = <int>[];

    for (final Object? item in value) {
      if (item is! int || item <= 0) {
        throw const FormatException('Invalid search result genre ID.');
      }

      genreIds.add(item);
    }

    return List<int>.unmodifiable(genreIds);
  }
}
