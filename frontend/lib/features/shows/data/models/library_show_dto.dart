import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';
import 'package:sofawatch/features/shows/domain/models/library_first_episode.dart';
import 'package:sofawatch/features/shows/data/models/library_show_progress_dto.dart';
import 'package:sofawatch/features/shows/domain/models/library_show_progress.dart';

final class LibraryShowDto {
  factory LibraryShowDto.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> show = _requiredMap(json, 'show');

    final Map<String, dynamic>? firstAvailableEpisodeJson = _optionalMap(
      json['first_available_episode'],
    );

    final Map<String, dynamic> progressJson = _requiredMap(json, 'progress');

    final LibraryShowProgress progress = LibraryShowProgressDto.fromJson(
      progressJson,
    ).toDomain();
    return LibraryShowDto(
      libraryEntryId: _requiredString(json, 'id'),
      showId: _requiredString(show, 'id'),
      tmdbId: _requiredInt(show, 'tmdb_id'),
      title: _requiredString(show, 'title'),
      originalTitle: _requiredString(show, 'original_title'),
      firstAirDate: _optionalDate(show['first_air_date']),
      posterUrl: _optionalString(show['poster_url']),
      backdropUrl: _optionalString(show['backdrop_url']),
      status: _parseLibraryStatus(_requiredString(json, 'status')),
      showStatus: _requiredString(show, 'status'),
      voteAverage: _requiredDouble(show, 'vote_average'),
      rating: _optionalDouble(json['rating']),
      startedAt: _optionalDateTime(json['started_at']),
      completedAt: _optionalDateTime(json['completed_at']),
      createdAt: _requiredDateTime(json, 'created_at'),
      updatedAt: _requiredDateTime(json, 'updated_at'),
      progress: progress,
      firstAvailableEpisode: firstAvailableEpisodeJson == null
          ? null
          : LibraryFirstEpisode(
              id: _requiredString(firstAvailableEpisodeJson, 'id'),
              tmdbId: _requiredInt(firstAvailableEpisodeJson, 'tmdb_id'),
              seasonNumber: _requiredInt(
                firstAvailableEpisodeJson,
                'season_number',
              ),
              episodeNumber: _requiredInt(
                firstAvailableEpisodeJson,
                'episode_number',
              ),
              title: _requiredString(firstAvailableEpisodeJson, 'title'),
              airDate: _optionalDate(firstAvailableEpisodeJson['air_date']),
              runtime: _optionalPositiveInt(
                firstAvailableEpisodeJson['runtime'],
              ),
            ),
    );
  }
  const LibraryShowDto({
    required this.libraryEntryId,
    required this.showId,
    required this.tmdbId,
    required this.title,
    required this.originalTitle,
    required this.status,
    required this.showStatus,
    required this.voteAverage,
    required this.createdAt,
    required this.updatedAt,
    this.firstAirDate,
    this.posterUrl,
    this.backdropUrl,
    this.rating,
    this.startedAt,
    this.completedAt,
    this.firstAvailableEpisode,
    required this.progress,
  });

  final String libraryEntryId;

  final String showId;
  final int tmdbId;

  final String title;
  final String originalTitle;

  final DateTime? firstAirDate;

  final String? posterUrl;
  final String? backdropUrl;

  final LibraryStatus status;
  final String showStatus;

  final double voteAverage;
  final double? rating;

  final DateTime? startedAt;
  final DateTime? completedAt;

  final DateTime createdAt;
  final DateTime updatedAt;
  final LibraryFirstEpisode? firstAvailableEpisode;
  final LibraryShowProgress progress;

  LibraryShow toDomain() {
    return LibraryShow(
      libraryEntryId: libraryEntryId,
      showId: showId,
      tmdbId: tmdbId,
      title: title,
      originalTitle: originalTitle,
      firstAirDate: firstAirDate,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
      status: status,
      showStatus: showStatus,
      voteAverage: voteAverage,
      rating: rating,
      startedAt: startedAt,
      completedAt: completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      firstAvailableEpisode: firstAvailableEpisode,
      progress: progress,
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

Map<String, dynamic>? _optionalMap(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is! Map<String, dynamic>) {
    throw const FormatException('Invalid optional map.');
  }

  return value;
}

int? _optionalPositiveInt(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is! int || value <= 0) {
    throw const FormatException('Invalid optional positive integer.');
  }

  return value;
}
