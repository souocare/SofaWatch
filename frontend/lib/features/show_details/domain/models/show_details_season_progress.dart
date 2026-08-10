import 'package:equatable/equatable.dart';

final class ShowDetailsSeasonProgress extends Equatable {
  const ShowDetailsSeasonProgress({
    required this.seasonId,
    required this.watchedEpisodes,
    required this.totalEpisodes,
    required this.progressPercentage,
    required this.airedEpisodes,
    required this.watchedAiredEpisodes,
    required this.airedProgressPercentage,
    required this.caughtUp,
  });

  final String seasonId;

  final int watchedEpisodes;
  final int totalEpisodes;
  final double progressPercentage;

  final int airedEpisodes;
  final int watchedAiredEpisodes;
  final double airedProgressPercentage;

  final bool caughtUp;

  double get airedProgressValue {
    return (airedProgressPercentage / 100).clamp(0.0, 1.0);
  }

  bool get hasAiredEpisodes => airedEpisodes > 0;

  @override
  List<Object?> get props => <Object?>[
    seasonId,
    watchedEpisodes,
    totalEpisodes,
    progressPercentage,
    airedEpisodes,
    watchedAiredEpisodes,
    airedProgressPercentage,
    caughtUp,
  ];
}
