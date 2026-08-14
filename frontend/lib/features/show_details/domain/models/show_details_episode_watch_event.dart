import 'package:equatable/equatable.dart';

final class ShowDetailsEpisodeWatchEvent extends Equatable {
  const ShowDetailsEpisodeWatchEvent({
    required this.id,
    required this.episodeId,
    required this.watchedAt,
  });

  final String id;
  final String episodeId;
  final DateTime watchedAt;

  @override
  List<Object?> get props => <Object?>[id, episodeId, watchedAt];
}
