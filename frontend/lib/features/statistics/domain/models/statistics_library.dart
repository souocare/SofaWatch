import 'package:equatable/equatable.dart';

final class StatisticsLibrary extends Equatable {
  const StatisticsLibrary({
    required this.showsAdded,
    required this.moviesAdded,
    required this.showsCompleted,
  });

  final int showsAdded;
  final int moviesAdded;
  final int showsCompleted;

  @override
  List<Object?> get props => <Object?>[showsAdded, moviesAdded, showsCompleted];
}
