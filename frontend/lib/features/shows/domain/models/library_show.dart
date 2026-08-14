import 'package:equatable/equatable.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/shows/domain/models/library_first_episode.dart';

final class LibraryShow extends Equatable {
  const LibraryShow({
    required this.libraryEntryId,
    required this.showId,
    required this.tmdbId,
    required this.title,
    required this.originalTitle,
    required this.status,
    required this.showStatus,
    required this.voteAverage,
    required this.createdAt,
    required this.updatedAt,
    this.firstAirDate,
    this.posterUrl,
    this.backdropUrl,
    this.rating,
    this.startedAt,
    this.completedAt,
    this.firstAvailableEpisode,
  });

  final String libraryEntryId;

  final String showId;
  final int tmdbId;

  final String title;
  final String originalTitle;

  final DateTime? firstAirDate;

  final String? posterUrl;
  final String? backdropUrl;

  final LibraryStatus status;

  /// Provider/local metadata status of the TV series itself
  /// (for example "Returning Series" or "Ended").
  final String showStatus;

  final double voteAverage;

  /// User rating stored on the Library entry.
  final double? rating;

  final DateTime? startedAt;
  final DateTime? completedAt;

  final DateTime createdAt;
  final DateTime updatedAt;
  final LibraryFirstEpisode? firstAvailableEpisode;

  @override
  List<Object?> get props => <Object?>[
    libraryEntryId,
    showId,
    tmdbId,
    title,
    originalTitle,
    firstAirDate,
    posterUrl,
    backdropUrl,
    status,
    showStatus,
    voteAverage,
    rating,
    startedAt,
    completedAt,
    createdAt,
    updatedAt,
    firstAvailableEpisode,
  ];
}
