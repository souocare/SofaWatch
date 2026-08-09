import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/state/remote_state.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_collection.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_item.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending.dart';

enum ExploreWeekFilter { all, shows, movies }

class ExploreState extends Equatable {
  const ExploreState({
    this.today = const RemoteState<ExploreTrending>.initial(),
    this.week = const RemoteState<ExploreTrending>.initial(),
    this.weekFilter = ExploreWeekFilter.all,
    this.popularShows = const RemoteState.initial(),
    this.popularMovies = const RemoteState<ExploreMediaCollection>.initial(),
  });

  final RemoteState<ExploreTrending> today;
  final RemoteState<ExploreTrending> week;

  final ExploreWeekFilter weekFilter;
  final RemoteState<ExploreMediaCollection> popularShows;
  final RemoteState<ExploreMediaCollection> popularMovies;

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
    RemoteState<ExploreMediaCollection>? popularShows,
    RemoteState<ExploreMediaCollection>? popularMovies,
  }) {
    return ExploreState(
      today: today ?? this.today,
      week: week ?? this.week,
      weekFilter: weekFilter ?? this.weekFilter,
      popularShows: popularShows ?? this.popularShows,
      popularMovies: popularMovies ?? this.popularMovies,
    );
  }

  @override
  List<Object?> get props => <Object?>[today, week, weekFilter];
}
