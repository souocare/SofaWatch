import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/movies/domain/models/library_movie.dart';

final class LibraryMovieDto {
  factory LibraryMovieDto.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> movie = _requiredMap(json, 'movie');

    return LibraryMovieDto(
      libraryEntryId: _requiredString(json, 'id'),
      movieId: _requiredString(movie, 'id'),
      tmdbId: _requiredInt(movie, 'tmdb_id'),
      title: _requiredString(movie, 'title'),
      originalTitle: _requiredString(movie, 'original_title'),
      releaseDate: _optionalDate(movie['release_date']),
      posterUrl: _optionalString(movie['poster_url']),
      backdropUrl: _optionalString(movie['backdrop_url']),
      status: _parseLibraryStatus(_requiredString(json, 'status')),
      movieStatus: _requiredString(movie, 'status'),
      voteAverage: _requiredDouble(movie, 'vote_average'),
      rating: _optionalDouble(json['rating']),
      startedAt: _optionalDateTime(json['started_at']),
      completedAt: _optionalDateTime(json['completed_at']),
      createdAt: _requiredDateTime(json, 'created_at'),
      updatedAt: _requiredDateTime(json, 'updated_at'),
    );
  }
  const LibraryMovieDto({
    required this.libraryEntryId,
    required this.movieId,
    required this.tmdbId,
    required this.title,
    required this.originalTitle,
    required this.status,
    required this.movieStatus,
    required this.voteAverage,
    required this.createdAt,
    required this.updatedAt,
    this.releaseDate,
    this.posterUrl,
    this.backdropUrl,
    this.rating,
    this.startedAt,
    this.completedAt,
  });

  final String libraryEntryId;

  final String movieId;
  final int tmdbId;

  final String title;
  final String originalTitle;

  final DateTime? releaseDate;

  final String? posterUrl;
  final String? backdropUrl;

  final LibraryStatus status;
  final String movieStatus;

  final double voteAverage;
  final double? rating;

  final DateTime? startedAt;
  final DateTime? completedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  LibraryMovie toDomain() {
    return LibraryMovie(
      libraryEntryId: libraryEntryId,
      movieId: movieId,
      tmdbId: tmdbId,
      title: title,
      originalTitle: originalTitle,
      releaseDate: releaseDate,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
      status: status,
      movieStatus: movieStatus,
      voteAverage: voteAverage,
      rating: rating,
      startedAt: startedAt,
      completedAt: completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! Map<String, dynamic>) {
    throw FormatException('Invalid $key.');
  }

  return value;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Invalid $key.');
  }

  return value;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! int || value <= 0) {
    throw FormatException('Invalid $key.');
  }

  return value;
}

double _requiredDouble(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is num) {
    return value.toDouble();
  }

  throw FormatException('Invalid $key.');
}

String? _optionalString(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is! String) {
    throw const FormatException('Invalid optional string.');
  }

  final String normalized = value.trim();

  return normalized.isEmpty ? null : normalized;
}

double? _optionalDouble(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  throw const FormatException('Invalid optional double.');
}

DateTime? _optionalDate(Object? value) {
  final String? raw = _optionalString(value);

  if (raw == null) {
    return null;
  }

  final DateTime? parsed = DateTime.tryParse(raw);

  if (parsed == null) {
    throw const FormatException('Invalid optional date.');
  }

  return parsed;
}

DateTime? _optionalDateTime(Object? value) {
  final String? raw = _optionalString(value);

  if (raw == null) {
    return null;
  }

  final DateTime? parsed = DateTime.tryParse(raw);

  if (parsed == null) {
    throw const FormatException('Invalid optional datetime.');
  }

  return parsed;
}

DateTime _requiredDateTime(Map<String, dynamic> json, String key) {
  final String raw = _requiredString(json, key);

  final DateTime? parsed = DateTime.tryParse(raw);

  if (parsed == null) {
    throw FormatException('Invalid $key.');
  }

  return parsed;
}

LibraryStatus _parseLibraryStatus(String value) {
  return switch (value) {
    'planning' => LibraryStatus.planning,
    'watching' => LibraryStatus.watching,
    'completed' => LibraryStatus.completed,
    'paused' => LibraryStatus.paused,
    'dropped' => LibraryStatus.dropped,
    _ => throw FormatException('Invalid Library status: $value.'),
  };
}
