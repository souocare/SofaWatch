import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_backlog_state.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_backlog.dart';
import 'package:sofawatch/features/statistics/domain/repositories/statistics_repository.dart';

final class StatisticsBacklogCubit extends Cubit<StatisticsBacklogState> {
  StatisticsBacklogCubit({required this._repository})
    : super(const StatisticsBacklogInitial());

  final StatisticsRepository _repository;

  Future<void> load() async {
    if (state is StatisticsBacklogLoading) {
      return;
    }

    emit(const StatisticsBacklogLoading());

    try {
      final StatisticsBacklog statistics = await _repository
          .getBacklogStatistics();

      if (isClosed) {
        return;
      }

      emit(StatisticsBacklogSuccess(statistics));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(StatisticsBacklogFailure(error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        StatisticsBacklogFailure(AppException.unknown(originalError: error)),
      );
    }
  }

  Future<void> retry() {
    return load();
  }
}
