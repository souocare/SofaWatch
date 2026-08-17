import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/statistics/domain/models/weekly_statistics.dart';

sealed class StatisticsState extends Equatable {
  const StatisticsState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class StatisticsInitial extends StatisticsState {
  const StatisticsInitial();
}

final class StatisticsLoading extends StatisticsState {
  const StatisticsLoading();
}

final class StatisticsSuccess extends StatisticsState {
  const StatisticsSuccess(this.statistics);

  final WeeklyStatistics statistics;

  @override
  List<Object?> get props => <Object?>[statistics];
}

final class StatisticsFailure extends StatisticsState {
  const StatisticsFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}
