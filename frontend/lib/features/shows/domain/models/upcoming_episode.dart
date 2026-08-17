import 'package:equatable/equatable.dart';

final class UpcomingEpisode extends Equatable {
  const UpcomingEpisode({
    required this.id,
    required this.tmdbId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.title,
    required this.airDate,
    required this.isWatched,
    this.runtime,
    this.stillUrl,
  });

  final String id;
  final int tmdbId;

  final int seasonNumber;
  final int episodeNumber;

  final String title;

  final DateTime airDate;
  final int? runtime;

  final String? stillUrl;

  final bool isWatched;

  String get code {
    return 'S${seasonNumber.toString().padLeft(2, '0')}'
        'E${episodeNumber.toString().padLeft(2, '0')}';
  }

  UpcomingEpisode copyWith({bool? isWatched}) {
    return UpcomingEpisode(
      id: id,
      tmdbId: tmdbId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      title: title,
      airDate: airDate,
      runtime: runtime,
      stillUrl: stillUrl,
      isWatched: isWatched ?? this.isWatched,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    tmdbId,
    seasonNumber,
    episodeNumber,
    title,
    airDate,
    runtime,
    stillUrl,
    isWatched,
  ];
}
