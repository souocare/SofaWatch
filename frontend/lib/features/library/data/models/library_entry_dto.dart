import 'package:sofawatch/features/library/domain/models/library_entry.dart';
import 'package:sofawatch/features/library/domain/models/library_media_type.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';

final class LibraryEntryDto {
  const LibraryEntryDto({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.showId,
    this.movieId,
    this.rating,
    this.startedAt,
    this.completedAt,
  });

  factory LibraryEntryDto.fromJson(Map<String, dynamic> json) {
    final String? showId = _nullableString(json['show_id'], key: 'show_id');

    final String? movieId = _nullableString(json['movie_id'], key: 'movie_id');

    if ((showId == null) == (movieId == null)) {
      throw const FormatException(
        'A library entry must contain exactly one media target.',
      );
    }

    return LibraryEntryDto(
      id: _requiredString(json, 'id'),
      showId: showId,
      movieId: movieId,
      status: _parseStatus(json['status']),
      rating: _nullableDouble(json['rating'], key: 'rating'),
      startedAt: _nullableDateTime(json['started_at'], key: 'started_at'),
      completedAt: _nullableDateTime(json['completed_at'], key: 'completed_at'),
      createdAt: _requiredDateTime(json, 'created_at'),
      updatedAt: _requiredDateTime(json, 'updated_at'),
    );
  }

  final String id;

  final String? showId;
  final String? movieId;

  final LibraryStatus status;

  final double? rating;

  final DateTime? startedAt;
  final DateTime? completedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  LibraryEntry toDomain() {
    final String? currentShowId = showId;

    if (currentShowId != null) {
      return LibraryEntry(
        id: id,
        mediaId: currentShowId,
        mediaType: LibraryMediaType.show,
        status: status,
        rating: rating,
        startedAt: startedAt,
        completedAt: completedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    }

    return LibraryEntry(
      id: id,
      mediaId: movieId!,
      mediaType: LibraryMediaType.movie,
      status: status,
      rating: rating,
      startedAt: startedAt,
      completedAt: completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static LibraryStatus _parseStatus(Object? value) {
    return switch (value) {
      'planning' => LibraryStatus.planning,
      'watching' => LibraryStatus.watching,
      'completed' => LibraryStatus.completed,
      'paused' => LibraryStatus.paused,
      'dropped' => LibraryStatus.dropped,
      _ => throw const FormatException('Invalid library status.'),
    };
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final Object? value = json[key];

    if (value is String && value.trim().isNotEmpty) {
      return value;
    }

    throw FormatException('Expected "$key" to be a non-empty string.');
  }

  static String? _nullableString(Object? value, {required String key}) {
    if (value == null) {
      return null;
    }

    if (value is String && value.trim().isNotEmpty) {
      return value;
    }

    throw FormatException('Expected "$key" to be null or a non-empty string.');
  }

  static double? _nullableDouble(Object? value, {required String key}) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    throw FormatException('Expected "$key" to be null or a number.');
  }

  static DateTime _requiredDateTime(Map<String, dynamic> json, String key) {
    final DateTime? value = _nullableDateTime(json[key], key: key);

    if (value == null) {
      throw FormatException('Expected "$key" to contain a datetime.');
    }

    return value;
  }

  static DateTime? _nullableDateTime(Object? value, {required String key}) {
    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw FormatException('Expected "$key" to contain a datetime string.');
    }

    final DateTime? parsed = DateTime.tryParse(value);

    if (parsed == null) {
      throw FormatException('Invalid datetime for "$key".');
    }

    return parsed;
  }
}
