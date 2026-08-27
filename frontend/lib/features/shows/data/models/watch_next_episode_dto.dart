import 'package:sofawatch/features/shows/domain/models/watch_next_episode.dart';

final class WatchNextEpisodeDto {
  const WatchNextEpisodeDto({
    required this.id,
    required this.tmdbId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.title,
    this.airDate,
    this.runtime,
    this.stillUrl,
  });
  factory WatchNextEpisodeDto.fromJson(Map<String, dynamic> json) {
    return WatchNextEpisodeDto(
      id: _requiredString(json, 'id'),
      tmdbId: _requiredPositiveInt(json, 'tmdb_id'),
      seasonNumber: _requiredPositiveInt(json, 'season_number'),
      episodeNumber: _requiredNonNegativeInt(json, 'episode_number'),
      title: _requiredString(json, 'title'),
      airDate: _optionalDate(json['air_date']),
      runtime: _optionalNonNegativeInt(json['runtime'], fieldName: 'runtime'),
      stillUrl: _optionalString(json['still_url']),
    );
  }

  final String id;
  final int tmdbId;

  final int seasonNumber;
  final int episodeNumber;

  final String title;

  final DateTime? airDate;
  final int? runtime;

  final String? stillUrl;

  WatchNextEpisode toDomain() {
    return WatchNextEpisode(
      id: id,
      tmdbId: tmdbId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      title: title,
      airDate: airDate,
      runtime: runtime,
      stillUrl: stillUrl,
    );
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Invalid $key.');
  }

  return value.trim();
}

int _requiredPositiveInt(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! int || value <= 0) {
    throw FormatException('Invalid $key.');
  }

  return value;
}

int _requiredNonNegativeInt(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! int || value < 0) {
    throw FormatException('Invalid $key.');
  }

  return value;
}

int? _optionalNonNegativeInt(Object? value, {required String fieldName}) {
  if (value == null) {
    return null;
  }

  if (value is! int || value < 0) {
    throw FormatException('Invalid $fieldName.');
  }

  return value;
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
