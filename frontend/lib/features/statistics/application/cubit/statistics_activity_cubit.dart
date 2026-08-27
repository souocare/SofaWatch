import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_activity_state.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity_period.dart';
import 'package:sofawatch/features/statistics/domain/repositories/statistics_repository.dart';

final class StatisticsActivityCubit extends Cubit<StatisticsActivityState> {
  StatisticsActivityCubit({required this._repository})
    : super(const StatisticsActivityInitial());

  static const StatisticsActivityPeriod defaultPeriod =
      StatisticsActivityPeriod.days7;

  final StatisticsRepository _repository;

  bool _isRequestInFlight = false;

  Future<void> load({StatisticsActivityPeriod period = defaultPeriod}) async {
    if (_isRequestInFlight) {
      return;
    }

    _isRequestInFlight = true;

    emit(StatisticsActivityLoading(period: period));

    try {
      final StatisticsActivity activity = await _repository.getActivity(
        period: period,
      );

      if (isClosed) {
        return;
      }

      emit(StatisticsActivitySuccess(activity: activity, period: period));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(StatisticsActivityFailure(error: error, period: period));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        StatisticsActivityFailure(
          error: AppException.unknown(originalError: error),
          period: period,
        ),
      );
    } finally {
      _isRequestInFlight = false;
    }
  }

  Future<void> changePeriod(StatisticsActivityPeriod period) async {
    final StatisticsActivityState currentState = state;

    if (_isRequestInFlight) {
      return;
    }

    /*
     * Without existing data, changing the period is equivalent to
     * performing the initial load.
     */
    if (currentState is! StatisticsActivitySuccess) {
      await load(period: period);

      return;
    }

    /*
     * The requested period is already visible.
     *
     * Avoid an unnecessary network request.
     */
    if (currentState.period == period) {
      return;
    }

    _isRequestInFlight = true;

    emit(
      currentState.copyWith(
        isChangingPeriod: true,
        pendingPeriod: period,
        clearPeriodChangeError: true,
      ),
    );

    try {
      final StatisticsActivity activity = await _repository.getActivity(
        period: period,
      );

      if (isClosed) {
        return;
      }

      emit(StatisticsActivitySuccess(activity: activity, period: period));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        currentState.copyWith(
          isChangingPeriod: false,
          clearPendingPeriod: true,
          periodChangeError: error,
        ),
      );
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        currentState.copyWith(
          isChangingPeriod: false,
          clearPendingPeriod: true,
          periodChangeError: AppException.unknown(originalError: error),
        ),
      );
    } finally {
      _isRequestInFlight = false;
    }
  }

  Future<void> retry() async {
    final StatisticsActivityState currentState = state;

    if (currentState is StatisticsActivityFailure) {
      await load(period: currentState.period);

      return;
    }

    if (currentState is StatisticsActivitySuccess &&
        currentState.periodChangeError != null) {
      /*
       * A failed period change leaves the previous valid period selected.
       *
       * There is deliberately no hidden failed period to retry because
       * pendingPeriod is cleared after the failure.
       */
      return;
    }

    await load();
  }
}
