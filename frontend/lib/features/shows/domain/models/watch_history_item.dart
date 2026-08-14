import 'package:equatable/equatable.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_episode.dart';

final class WatchHistoryItem extends Equatable {
  const WatchHistoryItem({
    required this.eventId,
    required this.showId,
    required this.showTmdbId,
    required this.showTitle,
    required this.episode,
    this.posterUrl,
    this.backdropUrl,
  });

  /// Identifier of this specific historical viewing.
  ///
  /// Multiple Watch History items may reference the same Episode while
  /// having different event IDs.
  final String eventId;

  final String showId;
  final int showTmdbId;
  final String showTitle;

  final String? posterUrl;
  final String? backdropUrl;

  final WatchHistoryEpisode episode;

  @override
  List<Object?> get props => <Object?>[
    eventId,
    showId,
    showTmdbId,
    showTitle,
    posterUrl,
    backdropUrl,
    episode,
  ];
}
