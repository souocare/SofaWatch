import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/shows/data/models/watch_next_episode_dto.dart';
import 'package:sofawatch/features/shows/data/models/watch_next_progress_dto.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_show.dart';

final class WatchNextShowDto {
  const WatchNextShowDto({
    required this.libraryEntryId,
    required this.libraryStatus,
    required this.showId,
    required this.showTmdbId,
    required this.showTitle,
    required this.nextEpisode,
    required this.progress,
    this.posterUrl,
    this.backdropUrl,
  });

  factory WatchNextShowDto.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> show = _requiredMap(json, 'show');

    final Map<String, dynamic> nextEpisode = _requiredMap(json, 'next_episode');

    final Map<String, dynamic> progress = _requiredMap(json, 'progress');

    return WatchNextShowDto(
      libraryEntryId: _requiredString(json, 'library_entry_id'),
      libraryStatus: _parseLibraryStatus(
        _requiredString(json, 'library_status'),
      ),
      showId: _requiredString(show, 'id'),
      showTmdbId: _requiredPositiveInt(show, 'tmdb_id'),
      showTitle: _requiredString(show, 'title'),
      posterUrl: _optionalString(show['poster_url']),
      backdropUrl: _optionalString(show['backdrop_url']),
      nextEpisode: WatchNextEpisodeDto.fromJson(nextEpisode),
      progress: WatchNextProgressDto.fromJson(progress),
    );
  }

  final String libraryEntryId;
  final LibraryStatus libraryStatus;

  final String showId;
  final int showTmdbId;
  final String showTitle;

  final String? posterUrl;
  final String? backdropUrl;

  final WatchNextEpisodeDto nextEpisode;
  final WatchNextProgressDto progress;

  WatchNextShow toDomain() {
    return WatchNextShow(
      libraryEntryId: libraryEntryId,
      libraryStatus: libraryStatus,
      showId: showId,
      showTmdbId: showTmdbId,
      showTitle: showTitle,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
      nextEpisode: nextEpisode.toDomain(),
      progress: progress.toDomain(),
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
