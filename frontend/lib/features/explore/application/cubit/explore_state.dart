import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/state/remote_state.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending.dart';

class ExploreState extends Equatable {
  const ExploreState({
    this.trending = const RemoteState<ExploreTrending>.initial(),
  });

  final RemoteState<ExploreTrending> trending;

  bool get hasTrending => trending.data?.isEmpty == false;

  bool get isEmpty => trending.isSuccess && trending.data?.isEmpty == true;

  ExploreState copyWith({RemoteState<ExploreTrending>? trending}) {
    return ExploreState(trending: trending ?? this.trending);
  }

  @override
  List<Object?> get props => <Object?>[trending];
}
