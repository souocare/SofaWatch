import 'package:equatable/equatable.dart';

final class MovieDetails extends Equatable {
  const MovieDetails({
    this.id,
    required this.tmdbId,
    required this.title,
    required this.originalTitle,
    required this.originalLanguage,
    required this.status,
    required this.voteAverage,
    required this.voteCount,
    required this.genres,
    this.overview,
    this.tagline,
    this.releaseDate,
    this.posterUrl,
    this.backdropUrl,
    this.runtime,
  });
  final String? id;
  final int tmdbId;

  final String title;
  final String originalTitle;

  final String? overview;
  final String? tagline;

  final DateTime? releaseDate;

  final String? posterUrl;
  final String? backdropUrl;

  final List<String> genres;

  final String originalLanguage;

  final int? runtime;
  final String status;

  final double voteAverage;
  final int voteCount;

  int? get releaseYear => releaseDate?.year;

  @override
  List<Object?> get props => <Object?>[
    id,
    tmdbId,
    title,
    originalTitle,
    overview,
    tagline,
    releaseDate,
    posterUrl,
    backdropUrl,
    genres,
    originalLanguage,
    runtime,
    status,
    voteAverage,
    voteCount,
  ];
}
