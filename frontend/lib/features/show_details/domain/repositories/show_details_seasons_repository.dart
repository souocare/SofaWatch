import 'package:sofawatch/features/show_details/domain/models/show_details_episode.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_season_progress.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_seasons_bootstrap.dart';

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
}
