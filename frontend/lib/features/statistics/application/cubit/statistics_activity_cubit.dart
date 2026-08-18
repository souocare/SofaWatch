import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_activity_state.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity.dart';
import 'package:sofawatch/features/statistics/domain/repositories/statistics_repository.dart';

final class StatisticsActivityCubit extends Cubit<StatisticsActivityState> {
  StatisticsActivityCubit({required StatisticsRepository repository})
    : _repository = repository,
      super(const StatisticsActivityInitial());

  static const int defaultDays = 7;

  final StatisticsRepository _repository;

  bool _isRequestInFlight = false;

  Future<void> load({int days = defaultDays}) async {
    if (_isRequestInFlight) {
      return;
    }

    _isRequestInFlight = true;

    emit(StatisticsActivityLoading(days: days));

    try {
      final StatisticsActivity activity = await _repository.getActivity(
        days: days,
      );

      if (isClosed) {
        return;
      }

      emit(StatisticsActivitySuccess(activity: activity, days: days));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(StatisticsActivityFailure(error: error, days: days));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        StatisticsActivityFailure(
          error: AppException.unknown(originalError: error),
          days: days,
        ),
      );
    } finally {
      _isRequestInFlight = false;
    }
  }

  Future<void> changeRange(int days) async {
    final StatisticsActivityState currentState = state;

    if (_isRequestInFlight) {
      return;
    }

    /*
     * Without existing data, changing the range is equivalent to
     * performing the initial load.
     */
    if (currentState is! StatisticsActivitySuccess) {
      await load(days: days);

      return;
    }

    /*
     * The requested range is already visible.
     *
     * Avoid an unnecessary network request.
     */
    if (currentState.days == days) {
      return;
    }

    _isRequestInFlight = true;

    emit(
      currentState.copyWith(
        isChangingRange: true,
        pendingDays: days,
        clearRangeChangeError: true,
      ),
    );

    try {
      final StatisticsActivity activity = await _repository.getActivity(
        days: days,
      );

      if (isClosed) {
        return;
      }

      emit(StatisticsActivitySuccess(activity: activity, days: days));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      /*
       * Keep the previously loaded range visible.
       *
       * The failed range is not promoted to the selected range because
       * no valid data for it was received.
       */
      emit(
        currentState.copyWith(
          isChangingRange: false,
          clearPendingDays: true,
          rangeChangeError: error,
        ),
      );
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        currentState.copyWith(
          isChangingRange: false,
          clearPendingDays: true,
          rangeChangeError: AppException.unknown(originalError: error),
        ),
      );
    } finally {
      _isRequestInFlight = false;
    }
  }

  Future<void> retry() async {
    final StatisticsActivityState currentState = state;

    if (currentState is StatisticsActivityFailure) {
      await load(days: currentState.days);

      return;
    }

    if (currentState is StatisticsActivitySuccess &&
        currentState.rangeChangeError != null) {
      /*
       * A failed range change leaves the previous valid range selected.
       *
       * The UI can simply ask for another range again. There is no hidden
       * failed range to retry because pendingDays is deliberately cleared
       * after the failure.
       */
      return;
    }

    await load();
  }
}
