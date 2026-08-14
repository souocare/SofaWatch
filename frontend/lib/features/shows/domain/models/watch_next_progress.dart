import 'package:equatable/equatable.dart';

final class WatchNextProgress extends Equatable {
  const WatchNextProgress({
    required this.watchedEpisodes,
    required this.airedEpisodes,
    required this.percentage,
  });

  final int watchedEpisodes;
  final int airedEpisodes;
  final double percentage;

  @override
  List<Object?> get props => <Object?>[
    watchedEpisodes,
    airedEpisodes,
    percentage,
  ];
}
