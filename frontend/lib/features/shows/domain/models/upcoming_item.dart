import 'package:equatable/equatable.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/shows/domain/models/upcoming_episode.dart';

final class UpcomingItem extends Equatable {
  const UpcomingItem({
    required this.libraryEntryId,
    required this.libraryStatus,
    required this.showId,
    required this.showTmdbId,
    required this.showTitle,
    required this.episode,
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

  final UpcomingEpisode episode;

  @override
  List<Object?> get props => <Object?>[
    libraryEntryId,
    libraryStatus,
    showId,
    showTmdbId,
    showTitle,
    posterUrl,
    backdropUrl,
    episode,
  ];
}
