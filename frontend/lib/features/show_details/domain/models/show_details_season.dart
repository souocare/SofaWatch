import 'package:equatable/equatable.dart';

final class ShowDetailsSeason extends Equatable {
  const ShowDetailsSeason({
    required this.tmdbId,
    required this.seasonNumber,
    required this.title,
    required this.episodeCount,
    required this.voteAverage,
    this.overview,
    this.airDate,
    this.posterPath,
  });

  final int tmdbId;
  final int seasonNumber;

  final String title;
  final String? overview;

  final DateTime? airDate;

  final int episodeCount;

  final String? posterPath;

  final double voteAverage;

  bool get isSpecial => seasonNumber == 0;

  int? get airYear => airDate?.year;

  @override
  List<Object?> get props => <Object?>[
    tmdbId,
    seasonNumber,
    title,
    overview,
    airDate,
    episodeCount,
    posterPath,
    voteAverage,
  ];
}
