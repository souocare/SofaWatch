import 'package:equatable/equatable.dart';

final class ShowDetails extends Equatable {
  const ShowDetails({
    required this.tmdbId,
    required this.title,
    required this.originalTitle,
    required this.originalLanguage,
    required this.numberOfSeasons,
    required this.numberOfEpisodes,
    required this.inProduction,
    required this.status,
    required this.voteAverage,
    required this.voteCount,
    required this.genres,
    this.overview,
    this.tagline,
    this.firstAirDate,
    this.lastAirDate,
    this.posterUrl,
    this.backdropUrl,
  });

  final int tmdbId;

  final String title;
  final String originalTitle;

  final String? overview;
  final String? tagline;

  final DateTime? firstAirDate;
  final DateTime? lastAirDate;

  final String? posterUrl;
  final String? backdropUrl;

  final List<String> genres;

  final String originalLanguage;

  final int numberOfSeasons;
  final int numberOfEpisodes;

  final bool inProduction;
  final String status;

  final double voteAverage;
  final int voteCount;

  int? get releaseYear => firstAirDate?.year;

  @override
  List<Object?> get props => <Object?>[
    tmdbId,
    title,
    originalTitle,
    overview,
    tagline,
    firstAirDate,
    lastAirDate,
    posterUrl,
    backdropUrl,
    genres,
    originalLanguage,
    numberOfSeasons,
    numberOfEpisodes,
    inProduction,
    status,
    voteAverage,
    voteCount,
  ];
}
