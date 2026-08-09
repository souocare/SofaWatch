import 'package:sofawatch/features/explore/domain/entities/explore_genre_options.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_collection.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending_window.dart';

abstract interface class ExploreRepository {
  Future<ExploreTrending> getTrending({
    required ExploreTrendingWindow window,
    String? language,
  });

  Future<ExploreGenreOptions> getGenres({String? language});

  Future<ExploreMediaCollection> getPopularShows({
    int? genreId,
    String? language,
  });

  Future<ExploreMediaCollection> getPopularMovies({
    int? genreId,
    String? language,
  });
}
