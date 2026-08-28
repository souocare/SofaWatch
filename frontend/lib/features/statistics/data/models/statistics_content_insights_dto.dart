import 'package:sofawatch/features/statistics/domain/models/statistics_content_insights.dart';

final class StatisticsContentInsightsDto {
  const StatisticsContentInsightsDto({
    required this.mostWatchedShows,
    required this.mostRewatchedShows,
    required this.mostRewatchedEpisodes,
    required this.mostRewatchedMovies,
    required this.topShowGenres,
    required this.topMovieGenres,
  });

  factory StatisticsContentInsightsDto.fromJson(Map<String, dynamic> json) {
    return StatisticsContentInsightsDto(
      mostWatchedShows: _parseList(
        json,
        key: 'most_watched_shows',
        parser: StatisticsShowInsightDto.fromJson,
      ),
      mostRewatchedShows: _parseList(
        json,
        key: 'most_rewatched_shows',
        parser: StatisticsShowInsightDto.fromJson,
      ),
      mostRewatchedEpisodes: _parseList(
        json,
        key: 'most_rewatched_episodes',
        parser: StatisticsEpisodeInsightDto.fromJson,
      ),
      mostRewatchedMovies: _parseList(
        json,
        key: 'most_rewatched_movies',
        parser: StatisticsMovieInsightDto.fromJson,
      ),
      topShowGenres: _parseList(
        json,
        key: 'top_show_genres',
        parser: StatisticsGenreInsightDto.fromJson,
      ),
      topMovieGenres: _parseList(
        json,
        key: 'top_movie_genres',
        parser: StatisticsGenreInsightDto.fromJson,
      ),
    );
  }

  final List<StatisticsShowInsightDto> mostWatchedShows;
  final List<StatisticsShowInsightDto> mostRewatchedShows;
  final List<StatisticsEpisodeInsightDto> mostRewatchedEpisodes;
  final List<StatisticsMovieInsightDto> mostRewatchedMovies;
  final List<StatisticsGenreInsightDto> topShowGenres;
  final List<StatisticsGenreInsightDto> topMovieGenres;

  StatisticsContentInsights toDomain() {
    return StatisticsContentInsights(
      mostWatchedShows: mostWatchedShows
          .map((StatisticsShowInsightDto item) => item.toDomain())
          .toList(growable: false),
      mostRewatchedShows: mostRewatchedShows
          .map((StatisticsShowInsightDto item) => item.toDomain())
          .toList(growable: false),
      mostRewatchedEpisodes: mostRewatchedEpisodes
          .map((StatisticsEpisodeInsightDto item) => item.toDomain())
          .toList(growable: false),
      mostRewatchedMovies: mostRewatchedMovies
          .map((StatisticsMovieInsightDto item) => item.toDomain())
          .toList(growable: false),
      topShowGenres: topShowGenres
          .map((StatisticsGenreInsightDto item) => item.toDomain())
          .toList(growable: false),
      topMovieGenres: topMovieGenres
          .map((StatisticsGenreInsightDto item) => item.toDomain())
          .toList(growable: false),
    );
  }
}

final class StatisticsShowInsightDto {
  const StatisticsShowInsightDto({
    required this.showId,
    required this.tmdbId,
    required this.title,
    required this.posterUrl,
    required this.watchCount,
    required this.rewatchCount,
  });

  factory StatisticsShowInsightDto.fromJson(Map<String, dynamic> json) {
    return StatisticsShowInsightDto(
      showId: _requiredString(json, 'show_id'),
      tmdbId: _requiredPositiveInt(json, 'tmdb_id'),
      title: _requiredString(json, 'title'),
      posterUrl: _nullableString(json, 'poster_url'),
      watchCount: _requiredNonNegativeInt(json, 'watch_count'),
      rewatchCount: _requiredNonNegativeInt(json, 'rewatch_count'),
    );
  }

  final String showId;
  final int tmdbId;
  final String title;
  final String? posterUrl;
  final int watchCount;
  final int rewatchCount;

  StatisticsShowInsight toDomain() {
    return StatisticsShowInsight(
      showId: showId,
      tmdbId: tmdbId,
      title: title,
      posterUrl: posterUrl,
      watchCount: watchCount,
      rewatchCount: rewatchCount,
    );
  }
}

