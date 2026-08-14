import 'package:equatable/equatable.dart';

final class ShowDetailsEpisodeProgress extends Equatable {
  const ShowDetailsEpisodeProgress({
    required this.id,
    required this.episodeId,
    required this.isWatched,
    required this.watchCount,
    this.watchedAt,
  });

  final String id;
  final String episodeId;

  final bool isWatched;
  final DateTime? watchedAt;

  /// Number of historical viewing events recorded for this Episode.
  final int watchCount;

  @override
  List<Object?> get props => <Object?>[
    id,
    episodeId,
    isWatched,
    watchedAt,
    watchCount,
  ];
}
