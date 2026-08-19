import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_library.dart';

sealed class StatisticsLibraryState extends Equatable {
  const StatisticsLibraryState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class StatisticsLibraryInitial extends StatisticsLibraryState {
  const StatisticsLibraryInitial();
}

final class StatisticsLibraryLoading extends StatisticsLibraryState {
  const StatisticsLibraryLoading();
}

final class StatisticsLibrarySuccess extends StatisticsLibraryState {
  const StatisticsLibrarySuccess(this.statistics);

  final StatisticsLibrary statistics;

  @override
  List<Object?> get props => <Object?>[statistics];
}

final class StatisticsLibraryFailure extends StatisticsLibraryState {
  const StatisticsLibraryFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}
