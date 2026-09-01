import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/core/viewing/viewing_state_change_notifier.dart';
import 'package:sofawatch/features/history/domain/models/history_media_type.dart';
import 'package:sofawatch/features/history/domain/models/history_movie_item.dart';
import 'package:sofawatch/features/history/domain/models/history_page.dart';
import 'package:sofawatch/features/history/domain/repositories/history_repository.dart';
import 'package:sofawatch/features/movies/application/cubit/movie_history_state.dart';
import 'package:sofawatch/features/movies/domain/repositories/movie_viewing_repository.dart';

final class MovieHistoryCubit extends Cubit<MovieHistoryState> {
  MovieHistoryCubit({
    required this._historyRepository,
    required this._viewingRepository,
    required ViewingStateChangeNotifier viewingStateChangeNotifier,
  }) : _viewingStateChangeNotifier = viewingStateChangeNotifier,
       super(const MovieHistoryState()) {
    _viewingStateChangeSubscription = viewingStateChangeNotifier.changes.listen(
      (_) {
        unawaited(load());
      },
    );
  }

  static const int previewLimit = 18;

  final HistoryRepository _historyRepository;
  final MovieViewingRepository _viewingRepository;
  final ViewingStateChangeNotifier _viewingStateChangeNotifier;

  late final StreamSubscription<void> _viewingStateChangeSubscription;

  Future<void> load() async {
    if (state.isLoading) {
      return;
    }

    /*
     * Keep an already loaded preview visible while it is being refreshed.
     *
     * A viewing-state notification can arrive after Watch/Rewatch/Delete,
     * so replacing valid content with a loading placeholder would cause
     * unnecessary visual flicker.
     */
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final HistoryPage page = await _historyRepository.getHistory(
        limit: previewLimit,
        mediaType: HistoryMediaType.movies,
      );

      if (isClosed) {
        return;
      }

      /*
       * The backend request is already source-filtered to Movies.
       *
       * Keep the defensive type check here because HistoryPage is shared
       * with the combined Episodes + Movies timeline.
       */
      final List<HistoryMovieItem> items = page.items
          .whereType<HistoryMovieItem>()
          .take(previewLimit)
          .toList(growable: false);

      emit(state.copyWith(items: items, isLoading: false, clearError: true));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(state.copyWith(isLoading: false, error: error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          isLoading: false,
          error: AppException.unknown(originalError: error),
        ),
      );
    }
  }

  Future<void> retry() {
    return load();
  }

  /// Records either:
  /// - the first viewing of a Watchlist Movie; or
  /// - a Rewatch of an already watched Movie.
  Future<void> recordWatch(String movieId) async {
    if (state.isMovieMutating(movieId)) {
      return;
    }

    emit(
      state.copyWith(
        mutatingMovieIds: <String>{...state.mutatingMovieIds, movieId},
        clearMutationError: true,
      ),
    );

    try {
      await _viewingRepository.recordWatch(movieId);

      if (isClosed) {
        return;
      }

      /*
       * Do not directly reload History or Movies here.
       *
       * The notifier is the project-wide invalidation boundary. Every
       * interested consumer independently refreshes its server-owned state.
       */
      _viewingStateChangeNotifier.notifyChanged();
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(state.copyWith(mutationError: error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          mutationError: AppException.unknown(originalError: error),
        ),
      );
    } finally {
      if (!isClosed) {
        final Set<String> mutatingMovieIds = <String>{...state.mutatingMovieIds}
          ..remove(movieId);

        emit(state.copyWith(mutatingMovieIds: mutatingMovieIds));
      }
    }
  }

  /// Deletes exactly one historical viewing.
  ///
  /// The backend synchronizes the corresponding Library status. If this
  /// was the Movie's last remaining watch event, the Movie returns to
  /// Planning/Watchlist.
  Future<void> deleteWatchEvent({
    required String movieId,
    required String eventId,
  }) async {
    if (state.isEventMutating(eventId)) {
      return;
    }

    emit(
      state.copyWith(
        mutatingEventIds: <String>{...state.mutatingEventIds, eventId},
        clearMutationError: true,
      ),
    );

    try {
      await _viewingRepository.deleteWatchEvent(
        movieId: movieId,
        eventId: eventId,
      );

      if (isClosed) {
        return;
      }

      _viewingStateChangeNotifier.notifyChanged();
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(state.copyWith(mutationError: error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          mutationError: AppException.unknown(originalError: error),
        ),
      );
    } finally {
      if (!isClosed) {
        final Set<String> mutatingEventIds = <String>{...state.mutatingEventIds}
          ..remove(eventId);

        emit(state.copyWith(mutatingEventIds: mutatingEventIds));
      }
    }
  }

  void clearMutationError() {
    if (state.mutationError == null) {
      return;
    }

    emit(state.copyWith(clearMutationError: true));
  }

  @override
  Future<void> close() async {
    await _viewingStateChangeSubscription.cancel();
    return super.close();
  }
}