final class StatisticsEpisodeInsightDto {
  const StatisticsEpisodeInsightDto({
    required this.episodeId,
    required this.showTmdbId,
    required this.showTitle,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.episodeTitle,
    required this.stillUrl,
    required this.watchCount,
    required this.rewatchCount,
  });

  factory StatisticsEpisodeInsightDto.fromJson(Map<String, dynamic> json) {
    return StatisticsEpisodeInsightDto(
      episodeId: _requiredString(json, 'episode_id'),
      showTmdbId: _requiredPositiveInt(json, 'show_tmdb_id'),
      showTitle: _requiredString(json, 'show_title'),
      seasonNumber: _requiredNonNegativeInt(json, 'season_number'),
      episodeNumber: _requiredNonNegativeInt(json, 'episode_number'),
      episodeTitle: _requiredString(json, 'episode_title'),
      stillUrl: _nullableString(json, 'still_url'),
      watchCount: _requiredNonNegativeInt(json, 'watch_count'),
      rewatchCount: _requiredNonNegativeInt(json, 'rewatch_count'),
    );
  }

  final String episodeId;
  final int showTmdbId;
  final String showTitle;
  final int seasonNumber;
  final int episodeNumber;
  final String episodeTitle;
  final String? stillUrl;
  final int watchCount;
  final int rewatchCount;

  StatisticsEpisodeInsight toDomain() {
    return StatisticsEpisodeInsight(
      episodeId: episodeId,
      showTmdbId: showTmdbId,
      showTitle: showTitle,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      episodeTitle: episodeTitle,
      stillUrl: stillUrl,
      watchCount: watchCount,
      rewatchCount: rewatchCount,
    );
  }
}

final class StatisticsMovieInsightDto {
  const StatisticsMovieInsightDto({
    required this.movieId,
    required this.tmdbId,
    required this.title,
    required this.posterUrl,
    required this.watchCount,
    required this.rewatchCount,
  });

  factory StatisticsMovieInsightDto.fromJson(Map<String, dynamic> json) {
    return StatisticsMovieInsightDto(
      movieId: _requiredString(json, 'movie_id'),
      tmdbId: _requiredPositiveInt(json, 'tmdb_id'),
      title: _requiredString(json, 'title'),
      posterUrl: _nullableString(json, 'poster_url'),
      watchCount: _requiredNonNegativeInt(json, 'watch_count'),
      rewatchCount: _requiredNonNegativeInt(json, 'rewatch_count'),
    );
  }

  final String movieId;
  final int tmdbId;
  final String title;
  final String? posterUrl;
  final int watchCount;
  final int rewatchCount;

  StatisticsMovieInsight toDomain() {
    return StatisticsMovieInsight(
      movieId: movieId,
      tmdbId: tmdbId,
      title: title,
      posterUrl: posterUrl,
      watchCount: watchCount,
      rewatchCount: rewatchCount,
    );
  }
}

final class StatisticsGenreInsightDto {
  const StatisticsGenreInsightDto({
    required this.genreId,
    required this.name,
    required this.watchCount,
  });

  factory StatisticsGenreInsightDto.fromJson(Map<String, dynamic> json) {
    return StatisticsGenreInsightDto(
      genreId: _requiredPositiveInt(json, 'genre_id'),
      name: _requiredString(json, 'name'),
      watchCount: _requiredNonNegativeInt(json, 'watch_count'),
    );
  }

  final int genreId;
  final String name;
  final int watchCount;

  StatisticsGenreInsight toDomain() {
    return StatisticsGenreInsight(
      genreId: genreId,
      name: name,
      watchCount: watchCount,
    );
  }
}

List<T> _parseList<T>(
  Map<String, dynamic> json, {
  required String key,
  required T Function(Map<String, dynamic> json) parser,
}) {
  final Object? rawValue = json[key];

  if (rawValue is! List<dynamic>) {
    throw FormatException('$key must be a list.');
  }

  return rawValue
      .map((dynamic item) {
        if (item is! Map<String, dynamic>) {
          throw FormatException('$key must contain objects.');
        }

        return parser(item);
      })
      .toList(growable: false);
}

String _requiredString(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }

  return value;
}

String? _nullableString(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value == null) {
    return null;
  }

  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be null or a non-empty string.');
  }

  return value;
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
