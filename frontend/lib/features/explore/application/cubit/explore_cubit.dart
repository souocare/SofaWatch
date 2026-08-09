import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/core/state/remote_state.dart';
import 'package:sofawatch/features/explore/application/cubit/explore_state.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_collection.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending_window.dart';
import 'package:sofawatch/features/explore/domain/repositories/explore_repository.dart';

class ExploreCubit extends Cubit<ExploreState> {
  ExploreCubit(this._repository) : super(const ExploreState());

  final ExploreRepository _repository;

  Future<void> load() async {
    if (state.today.isLoading ||
        state.week.isLoading ||
        state.popularShows.isLoading) {
      return;
    }

    emit(
      state.copyWith(
        today: const RemoteState<ExploreTrending>.loading(),
        week: const RemoteState<ExploreTrending>.loading(),
        popularShows: const RemoteState<ExploreMediaCollection>.loading(),
      ),
    );

    try {
      final ExploreTrending today = await _repository.getTrending(
        window: ExploreTrendingWindow.day,
      );

      final ExploreTrending week = await _repository.getTrending(
        window: ExploreTrendingWindow.week,
      );

      final ExploreMediaCollection popularShows = await _repository
          .getPopularShows();

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          today: RemoteState<ExploreTrending>.success(today),
          week: RemoteState<ExploreTrending>.success(week),
          popularShows: RemoteState<ExploreMediaCollection>.success(
            popularShows,
          ),
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          today: RemoteState<ExploreTrending>.failure(error),
          week: RemoteState<ExploreTrending>.failure(error),
          popularShows: RemoteState<ExploreMediaCollection>.failure(error),
        ),
      );
    } catch (error) {
      if (isClosed) {
        return;
      }

      final AppException exception = AppException.unknown(originalError: error);

      emit(
        state.copyWith(
          today: RemoteState<ExploreTrending>.failure(exception),
          week: RemoteState<ExploreTrending>.failure(exception),
          popularShows: RemoteState<ExploreMediaCollection>.failure(exception),
        ),
      );
    }
  }

  void changeWeekFilter(ExploreWeekFilter filter) {
    if (filter == state.weekFilter) {
      return;
    }

    emit(state.copyWith(weekFilter: filter));
  }

  Future<void> retry() {
    return load();
  }
}
