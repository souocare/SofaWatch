import 'package:equatable/equatable.dart';

final class WatchHistoryEpisode extends Equatable {
  const WatchHistoryEpisode({
    required this.id,
    required this.tmdbId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.title,
    required this.watchedAt,
    required this.watchCount,
    this.airDate,
    this.runtime,
    this.stillUrl,
  });

  final String id;
  final int tmdbId;

  final int seasonNumber;
  final int episodeNumber;

  final String title;

  /// Date represented by this specific Watch History event.
  final DateTime watchedAt;

  /// Total number of historical viewing events for this Episode.
  final int watchCount;

  final DateTime? airDate;

  final int? runtime;
  final String? stillUrl;

  String get code {
    return 'S${seasonNumber.toString().padLeft(2, '0')}'
        'E${episodeNumber.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    tmdbId,
    seasonNumber,
    episodeNumber,
    title,
    watchedAt,
    watchCount,
    airDate,
    runtime,
    stillUrl,
  ];
}
