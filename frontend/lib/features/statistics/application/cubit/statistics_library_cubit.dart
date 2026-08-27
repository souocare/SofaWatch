import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_library_state.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_library.dart';
import 'package:sofawatch/features/statistics/domain/repositories/statistics_repository.dart';

final class StatisticsLibraryCubit extends Cubit<StatisticsLibraryState> {
  StatisticsLibraryCubit({required this._repository})
    : super(const StatisticsLibraryInitial());

  final StatisticsRepository _repository;

  Future<void> load() async {
    if (state is StatisticsLibraryLoading) {
      return;
    }

    emit(const StatisticsLibraryLoading());

    try {
      final StatisticsLibrary statistics = await _repository
          .getLibraryStatistics();

      if (isClosed) {
        return;
      }

      emit(StatisticsLibrarySuccess(statistics));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(StatisticsLibraryFailure(error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        StatisticsLibraryFailure(AppException.unknown(originalError: error)),
      );
    }
  }

  Future<void> retry() {
    return load();
  }
}
