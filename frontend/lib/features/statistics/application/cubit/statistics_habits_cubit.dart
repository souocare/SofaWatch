import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_habits_state.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_habits.dart';
import 'package:sofawatch/features/statistics/domain/repositories/statistics_repository.dart';

final class StatisticsHabitsCubit extends Cubit<StatisticsHabitsState> {
  StatisticsHabitsCubit({required this._repository})
    : super(const StatisticsHabitsInitial());

  final StatisticsRepository _repository;

  Future<void> load() async {
    if (state is StatisticsHabitsLoading) {
      return;
    }

    emit(const StatisticsHabitsLoading());

    try {
      final StatisticsHabits habits = await _repository.getHabits();

      if (isClosed) {
        return;
      }

      emit(StatisticsHabitsSuccess(habits));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(StatisticsHabitsFailure(error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(StatisticsHabitsFailure(AppException.unknown(originalError: error)));
    }
  }

  Future<void> retry() {
    return load();
  }
}
