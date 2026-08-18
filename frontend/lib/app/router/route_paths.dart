abstract final class RoutePaths {
  static const String root = '/';

  static const String serverSetup = '/server-setup';
  static const String search = '/search';

  static const String home = '/home';

  static const String shows = '/shows';
  static const String showDetails = '/shows/:showId';

  static const String movies = '/movies';
  static const String movieDetails = '/movies/:movieId';

  static const String explore = '/explore';

  static const String profile = '/profile';
  static const String detailedStatistics = 'statistics';
  static const String detailedStatisticsLocation = '/profile/statistics';

  static const String episodeDetails = '/episodes/:episodeId';

  static String showDetailsLocation(String showId) {
    return '/shows/$showId';
  }

  static String movieDetailsLocation(String movieId) {
    return '/movies/$movieId';
  }

  static String episodeDetailsLocation(String episodeId) {
    return '/episodes/$episodeId';
  }
}
