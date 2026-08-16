import 'package:equatable/equatable.dart';
import 'package:sofawatch/features/episode_details/domain/models/episode_details_episode.dart';
import 'package:sofawatch/features/episode_details/domain/models/episode_details_progress.dart';
import 'package:sofawatch/features/episode_details/domain/models/episode_details_season.dart';
import 'package:sofawatch/features/episode_details/domain/models/episode_details_show.dart';

final class EpisodeDetails extends Equatable {
  const EpisodeDetails({
    required this.episode,
    required this.season,
    required this.show,
    required this.progress,
  });

  final EpisodeDetailsEpisode episode;
  final EpisodeDetailsSeason season;
  final EpisodeDetailsShow show;
  final EpisodeDetailsProgress progress;

  String get episodeCode {
    return 'S${season.seasonNumber.toString().padLeft(2, '0')}'
        'E${episode.episodeNumber.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => <Object?>[episode, season, show, progress];
}
