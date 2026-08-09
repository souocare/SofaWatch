import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/core/state/remote_state.dart';
import 'package:sofawatch/features/explore/application/cubit/explore_state.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending.dart';
import 'package:sofawatch/features/explore/domain/repositories/explore_repository.dart';

class ExploreCubit extends Cubit<ExploreState> {
  ExploreCubit(this._repository) : super(const ExploreState());

  final ExploreRepository _repository;

  Future<void> load({String? language}) async {
    if (state.trending.isLoading) {
      return;
    }

    emit(
      state.copyWith(trending: const RemoteState<ExploreTrending>.loading()),
    );

    try {
      final ExploreTrending trending = await _repository.getTrending(
        language: language,
      );

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          trending: RemoteState<ExploreTrending>.success(trending),
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(trending: RemoteState<ExploreTrending>.failure(error)),
      );
    } catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          trending: RemoteState<ExploreTrending>.failure(
            AppException.unknown(originalError: error),
          ),
        ),
      );
    }
  }

  Future<void> retry() {
    return load();
  }
}
