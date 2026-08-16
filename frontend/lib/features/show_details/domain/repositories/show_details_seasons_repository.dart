import 'package:sofawatch/features/show_details/domain/models/show_details_episode.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_season_progress.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_seasons_bootstrap.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_episode_progress.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_episode_watch_event.dart';

abstract interface class ShowDetailsSeasonsRepository {
  Future<ShowDetailsSeasonsBootstrap> resolveLocalSeasons({
    required int showTmdbId,
  });

  Future<List<ShowDetailsSeasonProgress>> getSeasonsProgress({
    required String showId,
  });

  Future<List<ShowDetailsEpisode>> getEpisodes({required String seasonId});

  Future<List<ShowDetailsEpisode>> syncEpisodes({required String seasonId});

  Future<ShowDetailsSeasonProgress> getSeasonProgress({
    required String seasonId,
  });

  Future<ShowDetailsSeasonProgress> markSeasonWatched({
    required String seasonId,
  });

  Future<List<ShowDetailsEpisodeProgress>> getEpisodeProgress({
    required String seasonId,
  });

  Future<ShowDetailsEpisodeProgress> markEpisodeWatched({
    required String episodeId,
    DateTime? watchedAt,
  });

  Future<ShowDetailsEpisodeProgress> markEpisodeUnwatched({
    required String episodeId,
  });

  Future<List<ShowDetailsEpisodeWatchEvent>> getEpisodeWatchEvents({
    required String episodeId,
  });

  Future<void> deleteEpisodeWatchEvent({
    required String episodeId,
    required String eventId,
  });

  Future<void> deleteAllEpisodeWatchEvents({required String episodeId});
}
