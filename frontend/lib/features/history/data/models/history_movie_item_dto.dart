import 'package:sofawatch/features/history/domain/models/history_movie_item.dart';

final class HistoryMovieItemDto {
  const HistoryMovieItemDto({
    required this.eventId,
    required this.watchedAt,
    required this.movieId,
    required this.movieTmdbId,
    required this.movieTitle,
    this.posterUrl,
    this.backdropUrl,
  });

  factory HistoryMovieItemDto.fromJson(Map<String, dynamic> json) {
    final String mediaType = _requiredString(json, 'media_type');

    if (mediaType != 'movie') {
      throw const FormatException('History item must be a Movie.');
    }

    final Map<String, dynamic> movie = _requiredObject(json, 'movie');

    return HistoryMovieItemDto(
      eventId: _requiredString(json, 'event_id'),
      watchedAt: _requiredDateTime(json, 'watched_at'),
      movieId: _requiredString(movie, 'id'),
      movieTmdbId: _requiredPositiveInt(movie, 'tmdb_id'),
      movieTitle: _requiredString(movie, 'title'),
      posterUrl: _optionalString(movie['poster_url']),
      backdropUrl: _optionalString(movie['backdrop_url']),
    );
  }

  final String eventId;
  final DateTime watchedAt;

  final String movieId;
  final int movieTmdbId;
  final String movieTitle;

  final String? posterUrl;
  final String? backdropUrl;

  HistoryMovieItem toDomain({
    required String Function(String path) resolveUrl,
  }) {
    return HistoryMovieItem(
      eventId: eventId,
      watchedAt: watchedAt,
      movieId: movieId,
      movieTmdbId: movieTmdbId,
      movieTitle: movieTitle,
      posterUrl: _resolveOptionalUrl(posterUrl, resolveUrl: resolveUrl),
      backdropUrl: _resolveOptionalUrl(backdropUrl, resolveUrl: resolveUrl),
    );
  }
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

  return value.trim();
}

int _requiredPositiveInt(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! int || value <= 0) {
    throw FormatException('$key must be a positive integer.');
  }

  return value;
}

DateTime _requiredDateTime(Map<String, dynamic> json, String key) {
  final String rawValue = _requiredString(json, key);

  final DateTime? parsed = DateTime.tryParse(rawValue);

  if (parsed == null) {
    throw FormatException('$key must be a valid datetime.');
  }

  return parsed;
}

String? _optionalString(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('Optional string must be null or non-empty.');
  }

  return value.trim();
}

String? _resolveOptionalUrl(
  String? value, {
  required String Function(String path) resolveUrl,
}) {
  if (value == null) {
    return null;
  }

  return resolveUrl(value);
}
