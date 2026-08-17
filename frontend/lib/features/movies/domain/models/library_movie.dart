import 'package:equatable/equatable.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';

final class LibraryMovie extends Equatable {
  const LibraryMovie({
    required this.libraryEntryId,
    required this.movieId,
    required this.tmdbId,
    required this.title,
    required this.originalTitle,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.movieStatus,
    required this.voteAverage,
    this.releaseDate,
    this.posterUrl,
    this.backdropUrl,
    this.rating,
    this.startedAt,
    this.completedAt,
  });

  final String libraryEntryId;

  /// Internal SofaWatch Movie UUID.
  final String movieId;

  /// TMDB identifier used when opening Movie Details.
  final int tmdbId;

  final String title;
  final String originalTitle;

  final DateTime? releaseDate;

  final String? posterUrl;
  final String? backdropUrl;

  final String movieStatus;
  final double voteAverage;

  final LibraryStatus status;

  final double? rating;

  final DateTime? startedAt;
  final DateTime? completedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isWatchlist => status == LibraryStatus.planning;

  bool get isWatched => status == LibraryStatus.completed;

  bool get isComingSoon {
    final DateTime? date = releaseDate;

    if (date == null) {
      return false;
    }

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    final DateTime normalizedReleaseDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    return normalizedReleaseDate.isAfter(today);
  }

  @override
  List<Object?> get props => <Object?>[
    libraryEntryId,
    movieId,
    tmdbId,
    title,
    originalTitle,
    releaseDate,
    posterUrl,
    backdropUrl,
    movieStatus,
    voteAverage,
    status,
    rating,
    startedAt,
    completedAt,
    createdAt,
    updatedAt,
  ];
}
