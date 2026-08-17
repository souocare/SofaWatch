import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/movies/application/models/movies_filter.dart';
import 'package:sofawatch/features/movies/application/models/movies_sort.dart';
import 'package:sofawatch/features/movies/domain/models/library_movie.dart';

final class MoviesState extends Equatable {
  const MoviesState({
    this.libraryMovies = const <LibraryMovie>[],
    this.isLoading = false,
    this.error,
    this.isRefreshing = false,
    this.refreshError,
    this.searchQuery = '',
    this.filter = MoviesFilter.all,
    this.sort = MoviesSort.recentlyUpdated,
  });

  final List<LibraryMovie> libraryMovies;

  /// Whether the initial Movies data is being loaded.
  final bool isLoading;

  /// Fatal failure while loading the core Movies/Library data.
  final AppException? error;

  /// Whether Movies is being explicitly refreshed.
  ///
  /// Existing content remains visible while this is true.
  final bool isRefreshing;

  /// Failure while explicitly refreshing Movies.
  ///
  /// A refresh failure must not replace already loaded content.
  final AppException? refreshError;

  /// Local search query applied to the already loaded Movie library.
  ///
  /// No API request is performed when this changes.
  final String searchQuery;

  /// Local collection filter.
  final MoviesFilter filter;

  /// Local ordering applied after search/filtering.
  final MoviesSort sort;

  bool get hasFatalError => error != null;

  bool get isLibraryEmpty => libraryMovies.isEmpty;

  bool get hasSearchQuery => searchQuery.trim().isNotEmpty;

  bool get hasActiveFilter => filter != MoviesFilter.all;

  bool get hasLocalConstraints => hasSearchQuery || hasActiveFilter;

  /// Movies after applying the current local search, filter and sorting.
  List<LibraryMovie> get visibleMovies {
    final String normalizedQuery = searchQuery.trim().toLowerCase();

    final List<LibraryMovie> result = libraryMovies
        .where((LibraryMovie movie) {
          if (!_matchesFilter(movie)) {
            return false;
          }

          if (normalizedQuery.isEmpty) {
            return true;
          }

          return movie.title.toLowerCase().contains(normalizedQuery) ||
              movie.originalTitle.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: true);

    result.sort(_compareMovies);

    return List<LibraryMovie>.unmodifiable(result);
  }

  /// Watchlist Movies currently visible after local search/filtering.
  List<LibraryMovie> get watchlist {
    return visibleMovies
        .where(
          (LibraryMovie movie) =>
              movie.status == LibraryStatus.planning && !movie.isComingSoon,
        )
        .toList(growable: false);
  }

  /// Finished Movies currently visible after local search/filtering.
  List<LibraryMovie> get watched {
    return visibleMovies
        .where((LibraryMovie movie) => movie.status == LibraryStatus.completed)
        .toList(growable: false);
  }

  /// Upcoming Watchlist Movies currently visible after local search/filtering.
  List<LibraryMovie> get comingSoon {
    return visibleMovies
        .where(
          (LibraryMovie movie) =>
              movie.status == LibraryStatus.planning && movie.isComingSoon,
        )
        .toList(growable: false);
  }

  bool get isWatchlistEmpty => watchlist.isEmpty;

  bool get isWatchedEmpty => watched.isEmpty;

  bool get isComingSoonEmpty => comingSoon.isEmpty;

  bool get hasVisibleMovies => visibleMovies.isNotEmpty;

  bool _matchesFilter(LibraryMovie movie) {
    return switch (filter) {
      MoviesFilter.all => true,
      MoviesFilter.watchlist => movie.status == LibraryStatus.planning,
      MoviesFilter.watched => movie.status == LibraryStatus.completed,
      MoviesFilter.comingSoon =>
        movie.status == LibraryStatus.planning && movie.isComingSoon,
    };
  }

  int _compareMovies(LibraryMovie left, LibraryMovie right) {
    return switch (sort) {
      MoviesSort.recentlyUpdated => _compareRecentlyUpdated(left, right),
      MoviesSort.title => _compareTitle(left, right),
      MoviesSort.releaseDateNewest => _compareReleaseDate(
        left,
        right,
        newestFirst: true,
      ),
      MoviesSort.releaseDateOldest => _compareReleaseDate(
        left,
        right,
        newestFirst: false,
      ),
      MoviesSort.ratingHighest => _compareRating(left, right),
    };
  }

  int _compareRecentlyUpdated(LibraryMovie left, LibraryMovie right) {
    final int comparison = right.updatedAt.compareTo(left.updatedAt);

    if (comparison != 0) {
      return comparison;
    }

    return _compareTitle(left, right);
  }

  int _compareTitle(LibraryMovie left, LibraryMovie right) {
    return left.title.toLowerCase().compareTo(right.title.toLowerCase());
  }

  int _compareReleaseDate(
    LibraryMovie left,
    LibraryMovie right, {
    required bool newestFirst,
  }) {
    final DateTime? leftDate = left.releaseDate;
    final DateTime? rightDate = right.releaseDate;

    /*
     * Unknown release dates are always placed last, regardless of
     * ascending/descending ordering.
     */
    if (leftDate == null && rightDate == null) {
      return _compareTitle(left, right);
    }

    if (leftDate == null) {
      return 1;
    }

    if (rightDate == null) {
      return -1;
    }

    final int comparison = newestFirst
        ? rightDate.compareTo(leftDate)
        : leftDate.compareTo(rightDate);

    if (comparison != 0) {
      return comparison;
    }

    return _compareTitle(left, right);
  }

  int _compareRating(LibraryMovie left, LibraryMovie right) {
    final int comparison = right.voteAverage.compareTo(left.voteAverage);

    if (comparison != 0) {
      return comparison;
    }

    return _compareTitle(left, right);
  }

  MoviesState copyWith({
    List<LibraryMovie>? libraryMovies,
    bool? isLoading,
    AppException? error,
    bool clearError = false,
    bool? isRefreshing,
    AppException? refreshError,
    bool clearRefreshError = false,
    String? searchQuery,
    MoviesFilter? filter,
    MoviesSort? sort,
  }) {
    return MoviesState(
      libraryMovies: libraryMovies ?? this.libraryMovies,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      refreshError: clearRefreshError
          ? null
          : refreshError ?? this.refreshError,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    libraryMovies,
    isLoading,
    error,
    isRefreshing,
    refreshError,
    searchQuery,
    filter,
    sort,
  ];
}
