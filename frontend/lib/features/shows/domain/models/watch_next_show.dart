import 'package:equatable/equatable.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_episode.dart';

final class WatchNextShow extends Equatable {
  const WatchNextShow({
    required this.libraryEntryId,
    required this.libraryStatus,
    required this.showId,
    required this.showTmdbId,
    required this.showTitle,
    required this.nextEpisode,
    this.posterUrl,
    this.backdropUrl,
  });

  final String libraryEntryId;
  final LibraryStatus libraryStatus;

  final String showId;
  final int showTmdbId;
  final String showTitle;

  final String? posterUrl;
  final String? backdropUrl;

  final WatchNextEpisode nextEpisode;

  @override
  List<Object?> get props => <Object?>[
    libraryEntryId,
    libraryStatus,
    showId,
    showTmdbId,
    showTitle,
    posterUrl,
    backdropUrl,
    nextEpisode,
  ];
}
