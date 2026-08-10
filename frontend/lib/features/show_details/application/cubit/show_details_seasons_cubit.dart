import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_season_state.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_local_season.dart';
import 'package:sofawatch/features/show_details/domain/repositories/show_details_seasons_repository.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_episode.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_season_progress.dart';

final class ShowDetailsSeasonsCubit
    extends Cubit<Map<int, ShowDetailsSeasonState>> {
  ShowDetailsSeasonsCubit({
    required ShowDetailsSeasonsRepository repository,
    required int showTmdbId,
  }) : _repository = repository,
       _showTmdbId = showTmdbId,
       super(const <int, ShowDetailsSeasonState>{});

  final ShowDetailsSeasonsRepository _repository;
  final int _showTmdbId;

  List<ShowDetailsLocalSeason>? _localSeasons;

  Future<void> toggleSeason(int seasonNumber) async {
    final ShowDetailsSeasonState current =
        state[seasonNumber] ?? const ShowDetailsSeasonState();

    if (current.isExpanded) {
      _setSeasonState(seasonNumber, current.copyWith(isExpanded: false));

      return;
    }

    _setSeasonState(seasonNumber, current.copyWith(isExpanded: true));

    if (current.isLoaded) {
      return;
    }

    await _loadSeason(seasonNumber);
  }

  Future<void> retrySeason(int seasonNumber) {
    return _loadSeason(seasonNumber);
  }

  Future<void> _loadSeason(int seasonNumber) async {
    final ShowDetailsSeasonState current =
        state[seasonNumber] ?? const ShowDetailsSeasonState();

    _setSeasonState(
      seasonNumber,
      current.copyWith(isExpanded: true, isLoading: true, clearError: true),
    );

    try {
      final List<ShowDetailsLocalSeason> localSeasons =
          _localSeasons ??
          await _repository.resolveLocalSeasons(showTmdbId: _showTmdbId);

      _localSeasons = localSeasons;

      final ShowDetailsLocalSeason? localSeason = _findSeason(
        localSeasons,
        seasonNumber,
      );

      if (localSeason == null) {
        throw const AppException.invalidData();
      }

      final List<Object> results = await Future.wait<Object>(<Future<Object>>[
        _repository.getEpisodes(seasonId: localSeason.id),
        _repository.getSeasonProgress(seasonId: localSeason.id),
      ]);

      final List<ShowDetailsEpisode> episodes =
          results[0] as List<ShowDetailsEpisode>;

      final ShowDetailsSeasonProgress progress =
          results[1] as ShowDetailsSeasonProgress;

      if (isClosed) {
        return;
      }

      _setSeasonState(
        seasonNumber,
        ShowDetailsSeasonState(
          isExpanded: true,
          episodes: episodes,
          progress: progress,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      _setSeasonState(
        seasonNumber,
        ShowDetailsSeasonState(isExpanded: true, error: error),
      );
    } catch (error) {
      if (isClosed) {
        return;
      }

      _setSeasonState(
        seasonNumber,
        ShowDetailsSeasonState(
          isExpanded: true,
          error: AppException.unknown(originalError: error),
        ),
      );
    }
  }

  ShowDetailsLocalSeason? _findSeason(
    List<ShowDetailsLocalSeason> seasons,
    int seasonNumber,
  ) {
    for (final ShowDetailsLocalSeason season in seasons) {
      if (season.seasonNumber == seasonNumber) {
        return season;
      }
    }

    return null;
  }

  void _setSeasonState(int seasonNumber, ShowDetailsSeasonState seasonState) {
    emit(<int, ShowDetailsSeasonState>{...state, seasonNumber: seasonState});
  }
}
