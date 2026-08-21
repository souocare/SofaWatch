import 'package:equatable/equatable.dart';

final class DataImportPreview extends Equatable {
  const DataImportPreview({
    required this.format,
    required this.version,
    required this.userDisplayName,
    required this.libraryShows,
    required this.libraryMovies,
    required this.episodeWatchEvents,
    required this.movieWatchEvents,
  });

  final String format;
  final int version;
  final String userDisplayName;

  final int libraryShows;
  final int libraryMovies;
  final int episodeWatchEvents;
  final int movieWatchEvents;

  @override
  List<Object?> get props => <Object?>[
    format,
    version,
    userDisplayName,
    libraryShows,
    libraryMovies,
    episodeWatchEvents,
    movieWatchEvents,
  ];
}
