import 'package:sofawatch/features/statistics/domain/models/weekly_statistics.dart';

abstract interface class StatisticsRepository {
  Future<WeeklyStatistics> getWeeklyStatistics();
}
