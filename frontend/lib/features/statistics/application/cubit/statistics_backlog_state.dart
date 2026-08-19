import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_backlog.dart';

sealed class StatisticsBacklogState extends Equatable {
  const StatisticsBacklogState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class StatisticsBacklogInitial extends StatisticsBacklogState {
  const StatisticsBacklogInitial();
}

final class StatisticsBacklogLoading extends StatisticsBacklogState {
  const StatisticsBacklogLoading();
}

final class StatisticsBacklogSuccess extends StatisticsBacklogState {
  const StatisticsBacklogSuccess(this.statistics);

  final StatisticsBacklog statistics;

  @override
  List<Object?> get props => <Object?>[statistics];
}

final class StatisticsBacklogFailure extends StatisticsBacklogState {
  const StatisticsBacklogFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}
