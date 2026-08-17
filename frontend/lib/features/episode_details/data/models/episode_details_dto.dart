import 'package:sofawatch/features/episode_details/domain/models/episode_details.dart';
import 'package:sofawatch/features/episode_details/domain/models/episode_details_episode.dart';
import 'package:sofawatch/features/episode_details/domain/models/episode_details_progress.dart';
import 'package:sofawatch/features/episode_details/domain/models/episode_details_season.dart';
import 'package:sofawatch/features/episode_details/domain/models/episode_details_show.dart';

final class EpisodeDetailsDto {
  factory EpisodeDetailsDto.fromJson(Map<String, dynamic> json) {
    return EpisodeDetailsDto(
      episode: EpisodeDetailsEpisodeDto.fromJson(_requiredMap(json, 'episode')),
      season: EpisodeDetailsSeasonDto.fromJson(_requiredMap(json, 'season')),
      show: EpisodeDetailsShowDto.fromJson(_requiredMap(json, 'show')),
      progress: EpisodeDetailsProgressDto.fromJson(
        _requiredMap(json, 'progress'),
      ),
    );
  }
  const EpisodeDetailsDto({
    required this.episode,
    required this.season,
    required this.show,
    required this.progress,
  });

  final EpisodeDetailsEpisodeDto episode;
  final EpisodeDetailsSeasonDto season;
  final EpisodeDetailsShowDto show;
  final EpisodeDetailsProgressDto progress;

  EpisodeDetails toDomain() {
    return EpisodeDetails(
      episode: episode.toDomain(),
      season: season.toDomain(),
      show: show.toDomain(),
      progress: progress.toDomain(),
    );
  }
}

final class EpisodeDetailsEpisodeDto {
  factory EpisodeDetailsEpisodeDto.fromJson(Map<String, dynamic> json) {
    return EpisodeDetailsEpisodeDto(
      id: _requiredString(json, 'id'),
      tmdbId: _requiredInt(json, 'tmdb_id'),
      episodeNumber: _requiredInt(json, 'episode_number'),
      title: _requiredString(json, 'title'),
      overview: _optionalString(json, 'overview'),
      airDate: _optionalDate(json, 'air_date'),
      runtime: _optionalInt(json, 'runtime'),
      voteAverage: _requiredDouble(json, 'vote_average'),
      voteCount: _requiredInt(json, 'vote_count'),
      stillUrl: _optionalString(json, 'still_url'),
    );
  }
  const EpisodeDetailsEpisodeDto({
    required this.id,
    required this.tmdbId,
    required this.episodeNumber,
    required this.title,
    required this.voteAverage,
    required this.voteCount,
    this.overview,
    this.airDate,
    this.runtime,
    this.stillUrl,
  });

  final String id;
  final int tmdbId;
  final int episodeNumber;

  final String title;
  final String? overview;

  final DateTime? airDate;
  final int? runtime;

  final double voteAverage;
  final int voteCount;

  final String? stillUrl;

  EpisodeDetailsEpisode toDomain() {
    return EpisodeDetailsEpisode(
      id: id,
      tmdbId: tmdbId,
      episodeNumber: episodeNumber,
      title: title,
      overview: overview,
      airDate: airDate,
      runtime: runtime,
      voteAverage: voteAverage,
      voteCount: voteCount,
      stillUrl: stillUrl,
    );
  }
}

final class EpisodeDetailsSeasonDto {
  factory EpisodeDetailsSeasonDto.fromJson(Map<String, dynamic> json) {
    return EpisodeDetailsSeasonDto(
      id: _requiredString(json, 'id'),
      seasonNumber: _requiredInt(json, 'season_number'),
      title: _requiredString(json, 'title'),
    );
  }
  const EpisodeDetailsSeasonDto({
    required this.id,
    required this.seasonNumber,
    required this.title,
  });

  final String id;
  final int seasonNumber;
  final String title;

