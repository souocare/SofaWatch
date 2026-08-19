import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_content_insights_state.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_content_insights.dart';
import 'package:sofawatch/features/statistics/domain/repositories/statistics_repository.dart';

final class StatisticsContentInsightsCubit
    extends Cubit<StatisticsContentInsightsState> {
  StatisticsContentInsightsCubit({required StatisticsRepository repository})
    : _repository = repository,
      super(const StatisticsContentInsightsInitial());

  final StatisticsRepository _repository;

  Future<void> load() async {
    if (state is StatisticsContentInsightsLoading) {
      return;
    }

    emit(const StatisticsContentInsightsLoading());

    try {
      final StatisticsContentInsights insights = await _repository
          .getContentInsights();

      if (isClosed) {
        return;
      }

      emit(StatisticsContentInsightsSuccess(insights));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(StatisticsContentInsightsFailure(error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        StatisticsContentInsightsFailure(
          AppException.unknown(originalError: error),
        ),
      );
    }
  }

  Future<void> retry() {
    return load();
  }
}
