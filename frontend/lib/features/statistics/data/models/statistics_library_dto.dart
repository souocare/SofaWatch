import 'package:sofawatch/features/statistics/domain/models/statistics_library.dart';

final class StatisticsLibraryDto {
  const StatisticsLibraryDto({
    required this.showsAdded,
    required this.moviesAdded,
    required this.showsCompleted,
  });

  final int showsAdded;
  final int moviesAdded;
  final int showsCompleted;

  factory StatisticsLibraryDto.fromJson(Map<String, dynamic> json) {
    return StatisticsLibraryDto(
      showsAdded: _requiredNonNegativeInt(json, 'shows_added'),
      moviesAdded: _requiredNonNegativeInt(json, 'movies_added'),
      showsCompleted: _requiredNonNegativeInt(json, 'shows_completed'),
    );
  }

  StatisticsLibrary toDomain() {
    return StatisticsLibrary(
      showsAdded: showsAdded,
      moviesAdded: moviesAdded,
      showsCompleted: showsCompleted,
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