  EpisodeDetailsSeason toDomain() {
    return EpisodeDetailsSeason(
      id: id,
      seasonNumber: seasonNumber,
      title: title,
    );
  }
}

final class EpisodeDetailsShowDto {
  factory EpisodeDetailsShowDto.fromJson(Map<String, dynamic> json) {
    return EpisodeDetailsShowDto(
      id: _requiredString(json, 'id'),
      tmdbId: _requiredInt(json, 'tmdb_id'),
      title: _requiredString(json, 'title'),
      originalTitle: _requiredString(json, 'original_title'),
      firstAirDate: _optionalDate(json, 'first_air_date'),
      posterUrl: _optionalString(json, 'poster_url'),
      backdropUrl: _optionalString(json, 'backdrop_url'),
      status: _requiredString(json, 'status'),
      voteAverage: _requiredDouble(json, 'vote_average'),
    );
  }
  const EpisodeDetailsShowDto({
    required this.id,
    required this.tmdbId,
    required this.title,
    required this.originalTitle,
    required this.status,
    required this.voteAverage,
    this.firstAirDate,
    this.posterUrl,
    this.backdropUrl,
  });

  final String id;
  final int tmdbId;

  final String title;
  final String originalTitle;

  final DateTime? firstAirDate;

  final String? posterUrl;
  final String? backdropUrl;

  final String status;
  final double voteAverage;

  EpisodeDetailsShow toDomain() {
    return EpisodeDetailsShow(
      id: id,
      tmdbId: tmdbId,
      title: title,
      originalTitle: originalTitle,
      firstAirDate: firstAirDate,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
      status: status,
      voteAverage: voteAverage,
    );
  }
}

final class EpisodeDetailsProgressDto {
  factory EpisodeDetailsProgressDto.fromJson(Map<String, dynamic> json) {
    return EpisodeDetailsProgressDto(
      isWatched: _requiredBool(json, 'is_watched'),
      watchedAt: _optionalDateTime(json, 'watched_at'),
      watchCount: _requiredInt(json, 'watch_count'),
      lastWatchedAt: _optionalDateTime(json, 'last_watched_at'),
    );
  }
  const EpisodeDetailsProgressDto({
    required this.isWatched,
    required this.watchCount,
    this.watchedAt,
    this.lastWatchedAt,
  });

  final bool isWatched;
  final DateTime? watchedAt;
  final int watchCount;
  final DateTime? lastWatchedAt;

  EpisodeDetailsProgress toDomain() {
    return EpisodeDetailsProgress(
      isWatched: isWatched,
      watchedAt: watchedAt,
      watchCount: watchCount,
      lastWatchedAt: lastWatchedAt,
    );
  }
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! Map<String, dynamic>) {
    throw FormatException('Expected "$key" to be an object.');
  }

  return value;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! String || value.isEmpty) {
    throw FormatException('Expected "$key" to be a non-empty String.');
  }

  return value;
}

String? _optionalString(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value == null) {
    return null;
  }

  if (value is! String) {
    throw FormatException('Expected "$key" to be a String or null.');
  }

  return value;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! int) {
    throw FormatException('Expected "$key" to be an int.');
  }

  return value;
}

int? _optionalInt(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value == null) {
    return null;
  }

  if (value is! int) {
    throw FormatException('Expected "$key" to be an int or null.');
  }

  return value;
}

double _requiredDouble(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! num) {
    throw FormatException('Expected "$key" to be numeric.');
  }

  return value.toDouble();
}

bool _requiredBool(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! bool) {
    throw FormatException('Expected "$key" to be a bool.');
  }

  return value;
}

DateTime? _optionalDate(Map<String, dynamic> json, String key) {
  return _optionalDateTime(json, key);
}

DateTime? _optionalDateTime(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value == null) {
    return null;
  }

  if (value is! String) {
    throw FormatException('Expected "$key" to be a date String or null.');
  }

  return DateTime.tryParse(value) ??
      (throw FormatException('Invalid date for "$key".'));
}
