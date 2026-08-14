import 'package:sofawatch/features/shows/data/models/watch_history_episode_dto.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_item.dart';

final class WatchHistoryItemDto {
  const WatchHistoryItemDto({
    required this.eventId,
    required this.showId,
    required this.showTmdbId,
    required this.showTitle,
    required this.episode,
    this.posterUrl,
    this.backdropUrl,
  });

  /// Identifier of this specific historical viewing event.
  final String eventId;

  final String showId;
  final int showTmdbId;
  final String showTitle;

  final String? posterUrl;
  final String? backdropUrl;

  final WatchHistoryEpisodeDto episode;

  factory WatchHistoryItemDto.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> show = _requiredMap(json, 'show');

    final Map<String, dynamic> episode = _requiredMap(json, 'episode');

    return WatchHistoryItemDto(
      eventId: _requiredString(json, 'event_id'),
      showId: _requiredString(show, 'id'),
      showTmdbId: _requiredPositiveInt(show, 'tmdb_id'),
      showTitle: _requiredString(show, 'title'),
      posterUrl: _optionalString(show['poster_url']),
      backdropUrl: _optionalString(show['backdrop_url']),
      episode: WatchHistoryEpisodeDto.fromJson(episode),
    );
  }

  WatchHistoryItem toDomain() {
    return WatchHistoryItem(
      eventId: eventId,
      showId: showId,
      showTmdbId: showTmdbId,
      showTitle: showTitle,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
      episode: episode.toDomain(),
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

  return value.trim();
}

int _requiredPositiveInt(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! int || value <= 0) {
    throw FormatException('Invalid $key.');
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
