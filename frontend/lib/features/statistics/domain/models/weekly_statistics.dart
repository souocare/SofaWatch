import 'package:equatable/equatable.dart';

final class WeeklyStatistics extends Equatable {
  const WeeklyStatistics({
    required this.weekStart,
    required this.weekEnd,
    required this.episodesWatched,
    required this.moviesWatched,
    required this.watchTimeMinutes,
  });

  final DateTime weekStart;
  final DateTime weekEnd;

  /// Number of real Episode viewing events recorded during the week.
  ///
  /// Rewatches therefore count as additional viewings.
  final int episodesWatched;

  /// Number of real Movie viewing events recorded during the week.
  ///
  /// Rewatches therefore count as additional viewings.
  final int moviesWatched;

  /// Total known runtime watched during the week, in minutes.
  final int watchTimeMinutes;

  @override
  List<Object?> get props => <Object?>[
    weekStart,
    weekEnd,
    episodesWatched,
    moviesWatched,
    watchTimeMinutes,
  ];
}
