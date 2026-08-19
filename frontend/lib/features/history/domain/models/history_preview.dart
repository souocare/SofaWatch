import 'package:equatable/equatable.dart';
import 'package:sofawatch/features/history/domain/models/history_episode_item.dart';
import 'package:sofawatch/features/history/domain/models/history_movie_item.dart';

final class HistoryPreview extends Equatable {
  const HistoryPreview({required this.episodes, required this.movies});

  final List<HistoryEpisodeItem> episodes;
  final List<HistoryMovieItem> movies;

  bool get isEmpty => episodes.isEmpty && movies.isEmpty;

  @override
  List<Object?> get props => <Object?>[episodes, movies];
}
