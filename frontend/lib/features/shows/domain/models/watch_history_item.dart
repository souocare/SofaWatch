import 'package:equatable/equatable.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_episode.dart';

final class WatchHistoryItem extends Equatable {
  const WatchHistoryItem({
    required this.showId,
    required this.showTmdbId,
    required this.showTitle,
    required this.episode,
    this.posterUrl,
    this.backdropUrl,
  });

  final String showId;
  final int showTmdbId;
  final String showTitle;

  final String? posterUrl;
  final String? backdropUrl;

  final WatchHistoryEpisode episode;

  @override
  List<Object?> get props => <Object?>[
    showId,
    showTmdbId,
    showTitle,
    posterUrl,
    backdropUrl,
    episode,
  ];
}
