import 'package:equatable/equatable.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/shows/domain/models/library_show_progress.dart';
import 'package:sofawatch/features/shows/domain/models/stale_watching_episode.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_episode.dart';

final class StaleWatchingShow extends Equatable {
  const StaleWatchingShow({
    required this.libraryEntryId,
    required this.libraryStatus,
    required this.showId,
    required this.showTmdbId,
    required this.showTitle,
    required this.lastWatched,
    required this.nextEpisode,
    required this.progress,
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

  final StaleWatchingEpisode lastWatched;
  final WatchNextEpisode nextEpisode;
  final LibraryShowProgress progress;

  @override
  List<Object?> get props => <Object?>[
    libraryEntryId,
    libraryStatus,
    showId,
    showTmdbId,
    showTitle,
    posterUrl,
    backdropUrl,
    lastWatched,
    nextEpisode,
    progress,
  ];
}
