import 'package:sofawatch/features/profile/domain/models/data_import_preview.dart';

final class DataImportPreviewDto {
  const DataImportPreviewDto({
    required this.format,
    required this.version,
    required this.userDisplayName,
    required this.libraryShows,
    required this.libraryMovies,
    required this.episodeWatchEvents,
    required this.movieWatchEvents,
  });

  factory DataImportPreviewDto.fromJson(Map<String, dynamic> json) {
    final Object? summaryValue = json['summary'];

    if (summaryValue is! Map<String, dynamic>) {
      throw const FormatException('The import preview summary is missing.');
    }

    return DataImportPreviewDto(
      format: json['format'] as String,
      version: json['version'] as int,
      userDisplayName: json['user_display_name'] as String,
      libraryShows: summaryValue['library_shows'] as int,
      libraryMovies: summaryValue['library_movies'] as int,
      episodeWatchEvents: summaryValue['episode_watch_events'] as int,
      movieWatchEvents: summaryValue['movie_watch_events'] as int,
    );
  }

  final String format;
  final int version;
  final String userDisplayName;

  final int libraryShows;
  final int libraryMovies;
  final int episodeWatchEvents;
  final int movieWatchEvents;

  DataImportPreview toDomain() {
    return DataImportPreview(
      format: format,
      version: version,
      userDisplayName: userDisplayName,
      libraryShows: libraryShows,
      libraryMovies: libraryMovies,
      episodeWatchEvents: episodeWatchEvents,
      movieWatchEvents: movieWatchEvents,
    );
  }
}
