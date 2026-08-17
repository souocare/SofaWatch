import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_state.dart';
import 'package:sofawatch/features/statistics/domain/models/weekly_statistics.dart';
import 'package:sofawatch/features/statistics/domain/repositories/statistics_repository.dart';

final class StatisticsCubit extends Cubit<StatisticsState> {
  StatisticsCubit({required StatisticsRepository repository})
    : _repository = repository,
      super(const StatisticsInitial());

  final StatisticsRepository _repository;

  Future<void> loadWeeklyStatistics() async {
    if (state is StatisticsLoading) {
      return;
    }

    emit(const StatisticsLoading());

    try {
      final WeeklyStatistics statistics = await _repository
          .getWeeklyStatistics();

      if (isClosed) {
        return;
      }

      emit(StatisticsSuccess(statistics));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(StatisticsFailure(error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(StatisticsFailure(AppException.unknown(originalError: error)));
    }
  }

  Future<void> retry() {
    return loadWeeklyStatistics();
  }
}
