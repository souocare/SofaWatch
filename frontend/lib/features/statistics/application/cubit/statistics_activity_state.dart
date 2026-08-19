import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity_period.dart';

sealed class StatisticsActivityState extends Equatable {
  const StatisticsActivityState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class StatisticsActivityInitial extends StatisticsActivityState {
  const StatisticsActivityInitial();
}

final class StatisticsActivityLoading extends StatisticsActivityState {
  const StatisticsActivityLoading({required this.period});

  final StatisticsActivityPeriod period;

  @override
  List<Object?> get props => <Object?>[period];
}

final class StatisticsActivitySuccess extends StatisticsActivityState {
  const StatisticsActivitySuccess({
    required this.activity,
    required this.period,
    this.isChangingPeriod = false,
    this.pendingPeriod,
    this.periodChangeError,
  });

  final StatisticsActivity activity;

  /// Period represented by [activity].
  final StatisticsActivityPeriod period;

  /// Whether another period is currently being requested.
  final bool isChangingPeriod;

  /// Period currently being requested while preserving [activity].
  final StatisticsActivityPeriod? pendingPeriod;

  /// Non-blocking failure from a period change.
  final AppException? periodChangeError;

  StatisticsActivitySuccess copyWith({
    StatisticsActivity? activity,
    StatisticsActivityPeriod? period,
    bool? isChangingPeriod,
    StatisticsActivityPeriod? pendingPeriod,
    bool clearPendingPeriod = false,
    AppException? periodChangeError,
    bool clearPeriodChangeError = false,
  }) {
    return StatisticsActivitySuccess(
      activity: activity ?? this.activity,
      period: period ?? this.period,
      isChangingPeriod: isChangingPeriod ?? this.isChangingPeriod,
      pendingPeriod: clearPendingPeriod
          ? null
          : pendingPeriod ?? this.pendingPeriod,
      periodChangeError: clearPeriodChangeError
          ? null
          : periodChangeError ?? this.periodChangeError,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    activity,
    period,
    isChangingPeriod,
    pendingPeriod,
    periodChangeError,
  ];
}

final class StatisticsActivityFailure extends StatisticsActivityState {
  const StatisticsActivityFailure({required this.error, required this.period});

  final AppException error;

  /// Period whose initial load failed.
  final StatisticsActivityPeriod period;

  @override
  List<Object?> get props => <Object?>[error, period];
}
