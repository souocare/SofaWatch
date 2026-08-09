import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/state/remote_state.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_genre_options.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_collection.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_item.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending.dart';

enum ExploreWeekFilter { all, shows, movies }

class ExploreState extends Equatable {
  const ExploreState({
    this.today = const RemoteState<ExploreTrending>.initial(),
    this.week = const RemoteState<ExploreTrending>.initial(),
    this.weekFilter = ExploreWeekFilter.all,
    this.genres = const RemoteState<ExploreGenreOptions>.initial(),
    this.popularShows = const RemoteState<ExploreMediaCollection>.initial(),
    this.popularMovies = const RemoteState<ExploreMediaCollection>.initial(),
    this.selectedShowGenreId,
    this.selectedMovieGenreId,
  });

  final RemoteState<ExploreTrending> today;
  final RemoteState<ExploreTrending> week;
  final ExploreWeekFilter weekFilter;

  final RemoteState<ExploreGenreOptions> genres;

  final RemoteState<ExploreMediaCollection> popularShows;
  final RemoteState<ExploreMediaCollection> popularMovies;

  final int? selectedShowGenreId;
  final int? selectedMovieGenreId;

  List<ExploreMediaItem> get filteredWeekItems {
    final ExploreTrending? trending = week.data;

    if (trending == null) {
      return const <ExploreMediaItem>[];
    }

    return switch (weekFilter) {
      ExploreWeekFilter.all => trending.items,
      ExploreWeekFilter.shows => trending.shows,
      ExploreWeekFilter.movies => trending.movies,
    };
  }

  ExploreState copyWith({
    RemoteState<ExploreTrending>? today,
    RemoteState<ExploreTrending>? week,
    ExploreWeekFilter? weekFilter,
    RemoteState<ExploreGenreOptions>? genres,
    RemoteState<ExploreMediaCollection>? popularShows,
    RemoteState<ExploreMediaCollection>? popularMovies,
    int? selectedShowGenreId,
    int? selectedMovieGenreId,
    bool clearSelectedShowGenre = false,
    bool clearSelectedMovieGenre = false,
  }) {
    return ExploreState(
      today: today ?? this.today,
      week: week ?? this.week,
      weekFilter: weekFilter ?? this.weekFilter,
      genres: genres ?? this.genres,
      popularShows: popularShows ?? this.popularShows,
      popularMovies: popularMovies ?? this.popularMovies,
      selectedShowGenreId: clearSelectedShowGenre
          ? null
          : selectedShowGenreId ?? this.selectedShowGenreId,
      selectedMovieGenreId: clearSelectedMovieGenre
          ? null
          : selectedMovieGenreId ?? this.selectedMovieGenreId,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    today,
    week,
    weekFilter,
    genres,
    popularShows,
    popularMovies,
    selectedShowGenreId,
    selectedMovieGenreId,
  ];
}
