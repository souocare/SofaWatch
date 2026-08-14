import 'package:equatable/equatable.dart';

final class LibraryFirstEpisode extends Equatable {
  const LibraryFirstEpisode({
    required this.id,
    required this.tmdbId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.title,
    this.airDate,
    this.runtime,
  });

  final String id;
  final int tmdbId;

  final int seasonNumber;
  final int episodeNumber;

  final String title;

  final DateTime? airDate;
  final int? runtime;

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
    airDate,
    runtime,
  ];
}
