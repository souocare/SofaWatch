import 'package:sofawatch/features/shows/domain/models/library_show_progress.dart';

final class LibraryShowProgressDto {
  const LibraryShowProgressDto({
    required this.watchedEpisodes,
    required this.airedEpisodes,
    required this.percentage,
    required this.caughtUp,
  });

  factory LibraryShowProgressDto.fromJson(Map<String, dynamic> json) {
    return LibraryShowProgressDto(
      watchedEpisodes: _requiredNonNegativeInt(json, 'watched_episodes'),
      airedEpisodes: _requiredNonNegativeInt(json, 'aired_episodes'),
      percentage: _requiredPercentage(json, 'percentage'),
      caughtUp: _requiredBool(json, 'caught_up'),
    );
  }

  final int watchedEpisodes;
  final int airedEpisodes;
  final double percentage;
  final bool caughtUp;

  LibraryShowProgress toDomain() {
    return LibraryShowProgress(
      watchedEpisodes: watchedEpisodes,
      airedEpisodes: airedEpisodes,
      percentage: percentage,
      caughtUp: caughtUp,
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

bool _requiredBool(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! bool) {
    throw FormatException('Invalid $key.');
  }

  return value;
}
