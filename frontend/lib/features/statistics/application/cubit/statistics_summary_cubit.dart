import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_summary_state.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_summary.dart';
import 'package:sofawatch/features/statistics/domain/repositories/statistics_repository.dart';

final class StatisticsSummaryCubit extends Cubit<StatisticsSummaryState> {
  StatisticsSummaryCubit({required StatisticsRepository repository})
    : _repository = repository,
      super(const StatisticsSummaryInitial());

  final StatisticsRepository _repository;

  Future<void> load() async {
    if (state is StatisticsSummaryLoading) {
      return;
    }

    emit(const StatisticsSummaryLoading());

    try {
      final StatisticsSummary summary = await _repository.getSummary();

      if (isClosed) {
        return;
      }

      emit(StatisticsSummarySuccess(summary));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(StatisticsSummaryFailure(error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        StatisticsSummaryFailure(AppException.unknown(originalError: error)),
      );
    }
  }

  Future<void> retry() {
    return load();
  }
}
