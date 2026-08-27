import 'package:sofawatch/features/history/domain/models/history_episode.dart';

final class HistoryEpisodeDto {
  const HistoryEpisodeDto({
    required this.id,
    required this.tmdbId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.title,
    this.airDate,
    this.runtime,
    this.stillUrl,
  });

  factory HistoryEpisodeDto.fromJson(Map<String, dynamic> json) {
    return HistoryEpisodeDto(
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

  HistoryEpisode toDomain({required String Function(String path) resolveUrl}) {
    return HistoryEpisode(
      id: id,
      tmdbId: tmdbId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      title: title,
      airDate: airDate,
      runtime: runtime,
      stillUrl: _resolveOptionalUrl(stillUrl, resolveUrl: resolveUrl),
    );
  }
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

int _requiredNonNegativeInt(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! int || value < 0) {
    throw FormatException('$key must be a non-negative integer.');
  }

  return value;
}

int? _optionalNonNegativeInt(Object? value, {required String fieldName}) {
  if (value == null) {
    return null;
  }

  if (value is! int || value < 0) {
    throw FormatException('$fieldName must be null or a non-negative integer.');
  }

  return value;
}

DateTime? _optionalDate(Object? value) {
  final String? rawValue = _optionalString(value);

  if (rawValue == null) {
    return null;
  }

  final DateTime? parsed = DateTime.tryParse(rawValue);

  if (parsed == null) {
    throw const FormatException('air_date must be null or a valid date.');
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
