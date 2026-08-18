import 'package:sofawatch/features/statistics/domain/models/statistics_activity.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_summary.dart';
import 'package:sofawatch/features/statistics/domain/models/weekly_statistics.dart';

abstract interface class StatisticsRepository {
  Future<WeeklyStatistics> getWeeklyStatistics();

  Future<StatisticsSummary> getSummary();

  Future<StatisticsActivity> getActivity({required int days});
}
