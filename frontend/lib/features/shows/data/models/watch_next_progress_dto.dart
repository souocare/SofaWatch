import 'package:sofawatch/features/shows/domain/models/watch_next_progress.dart';

final class WatchNextProgressDto {
  const WatchNextProgressDto({
    required this.watchedEpisodes,
    required this.airedEpisodes,
    required this.percentage,
  });

  factory WatchNextProgressDto.fromJson(Map<String, dynamic> json) {
    return WatchNextProgressDto(
      watchedEpisodes: _requiredNonNegativeInt(json, 'watched_episodes'),
      airedEpisodes: _requiredNonNegativeInt(json, 'aired_episodes'),
      percentage: _requiredPercentage(json, 'percentage'),
    );
  }

  final int watchedEpisodes;
  final int airedEpisodes;
  final double percentage;

  WatchNextProgress toDomain() {
    return WatchNextProgress(
      watchedEpisodes: watchedEpisodes,
      airedEpisodes: airedEpisodes,
      percentage: percentage,
    );
  }
}

int _requiredNonNegativeInt(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! int || value < 0) {
    throw FormatException('Invalid $key.');
  }

  return value;
}

double _requiredPercentage(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! num) {
    throw FormatException('Invalid $key.');
  }

  final double normalized = value.toDouble();

  if (normalized < 0 || normalized > 100) {
    throw FormatException('Invalid $key.');
  }

  return normalized;
}
