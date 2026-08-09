import 'package:equatable/equatable.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_item.dart';

class ExploreTrending extends Equatable {
  ExploreTrending({
    required List<ExploreMediaItem> shows,
    required List<ExploreMediaItem> movies,
  }) : shows = List<ExploreMediaItem>.unmodifiable(shows),
       movies = List<ExploreMediaItem>.unmodifiable(movies);

  final List<ExploreMediaItem> shows;
  final List<ExploreMediaItem> movies;

  bool get isEmpty => shows.isEmpty && movies.isEmpty;

  @override
  List<Object?> get props => <Object?>[shows, movies];
}
