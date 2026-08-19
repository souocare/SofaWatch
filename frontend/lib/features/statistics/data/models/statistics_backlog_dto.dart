import 'package:sofawatch/features/statistics/domain/models/statistics_backlog.dart';

final class StatisticsBacklogDto {
  const StatisticsBacklogDto({
    required this.unwatchedAiredEpisodes,
    required this.plannedMovies,
    required this.futureWatchTimeMinutes,
    required this.catchUpSpeedEpisodesPerWeek,
    required this.backlogTrend,
    required this.backlogTrendEpisodeDelta,
  });

  final int unwatchedAiredEpisodes;
  final int plannedMovies;
  final int futureWatchTimeMinutes;
  final double catchUpSpeedEpisodesPerWeek;
  final String backlogTrend;
  final int backlogTrendEpisodeDelta;

  factory StatisticsBacklogDto.fromJson(Map<String, dynamic> json) {
    return StatisticsBacklogDto(
      unwatchedAiredEpisodes: _requiredNonNegativeInt(
        json,
        'unwatched_aired_episodes',
      ),
      plannedMovies: _requiredNonNegativeInt(json, 'planned_movies'),
      futureWatchTimeMinutes: _requiredNonNegativeInt(
        json,
        'future_watch_time_minutes',
      ),
      catchUpSpeedEpisodesPerWeek: _requiredNonNegativeDouble(
        json,
        'catch_up_speed_episodes_per_week',
      ),
      backlogTrend: _requiredBacklogTrend(json, 'backlog_trend'),
      backlogTrendEpisodeDelta: _requiredInt(
        json,
        'backlog_trend_episode_delta',
      ),
    );
  }

  StatisticsBacklog toDomain() {
    return StatisticsBacklog(
      unwatchedAiredEpisodes: unwatchedAiredEpisodes,
      plannedMovies: plannedMovies,
      futureWatchTimeMinutes: futureWatchTimeMinutes,
      catchUpSpeedEpisodesPerWeek: catchUpSpeedEpisodesPerWeek,
      backlogTrend: backlogTrend,
      backlogTrendEpisodeDelta: backlogTrendEpisodeDelta,
    );
  }
}

int _requiredNonNegativeInt(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! int || value < 0) {
    throw FormatException('$key must be a non-negative integer.');
  }

  return value;
}

double _requiredNonNegativeDouble(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! num || value < 0) {
    throw FormatException('$key must be a non-negative number.');
  }

  return value.toDouble();
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! int) {
    throw FormatException('$key must be an integer.');
  }

  return value;
}

String _requiredBacklogTrend(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! String ||
      !const <String>{'growing', 'shrinking', 'stable'}.contains(value)) {
    throw FormatException('$key must be growing, shrinking or stable.');
  }

  return value;
}
