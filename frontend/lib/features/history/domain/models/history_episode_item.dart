import 'package:sofawatch/features/history/domain/models/history_episode.dart';
import 'package:sofawatch/features/history/domain/models/history_item.dart';

final class HistoryEpisodeItem extends HistoryItem {
  const HistoryEpisodeItem({
    required super.eventId,
    required super.watchedAt,
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

  final HistoryEpisode episode;

  @override
  List<Object?> get props => <Object?>[
    eventId,
    watchedAt,
    showId,
    showTmdbId,
    showTitle,
    posterUrl,
    backdropUrl,
    episode,
  ];
}
