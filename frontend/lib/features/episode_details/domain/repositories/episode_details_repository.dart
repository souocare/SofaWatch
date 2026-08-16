import 'package:sofawatch/features/episode_details/domain/models/episode_details.dart';

abstract interface class EpisodeDetailsRepository {
  Future<EpisodeDetails> getById(String episodeId);
}
