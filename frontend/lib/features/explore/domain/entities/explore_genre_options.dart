import 'package:equatable/equatable.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_genre.dart';

final class ExploreGenreOptions extends Equatable {
  const ExploreGenreOptions({
    this.shows = const <ExploreGenre>[],
    this.movies = const <ExploreGenre>[],
  });

  final List<ExploreGenre> shows;
  final List<ExploreGenre> movies;

  bool get isEmpty => shows.isEmpty && movies.isEmpty;

  @override
  List<Object?> get props => <Object?>[shows, movies];
}
