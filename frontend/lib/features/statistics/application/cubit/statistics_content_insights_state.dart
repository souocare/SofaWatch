import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_content_insights.dart';

sealed class StatisticsContentInsightsState extends Equatable {
  const StatisticsContentInsightsState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class StatisticsContentInsightsInitial
    extends StatisticsContentInsightsState {
  const StatisticsContentInsightsInitial();
}

final class StatisticsContentInsightsLoading
    extends StatisticsContentInsightsState {
  const StatisticsContentInsightsLoading();
}

final class StatisticsContentInsightsSuccess
    extends StatisticsContentInsightsState {
  const StatisticsContentInsightsSuccess(this.insights);

  final StatisticsContentInsights insights;

  @override
  List<Object?> get props => <Object?>[insights];
}

final class StatisticsContentInsightsFailure
    extends StatisticsContentInsightsState {
  const StatisticsContentInsightsFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}
