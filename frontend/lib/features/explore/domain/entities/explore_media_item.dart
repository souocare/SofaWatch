import 'package:equatable/equatable.dart';

enum ExploreMediaType { show, movie }

class ExploreMediaItem extends Equatable {
  const ExploreMediaItem({
    required this.mediaType,
    required this.tmdbId,
    required this.title,
    required this.originalTitle,
    required this.originalLanguage,
    required this.genreIds,
    required this.popularity,
    required this.voteAverage,
    required this.voteCount,
    this.overview,
    this.releaseDate,
    this.posterUrl,
    this.backdropUrl,
    this.inLibrary = false,
  });

  final ExploreMediaType mediaType;

  final int tmdbId;

  final String title;
  final String originalTitle;
  final String? overview;

  final DateTime? releaseDate;

  final Uri? posterUrl;
  final Uri? backdropUrl;

  final String originalLanguage;

  final List<int> genreIds;

  final double popularity;
  final double voteAverage;
  final int voteCount;
  final bool inLibrary;

  int? get releaseYear => releaseDate?.year;

  bool get isShow => mediaType == ExploreMediaType.show;
  bool get isMovie => mediaType == ExploreMediaType.movie;

  @override
  List<Object?> get props => <Object?>[
    mediaType,
    tmdbId,
    title,
    originalTitle,
    overview,
    releaseDate,
    posterUrl,
    backdropUrl,
    originalLanguage,
    genreIds,
    popularity,
    voteAverage,
    voteCount,
  ];
}
