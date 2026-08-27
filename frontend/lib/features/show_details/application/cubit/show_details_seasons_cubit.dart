import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_episode_operation.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_season_operation.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_season_state.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_episode.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_episode_progress.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_episode_watch_event.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_local_season.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_season_progress.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_seasons_bootstrap.dart';
import 'package:sofawatch/features/show_details/domain/repositories/show_details_seasons_repository.dart';

final class ShowDetailsSeasonsCubit
    extends Cubit<Map<int, ShowDetailsSeasonState>> {
  ShowDetailsSeasonsCubit({
    required this._repository,
    required this._showTmdbId,
  }) : super(const <int, ShowDetailsSeasonState>{});

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

  bool get hasMutationInProgress {
    return state.values.any((ShowDetailsSeasonState seasonState) {
      if (seasonState.operation.isUpdating) {
        return true;
      }

      return seasonState.episodeOperationsById.values.any(
        (ShowDetailsEpisodeOperation operation) => operation.isUpdating,
      );
    });
  }

  Future<void> refreshAfterShowWatched() async {
    final ShowDetailsSeasonsBootstrap bootstrap =
        _bootstrap ??
        await _repository.resolveLocalSeasons(showTmdbId: _showTmdbId);

    _bootstrap = bootstrap;

    final List<ShowDetailsSeasonProgress> progressItems = await _repository
        .getSeasonsProgress(showId: bootstrap.showId);

    final Map<String, ShowDetailsSeasonProgress> progressBySeasonId =
        <String, ShowDetailsSeasonProgress>{
          for (final ShowDetailsSeasonProgress progress in progressItems)
            progress.seasonId: progress,
        };

    final Map<int, ShowDetailsSeasonState> nextState =
        <int, ShowDetailsSeasonState>{...state};

    for (final ShowDetailsLocalSeason season in bootstrap.seasons) {
      final ShowDetailsSeasonState current =
          nextState[season.seasonNumber] ?? const ShowDetailsSeasonState();

      final ShowDetailsSeasonProgress? seasonProgress =
          progressBySeasonId[season.id];

      Map<String, ShowDetailsEpisodeProgress> episodeProgressById =
          current.episodeProgressById;

      /*
     * Only refresh Episode-level progress when those Episode rows have
     * already been loaded.
     *
     * Collapsed/unloaded Seasons only need their aggregate progress.
     */
      if (current.hasLoadedEpisodes) {
        final List<ShowDetailsEpisodeProgress> episodeProgress =
            await _repository.getEpisodeProgress(seasonId: season.id);

        episodeProgressById = <String, ShowDetailsEpisodeProgress>{
          for (final ShowDetailsEpisodeProgress progress in episodeProgress)
            progress.episodeId: progress,
        };
      }

      nextState[season.seasonNumber] = current.copyWith(
        progress: seasonProgress,
        episodeProgressById: episodeProgressById,
      );
    }

    if (isClosed) {
      return;
    }

    emit(nextState);
  }

  Future<void> markSeasonWatched({required int seasonNumber}) async {
    final ShowDetailsSeasonState current =
        state[seasonNumber] ?? const ShowDetailsSeasonState();

    final bool hasEpisodeOperationInProgress = current
        .episodeOperationsById
        .values
        .any((ShowDetailsEpisodeOperation operation) => operation.isUpdating);

    if (current.operation.isUpdating || hasEpisodeOperationInProgress) {
      return;
    }

    if (current.progress?.caughtUp ?? false) {
      return;
    }

    _setSeasonState(
      seasonNumber,
      current.copyWith(operation: const ShowDetailsSeasonOperation.updating()),
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

      final ShowDetailsSeasonProgress seasonProgress = await _repository
          .markSeasonWatched(seasonId: localSeason.id);

      /*
     * If the Season is already expanded, its Episode rows are visible.
     *
     * Refresh their progress as well so every newly watched Episode
     * immediately receives the correct watched state and watch count.
     *
     * A collapsed/unloaded Season only needs the aggregate Season progress.
     */
      List<ShowDetailsEpisodeProgress>? episodeProgress;

      if (current.hasLoadedEpisodes) {
        episodeProgress = await _repository.getEpisodeProgress(
          seasonId: localSeason.id,
        );
      }

      if (isClosed) {
        return;
      }

      final ShowDetailsSeasonState latest =
          state[seasonNumber] ?? const ShowDetailsSeasonState();

      final Map<String, ShowDetailsEpisodeProgress> nextProgressById =
          episodeProgress == null
          ? latest.episodeProgressById
          : <String, ShowDetailsEpisodeProgress>{
              for (final ShowDetailsEpisodeProgress progress in episodeProgress)
                progress.episodeId: progress,
            };

      _setSeasonState(
        seasonNumber,
        latest.copyWith(
          progress: seasonProgress,
          episodeProgressById: nextProgressById,
          operation: const ShowDetailsSeasonOperation.idle(),
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      final ShowDetailsSeasonState latest =
          state[seasonNumber] ?? const ShowDetailsSeasonState();

      _setSeasonState(
        seasonNumber,
        latest.copyWith(operation: ShowDetailsSeasonOperation.failure(error)),
      );
    } catch (error) {
      if (isClosed) {
        return;
      }

      final ShowDetailsSeasonState latest =
          state[seasonNumber] ?? const ShowDetailsSeasonState();

      _setSeasonState(
        seasonNumber,
        latest.copyWith(
          operation: ShowDetailsSeasonOperation.failure(
            AppException.unknown(originalError: error),
          ),
        ),
      );
    }
  }

  Future<void> retryMarkSeasonWatched({required int seasonNumber}) async {
    final ShowDetailsSeasonState current =
        state[seasonNumber] ?? const ShowDetailsSeasonState();

    if (!current.operation.hasFailed) {
      return;
    }

    await markSeasonWatched(seasonNumber: seasonNumber);
  }

  Future<int> getPreviousUnwatchedEpisodeCount({required String episodeId}) {
    return _repository.getPreviousUnwatchedEpisodeCount(episodeId: episodeId);
  }

  Future<void> markEpisodeWatchedWithPrevious({
    required int seasonNumber,
    required String episodeId,
  }) async {
    final ShowDetailsSeasonState current =
        state[seasonNumber] ?? const ShowDetailsSeasonState();

    final ShowDetailsEpisodeOperation currentOperation = current
        .operationForEpisode(episodeId);

    if (currentOperation.isUpdating) {
      return;
    }

    final ShowDetailsEpisodeProgress? currentProgress =
        current.episodeProgressById[episodeId];

    /*
   * Catch-up is only initiated from the normal "Mark as watched"
   * action for an unwatched Episode.
   *
   * It must never become another Rewatch path.
   */
    if (currentProgress?.isWatched ?? false) {
      return;
    }

    _setSeasonState(
      seasonNumber,
      current.copyWith(
        episodeOperationsById: <String, ShowDetailsEpisodeOperation>{
          ...current.episodeOperationsById,
          episodeId: const ShowDetailsEpisodeOperation.updating(
            targetWatched: true,
            intent: ShowDetailsEpisodeOperationIntent.catchUpWithPrevious,
          ),
        },
      ),
    );

    try {
      await _repository.markEpisodeWatchedWithPrevious(episodeId: episodeId);

      await _refreshProgressAfterEpisodeCatchUp();

      if (isClosed) {
        return;
      }

      final ShowDetailsSeasonState latest =
          state[seasonNumber] ?? const ShowDetailsSeasonState();

      _setSeasonState(
        seasonNumber,
        latest.copyWith(
          episodeOperationsById: <String, ShowDetailsEpisodeOperation>{
            ...latest.episodeOperationsById,
            episodeId: const ShowDetailsEpisodeOperation.idle(),
          },
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      _setEpisodeCatchUpFailure(
        seasonNumber: seasonNumber,
        episodeId: episodeId,
        error: error,
      );
    } catch (error) {
      if (isClosed) {
        return;
      }

      _setEpisodeCatchUpFailure(
        seasonNumber: seasonNumber,
        episodeId: episodeId,
        error: AppException.unknown(originalError: error),
      );
    }
  }

  void _setEpisodeCatchUpFailure({
    required int seasonNumber,
    required String episodeId,
    required AppException error,
  }) {
    final ShowDetailsSeasonState latest =
        state[seasonNumber] ?? const ShowDetailsSeasonState();

    _setSeasonState(
      seasonNumber,
      latest.copyWith(
        episodeOperationsById: <String, ShowDetailsEpisodeOperation>{
          ...latest.episodeOperationsById,
          episodeId: ShowDetailsEpisodeOperation.failure(
            error,
            targetWatched: true,
            intent: ShowDetailsEpisodeOperationIntent.catchUpWithPrevious,
          ),
        },
      ),
    );
  }

  Future<void> markEpisodeWatched({
    required int seasonNumber,
    required String episodeId,
  }) {
    return _updateEpisodeWatchedState(
      seasonNumber: seasonNumber,
      episodeId: episodeId,
      watched: true,
      intent: ShowDetailsEpisodeOperationIntent.setWatchedState,
    );
  }

  Future<void> markEpisodeUnwatched({
    required int seasonNumber,
    required String episodeId,
  }) {
    return _updateEpisodeWatchedState(
      seasonNumber: seasonNumber,
      episodeId: episodeId,
      watched: false,
      intent: ShowDetailsEpisodeOperationIntent.setWatchedState,
    );
  }

  Future<void> rewatchEpisode({
    required int seasonNumber,
    required String episodeId,
  }) {
    return _updateEpisodeWatchedState(
      seasonNumber: seasonNumber,
      episodeId: episodeId,
      watched: true,
      intent: ShowDetailsEpisodeOperationIntent.rewatch,
    );
  }

  Future<void> removeLatestEpisodeViewing({
    required int seasonNumber,
    required String episodeId,
  }) {
    return _removeLatestEpisodeViewing(
      seasonNumber: seasonNumber,
      episodeId: episodeId,
    );
  }

  Future<void> _removeLatestEpisodeViewing({
    required int seasonNumber,
    required String episodeId,
    String? eventId,
  }) async {
    final ShowDetailsSeasonState current =
        state[seasonNumber] ?? const ShowDetailsSeasonState();

    if (current.operationForEpisode(episodeId).isUpdating) {
      return;
    }

    _setSeasonState(
      seasonNumber,
      current.copyWith(
        episodeOperationsById: <String, ShowDetailsEpisodeOperation>{
          ...current.episodeOperationsById,
          episodeId: ShowDetailsEpisodeOperation.updating(
            intent: ShowDetailsEpisodeOperationIntent.removeLatestViewing,
            eventId: eventId,
          ),
        },
      ),
    );

    String? targetEventId = eventId;

    try {
      if (targetEventId == null) {
        final List<ShowDetailsEpisodeWatchEvent> events = await _repository
            .getEpisodeWatchEvents(episodeId: episodeId);

        if (events.isEmpty) {
          throw const AppException.invalidData();
        }

        /*
       * Episode watch events are returned newest first by the backend,
       * therefore the first item is the latest historical viewing.
       */
        targetEventId = events.first.id;
      }

      await _repository.deleteEpisodeWatchEvent(
        episodeId: episodeId,
        eventId: targetEventId,
      );

      await _refreshEpisodeProgressAfterWatchEventChange(
        seasonNumber: seasonNumber,
        episodeId: episodeId,
      );

      if (isClosed) {
        return;
      }

      final ShowDetailsSeasonState latest =
          state[seasonNumber] ?? const ShowDetailsSeasonState();

      _setSeasonState(
        seasonNumber,
        latest.copyWith(
          episodeOperationsById: <String, ShowDetailsEpisodeOperation>{
            ...latest.episodeOperationsById,
            episodeId: const ShowDetailsEpisodeOperation.idle(),
          },
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      _setViewingRemovalFailure(
        seasonNumber: seasonNumber,
        episodeId: episodeId,
        error: error,
        intent: ShowDetailsEpisodeOperationIntent.removeLatestViewing,
        eventId: targetEventId,
      );
    } catch (error) {
      if (isClosed) {
        return;
      }

      _setViewingRemovalFailure(
        seasonNumber: seasonNumber,
        episodeId: episodeId,
        error: AppException.unknown(originalError: error),
        intent: ShowDetailsEpisodeOperationIntent.removeLatestViewing,
        eventId: targetEventId,
      );
    }
  }

  Future<void> removeAllEpisodeViewings({
    required int seasonNumber,
    required String episodeId,
  }) async {
    final ShowDetailsSeasonState current =
        state[seasonNumber] ?? const ShowDetailsSeasonState();

    if (current.operationForEpisode(episodeId).isUpdating) {
      return;
    }

    _setSeasonState(
      seasonNumber,
      current.copyWith(
        episodeOperationsById: <String, ShowDetailsEpisodeOperation>{
          ...current.episodeOperationsById,
          episodeId: const ShowDetailsEpisodeOperation.updating(
            intent: ShowDetailsEpisodeOperationIntent.removeAllViewings,
          ),
        },
      ),
    );

    try {
      await _repository.deleteAllEpisodeWatchEvents(episodeId: episodeId);

      await _refreshEpisodeProgressAfterWatchEventChange(
        seasonNumber: seasonNumber,
        episodeId: episodeId,
      );

      if (isClosed) {
        return;
      }

      final ShowDetailsSeasonState latest =
          state[seasonNumber] ?? const ShowDetailsSeasonState();

      _setSeasonState(
        seasonNumber,
        latest.copyWith(
          episodeOperationsById: <String, ShowDetailsEpisodeOperation>{
            ...latest.episodeOperationsById,
            episodeId: const ShowDetailsEpisodeOperation.idle(),
          },
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      _setViewingRemovalFailure(
        seasonNumber: seasonNumber,
        episodeId: episodeId,
        error: error,
        intent: ShowDetailsEpisodeOperationIntent.removeAllViewings,
      );
    } catch (error) {
      if (isClosed) {
        return;
      }

      _setViewingRemovalFailure(
        seasonNumber: seasonNumber,
        episodeId: episodeId,
        error: AppException.unknown(originalError: error),
        intent: ShowDetailsEpisodeOperationIntent.removeAllViewings,
      );
    }
  }

  void _setViewingRemovalFailure({
    required int seasonNumber,
    required String episodeId,
    required AppException error,
    required ShowDetailsEpisodeOperationIntent intent,
    String? eventId,
  }) {
    final ShowDetailsSeasonState latest =
        state[seasonNumber] ?? const ShowDetailsSeasonState();

    _setSeasonState(
      seasonNumber,
      latest.copyWith(
        episodeOperationsById: <String, ShowDetailsEpisodeOperation>{
          ...latest.episodeOperationsById,
          episodeId: ShowDetailsEpisodeOperation.failure(
            error,
            intent: intent,
            eventId: eventId,
          ),
        },
      ),
    );
  }

  Future<void> _updateEpisodeWatchedState({
    required int seasonNumber,
    required String episodeId,
    required bool watched,
    required ShowDetailsEpisodeOperationIntent intent,
  }) async {
    final ShowDetailsSeasonState current =
        state[seasonNumber] ?? const ShowDetailsSeasonState();

    final ShowDetailsEpisodeOperation operation = current.operationForEpisode(
      episodeId,
    );

    if (operation.isUpdating) {
      return;
    }

    final ShowDetailsEpisodeProgress? currentProgress =
        current.episodeProgressById[episodeId];

    final bool currentlyWatched = currentProgress?.isWatched ?? false;

    switch (intent) {
      case ShowDetailsEpisodeOperationIntent.setWatchedState:
        if (currentlyWatched == watched) {
          return;
        }

      case ShowDetailsEpisodeOperationIntent.catchUpWithPrevious:
        /*
   * Catch-up has its own mutation flow because it may update Episodes
   * across multiple Seasons.
   */
        return;

      case ShowDetailsEpisodeOperationIntent.rewatch:
        /*
     * Rewatch only makes sense for an Episode that is already watched.
     *
     * The backend keeps it watched and records another viewing event.
     */
        if (!currentlyWatched) {
          return;
        }

      case ShowDetailsEpisodeOperationIntent.removeLatestViewing:
      case ShowDetailsEpisodeOperationIntent.removeAllViewings:
        /*
     * Viewing removal has its own operation flow and must never be
     * handled as a watched-state update.
     */
        return;
    }

    final Map<String, ShowDetailsEpisodeOperation> updatingOperations =
        <String, ShowDetailsEpisodeOperation>{
          ...current.episodeOperationsById,
          episodeId: ShowDetailsEpisodeOperation.updating(
            targetWatched: watched,
            intent: intent,
          ),
        };

    _setSeasonState(
      seasonNumber,
      current.copyWith(episodeOperationsById: updatingOperations),
    );

    try {
      final ShowDetailsEpisodeProgress updatedProgress = watched
          ? await _repository.markEpisodeWatched(episodeId: episodeId)
          : await _repository.markEpisodeUnwatched(episodeId: episodeId);

      final ShowDetailsLocalSeason? localSeason = _findSeason(
        _bootstrap?.seasons ?? const <ShowDetailsLocalSeason>[],
        seasonNumber,
      );

      if (localSeason == null) {
        throw const AppException.invalidData();
      }

      final ShowDetailsSeasonProgress seasonProgress = await _repository
          .getSeasonProgress(seasonId: localSeason.id);

      if (isClosed) {
        return;
      }

      final ShowDetailsSeasonState latest =
          state[seasonNumber] ?? const ShowDetailsSeasonState();

      final Map<String, ShowDetailsEpisodeProgress> nextProgressById =
          <String, ShowDetailsEpisodeProgress>{
            ...latest.episodeProgressById,
            episodeId: updatedProgress,
          };

      final Map<String, ShowDetailsEpisodeOperation> nextOperations =
          <String, ShowDetailsEpisodeOperation>{
            ...latest.episodeOperationsById,
            episodeId: const ShowDetailsEpisodeOperation.idle(),
          };

      _setSeasonState(
        seasonNumber,
        latest.copyWith(
          episodeProgressById: nextProgressById,
          progress: seasonProgress,
          episodeOperationsById: nextOperations,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      final ShowDetailsSeasonState latest =
          state[seasonNumber] ?? const ShowDetailsSeasonState();

      _setSeasonState(
        seasonNumber,
        latest.copyWith(
          episodeOperationsById: <String, ShowDetailsEpisodeOperation>{
            ...latest.episodeOperationsById,
            episodeId: ShowDetailsEpisodeOperation.failure(
              error,
              targetWatched: watched,
              intent: intent,
            ),
          },
        ),
      );
    } catch (error) {
      if (isClosed) {
        return;
      }

      final ShowDetailsSeasonState latest =
          state[seasonNumber] ?? const ShowDetailsSeasonState();

      _setSeasonState(
        seasonNumber,
        latest.copyWith(
          episodeOperationsById: <String, ShowDetailsEpisodeOperation>{
            ...latest.episodeOperationsById,
            episodeId: ShowDetailsEpisodeOperation.failure(
              AppException.unknown(originalError: error),
              targetWatched: watched,
              intent: intent,
            ),
          },
        ),
      );
    }
  }

  Future<void> retryEpisodeUpdate({
    required int seasonNumber,
    required String episodeId,
  }) async {
    final ShowDetailsSeasonState current =
        state[seasonNumber] ?? const ShowDetailsSeasonState();

    final ShowDetailsEpisodeOperation operation = current.operationForEpisode(
      episodeId,
    );

    final ShowDetailsEpisodeOperationIntent? intent = operation.intent;

    if (!operation.hasFailed || intent == null) {
      return;
    }

    switch (intent) {
      case ShowDetailsEpisodeOperationIntent.setWatchedState:
        final bool? targetWatched = operation.targetWatched;

        if (targetWatched == null) {
          return;
        }

        await _updateEpisodeWatchedState(
          seasonNumber: seasonNumber,
          episodeId: episodeId,
          watched: targetWatched,
          intent: intent,
        );

      case ShowDetailsEpisodeOperationIntent.catchUpWithPrevious:
        await markEpisodeWatchedWithPrevious(
          seasonNumber: seasonNumber,
          episodeId: episodeId,
        );

      case ShowDetailsEpisodeOperationIntent.rewatch:
        await _updateEpisodeWatchedState(
          seasonNumber: seasonNumber,
          episodeId: episodeId,
          watched: true,
          intent: intent,
        );

      case ShowDetailsEpisodeOperationIntent.removeLatestViewing:
        await _removeLatestEpisodeViewing(
          seasonNumber: seasonNumber,
          episodeId: episodeId,
          eventId: operation.eventId,
        );

      case ShowDetailsEpisodeOperationIntent.removeAllViewings:
        await removeAllEpisodeViewings(
          seasonNumber: seasonNumber,
          episodeId: episodeId,
        );
    }
  }

  Future<void> _refreshProgressAfterEpisodeCatchUp() async {
    final ShowDetailsSeasonsBootstrap bootstrap =
        _bootstrap ??
        await _repository.resolveLocalSeasons(showTmdbId: _showTmdbId);

    _bootstrap = bootstrap;

    /*
   * Catch-up may affect the target Season and any earlier regular Season.
   *
   * Refresh all aggregate Season progress in one request so collapsed
   * Seasons immediately display the correct progress as well.
   */
    final List<ShowDetailsSeasonProgress> seasonProgressItems =
        await _repository.getSeasonsProgress(showId: bootstrap.showId);

    final Map<String, ShowDetailsSeasonProgress> progressBySeasonId =
        <String, ShowDetailsSeasonProgress>{
          for (final ShowDetailsSeasonProgress progress in seasonProgressItems)
            progress.seasonId: progress,
        };

    final Map<int, List<ShowDetailsEpisodeProgress>> loadedEpisodeProgress =
        <int, List<ShowDetailsEpisodeProgress>>{};

    /*
   * Only refresh Episode-level progress for Seasons whose Episode rows have
   * already been loaded.
   *
   * Collapsed/unloaded Seasons only need their aggregate progress.
   */
    for (final ShowDetailsLocalSeason localSeason in bootstrap.seasons) {
      final ShowDetailsSeasonState current =
          state[localSeason.seasonNumber] ?? const ShowDetailsSeasonState();

      if (!current.hasLoadedEpisodes) {
        continue;
      }

      loadedEpisodeProgress[localSeason.seasonNumber] = await _repository
          .getEpisodeProgress(seasonId: localSeason.id);
    }

    if (isClosed) {
      return;
    }

    final Map<int, ShowDetailsSeasonState> nextState =
        <int, ShowDetailsSeasonState>{...state};

    for (final ShowDetailsLocalSeason localSeason in bootstrap.seasons) {
      final ShowDetailsSeasonState current =
          nextState[localSeason.seasonNumber] ?? const ShowDetailsSeasonState();

      final ShowDetailsSeasonProgress? seasonProgress =
          progressBySeasonId[localSeason.id];

      final List<ShowDetailsEpisodeProgress>? episodeProgress =
          loadedEpisodeProgress[localSeason.seasonNumber];

      nextState[localSeason.seasonNumber] = current.copyWith(
        progress: seasonProgress,
        episodeProgressById: episodeProgress == null
            ? current.episodeProgressById
            : <String, ShowDetailsEpisodeProgress>{
                for (final ShowDetailsEpisodeProgress progress
                    in episodeProgress)
                  progress.episodeId: progress,
              },
      );
    }

    emit(nextState);
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

      final List<ShowDetailsEpisodeProgress> episodeProgress = await _repository
          .getEpisodeProgress(seasonId: localSeason.id);

      final Map<String, ShowDetailsEpisodeProgress> episodeProgressById =
          <String, ShowDetailsEpisodeProgress>{
            for (final ShowDetailsEpisodeProgress progress in episodeProgress)
              progress.episodeId: progress,
          };

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
          episodeProgressById: episodeProgressById,
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

  Future<List<ShowDetailsEpisodeWatchEvent>> getEpisodeWatchEvents({
    required String episodeId,
  }) {
    return _repository.getEpisodeWatchEvents(episodeId: episodeId);
  }

  Future<void> deleteEpisodeWatchEvent({
    required int seasonNumber,
    required String episodeId,
    required String eventId,
  }) async {
    await _repository.deleteEpisodeWatchEvent(
      episodeId: episodeId,
      eventId: eventId,
    );

    await _refreshEpisodeProgressAfterWatchEventChange(
      seasonNumber: seasonNumber,
      episodeId: episodeId,
    );
  }

  Future<void> deleteAllEpisodeWatchEvents({
    required int seasonNumber,
    required String episodeId,
  }) async {
    await _repository.deleteAllEpisodeWatchEvents(episodeId: episodeId);

    await _refreshEpisodeProgressAfterWatchEventChange(
      seasonNumber: seasonNumber,
      episodeId: episodeId,
    );
  }

  Future<void> _refreshEpisodeProgressAfterWatchEventChange({
    required int seasonNumber,
    required String episodeId,
  }) async {
    final ShowDetailsLocalSeason? localSeason = _findSeason(
      _bootstrap?.seasons ?? const <ShowDetailsLocalSeason>[],
      seasonNumber,
    );

    if (localSeason == null) {
      throw const AppException.invalidData();
    }

    /*
   * Historical viewing changes can affect:
   *
   * - watch_count;
   * - watched_at;
   * - is_watched;
   * - Season progress.
   *
   * Re-read the backend state instead of reproducing those rules
   * in Flutter.
   */
    final List<ShowDetailsEpisodeProgress> episodeProgress = await _repository
        .getEpisodeProgress(seasonId: localSeason.id);

    final ShowDetailsSeasonProgress seasonProgress = await _repository
        .getSeasonProgress(seasonId: localSeason.id);

    if (isClosed) {
      return;
    }

    final ShowDetailsSeasonState current =
        state[seasonNumber] ?? const ShowDetailsSeasonState();

    final Map<String, ShowDetailsEpisodeProgress> nextProgressById =
        <String, ShowDetailsEpisodeProgress>{...current.episodeProgressById};

    ShowDetailsEpisodeProgress? updatedEpisodeProgress;

    for (final ShowDetailsEpisodeProgress progress in episodeProgress) {
      if (progress.episodeId == episodeId) {
        updatedEpisodeProgress = progress;
        break;
      }
    }

    if (updatedEpisodeProgress == null) {
      nextProgressById.remove(episodeId);
    } else {
      nextProgressById[episodeId] = updatedEpisodeProgress;
    }

    _setSeasonState(
      seasonNumber,
      current.copyWith(
        episodeProgressById: nextProgressById,
        progress: seasonProgress,
      ),
    );
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
