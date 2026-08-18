import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity.dart';

sealed class StatisticsActivityState extends Equatable {
  const StatisticsActivityState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class StatisticsActivityInitial extends StatisticsActivityState {
  const StatisticsActivityInitial();
}

final class StatisticsActivityLoading extends StatisticsActivityState {
  const StatisticsActivityLoading({required this.days});

  final int days;

  @override
  List<Object?> get props => <Object?>[days];
}

final class StatisticsActivitySuccess extends StatisticsActivityState {
  const StatisticsActivitySuccess({
    required this.activity,
    required this.days,
    this.isChangingRange = false,
    this.pendingDays,
    this.rangeChangeError,
  });

  final StatisticsActivity activity;

  /// Range represented by [activity].
  final int days;

  /// Whether another range is currently being requested.
  final bool isChangingRange;

  /// Range currently being requested while preserving [activity].
  final int? pendingDays;

  /// Non-blocking failure from a range change.
  final AppException? rangeChangeError;

  StatisticsActivitySuccess copyWith({
    StatisticsActivity? activity,
    int? days,
    bool? isChangingRange,
    int? pendingDays,
    bool clearPendingDays = false,
    AppException? rangeChangeError,
    bool clearRangeChangeError = false,
  }) {
    return StatisticsActivitySuccess(
      activity: activity ?? this.activity,
      days: days ?? this.days,
      isChangingRange: isChangingRange ?? this.isChangingRange,
      pendingDays: clearPendingDays ? null : pendingDays ?? this.pendingDays,
      rangeChangeError: clearRangeChangeError
          ? null
          : rangeChangeError ?? this.rangeChangeError,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    activity,
    days,
    isChangingRange,
    pendingDays,
    rangeChangeError,
  ];
}

final class StatisticsActivityFailure extends StatisticsActivityState {
  const StatisticsActivityFailure({required this.error, required this.days});

  final AppException error;

  /// Range whose initial load failed.
  final int days;

  @override
  List<Object?> get props => <Object?>[error, days];
}
