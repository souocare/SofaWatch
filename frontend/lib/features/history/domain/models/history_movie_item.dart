import 'package:sofawatch/features/history/domain/models/history_item.dart';

final class HistoryMovieItem extends HistoryItem {
  const HistoryMovieItem({
    required super.eventId,
    required super.watchedAt,
    required this.movieId,
    required this.movieTmdbId,
    required this.movieTitle,
    this.posterUrl,
    this.backdropUrl,
  });

  final String movieId;
  final int movieTmdbId;
  final String movieTitle;

  final String? posterUrl;
  final String? backdropUrl;

  @override
  List<Object?> get props => <Object?>[
    eventId,
    watchedAt,
    movieId,
    movieTmdbId,
    movieTitle,
    posterUrl,
    backdropUrl,
  ];
}
