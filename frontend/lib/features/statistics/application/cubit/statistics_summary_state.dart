import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_summary.dart';

sealed class StatisticsSummaryState extends Equatable {
  const StatisticsSummaryState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class StatisticsSummaryInitial extends StatisticsSummaryState {
  const StatisticsSummaryInitial();
}

final class StatisticsSummaryLoading extends StatisticsSummaryState {
  const StatisticsSummaryLoading();
}

final class StatisticsSummarySuccess extends StatisticsSummaryState {
  const StatisticsSummarySuccess(this.summary);

  final StatisticsSummary summary;

  @override
  List<Object?> get props => <Object?>[summary];
}

final class StatisticsSummaryFailure extends StatisticsSummaryState {
  const StatisticsSummaryFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}
