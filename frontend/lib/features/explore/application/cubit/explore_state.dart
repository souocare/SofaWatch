import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/state/remote_state.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_item.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending.dart';

enum ExploreWeekFilter { all, shows, movies }

class ExploreState extends Equatable {
  const ExploreState({
    this.today = const RemoteState<ExploreTrending>.initial(),
    this.week = const RemoteState<ExploreTrending>.initial(),
    this.weekFilter = ExploreWeekFilter.all,
  });

  final RemoteState<ExploreTrending> today;
  final RemoteState<ExploreTrending> week;

  final ExploreWeekFilter weekFilter;

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
  }) {
    return ExploreState(
      today: today ?? this.today,
      week: week ?? this.week,
      weekFilter: weekFilter ?? this.weekFilter,
    );
  }

  @override
  List<Object?> get props => <Object?>[today, week, weekFilter];
}
