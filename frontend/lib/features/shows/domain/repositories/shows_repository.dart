import 'package:sofawatch/features/shows/domain/models/library_show.dart';
import 'package:sofawatch/features/shows/domain/models/stale_watching_show.dart';
import 'package:sofawatch/features/shows/domain/models/upcoming_item.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_page.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_show.dart';

abstract interface class ShowsRepository {
  Future<List<LibraryShow>> getLibraryShows();

  Future<List<WatchNextShow>> getWatchNext();

  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
  });

  Future<List<StaleWatchingShow>> getStaleWatching();

  Future<WatchHistoryPage> getWatchHistory({int limit = 30, String? cursor});

  Future<void> markEpisodeWatched({required String episodeId});

  Future<void> startShow({required String showId});

  Future<void> markEpisodeUnwatched({required String episodeId});
}
