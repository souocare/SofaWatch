import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/episode_details/domain/models/episode_details_episode.dart';

void main() {
  group('EpisodeDetailsEpisode.isAvailableToWatchOn', () {
    test('returns true when Episode aired before requested date', () {
      const EpisodeDetailsEpisode episode = EpisodeDetailsEpisode(
        id: 'episode-uuid',
        tmdbId: 1947648,
        episodeNumber: 4,
        title: "Woe's Hollow",
        airDate: null,
        voteAverage: 8.5,
        voteCount: 100,
      );

      final EpisodeDetailsEpisode airedEpisode = EpisodeDetailsEpisode(
        id: episode.id,
        tmdbId: episode.tmdbId,
        episodeNumber: episode.episodeNumber,
        title: episode.title,
        airDate: DateTime(2026, 8, 14),
        voteAverage: episode.voteAverage,
        voteCount: episode.voteCount,
      );

      expect(airedEpisode.isAvailableToWatchOn(DateTime(2026, 8, 15)), isTrue);
    });

    test('returns true when Episode airs on requested date', () {
      final EpisodeDetailsEpisode episode = EpisodeDetailsEpisode(
        id: 'episode-uuid',
        tmdbId: 1947648,
        episodeNumber: 4,
        title: "Woe's Hollow",
        airDate: DateTime(2026, 8, 15),
        voteAverage: 8.5,
        voteCount: 100,
      );

      expect(episode.isAvailableToWatchOn(DateTime(2026, 8, 15, 1)), isTrue);

      expect(
        episode.isAvailableToWatchOn(DateTime(2026, 8, 15, 23, 59)),
        isTrue,
      );
    });

    test('returns false when Episode airs after requested date', () {
      final EpisodeDetailsEpisode episode = EpisodeDetailsEpisode(
        id: 'episode-uuid',
        tmdbId: 1947648,
        episodeNumber: 4,
        title: "Woe's Hollow",
        airDate: DateTime(2026, 8, 16),
        voteAverage: 8.5,
        voteCount: 100,
      );

      expect(episode.isAvailableToWatchOn(DateTime(2026, 8, 15)), isFalse);
    });

    test('returns false when Episode has no known air date', () {
      const EpisodeDetailsEpisode episode = EpisodeDetailsEpisode(
        id: 'episode-uuid',
        tmdbId: 1947648,
        episodeNumber: 4,
        title: "Woe's Hollow",
        voteAverage: 8.5,
        voteCount: 100,
      );

      expect(episode.isAvailableToWatchOn(DateTime(2026, 8, 15)), isFalse);
    });
  });
}
