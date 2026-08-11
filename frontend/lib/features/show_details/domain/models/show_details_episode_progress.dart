import 'package:equatable/equatable.dart';

final class ShowDetailsEpisodeProgress extends Equatable {
  const ShowDetailsEpisodeProgress({
    required this.id,
    required this.episodeId,
    required this.isWatched,
    this.watchedAt,
  });

  final String id;
  final String episodeId;
  final bool isWatched;
  final DateTime? watchedAt;

  @override
  List<Object?> get props => <Object?>[id, episodeId, isWatched, watchedAt];
}
