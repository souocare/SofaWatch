import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/movies/domain/models/library_movie.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';

final class LibraryCollectionState extends Equatable {
  const LibraryCollectionState({
    this.shows = const <LibraryShow>[],
    this.movies = const <LibraryMovie>[],
    this.isLoadingShows = false,
    this.isLoadingMovies = false,
    this.showsError,
    this.moviesError,
  });

  final List<LibraryShow> shows;
  final List<LibraryMovie> movies;

  final bool isLoadingShows;
  final bool isLoadingMovies;

  final AppException? showsError;
  final AppException? moviesError;

  bool get isLoading => isLoadingShows || isLoadingMovies;

  bool get areShowsEmpty => shows.isEmpty;

  bool get areMoviesEmpty => movies.isEmpty;

  List<LibraryShow> get watchingShows {
    return shows
        .where(
          (LibraryShow show) =>
              show.status == LibraryStatus.watching && !show.progress.caughtUp,
        )
        .toList(growable: false);
  }

  List<LibraryShow> get upToDateShows {
    return shows
        .where(
          (LibraryShow show) =>
              show.status == LibraryStatus.watching && show.progress.caughtUp,
        )
        .toList(growable: false);
  }

  List<LibraryShow> get haventStartedShows {
    return shows
        .where((LibraryShow show) => show.status == LibraryStatus.planning)
        .toList(growable: false);
  }

  List<LibraryShow> get finishedShows {
    return shows
        .where((LibraryShow show) => show.status == LibraryStatus.completed)
        .toList(growable: false);
  }

  List<LibraryShow> get pausedShows {
    return shows
        .where((LibraryShow show) => show.status == LibraryStatus.paused)
        .toList(growable: false);
  }

  List<LibraryShow> get droppedShows {
    return shows
        .where((LibraryShow show) => show.status == LibraryStatus.dropped)
        .toList(growable: false);
  }

  List<LibraryMovie> get watchlistMovies {
    return movies
        .where(
          (LibraryMovie movie) =>
              movie.status == LibraryStatus.planning && !movie.isComingSoon,
        )
        .toList(growable: false);
  }

  List<LibraryMovie> get upcomingMovies {
    return movies
        .where(
          (LibraryMovie movie) =>
              movie.status == LibraryStatus.planning && movie.isComingSoon,
        )
        .toList(growable: false);
  }

  List<LibraryMovie> get watchedMovies {
    return movies
        .where((LibraryMovie movie) => movie.status == LibraryStatus.completed)
        .toList(growable: false);
  }

  LibraryCollectionState copyWith({
    List<LibraryShow>? shows,
    List<LibraryMovie>? movies,
    bool? isLoadingShows,
    bool? isLoadingMovies,
    AppException? showsError,
    bool clearShowsError = false,
    AppException? moviesError,
    bool clearMoviesError = false,
  }) {
    return LibraryCollectionState(
      shows: shows ?? this.shows,
      movies: movies ?? this.movies,
      isLoadingShows: isLoadingShows ?? this.isLoadingShows,
      isLoadingMovies: isLoadingMovies ?? this.isLoadingMovies,
      showsError: clearShowsError ? null : showsError ?? this.showsError,
      moviesError: clearMoviesError ? null : moviesError ?? this.moviesError,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    shows,
    movies,
    isLoadingShows,
    isLoadingMovies,
    showsError,
    moviesError,
  ];
}
