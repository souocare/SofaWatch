import 'package:equatable/equatable.dart';

final class StatisticsHabits extends Equatable {
  const StatisticsHabits({
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.biggestMarathonWatchTimeMinutes,
    required this.biggestMarathonDay,
    required this.longestBingeEpisodeCount,
    required this.longestBingeDay,
    required this.averageActiveDayWatchTimeMinutes,
    required this.mostActiveWeekday,
    required this.mostActiveWeekdayWatchCount,
  });

  final int currentStreakDays;
  final int longestStreakDays;

  final int biggestMarathonWatchTimeMinutes;
  final DateTime? biggestMarathonDay;

  final int longestBingeEpisodeCount;
  final DateTime? longestBingeDay;

  final int averageActiveDayWatchTimeMinutes;

  final String? mostActiveWeekday;
  final int mostActiveWeekdayWatchCount;

  @override
  List<Object?> get props => <Object?>[
    currentStreakDays,
    longestStreakDays,
    biggestMarathonWatchTimeMinutes,
    biggestMarathonDay,
    longestBingeEpisodeCount,
    longestBingeDay,
    averageActiveDayWatchTimeMinutes,
    mostActiveWeekday,
    mostActiveWeekdayWatchCount,
  ];
}
