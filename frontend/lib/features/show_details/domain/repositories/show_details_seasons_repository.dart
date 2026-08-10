import 'package:sofawatch/features/show_details/domain/models/show_details_episode.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_local_season.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_season_progress.dart';

abstract interface class ShowDetailsSeasonsRepository {
  Future<List<ShowDetailsLocalSeason>> resolveLocalSeasons({
    required int showTmdbId,
  });

  Future<List<ShowDetailsEpisode>> getEpisodes({required String seasonId});

  Future<ShowDetailsSeasonProgress> getSeasonProgress({
    required String seasonId,
  });
}
