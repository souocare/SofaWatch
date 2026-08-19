import 'package:sofawatch/features/library/domain/models/library_preview.dart';

final class LibraryPreviewDto {
  const LibraryPreviewDto({required this.shows, required this.movies});

  final List<LibraryPreviewShowDto> shows;
  final List<LibraryPreviewMovieDto> movies;

  factory LibraryPreviewDto.fromJson(Map<String, dynamic> json) {
    return LibraryPreviewDto(
      shows: _parseList(
        json,
        key: 'shows',
        parser: LibraryPreviewShowDto.fromJson,
      ),
      movies: _parseList(
        json,
        key: 'movies',
        parser: LibraryPreviewMovieDto.fromJson,
      ),
    );
  }

  LibraryPreview toDomain({
    required String? Function(String? path) resolveUrl,
  }) {
    return LibraryPreview(
      shows: shows
          .map(
            (LibraryPreviewShowDto item) =>
                item.toDomain(resolveUrl: resolveUrl),
          )
          .toList(growable: false),
      movies: movies
          .map(
            (LibraryPreviewMovieDto item) =>
                item.toDomain(resolveUrl: resolveUrl),
          )
          .toList(growable: false),
    );
  }
}

final class LibraryPreviewShowDto {
  const LibraryPreviewShowDto({
    required this.id,
    required this.tmdbId,
    required this.title,
    required this.posterUrl,
  });

  final String id;
  final int tmdbId;
  final String title;
  final String? posterUrl;

  factory LibraryPreviewShowDto.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> show = _requiredObject(json, 'show');

    return LibraryPreviewShowDto(
      id: _requiredString(show, 'id'),
      tmdbId: _requiredPositiveInt(show, 'tmdb_id'),
      title: _requiredString(show, 'title'),
      posterUrl: _nullableString(show, 'poster_url'),
    );
  }

  LibraryPreviewShow toDomain({
    required String? Function(String? path) resolveUrl,
  }) {
    return LibraryPreviewShow(
      id: id,
      tmdbId: tmdbId,
      title: title,
      posterUrl: _resolveOptionalUrl(posterUrl, resolveUrl: resolveUrl),
    );
  }
}

final class LibraryPreviewMovieDto {
  const LibraryPreviewMovieDto({
    required this.id,
    required this.tmdbId,
    required this.title,
    required this.posterUrl,
  });

  final String id;
  final int tmdbId;
  final String title;
  final String? posterUrl;

  factory LibraryPreviewMovieDto.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> movie = _requiredObject(json, 'movie');

    return LibraryPreviewMovieDto(
      id: _requiredString(movie, 'id'),
      tmdbId: _requiredPositiveInt(movie, 'tmdb_id'),
      title: _requiredString(movie, 'title'),
      posterUrl: _nullableString(movie, 'poster_url'),
    );
  }

  LibraryPreviewMovie toDomain({
    required String? Function(String? path) resolveUrl,
  }) {
    return LibraryPreviewMovie(
      id: id,
      tmdbId: tmdbId,
      title: title,
      posterUrl: _resolveOptionalUrl(posterUrl, resolveUrl: resolveUrl),
    );
  }
}

List<T> _parseList<T>(
  Map<String, dynamic> json, {
  required String key,
  required T Function(Map<String, dynamic> json) parser,
}) {
  final Object? rawValue = json[key];

  if (rawValue is! List<dynamic>) {
    throw FormatException('$key must be a list.');
  }

  return rawValue
      .map((dynamic item) {
        if (item is! Map<String, dynamic>) {
          throw FormatException('$key must contain objects.');
        }

        return parser(item);
      })
      .toList(growable: false);
}

Map<String, dynamic> _requiredObject(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! Map<String, dynamic>) {
    throw FormatException('$key must be an object.');
  }

  return value;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }

  return value;
}

int _requiredPositiveInt(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! int || value <= 0) {
    throw FormatException('$key must be a positive integer.');
  }

  return value;
}

String? _nullableString(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value == null) {
    return null;
  }

  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be null or a non-empty string.');
  }

  return value;
}

String? _resolveOptionalUrl(
  String? value, {
  required String? Function(String? path) resolveUrl,
}) {
  if (value == null) {
    return null;
  }

  return resolveUrl(value);
}
