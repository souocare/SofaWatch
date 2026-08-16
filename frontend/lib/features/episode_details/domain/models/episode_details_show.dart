import 'package:equatable/equatable.dart';

final class EpisodeDetailsShow extends Equatable {
  const EpisodeDetailsShow({
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

  @override
  List<Object?> get props => <Object?>[
    id,
    tmdbId,
    title,
    originalTitle,
    firstAirDate,
    posterUrl,
    backdropUrl,
    status,
    voteAverage,
  ];
}
