import 'package:sofawatch/features/statistics/domain/models/statistics_activity.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_summary.dart';
import 'package:sofawatch/features/statistics/domain/models/weekly_statistics.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity_period.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_habits.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_content_insights.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_library.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_backlog.dart';

abstract interface class StatisticsRepository {
  Future<WeeklyStatistics> getWeeklyStatistics();

  Future<StatisticsSummary> getSummary();

  Future<StatisticsActivity> getActivity({
    required StatisticsActivityPeriod period,
  });

  Future<StatisticsHabits> getHabits();

  Future<StatisticsContentInsights> getContentInsights();

  Future<StatisticsLibrary> getLibraryStatistics();

  Future<StatisticsBacklog> getBacklogStatistics();
}
