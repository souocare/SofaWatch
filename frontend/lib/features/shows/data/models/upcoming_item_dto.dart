import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/shows/data/models/upcoming_episode_dto.dart';
import 'package:sofawatch/features/shows/domain/models/upcoming_item.dart';

final class UpcomingItemDto {
  const UpcomingItemDto({
    required this.libraryEntryId,
    required this.libraryStatus,
    required this.showId,
    required this.showTmdbId,
    required this.showTitle,
    required this.episode,
    this.posterUrl,
    this.backdropUrl,
  });

  factory UpcomingItemDto.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> show = _requiredMap(json, 'show');
    final Map<String, dynamic> episode = _requiredMap(json, 'episode');

    return UpcomingItemDto(
      libraryEntryId: _requiredString(json, 'library_entry_id'),
      libraryStatus: _parseLibraryStatus(
        _requiredString(json, 'library_status'),
      ),
      showId: _requiredString(show, 'id'),
      showTmdbId: _requiredPositiveInt(show, 'tmdb_id'),
      showTitle: _requiredString(show, 'title'),
      posterUrl: _optionalString(show['poster_url']),
      backdropUrl: _optionalString(show['backdrop_url']),
      episode: UpcomingEpisodeDto.fromJson(episode),
    );
  }

  final String libraryEntryId;
  final LibraryStatus libraryStatus;

  final String showId;
  final int showTmdbId;
  final String showTitle;

  final String? posterUrl;
  final String? backdropUrl;

  final UpcomingEpisodeDto episode;

  UpcomingItem toDomain() {
    return UpcomingItem(
      libraryEntryId: libraryEntryId,
      libraryStatus: libraryStatus,
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
