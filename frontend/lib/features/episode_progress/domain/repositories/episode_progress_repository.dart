abstract interface class EpisodeProgressRepository {
  Future<void> markEpisodeWatched({
    required String episodeId,
    DateTime? watchedAt,
  });

  Future<void> markEpisodeUnwatched({required String episodeId});
}
