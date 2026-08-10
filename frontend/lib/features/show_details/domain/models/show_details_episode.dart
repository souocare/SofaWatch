import 'package:equatable/equatable.dart';

final class ShowDetailsEpisode extends Equatable {
  const ShowDetailsEpisode({
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

  @override
  List<Object?> get props => <Object?>[
    id,
    tmdbId,
    episodeNumber,
    title,
    overview,
    airDate,
    runtime,
    voteAverage,
    voteCount,
    stillUrl,
  ];
}
