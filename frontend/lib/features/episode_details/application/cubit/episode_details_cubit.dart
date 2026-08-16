import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/episode_details/application/cubit/episode_details_operation.dart';
import 'package:sofawatch/features/episode_details/application/cubit/episode_details_state.dart';
import 'package:sofawatch/features/episode_details/domain/models/episode_details.dart';
import 'package:sofawatch/features/episode_details/domain/repositories/episode_details_repository.dart';
import 'package:sofawatch/features/episode_progress/domain/repositories/episode_progress_repository.dart';

final class EpisodeDetailsCubit extends Cubit<EpisodeDetailsState> {
  EpisodeDetailsCubit({
    required EpisodeDetailsRepository repository,
    required EpisodeProgressRepository progressRepository,
    required String episodeId,
  }) : _repository = repository,
       _progressRepository = progressRepository,
       _episodeId = episodeId,
       super(const EpisodeDetailsInitial());

  final EpisodeDetailsRepository _repository;
  final EpisodeProgressRepository _progressRepository;
  final String _episodeId;

  Future<void> load() async {
    emit(const EpisodeDetailsLoading());

    try {
      final EpisodeDetails details = await _repository.getById(_episodeId);

      if (isClosed) {
        return;
      }

      emit(EpisodeDetailsSuccess(details));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(EpisodeDetailsFailure(error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(EpisodeDetailsFailure(AppException.unknown(originalError: error)));
    }
  }

  Future<void> markWatched() async {
    final EpisodeDetailsState currentState = state;

    if (currentState is! EpisodeDetailsSuccess ||
        currentState.operation.isUpdating) {
      return;
    }

    const EpisodeDetailsOperationIntent intent =
        EpisodeDetailsOperationIntent.markWatched;

    emit(
      currentState.copyWith(
        operation: const EpisodeDetailsOperation.updating(intent: intent),
      ),
    );

    try {
      await _progressRepository.markEpisodeWatched(episodeId: _episodeId);

      if (isClosed) {
        return;
      }

      await _reloadAfterMutation();
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        currentState.copyWith(
          operation: EpisodeDetailsOperation.failure(error, intent: intent),
        ),
      );
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        currentState.copyWith(
          operation: EpisodeDetailsOperation.failure(
            AppException.unknown(originalError: error),
            intent: intent,
          ),
        ),
      );
    }
  }

  Future<void> rewatch() async {
    final EpisodeDetailsState currentState = state;

    if (currentState is! EpisodeDetailsSuccess ||
        currentState.operation.isUpdating) {
      return;
    }

    /*
   * Rewatch is only meaningful when this Episode already has viewing
   * history. The normal markWatched operation handles the first viewing.
   */
    if (!currentState.details.progress.hasWatchHistory) {
      return;
    }

    const EpisodeDetailsOperationIntent intent =
        EpisodeDetailsOperationIntent.rewatch;

    emit(
      currentState.copyWith(
        operation: const EpisodeDetailsOperation.updating(intent: intent),
      ),
    );

    try {
      /*
     * The backend deliberately records a new EpisodeWatchEvent every time
     * POST /episodes/{episodeId}/watched is called.
     *
     * Therefore the same repository operation represents both:
     * - the first viewing;
     * - a rewatch.
     */
      await _progressRepository.markEpisodeWatched(episodeId: _episodeId);

      if (isClosed) {
        return;
      }

      await _reloadAfterMutation();
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        currentState.copyWith(
          operation: EpisodeDetailsOperation.failure(error, intent: intent),
        ),
      );
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        currentState.copyWith(
          operation: EpisodeDetailsOperation.failure(
            AppException.unknown(originalError: error),
            intent: intent,
          ),
        ),
      );
    }
  }

  Future<void> markUnwatched() async {
    final EpisodeDetailsState currentState = state;

    if (currentState is! EpisodeDetailsSuccess ||
        currentState.operation.isUpdating) {
      return;
    }

    const EpisodeDetailsOperationIntent intent =
        EpisodeDetailsOperationIntent.markUnwatched;

    emit(
      currentState.copyWith(
        operation: const EpisodeDetailsOperation.updating(intent: intent),
      ),
    );

    try {
      await _progressRepository.markEpisodeUnwatched(episodeId: _episodeId);

      if (isClosed) {
        return;
      }

      await _reloadAfterMutation();
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        currentState.copyWith(
          operation: EpisodeDetailsOperation.failure(error, intent: intent),
        ),
      );
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        currentState.copyWith(
          operation: EpisodeDetailsOperation.failure(
            AppException.unknown(originalError: error),
            intent: intent,
          ),
        ),
      );
    }
  }

  Future<void> _reloadAfterMutation() async {
    try {
      final EpisodeDetails details = await _repository.getById(_episodeId);

      if (isClosed) {
        return;
      }

      emit(EpisodeDetailsSuccess(details));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      /*
       * The mutation itself succeeded.
       *
       * If reloading the aggregate fails afterwards, retaining stale data
       * would make the displayed watched state potentially incorrect.
       */
      emit(EpisodeDetailsFailure(error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(EpisodeDetailsFailure(AppException.unknown(originalError: error)));
    }
  }

  Future<void> retry() {
    return load();
  }
}
