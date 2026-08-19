import 'package:equatable/equatable.dart';

final class StatisticsShowInsight extends Equatable {
  const StatisticsShowInsight({
    required this.showId,
    required this.tmdbId,
    required this.title,
    required this.posterUrl,
    required this.watchCount,
    required this.rewatchCount,
  });

  final String showId;
  final int tmdbId;
  final String title;
  final String? posterUrl;
  final int watchCount;
  final int rewatchCount;

  @override
  List<Object?> get props => <Object?>[
    showId,
    tmdbId,
    title,
    posterUrl,
    watchCount,
    rewatchCount,
  ];
}

final class StatisticsEpisodeInsight extends Equatable {
  const StatisticsEpisodeInsight({
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

  final String episodeId;
  final int showTmdbId;
  final String showTitle;
  final int seasonNumber;
  final int episodeNumber;
  final String episodeTitle;
  final String? stillUrl;
  final int watchCount;
  final int rewatchCount;

  @override
  List<Object?> get props => <Object?>[
    episodeId,
    showTmdbId,
    showTitle,
    seasonNumber,
    episodeNumber,
    episodeTitle,
    stillUrl,
    watchCount,
    rewatchCount,
  ];
}

final class StatisticsMovieInsight extends Equatable {
  const StatisticsMovieInsight({
    required this.movieId,
    required this.tmdbId,
    required this.title,
    required this.posterUrl,
    required this.watchCount,
    required this.rewatchCount,
  });

  final String movieId;
  final int tmdbId;
  final String title;
  final String? posterUrl;
  final int watchCount;
  final int rewatchCount;

  @override
  List<Object?> get props => <Object?>[
    movieId,
    tmdbId,
    title,
    posterUrl,
    watchCount,
    rewatchCount,
  ];
}

final class StatisticsGenreInsight extends Equatable {
  const StatisticsGenreInsight({
    required this.genreId,
    required this.name,
    required this.watchCount,
  });

  final int genreId;
  final String name;
  final int watchCount;

  @override
  List<Object?> get props => <Object?>[genreId, name, watchCount];
}

final class StatisticsContentInsights extends Equatable {
  const StatisticsContentInsights({
    required this.mostWatchedShows,
    required this.mostRewatchedShows,
    required this.mostRewatchedEpisodes,
    required this.mostRewatchedMovies,
    required this.topShowGenres,
    required this.topMovieGenres,
  });

  final List<StatisticsShowInsight> mostWatchedShows;
  final List<StatisticsShowInsight> mostRewatchedShows;

  final List<StatisticsEpisodeInsight> mostRewatchedEpisodes;
  final List<StatisticsMovieInsight> mostRewatchedMovies;

  final List<StatisticsGenreInsight> topShowGenres;
  final List<StatisticsGenreInsight> topMovieGenres;

  @override
  List<Object?> get props => <Object?>[
    mostWatchedShows,
    mostRewatchedShows,
    mostRewatchedEpisodes,
    mostRewatchedMovies,
    topShowGenres,
    topMovieGenres,
  ];
}
