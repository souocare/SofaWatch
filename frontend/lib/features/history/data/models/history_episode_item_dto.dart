import 'package:sofawatch/features/history/data/models/history_episode_dto.dart';
import 'package:sofawatch/features/history/domain/models/history_episode_item.dart';

final class HistoryEpisodeItemDto {
  const HistoryEpisodeItemDto({
    required this.eventId,
    required this.watchedAt,
    required this.showId,
    required this.showTmdbId,
    required this.showTitle,
    required this.episode,
    this.posterUrl,
    this.backdropUrl,
  });

  final String eventId;
  final DateTime watchedAt;

  final String showId;
  final int showTmdbId;
  final String showTitle;

  final String? posterUrl;
  final String? backdropUrl;

  final HistoryEpisodeDto episode;

  factory HistoryEpisodeItemDto.fromJson(Map<String, dynamic> json) {
    final String mediaType = _requiredString(json, 'media_type');

    if (mediaType != 'episode') {
      throw const FormatException('History item must be an Episode.');
    }

    final Map<String, dynamic> show = _requiredObject(json, 'show');

    final Map<String, dynamic> episode = _requiredObject(json, 'episode');

    return HistoryEpisodeItemDto(
      eventId: _requiredString(json, 'event_id'),
      watchedAt: _requiredDateTime(json, 'watched_at'),
      showId: _requiredString(show, 'id'),
      showTmdbId: _requiredPositiveInt(show, 'tmdb_id'),
      showTitle: _requiredString(show, 'title'),
      posterUrl: _optionalString(show['poster_url']),
      backdropUrl: _optionalString(show['backdrop_url']),
      episode: HistoryEpisodeDto.fromJson(episode),
    );
  }

  HistoryEpisodeItem toDomain({
    required String Function(String path) resolveUrl,
  }) {
    return HistoryEpisodeItem(
      eventId: eventId,
      watchedAt: watchedAt,
      showId: showId,
      showTmdbId: showTmdbId,
      showTitle: showTitle,
      posterUrl: _resolveOptionalUrl(posterUrl, resolveUrl: resolveUrl),
      backdropUrl: _resolveOptionalUrl(backdropUrl, resolveUrl: resolveUrl),
      episode: episode.toDomain(resolveUrl: resolveUrl),
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
