import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/home/application/cubit/home_state.dart';
import 'package:sofawatch/features/shows/domain/models/upcoming_item.dart';
import 'package:sofawatch/features/shows/domain/repositories/shows_repository.dart';

final class HomeCubit extends Cubit<HomeState> {
  HomeCubit({required this.repository, DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(const HomeState());

  static const int premieringTodayLimit = 5;
  static const int upcomingLimit = 6;

  static const int upcomingDays = 7;

  final ShowsRepository repository;
  final DateTime Function() _now;

  DateTime _today() {
    final DateTime now = _now();

    return DateTime(now.year, now.month, now.day);
  }

  // ---------------------------------------------------------------------------
  // Initial load
  // ---------------------------------------------------------------------------

  Future<void> load() async {
    /*
     * Home sections deliberately load independently.
     *
     * A failure in Premiering Today must not prevent Upcoming from loading,
     * and vice versa.
     */
    await Future.wait(<Future<void>>[loadPremieringToday(), loadUpcoming()]);
  }

  // ---------------------------------------------------------------------------
  // Premiering Today
  // ---------------------------------------------------------------------------

  Future<void> loadPremieringToday() async {
    if (state.isLoadingPremieringToday) {
      return;
    }

    emit(
      state.copyWith(
        isLoadingPremieringToday: true,
        clearPremieringTodayError: true,
      ),
    );

    final DateTime today = _today();

    try {
      final List<UpcomingItem> result = await repository.getUpcoming(
        fromDate: today,
        toDate: today,
      );

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          premieringToday: result
              .take(premieringTodayLimit)
              .toList(growable: false),
          isLoadingPremieringToday: false,
          clearPremieringTodayError: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          isLoadingPremieringToday: false,
          premieringTodayError: error,
        ),
      );
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          isLoadingPremieringToday: false,
          premieringTodayError: AppException.unknown(originalError: error),
        ),
      );
    }
  }

  Future<void> retryPremieringToday() {
    return loadPremieringToday();
  }

  Future<void> markPremieringTodayEpisodeWatched({
    required String episodeId,
  }) async {
    if (state.updatingPremieringTodayEpisodeId != null) {
      return;
    }

    final int itemIndex = state.premieringToday.indexWhere(
      (UpcomingItem item) => item.episode.id == episodeId,
    );

    if (itemIndex == -1) {
      return;
    }

    final UpcomingItem currentItem = state.premieringToday[itemIndex];

    if (currentItem.episode.isWatched) {
      return;
    }

    final List<UpcomingItem> previousItems = state.premieringToday;

    /*
     * Give immediate visual feedback.
     *
     * The server is still the source of truth. If the request fails,
     * rollback to the previous collection.
     */
    final List<UpcomingItem> optimisticItems = previousItems
        .map((UpcomingItem item) {
          if (item.episode.id != episodeId) {
            return item;
          }

          return UpcomingItem(
            libraryEntryId: item.libraryEntryId,
            libraryStatus: item.libraryStatus,
            showId: item.showId,
            showTmdbId: item.showTmdbId,
            showTitle: item.showTitle,
            posterUrl: item.posterUrl,
            backdropUrl: item.backdropUrl,
            episode: item.episode.copyWith(isWatched: true),
          );
        })
        .toList(growable: false);

    emit(
      state.copyWith(
        premieringToday: optimisticItems,
        updatingPremieringTodayEpisodeId: episodeId,
        clearPremieringTodayOperationError: true,
      ),
    );

    try {
      await repository.markEpisodeWatched(episodeId: episodeId);

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          clearUpdatingPremieringTodayEpisodeId: true,
          clearPremieringTodayOperationError: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          premieringToday: previousItems,
          clearUpdatingPremieringTodayEpisodeId: true,
          premieringTodayOperationError: error,
        ),
      );
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          premieringToday: previousItems,
          clearUpdatingPremieringTodayEpisodeId: true,
          premieringTodayOperationError: AppException.unknown(
            originalError: error,
          ),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Upcoming
  // ---------------------------------------------------------------------------

  Future<void> loadUpcoming() async {
    if (state.isLoadingUpcoming) {
      return;
    }

    emit(state.copyWith(isLoadingUpcoming: true, clearUpcomingError: true));

    final DateTime today = _today();

    /*
     * Premiering Today owns today's Episodes.
     *
     * Upcoming starts tomorrow so the same Episode can never appear in both
     * Home sections.
     *
     * Example:
     *
     * today    = 17 Aug
     * fromDate = 18 Aug
     * toDate   = 24 Aug
     *
     * Exactly seven future calendar days.
     */
    final DateTime fromDate = today.add(const Duration(days: 1));

    final DateTime toDate = today.add(const Duration(days: upcomingDays));

    try {
      final List<UpcomingItem> result = await repository.getUpcoming(
        fromDate: fromDate,
        toDate: toDate,
      );

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          upcoming: result.take(upcomingLimit).toList(growable: false),
          isLoadingUpcoming: false,
          clearUpcomingError: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(state.copyWith(isLoadingUpcoming: false, upcomingError: error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          isLoadingUpcoming: false,
          upcomingError: AppException.unknown(originalError: error),
        ),
      );
    }
  }

  Future<void> retryUpcoming() {
    return loadUpcoming();
  }
}
