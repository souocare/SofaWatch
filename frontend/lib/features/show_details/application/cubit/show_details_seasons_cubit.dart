import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_season_state.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_episode.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_local_season.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_season_progress.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_seasons_bootstrap.dart';
import 'package:sofawatch/features/show_details/domain/repositories/show_details_seasons_repository.dart';

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

  ShowDetailsSeasonsBootstrap? _bootstrap;

  Future<void> loadInitialProgress() async {
    try {
      final ShowDetailsSeasonsBootstrap bootstrap =
          _bootstrap ??
          await _repository.resolveLocalSeasons(showTmdbId: _showTmdbId);

      _bootstrap = bootstrap;

      final List<ShowDetailsSeasonProgress> progressItems = await _repository
          .getSeasonsProgress(showId: bootstrap.showId);

      if (isClosed) {
        return;
      }

      final Map<String, ShowDetailsSeasonProgress> progressBySeasonId =
          <String, ShowDetailsSeasonProgress>{
            for (final ShowDetailsSeasonProgress progress in progressItems)
              progress.seasonId: progress,
          };

      final Map<int, ShowDetailsSeasonState> nextState =
          <int, ShowDetailsSeasonState>{...state};

      for (final ShowDetailsLocalSeason season in bootstrap.seasons) {
        final ShowDetailsSeasonProgress? progress =
            progressBySeasonId[season.id];

        if (progress == null) {
          continue;
        }

        final ShowDetailsSeasonState current =
            nextState[season.seasonNumber] ?? const ShowDetailsSeasonState();

        nextState[season.seasonNumber] = current.copyWith(progress: progress);
      }

      emit(nextState);
    } on AppException {
      /*
       * Initial progress is supplementary information.
       *
       * A failure here must not prevent Show Details from opening
       * or put every Season into an error state.
       *
       * Progress will be requested again when an individual Season
       * is expanded.
       */
    }
  }

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
      final ShowDetailsSeasonsBootstrap bootstrap =
          _bootstrap ??
          await _repository.resolveLocalSeasons(showTmdbId: _showTmdbId);

      _bootstrap = bootstrap;

      final ShowDetailsLocalSeason? localSeason = _findSeason(
        bootstrap.seasons,
        seasonNumber,
      );

      if (localSeason == null) {
        throw const AppException.invalidData();
      }

      /*
       * Always try the locally stored Episodes first.
       *
       * This keeps previously synchronized Seasons instant to open and
       * avoids unnecessary TMDB requests.
       */
      List<ShowDetailsEpisode> episodes = await _repository.getEpisodes(
        seasonId: localSeason.id,
      );

      /*
       * An empty local Season means that its Episodes have not yet been
       * synchronized.
       *
       * Only that specific Season is synchronized with the provider.
       */
      if (episodes.isEmpty) {
        episodes = await _repository.syncEpisodes(seasonId: localSeason.id);
      }

      /*
       * Recalculate progress after Episode loading/synchronization.
       *
       * Synchronization may have changed the number of locally known
       * Episodes, so the bootstrap progress may no longer be accurate.
       */
      final ShowDetailsSeasonProgress progress = await _repository
          .getSeasonProgress(seasonId: localSeason.id);

      if (isClosed) {
        return;
      }

      _setSeasonState(
        seasonNumber,
        ShowDetailsSeasonState(
          isExpanded: true,
          hasLoadedEpisodes: true,
          episodes: episodes,
          progress: progress,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      final ShowDetailsSeasonState previous =
          state[seasonNumber] ?? const ShowDetailsSeasonState();

      _setSeasonState(
        seasonNumber,
        previous.copyWith(isExpanded: true, isLoading: false, error: error),
      );
    } catch (error) {
      if (isClosed) {
        return;
      }

      final ShowDetailsSeasonState previous =
          state[seasonNumber] ?? const ShowDetailsSeasonState();

      _setSeasonState(
        seasonNumber,
        previous.copyWith(
          isExpanded: true,
          isLoading: false,
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
