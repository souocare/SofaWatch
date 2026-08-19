import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_habits.dart';

sealed class StatisticsHabitsState extends Equatable {
  const StatisticsHabitsState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class StatisticsHabitsInitial extends StatisticsHabitsState {
  const StatisticsHabitsInitial();
}

final class StatisticsHabitsLoading extends StatisticsHabitsState {
  const StatisticsHabitsLoading();
}

final class StatisticsHabitsSuccess extends StatisticsHabitsState {
  const StatisticsHabitsSuccess(this.habits);

  final StatisticsHabits habits;

  @override
  List<Object?> get props => <Object?>[habits];
}

final class StatisticsHabitsFailure extends StatisticsHabitsState {
  const StatisticsHabitsFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}
