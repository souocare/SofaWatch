import 'package:equatable/equatable.dart';

final class EpisodeDetailsEpisode extends Equatable {
  const EpisodeDetailsEpisode({
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

  bool isAvailableToWatchOn(DateTime date) {
    final DateTime? episodeAirDate = airDate;

    if (episodeAirDate == null) {
      return false;
    }

    final DateTime requestedDate = DateTime(date.year, date.month, date.day);

    final DateTime normalizedAirDate = DateTime(
      episodeAirDate.year,
      episodeAirDate.month,
      episodeAirDate.day,
    );

    return !normalizedAirDate.isAfter(requestedDate);
  }

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
